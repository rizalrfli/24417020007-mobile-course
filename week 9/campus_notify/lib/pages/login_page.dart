import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/server_config.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _server = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  bool _serverOpen = false;
  String? _error;
  String? _diagnostic;
  String? _serverHint;

  @override
  void initState() {
    super.initState();
    _server.text = ref.read(serverUrlProvider);
    // Alamat contoh berarti belum pernah diatur: buka panel server supaya
    // pengguna langsung tahu harus mengisinya.
    _serverOpen = isPlaceholderUrl(_server.text);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _diagnostic = null;
      _serverHint = null;
    });
    await ref
        .read(authStateProvider.notifier)
        .login(_email.text.trim(), _password.text);

    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      setState(() {
        _error = _friendly(state.error);
        _diagnostic = describeAuthFailure(
          state.error,
          ref.read(serverUrlProvider),
        );
      });
      return;
    }
    // Guard route di router memindahkan pengguna; rute tertunda dari notifikasi
    // dibuka oleh listener di `main.dart` setelah status login berubah.
  }

  /// Menyimpan alamat server yang diketik. Login berikutnya langsung memakai
  /// alamat ini, tanpa perlu menjalankan ulang aplikasi dengan flag.
  Future<void> _saveServer() async {
    final ok = await ref.read(serverUrlProvider.notifier).save(_server.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _serverHint = 'Alamat tidak sah. Contoh: http://10.0.2.2:8080');
      return;
    }
    final saved = ref.read(serverUrlProvider);
    _server.text = saved;
    setState(() {
      _serverHint = 'Tersimpan: $saved';
      _diagnostic = null;
      _error = null;
    });
  }

  /// Menembak `GET /health` untuk memisahkan "server tidak terjangkau" dari
  /// "kredensial salah". Tanpa ini, pengguna hanya melihat pesan umum dan
  /// menebak-nebak apakah masalahnya jaringan, URL, atau kata sandi.
  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _diagnostic = null;
      _error = null;
      _serverHint = null;
    });
    final result = await pingApi(
      ref.read(authDioProvider),
      ref.read(serverUrlProvider),
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      if (result.ok) {
        _diagnostic = 'Server terjangkau (${result.detail}). '
            'Kalau login masih gagal, periksa email dan kata sandi.';
      } else {
        _error = 'Server tidak terjangkau.';
        _diagnostic = result.detail;
      }
    });
  }

  String _friendly(Object? error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final error = _error ?? (auth.hasError ? _friendly(auth.error) : null);
    final diagnostic = _diagnostic ??
        (auth.hasError
            ? describeAuthFailure(auth.error, ref.read(serverUrlProvider))
            : null);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Campus Notify', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk menerima pengumuman kampus.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _serverPanel(theme),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'nama@student.polinema.ac.id',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('password'),
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscure
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
                if (diagnostic != null) ...[
                  const SizedBox(height: 8),
                  _note(theme, diagnostic, selectable: true),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Masuk'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed:
                      (_testing || auth.isLoading) ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 18),
                  label: const Text('Tes koneksi ke server'),
                ),
                const SizedBox(height: 16),
                Text(
                  useMockAuth
                      ? 'Mode demo: autentikasi tiruan aktif. Email apa pun yang '
                          'mengandung @ dan kata sandi 6 karakter akan diterima.'
                      : 'Masuk memakai akun kampus Anda.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serverPanel(ThemeData theme) {
    final current = ref.watch(serverUrlProvider);
    final placeholder = isPlaceholderUrl(current);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: placeholder
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _serverOpen = !_serverOpen),
            child: Row(
              children: [
                Icon(
                  placeholder ? Icons.warning_amber : Icons.dns_outlined,
                  size: 18,
                  color: placeholder ? theme.colorScheme.error : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Server: $current',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _serverOpen ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
              ],
            ),
          ),
          if (placeholder)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 26),
              child: Text(
                'Alamat contoh belum diganti. Isi alamat backend lalu tekan '
                'Simpan, atau login tidak akan pernah berhasil.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          if (_serverOpen) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('server'),
              controller: _server,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Alamat server',
                hintText: 'http://10.0.2.2:8080',
                helperText: 'Emulator: 10.0.2.2 · HP fisik: IP laptop',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _saveServer(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _saveServer,
                    child: const Text('Simpan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(serverUrlProvider.notifier).reset();
                      if (!mounted) return;
                      _server.text = ref.read(serverUrlProvider);
                      setState(() => _serverHint = 'Dikembalikan ke default.');
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
            if (_serverHint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_serverHint!, style: theme.textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
  }

  Widget _note(ThemeData theme, String text, {bool selectable = false}) {
    final style = theme.textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: selectable
          ? SelectableText(text, style: style)
          : Text(text, style: style),
    );
  }
}
