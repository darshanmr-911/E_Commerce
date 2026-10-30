import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.onNotificationTap, super.key});

  final VoidCallback onNotificationTap;

  String _greetingForHour(int hour) {
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FreshKartColors.green,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'FreshKart',
                style: TextStyle(
                  color: FreshKartColors.darkGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const ValueKey('notificationButton'),
                tooltip: 'Notifications',
                onPressed: onNotificationTap,
                style: IconButton.styleFrom(
                  foregroundColor: FreshKartColors.darkGreen,
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            '${_greetingForHour(DateTime.now().hour)} 👋',
            style: const TextStyle(
              color: FreshKartColors.text,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: FreshKartColors.green,
                size: 17,
              ),
              const SizedBox(width: 5),
              const Text(
                'Deliver to',
                style: TextStyle(
                  color: FreshKartColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Home · Bengaluru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FreshKartColors.darkGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: FreshKartColors.darkGreen,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
