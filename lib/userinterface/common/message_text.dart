import 'package:flutter/material.dart';

/// A line of text shown under a button, such as a result or an error.
class MessageText extends StatelessWidget {
  const MessageText(this.text, {super.key, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: isError
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
    );
  }
}
