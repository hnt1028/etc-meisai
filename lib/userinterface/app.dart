import 'package:etc_meisai/userinterface/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

/// Root widget of the application.
class EtcMeisaiApp extends StatefulWidget {
  const EtcMeisaiApp({super.key});

  @override
  State<EtcMeisaiApp> createState() => _EtcMeisaiAppState();
}

class _EtcMeisaiAppState extends State<EtcMeisaiApp> {
  late final GoRouter _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
