import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../services/customer_api_client.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({required this.api, super.key});

  final CustomerApiClient api;

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;
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
      if (mounted) Navigator.of(context).pop(true);
    } on CustomerApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Customer sign in'),
      backgroundColor: FreshKartColors.cream,
      surfaceTintColor: Colors.transparent,
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
                  const Text(
                    'Sign in to place your order',
                    style: TextStyle(
                      color: FreshKartColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use the customer account registered with FreshKart.',
                    style: TextStyle(color: FreshKartColors.mutedText),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _identifier,
                    decoration: const InputDecoration(
                      labelText: 'Phone number or email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your phone or email.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    onFieldSubmitted: (_) => _login(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 10),
                    Text(error, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: FreshKartColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign in securely'),
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
