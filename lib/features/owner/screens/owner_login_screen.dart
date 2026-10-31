import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({
    required this.api,
    required this.onAuthenticated,
    super.key,
  });

  final OwnerApiClient api;
  final VoidCallback onAuthenticated;

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.api.login(_identifier.text.trim(), _password.text);
      if (mounted) widget.onAuthenticated();
    } on OwnerApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your owner password'),
        content: const Text(
          'Password recovery is not enabled yet. Contact the FreshKart '
          'administrator to reset your owner account securely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FreshKartColors.cream,
        surfaceTintColor: Colors.transparent,
        title: const Text('Shop Owner'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: FreshKartColors.paleGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 37,
                        color: FreshKartColors.green,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: FreshKartColors.text,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Sign in to manage your FreshKart shop.',
                      style: TextStyle(color: FreshKartColors.mutedText),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      key: const ValueKey('ownerIdentifier'),
                      controller: _identifier,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone number or email',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your phone number or email.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const ValueKey('ownerPassword'),
                      controller: _password,
                      obscureText: _obscurePassword,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (_error case final error?) ...[
                      Text(
                        error,
                        key: const ValueKey('ownerLoginError'),
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                    ],
                    FilledButton(
                      key: const ValueKey('ownerLoginButton'),
                      onPressed: _isSubmitting ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: FreshKartColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in securely'),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Owner access is verified by the FreshKart server.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FreshKartColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
