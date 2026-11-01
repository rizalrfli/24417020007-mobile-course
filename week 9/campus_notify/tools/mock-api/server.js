#!/usr/bin/env node
/**
 * Mock API untuk Campus Notify.
 *
 * Menjalankan backend tiruan di satu port supaya aplikasi Flutter bisa login
 * lewat HTTP sungguhan tanpa backend kampus. Tanpa dependency eksternal:
 * cukup `node server.js`.
 *
 * Endpoint:
 *   GET  /health              -> cek server hidup
 *   POST /auth/login          -> {access_token, refresh_token, user}
 *   POST /auth/refresh        -> {access_token}
 *   POST /auth/logout         -> mencabut refresh token
 *   POST /devices             -> mendaftarkan FCM token (butuh Bearer)
 *   GET  /devices             -> daftar token terdaftar (butuh Bearer)
 *   GET  /pengumuman/:id      -> isi pengumuman untuk halaman deep link
 *
 * Akun demo ada di bagian ACCOUNTS. Token ditandatangani HMAC supaya
 * kedaluwarsanya bisa diuji, bukan string acak tanpa makna.
 */

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');
const { URL } = require('node:url');

const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || '0.0.0.0';

// Jangan pakai nilai ini di produksi. Cukup untuk demo lokal.
const SECRET = process.env.MOCK_API_SECRET || 'mock-api-secret-untuk-demo-lokal';
const ACCESS_TTL_SECONDS = Number(process.env.ACCESS_TTL || 3600);
const REFRESH_TTL_SECONDS = Number(process.env.REFRESH_TTL || 86400);

/** Akun demo. Tambah baris baru kalau butuh akun lain. */
const ACCOUNTS = [
  {
    id: 'u-1',
    email: 'mhs@polinema.ac.id',
    password: 'rahasia1',
    name: 'Mahasiswa Demo',
  },
  {
    id: 'u-2',
    email: 'admin@polinema.ac.id',
    password: 'admin123',
    name: 'Admin Jurusan',
  },
];

/** refresh token -> {userId, expiresAt} */
const refreshTokens = new Map();
/** access token -> {userId, expiresAt}. Dipakai untuk validasi cepat. */
const accessTokens = new Map();
/** fcm token -> {userId, platform, registeredAt} */
const devices = new Map();

// ---------------------------------------------------------------- token util

function base64url(input) {
  return Buffer.from(input).toString('base64url');
}

function sign(payload) {
  return crypto
    .createHmac('sha256', SECRET)
    .update(payload)
    .digest('base64url');
}

function issueToken(userId, kind, ttlSeconds) {
  const now = Math.floor(Date.now() / 1000);
  const body = {
    sub: userId,
    typ: kind,
    iat: now,
    exp: now + ttlSeconds,
    jti: crypto.randomUUID(),
  };
  const payload = base64url(JSON.stringify(body));
  const token = `${payload}.${sign(payload)}`;
  const store = kind === 'access' ? accessTokens : refreshTokens;
  store.set(token, { userId, expiresAt: body.exp * 1000 });
  return token;
}

/** Mengembalikan userId bila token sah dan belum kedaluwarsa, selain itu null. */
function verifyToken(token, kind) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [payload, signature] = token.split('.');
  if (sign(payload) !== signature) return null;

  let body;
  try {
    body = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (body.typ !== kind) return null;
  if (body.exp * 1000 < Date.now()) {
    const store = kind === 'access' ? accessTokens : refreshTokens;
    store.delete(token);
    return null;
  }

  // Tanda tangan sah belum cukup: token yang sudah dicabut (logout, atau
  // refresh token yang sudah diputar) harus ditolak walau HMAC-nya benar.
  const store = kind === 'access' ? accessTokens : refreshTokens;
  const entry = store.get(token);
  if (!entry) return null;
  if (entry.expiresAt < Date.now()) {
    store.delete(token);
    return null;
  }
  return body.sub || null;
}

// ------------------------------------------------------------------ helpers

function json(res, status, body) {
  const text = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(text),
    'Cache-Control': 'no-store',
  });
  res.end(text);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      // Batas kecil: payload login tidak pernah sebesar ini.
      if (raw.length > 1_000_000) {
        reject(new Error('Body terlalu besar'));
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new Error('Body bukan JSON yang valid'));
      }
    });
    req.on('error', reject);
  });
}

function bearer(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  return header.slice(7).trim();
}

function requireAuth(req, res) {
  const userId = verifyToken(bearer(req), 'access');
  if (!userId) {
    json(res, 401, { message: 'Token tidak valid atau sudah kedaluwarsa.' });
    return null;
  }
  return userId;
}

function findUser(email) {
  return ACCOUNTS.find(
    (account) => account.email.toLowerCase() === String(email).toLowerCase(),
  );
}

function publicUser(account) {
  return { id: account.id, email: account.email, name: account.name };
}

function log(req, status) {
  const time = new Date().toISOString().slice(11, 19);
  console.log(`[${time}] ${status} ${req.method} ${req.url}`);
}

