import 'package:flutter/material.dart';

Future<String?> showRenameDialog(
  BuildContext context,
  String currentName, {
  String title = 'Renomear documento',
  bool selectAll = false,
}) {
  final controller = TextEditingController(text: currentName);
  if (selectAll) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome do documento'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
