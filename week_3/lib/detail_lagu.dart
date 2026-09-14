import 'package:flutter/material.dart';

import 'liriklagu.dart';

class DetailLagu extends StatelessWidget {
  const DetailLagu({super.key, required this.lagu});

  final Liriklagu lagu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail lagu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Image.asset(
                'assets/image.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(lagu.judul, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Penyanyi: ${lagu.penyanyi}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
