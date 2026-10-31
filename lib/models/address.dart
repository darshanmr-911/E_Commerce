class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.houseNumber,
    required this.street,
    required this.locality,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.label,
    this.instructions = '',
    this.isDefault = false,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String houseNumber;
  final String street;
  final String locality;
  final String city;
  final String state;
  final String pinCode;
  final String label;
  final String instructions;
  final bool isDefault;

  String get formattedAddress =>
      '$houseNumber, $street, $locality, $city, $state - $pinCode';

  DeliveryAddress copyWith({bool? isDefault}) {
    return DeliveryAddress(
      id: id,
      fullName: fullName,
      mobileNumber: mobileNumber,
      houseNumber: houseNumber,
      street: street,
      locality: locality,
      city: city,
      state: state,
      pinCode: pinCode,
      label: label,
      instructions: instructions,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

String? validateIndianMobile(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
    return 'Enter a valid 10-digit Indian mobile number.';
  }
  return null;
}

String? validateIndianPinCode(String? value) {
  if (!RegExp(r'^[1-9]\d{5}$').hasMatch((value ?? '').trim())) {
    return 'Enter a valid 6-digit PIN code.';
  }
  return null;
}