// ------------------------------------------------------------------- routes

async function handleLogin(req, res) {
  const body = await readBody(req);
  const email = String(body.email || '').trim();
  const password = String(body.password || '');

  if (!email || !password) {
    return json(res, 400, { message: 'Email dan password wajib diisi.' });
  }

  const account = findUser(email);
  // Pesan sengaja sama untuk email tidak dikenal dan password salah, supaya
  // tidak membocorkan email mana yang terdaftar.
  if (!account || account.password !== password) {
    return json(res, 401, { message: 'Email atau password salah.' });
  }

  const accessToken = issueToken(account.id, 'access', ACCESS_TTL_SECONDS);
  const refreshToken = issueToken(account.id, 'refresh', REFRESH_TTL_SECONDS);

  return json(res, 200, {
    access_token: accessToken,
    refresh_token: refreshToken,
    token_type: 'Bearer',
    expires_in: ACCESS_TTL_SECONDS,
    user: publicUser(account),
  });
}

async function handleRefresh(req, res) {
  const body = await readBody(req);
  const userId = verifyToken(body.refresh_token, 'refresh');
  if (!userId) {
    return json(res, 401, { message: 'Refresh token tidak valid.' });
  }

  // Refresh token lama diputar: yang dipakai sekali langsung mati.
  refreshTokens.delete(body.refresh_token);
  const accessToken = issueToken(userId, 'access', ACCESS_TTL_SECONDS);
  const refreshToken = issueToken(userId, 'refresh', REFRESH_TTL_SECONDS);

  return json(res, 200, {
    access_token: accessToken,
    refresh_token: refreshToken,
    expires_in: ACCESS_TTL_SECONDS,
  });
}

async function handleLogout(req, res) {
  const body = await readBody(req);
  if (body.refresh_token) refreshTokens.delete(body.refresh_token);
  const token = bearer(req);
  if (token) accessTokens.delete(token);
  return json(res, 200, { message: 'Sesi diakhiri.' });
}

async function handleRegisterDevice(req, res) {
  const userId = requireAuth(req, res);
  if (!userId) return;

  const body = await readBody(req);
  const fcmToken = String(body.fcm_token || '').trim();
  if (!fcmToken) {
    return json(res, 400, { message: 'fcm_token wajib diisi.' });
  }

  devices.set(fcmToken, {
    userId,
    platform: String(body.platform || 'unknown'),
    registeredAt: new Date().toISOString(),
  });

  return json(res, 200, { message: 'Token perangkat tersimpan.' });
}

function handleListDevices(req, res) {
  const userId = requireAuth(req, res);
  if (!userId) return;

  const mine = [...devices.entries()]
    .filter(([, value]) => value.userId === userId)
    .map(([token, value]) => ({
      // Hanya 12 karakter pertama, sama seperti layar Debug aplikasi.
      fcm_token_prefix: `${token.slice(0, 12)}...`,
      platform: value.platform,
      registered_at: value.registeredAt,
    }));

  return json(res, 200, { devices: mine });
}

function handleAnnouncement(req, res, id) {
  return json(res, 200, {
    id,
    title: 'Jadwal kuliah berubah',
    body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00.',
    published_at: '2026-11-01T08:00:00+07:00',
  });
}

// -------------------------------------------------------------------- server

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const path = url.pathname.replace(/\/+$/, '') || '/';

  // CORS: hanya untuk kenyamanan saat menguji lewat browser/curl.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  try {
    if (req.method === 'GET' && path === '/health') {
      log(req, 200);
      return json(res, 200, {
        status: 'ok',
        accounts: ACCOUNTS.map((a) => a.email),
        devices: devices.size,
      });
    }
    if (req.method === 'POST' && path === '/auth/login') {
      log(req, 200);
      return await handleLogin(req, res);
    }
    if (req.method === 'POST' && path === '/auth/refresh') {
      log(req, 200);
      return await handleRefresh(req, res);
    }
    if (req.method === 'POST' && path === '/auth/logout') {
      log(req, 200);
      return await handleLogout(req, res);
    }
    if (req.method === 'POST' && path === '/devices') {
      log(req, 200);
      return await handleRegisterDevice(req, res);
    }
    if (req.method === 'GET' && path === '/devices') {
      log(req, 200);
      return handleListDevices(req, res);
    }
    if (req.method === 'GET' && path.startsWith('/pengumuman/')) {
      log(req, 200);
      return handleAnnouncement(req, res, path.split('/').pop());
    }

    log(req, 404);
    return json(res, 404, { message: `Rute ${path} tidak ada.` });
  } catch (error) {
    log(req, 400);
    return json(res, 400, { message: error.message || 'Permintaan ditolak.' });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Mock API Campus Notify berjalan di http://${HOST}:${PORT}`);
  console.log('Akun demo:');
  for (const account of ACCOUNTS) {
    console.log(`  ${account.email} / ${account.password}`);
  }
  console.log(`Access token berlaku ${ACCESS_TTL_SECONDS} detik.`);
});
