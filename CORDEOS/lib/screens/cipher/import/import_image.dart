import 'package:flutter/material.dart';

class ImportImageScreen extends StatelessWidget {
  final bool isNewCipher;

  const ImportImageScreen({super.key, required this.isNewCipher});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar de Imagem')),
      body: Center(
        child: Text(
          isNewCipher
              ? 'Tela para importar uma nova cifra de uma imagem.'
              : 'Tela para importar uma cifra existente de uma imagem.',
        ),
      ),
    );
  }
}
