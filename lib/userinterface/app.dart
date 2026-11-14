import 'package:flutter/material.dart';

/// Root widget of the application. Screens are added in later steps.
class EtcMeisaiApp extends StatelessWidget {
  const EtcMeisaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SizedBox.shrink());
  }
}
