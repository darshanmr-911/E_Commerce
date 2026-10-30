import 'dart:async';

import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../data/home_sample_data.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({required this.onShopNow, super.key});

  final VoidCallback onShopNow;

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  static const _slideDuration = Duration(seconds: 4);

  final _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_slideDuration, (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextPage = (_currentPage + 1) % promoSlides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 194,
          child: PageView.builder(
            key: const ValueKey('promoCarousel'),
            controller: _pageController,
            itemCount: promoSlides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final slide = promoSlides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PromoSlide(
                  eyebrow: slide.eyebrow,
                  title: slide.title,
                  subtitle: slide.subtitle,
                  artwork: slide.artwork,
                  onShopNow: widget.onShopNow,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(promoSlides.length, (index) {
            final selected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 19 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected
                    ? FreshKartColors.green
                    : const Color(0xFFD7DED5),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.onShopNow,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String artwork;
  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF236F41), Color(0xFF3C9257)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: FreshKartColors.green.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -50,
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.16, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey(artwork),
                width: 118,
                height: 125,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(60),
                ),
                alignment: Alignment.center,
                child: Text(artwork, style: const TextStyle(fontSize: 65)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 17, 132, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.83),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: FilledButton(
                    key: const ValueKey('shopNowButton'),
                    onPressed: onShopNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: FreshKartColors.darkGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Shop Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
