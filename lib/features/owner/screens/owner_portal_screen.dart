import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';
import 'owner_dashboard_screen.dart';
import 'owner_login_screen.dart';

class OwnerPortalScreen extends StatefulWidget {
  const OwnerPortalScreen({super.key});

  @override
  State<OwnerPortalScreen> createState() => _OwnerPortalScreenState();
}

class _OwnerPortalScreenState extends State<OwnerPortalScreen> {
  final _api = OwnerApiClient();
  bool? _hasSession;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final hasSession = await _api.hasSession;
    if (mounted) setState(() => _hasSession = hasSession);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSession == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: FreshKartColors.green),
        ),
      );
    }
    if (_hasSession!) {
      return OwnerDashboardScreen(
        api: _api,
        onLogout: () => setState(() => _hasSession = false),
      );
    }
    return OwnerLoginScreen(
      api: _api,
      onAuthenticated: () => setState(() => _hasSession = true),
    );
  }
}
