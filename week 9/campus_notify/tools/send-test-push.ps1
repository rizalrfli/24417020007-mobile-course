#!/usr/bin/env pwsh
<#
Kirim pesan FCM HTTP v1 dengan payload gabungan notification + data.

Butuh access token OAuth yang punya izin cloudmessaging. Jangan commit token ke
repo, dan jangan tempel token ke screenshot.

Contoh:
  $env:FCM_ACCESS_TOKEN = "<token>"
  ./tools/send-test-push.ps1 -Token "<token perangkat>"
  ./tools/send-test-push.ps1 -Topic "pengumuman-kampus"
#>
param(
  [string]$Token,
  [string]$Topic = "pengumuman-kampus",
  [string]$ProjectId = "campus-notify-24417020007",
  [string]$Route = "/pengumuman/3",
  [string]$Id = "3",
  [string]$Title = "Jadwal kuliah berubah",
  [string]$Body = "Kelas Mobile pindah ke Ruang A2 jam 13.00"
)

if (-not $env:FCM_ACCESS_TOKEN) {
  throw "Set FCM_ACCESS_TOKEN dulu (lihat docs/fcm-send.md)."
}

$message = @{
  notification = @{ title = $Title; body = $Body }
  data         = @{ route = $Route; id = $Id }
  android      = @{ priority = "high" }
}

if ($Token) {
  $message.token = $Token
} else {
  $message.topic = $Topic
}

$payload = @{ message = $message } | ConvertTo-Json -Depth 6

$response = Invoke-RestMethod `
  -Uri "https://fcm.googleapis.com/v1/projects/$ProjectId/messages:send" `
  -Method Post `
  -Headers @{ Authorization = "Bearer $($env:FCM_ACCESS_TOKEN)" } `
  -ContentType "application/json; charset=utf-8" `
  -Body $payload

$response | ConvertTo-Json -Depth 4
