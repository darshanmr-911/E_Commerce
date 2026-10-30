import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'freshkart_colors.dart';

enum OtpVerificationResult { invalidCode, unavailable }

class OtpVerificationPlaceholder {
  const OtpVerificationPlaceholder();

  Future<OtpVerificationResult> verify(String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return OtpVerificationResult.invalidCode;
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    return OtpVerificationResult.unavailable;
  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({required this.phoneNumber, super.key});

  final String phoneNumber;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  static const _digitCount = 6;
  static const _countdownDuration = 30;
  static const _placeholderMessage =
      'Temporary placeholder: OTP verification is not connected. No login has taken place.';

  final _controllers = List.generate(
    _digitCount,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_digitCount, (_) => FocusNode());
  final _verificationPlaceholder = const OtpVerificationPlaceholder();
  late final AnimationController _entranceController;
  late final AnimationController _feedbackController;
  late final Animation<double> _shakeAnimation;
  Timer? _countdownTimer;
  int _secondsRemaining = _countdownDuration;
  bool _showIncompleteError = false;
  bool _isLoading = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  String get _code => _controllers.map((controller) => controller.text).join();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -7), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 7, end: -4), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
        );
    for (final focusNode in _focusNodes) {
      focusNode.addListener(_handleFocusChange);
    }
    for (final controller in _controllers) {
      controller.addListener(_handleCodeChange);
    }
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _controllers) {
      controller
        ..removeListener(_handleCodeChange)
        ..dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode
        ..removeListener(_handleFocusChange)
        ..dispose();
    }
    _entranceController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleCodeChange() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showIncompleteError = false;
      _feedbackIsError = false;
      _feedbackMessage = _code.length == _digitCount
          ? '6 digits entered'
          : null;
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = _countdownDuration);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _digitCount - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  Future<void> _verify() async {
    if (_isLoading) {
      return;
    }
    if (_code.length != _digitCount || !RegExp(r'^\d{6}$').hasMatch(_code)) {
      setState(() {
        _showIncompleteError = true;
        _feedbackMessage = 'Please enter all 6 digits.';
        _feedbackIsError = true;
      });
      _feedbackController.forward(from: 0);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    final result = await _verificationPlaceholder.verify(_code);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _feedbackMessage = result == OtpVerificationResult.unavailable
          ? _placeholderMessage
          : 'Please enter all 6 digits.';
      _feedbackIsError = result == OtpVerificationResult.invalidCode;
      _showIncompleteError = result == OtpVerificationResult.invalidCode;
    });
    _feedbackController.forward(from: 0);
  }

  void _resend() {
    if (_secondsRemaining != 0) {
      return;
    }
    _startCountdown();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Resend is a UI-only placeholder. No SMS has been sent.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _entrance({required Widget child, required double start}) {
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
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
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 34,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        key: const ValueKey('otpBackButton'),
                        tooltip: 'Back to login',
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: FreshKartColors.darkGreen,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _entrance(start: 0, child: const _OtpBrandHeader()),
                    const SizedBox(height: 28),
                    _entrance(start: 0.08, child: const _OtpHeading()),
                    const SizedBox(height: 20),
                    _entrance(
                      start: 0.17,
                      child: _PhoneNumberBadge(phoneNumber: widget.phoneNumber),
                    ),
                    const SizedBox(height: 28),
                    _entrance(
                      start: 0.25,
                      child: OtpDigitFields(
                        controllers: _controllers,
                        focusNodes: _focusNodes,
                        onChanged: _onDigitChanged,
                        hasError: _showIncompleteError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: Listenable.merge(_controllers),
                      builder: (context, child) => _FeedbackMessage(
                        message:
                            _feedbackMessage ??
                            (_code.length == _digitCount && !_isLoading
                                ? '6 digits entered'
                                : null),
                        isError: _feedbackIsError,
                        shakeAnimation: _shakeAnimation,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _entrance(
                      start: 0.35,
                      child: _ResendCountdown(
                        secondsRemaining: _secondsRemaining,
                        onResend: _resend,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _entrance(
                      start: 0.44,
                      child: _VerifyButton(
                        isLoading: _isLoading,
                        onPressed: _verify,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    const Text(
                      'OTP verification is a temporary placeholder. SMS and authentication are not connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FreshKartColors.mutedText,
                        fontSize: 12,
                        height: 1.5,
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

class OtpDigitFields extends StatelessWidget {
  const OtpDigitFields({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.hasError,
    super.key,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(controllers.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == controllers.length - 1 ? 0 : 8,
            ),
            child: _OtpDigitField(
              index: index,
              controller: controllers[index],
              focusNode: focusNodes[index],
              previousFocusNode: index == 0 ? null : focusNodes[index - 1],
              onChanged: (value) => onChanged(index, value),
              hasError: hasError,
            ),
          ),
        );
      }),
    );
  }
}

class _OtpDigitField extends StatelessWidget {
  const _OtpDigitField({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.previousFocusNode,
    required this.onChanged,
    required this.hasError,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasError
              ? const Color(0xFFD84B4B)
              : focusNode.hasFocus
              ? FreshKartColors.green
              : const Color(0xFFE1E8DF),
          width: focusNode.hasFocus ? 1.8 : 1.2,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: FreshKartColors.green.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty &&
              previousFocusNode != null) {
            previousFocusNode!.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          key: ValueKey('otpDigit$index'),
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: index == 5
              ? TextInputAction.done
              : TextInputAction.next,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: FreshKartColors.darkGreen,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
        ),
      ),
    );
  }
}

class _OtpBrandHeader extends StatelessWidget {
  const _OtpBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: FreshKartColors.green,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.shopping_basket_rounded,
            color: Colors.white,
            size: 25,
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

class _OtpHeading extends StatelessWidget {
  const _OtpHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Verify Your Number',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FreshKartColors.text,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "We've sent a verification code to your mobile number.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FreshKartColors.mutedText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PhoneNumberBadge extends StatelessWidget {
  const _PhoneNumberBadge({required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: FreshKartColors.paleGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.phone_iphone_rounded,
            size: 18,
            color: FreshKartColors.green,
          ),
          const SizedBox(width: 8),
          Text(
            '+91 $phoneNumber',
            style: const TextStyle(
              color: FreshKartColors.darkGreen,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({
    required this.message,
    required this.isError,
    required this.shakeAnimation,
  });

  final String? message;
  final bool isError;
  final Animation<double> shakeAnimation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: message == null ? 0 : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: message == null
            ? const SizedBox.shrink(key: ValueKey('emptyFeedback'))
            : AnimatedBuilder(
                key: ValueKey(message),
                animation: shakeAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(isError ? shakeAnimation.value : 0, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 17,
                      color: isError
                          ? const Color(0xFFC33D3D)
                          : FreshKartColors.green,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isError
                              ? const Color(0xFFC33D3D)
                              : FreshKartColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ResendCountdown extends StatelessWidget {
  const _ResendCountdown({
    required this.secondsRemaining,
    required this.onResend,
  });

  final int secondsRemaining;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsRemaining == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          canResend ? 'Didn’t receive the code? ' : 'Resend OTP in 00:',
          style: const TextStyle(
            color: FreshKartColors.mutedText,
            fontSize: 13,
          ),
        ),
        TextButton(
          key: const ValueKey('resendOtpButton'),
          onPressed: canResend ? onResend : null,
          style: TextButton.styleFrom(
            foregroundColor: FreshKartColors.green,
            disabledForegroundColor: FreshKartColors.darkGreen,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            canResend
                ? 'Resend OTP'
                : secondsRemaining.toString().padLeft(2, '0'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _VerifyButton extends StatefulWidget {
  const _VerifyButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            key: const ValueKey('verifyOtpButton'),
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: FreshKartColors.green,
              disabledBackgroundColor: FreshKartColors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.isLoading
                  ? const Row(
                      key: ValueKey('otpLoading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 11),
                        Text(
                          'Verifying...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Verify',
                      key: ValueKey('verify'),
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
    );
  }
}
