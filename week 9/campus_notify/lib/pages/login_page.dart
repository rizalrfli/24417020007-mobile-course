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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    await ref
        .read(authStateProvider.notifier)
        .login(_email.text.trim(), _password.text);

    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      setState(() => _error = _friendly(state.error));
      return;
    }
    // Guard route di router memindahkan pengguna; rute tertunda dari notifikasi
    // dibuka oleh listener di `main.dart` setelah status login berubah.
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
                    helperText: 'Minimal 6 karakter',
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
}
