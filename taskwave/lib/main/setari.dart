// lib/setari.dart

import 'package:flutter/material.dart';

class PaginaSetari extends StatelessWidget {
  const PaginaSetari({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setări'),
      ),
      body: const Center(
        child: Text(
          'Aici vei găsi setările aplicației.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
