String formatCurrencyPaise(int amountPaise) {
  final rupees = amountPaise.abs() ~/ 100;
  final paise = amountPaise.abs() % 100;
  final value = paise == 0
      ? '₹$rupees'
      : '₹$rupees.${paise.toString().padLeft(2, '0')}';
  return amountPaise < 0 ? '-$value' : value;
}
