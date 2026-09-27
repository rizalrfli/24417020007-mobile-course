import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LokasiSayaButton extends StatefulWidget {
  const LokasiSayaButton({super.key});

  @override
  State<LokasiSayaButton> createState() => _LokasiSayaButtonState();
}

class _LokasiSayaButtonState extends State<LokasiSayaButton> {
  final Location _location = Location();
  bool _loading = false;

  Future<void> _showLocation() async {
    setState(() => _loading = true);
    try {
      final message = await _getLocationMessage();
      if (!mounted) return;
      setState(() => _loading = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lokasi saya'),
          scrollable: true,
          content: SelectableText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _getLocationMessage() async {
    try {
      var enabled = await _location.serviceEnabled();
      if (!enabled) enabled = await _location.requestService();
      if (!enabled) {
        return 'GPS belum aktif. Aktifkan layanan lokasi di pengaturan perangkat, lalu coba lagi.';
      }

      var permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }
      if (permission == PermissionStatus.deniedForever) {
        return 'Izin lokasi diblokir. Izinkan akses lokasi untuk aplikasi ini di pengaturan perangkat, lalu coba lagi.';
      }
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        return 'Izin lokasi ditolak. Tekan Lokasi saya kembali dan izinkan akses untuk melihat posisi Anda.';
      }

      final position = await _location.getLocation().timeout(
        const Duration(seconds: 20),
      );
      final latitude = position.latitude;
      final longitude = position.longitude;
      if (!latitude.isFinite ||
          !longitude.isFinite ||
          latitude.abs() > 90 ||
          longitude.abs() > 180) {
        return 'Koordinat belum tersedia. Pastikan GPS aktif, lalu coba lagi.';
      }
      return 'Latitude: ${latitude.toStringAsFixed(6)}\n'
          'Longitude: ${longitude.toStringAsFixed(6)}';
    } on TimeoutException {
      return 'Lokasi belum ditemukan. Coba di tempat dengan sinyal GPS lebih baik, lalu tekan Lokasi saya kembali.';
    } catch (_) {
      return 'Lokasi gagal diambil. Periksa izin lokasi dan GPS perangkat, lalu coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _showLocation,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(_loading ? 'Mencari lokasi...' : 'Lokasi saya'),
    );
  }
}
