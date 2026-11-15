import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The frame around the screens: a bottom navigation bar that switches them.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: AppStrings.statementsTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: AppStrings.routeMapTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: AppStrings.settingsTab,
          ),
        ],
      ),
    );
  }
}
