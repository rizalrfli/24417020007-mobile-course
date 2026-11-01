# FCM HTTP v1: kirim pesan uji

Skrip `tools/send-test-push.ps1` mengirim payload gabungan `notification + data`
ke satu perangkat atau ke topik `pengumuman-kampus`, tanpa membuka Firebase
Console.

## Siapkan access token

```powershell
firebase login:ci            # sekali saja, simpan token yang dicetak
$env:FCM_ACCESS_TOKEN = "<token>"
```

Access token OAuth berumur sekitar satu jam. Jangan tulis token ke repo,
screenshot, atau log.

## Kirim

```powershell
# Ke satu perangkat (uji foreground/background/terminated)
./tools/send-test-push.ps1 -Token "<token perangkat>"

# Ke topik
./tools/send-test-push.ps1 -Topic pengumuman-kampus
```

Payload yang dikirim:

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": { "route": "/pengumuman/3", "id": "3" },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "pengumuman_v2",
        "sound": "default"
      }
    }
  }
}
```

`notification` dipakai sistem untuk banner otomatis di background/terminated.
`data.route` dibaca aplikasi saat banner diklik. Kalau `route` diubah ke nilai
yang tidak dikenal (mis. `/admin`), aplikasi kembali ke beranda, bukan membuka
layar kosong.

`android.notification.channel_id` **wajib** diisi `pengumuman_v2` agar banner
dari background memakai kanal yang dibuat aplikasi (bunyi + getar aktif). Tanpa
field itu FCM memakai kanal cadangan bawaannya sendiri, yang bisa senyap
tergantung perangkat.

## Kalau token perangkat tidak tersedia

Firebase Console -> Messaging -> Create campaign -> Notification. Isi title dan
body, lalu di bagian Additional options -> Custom data tambahkan `route` =
`/pengumuman/3` dan `id` = `3`.
