import 'package:flutter/material.dart';

/// Asks the user to confirm an action. Returns true only when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  required String cancelLabel,
  required String okLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
