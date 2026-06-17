import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/view/Authentication/AccessDeniedPage.dart';
import 'package:sams/view/Authentication/LoginPage.dart';

/// Wraps a page and redirects if the user is not logged in or lacks permission.
class AuthRouteGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;

  const AuthRouteGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Not logged in -> go to login
    if (!auth.checkSession()) {
      return _RedirectShell(
        target: const LoginPage(),
      );
    }

    // Logged in but wrong role -> access denied
    final hasPermission =
        allowedRoles.any((role) => auth.hasRole(role));
    if (!hasPermission) {
      return _RedirectShell(
        target: const AccessDeniedPage(),
      );
    }

    return child;
  }
}

/// Shows a brief loader, then navigates to the target page.
class _RedirectShell extends StatefulWidget {
  final Widget target;

  const _RedirectShell({required this.target});

  @override
  State<_RedirectShell> createState() => _RedirectShellState();
}

class _RedirectShellState extends State<_RedirectShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => widget.target),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
