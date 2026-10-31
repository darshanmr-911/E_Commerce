import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/home/screens/home_screen.dart';
import 'features/owner/screens/owner_portal_screen.dart';
import 'freshkart_colors.dart';
import 'otp_verification_screen.dart';
import 'services/customer_api_client.dart';

void main() {
  runApp(const FreshKartApp());
}

class FreshKartApp extends StatelessWidget {
  const FreshKartApp({this.customerApi, super.key});

  final CustomerApiClient? customerApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshKart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FreshKartColors.green,
          surface: FreshKartColors.cream,
        ),
        scaffoldBackgroundColor: FreshKartColors.cream,
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(customerApi: customerApi),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/owner': (context) => const OwnerPortalScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.customerApi, super.key});

  final CustomerApiClient? customerApi;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _entranceDuration = Duration(milliseconds: 1100);
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late final AnimationController _entranceController;
  late final CustomerApiClient _customerApi;
  bool _isButtonPressed = false;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    _customerApi = widget.customerApi ?? CustomerApiClient();
    _entranceController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSendingOtp = true);
    try {
      final resendCooldown = await _customerApi.sendOtp(_phoneController.text);
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) =>
              OtpVerificationScreen(
                phoneNumber: _phoneController.text,
                customerApi: _customerApi,
                initialCooldownSeconds: resendCooldown,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    } on CustomerApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Widget _entrance({
    required Widget child,
    required double start,
    required double end,
  }) {
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _entrance(
                        start: 0,
                        end: 0.58,
                        child: const _BrandHeader(),
                      ),
                      const SizedBox(height: 27),
                      _entrance(
                        start: 0.12,
                        end: 0.72,
                        child: const _WelcomeSection(),
                      ),
                      const SizedBox(height: 27),
                      _entrance(
                        start: 0.27,
                        end: 0.9,
                        child: _LoginForm(
                          formKey: _formKey,
                          phoneController: _phoneController,
                          isLoading: _isSendingOtp,
                          isButtonPressed: _isButtonPressed,
                          onPressed: _continue,
                          onButtonPressChanged: (pressed) {
                            if (_isButtonPressed == pressed) {
                              return;
                            }
                            setState(() => _isButtonPressed = pressed);
                          },
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 28),
                      const _LegalFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: FreshKartColors.green,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: FreshKartColors.green.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.shopping_basket_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'FreshKart',
          style: TextStyle(
            color: FreshKartColors.darkGreen,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _GroceryIllustration(),
        const SizedBox(height: 22),
        const Text(
          'Fresh groceries, delivered to your doorstep.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FreshKartColors.text,
            fontSize: 29,
            height: 1.14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Login to get fresh products at your door.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FreshKartColors.mutedText,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _GroceryIllustration extends StatelessWidget {
  const _GroceryIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      height: 144,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: const BoxDecoration(
              color: FreshKartColors.paleGreen,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            left: 8,
            top: 17,
            child: _produceBadge(
              color: const Color(0xFFF4C65E),
              icon: Icons.spa_rounded,
              iconColor: const Color(0xFF9A6B18),
              size: 36,
            ),
          ),
          Positioned(
            right: 7,
            top: 31,
            child: _produceBadge(
              color: const Color(0xFFF2A08B),
              icon: Icons.apple_rounded,
              iconColor: const Color(0xFFB64E3B),
              size: 38,
            ),
          ),
          Positioned(
            left: 19,
            bottom: 14,
            child: _produceBadge(
              color: const Color(0xFFDCEAC9),
              icon: Icons.eco_rounded,
              iconColor: FreshKartColors.green,
              size: 35,
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: FreshKartColors.darkGreen.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_basket_rounded,
              color: FreshKartColors.green,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _produceBadge({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: size * 0.57),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.phoneController,
    required this.isLoading,
    required this.isButtonPressed,
    required this.onPressed,
    required this.onButtonPressChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final bool isLoading;
  final bool isButtonPressed;
  final VoidCallback onPressed;
  final ValueChanged<bool> onButtonPressChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8ECE5)),
        boxShadow: [
          BoxShadow(
            color: FreshKartColors.darkGreen.withValues(alpha: 0.07),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Phone number',
              style: TextStyle(
                color: FreshKartColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5EAE2)),
              ),
              child: Row(
                children: [
                  const Text(
                    '+91',
                    style: TextStyle(
                      color: FreshKartColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFDDE3DA),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('phoneNumberField'),
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.length != 10) {
                          return 'Please enter a valid 10-digit mobile number.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter 10-digit number',
                        hintStyle: TextStyle(
                          color: Color(0xFFA0AAA2),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Listener(
              onPointerDown: (_) => onButtonPressChanged(true),
              onPointerUp: (_) => onButtonPressChanged(false),
              onPointerCancel: (_) => onButtonPressChanged(false),
              child: AnimatedScale(
                scale: isButtonPressed ? 0.97 : 1,
                duration: const Duration(milliseconds: 130),
                curve: Curves.easeOut,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    key: const ValueKey('continueButton'),
                    onPressed: isLoading ? null : onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FreshKartColors.green,
                      disabledBackgroundColor: FreshKartColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            color: FreshKartColors.mutedText,
            fontSize: 12,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: FreshKartColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: FreshKartColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
