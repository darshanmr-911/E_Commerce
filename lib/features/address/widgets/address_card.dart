import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/address.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    super.key,
  });

  final DeliveryAddress address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final icon = switch (address.label) {
      'Work' => Icons.work_outline_rounded,
      'Other' => Icons.location_on_outlined,
      _ => Icons.home_outlined,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? FreshKartColors.green : const Color(0xFFE9EEE7),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: FreshKartColors.green.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: FreshKartColors.green, size: 20),
                  const SizedBox(width: 7),
                  Text(
                    address.label,
                    style: const TextStyle(
                      color: FreshKartColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (address.isDefault) ...[
                    const SizedBox(width: 8),
                    const _AddressBadge(label: 'DEFAULT'),
                  ],
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: FreshKartColors.green,
                      size: 21,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                address.fullName,
                style: const TextStyle(
                  color: FreshKartColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address.formattedAddress,
                style: const TextStyle(
                  color: FreshKartColors.mutedText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '+91 ${address.mobileNumber}',
                style: const TextStyle(
                  color: FreshKartColors.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    key: ValueKey('edit-address-${address.id}'),
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    key: ValueKey('delete-address-${address.id}'),
                    onPressed: onDelete,
                    child: const Text('Delete'),
                  ),
                  if (!address.isDefault)
                    TextButton(
                      key: ValueKey('default-address-${address.id}'),
                      onPressed: onSetDefault,
                      child: const Text('Set default'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressBadge extends StatelessWidget {
  const _AddressBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: FreshKartColors.paleGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: FreshKartColors.green,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
