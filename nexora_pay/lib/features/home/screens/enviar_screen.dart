import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class EnviarScreen extends StatelessWidget {
  const EnviarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Transferir dinheiro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Funcionalidade em desenvolvimento',
              style: TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
