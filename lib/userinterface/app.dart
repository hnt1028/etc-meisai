import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/userinterface/app_shell.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_screen.dart';
import 'package:etc_meisai/userinterface/settings/settings_screen.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_screen.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/statements',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statements',
                builder: (context, state) => const StatementListScreen(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      return StatementDetailScreen(
                        line: extra is StatementLineDTO ? extra : null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'ic-mapping',
                    builder: (context, state) => const IcMappingScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
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
    return MaterialApp.router(
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      routerConfig: _router,
    );
  }

  /// Material 3, with colors made from one seed color. The dark theme follows
  /// the device setting.
  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F6EA8),
      brightness: brightness,
    ),
  );
}
