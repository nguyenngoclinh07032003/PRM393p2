import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';

/// Điều hướng nội bộ trong khu vực admin (không thay route Navigator).
class AdminNavigation extends InheritedWidget {
  const AdminNavigation({
    super.key,
    required this.go,
    required super.child,
  });

  final void Function(String route, {bool replaceStack}) go;

  static AdminNavigation? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminNavigation>();
  }

  static void navigate(
    BuildContext context,
    String route, {
    bool replaceStack = false,
  }) {
    final nav = maybeOf(context);
    if (nav != null) {
      nav.go(route, replaceStack: replaceStack);
      return;
    }

    if (replaceStack || route == AppRoutes.home) {
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      return;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  bool updateShouldNotify(AdminNavigation oldWidget) => go != oldWidget.go;
}
