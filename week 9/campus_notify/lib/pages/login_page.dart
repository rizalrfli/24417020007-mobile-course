import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  String? _error;
  String? _diagnostic;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _diagnostic = null;
    });
    await ref
        .read(authStateProvider.notifier)
        .login(_email.text.trim(), _password.text);

    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      setState(() {
        _error = _friendly(state.error);
        _diagnostic = describeAuthFailure(state.error, apiBaseUrl);
      });
      return;
    }
    // Guard route di router memindahkan pengguna; rute tertunda dari notifikasi
    // dibuka oleh listener di `main.dart` setelah status login berubah.
  }

  /// Menembak `GET /health` untuk memisahkan "server tidak terjangkau" dari
  /// "kredensial salah". Tanpa ini, pengguna hanya melihat pesan umum dan
  /// menebak-nebak apakah masalahnya jaringan, URL, atau kata sandi.
  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _diagnostic = null;
      _error = null;
    });
    final result = await pingApi(ref.read(authDioProvider));
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
    final diagnostic =
        _diagnostic ?? (auth.hasError ? describeAuthFailure(auth.error, apiBaseUrl) : null);

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
                const SizedBox(height: 32),
                TextField(
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      diagnostic,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
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
                  onPressed: (_testing || auth.isLoading) ? null : _testConnection,
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
                const SizedBox(height: 4),
                // Ditampilkan supaya salah set --dart-define langsung terlihat,
                // bukan jadi tebakan.
                SelectableText(
                  'Server: $apiBaseUrl',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
