import 'package:flutter/foundation.dart';

import '../models/address.dart';

class AddressService extends ChangeNotifier {
  final List<DeliveryAddress> _addresses = [];
  String? _selectedAddressId;

  List<DeliveryAddress> get addresses => List.unmodifiable(_addresses);
  String? get selectedAddressId => _selectedAddressId;

  DeliveryAddress? get selectedAddress =>
      _addresses.where((item) => item.id == _selectedAddressId).firstOrNull;

  void save(DeliveryAddress address) {
    final index = _addresses.indexWhere((item) => item.id == address.id);
    if (address.isDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }
    if (index >= 0) {
      _addresses[index] = address;
    } else {
      _addresses.add(address);
    }
    if (_selectedAddressId == null || address.isDefault) {
      _selectedAddressId = address.id;
    }
    notifyListeners();
  }

  void select(String id) {
    if (!_addresses.any((address) => address.id == id)) {
      throw ArgumentError.value(id, 'id', 'Address does not exist.');
    }
    _selectedAddressId = id;
    notifyListeners();
  }

  void setDefault(String id) {
    if (!_addresses.any((address) => address.id == id)) {
      throw ArgumentError.value(id, 'id', 'Address does not exist.');
    }
    for (var index = 0; index < _addresses.length; index++) {
      _addresses[index] = _addresses[index].copyWith(
        isDefault: _addresses[index].id == id,
      );
    }
    _selectedAddressId = id;
    notifyListeners();
  }

  void remove(String id) {
    final wasDefault = _addresses
        .where((address) => address.id == id)
        .firstOrNull
        ?.isDefault;
    _addresses.removeWhere((address) => address.id == id);
    if (_selectedAddressId == id) {
      _selectedAddressId =
          _addresses.where((address) => address.isDefault).firstOrNull?.id ??
          _addresses.firstOrNull?.id;
    }
    if (wasDefault == true && _addresses.isNotEmpty) {
      final first = _addresses.first;
      _addresses[0] = first.copyWith(isDefault: true);
      _selectedAddressId ??= first.id;
    }
    notifyListeners();
  }
}
