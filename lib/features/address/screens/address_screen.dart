import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../freshkart_colors.dart';
import '../../../models/address.dart';
import '../../../services/address_service.dart';
import '../widgets/address_card.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({
    required this.addressService,
    this.continueLabel = 'Continue to Checkout',
    super.key,
  });

  final AddressService addressService;
  final String continueLabel;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  Future<void> _openForm([DeliveryAddress? initial]) async {
    final address = await Navigator.of(context).push<DeliveryAddress>(
      MaterialPageRoute(
        builder: (context) => AddressFormScreen(address: initial),
      ),
    );
    if (address == null || !mounted) return;
    widget.addressService.save(address);
  }

  Future<void> _deleteAddress(DeliveryAddress address) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this address?'),
        content: const Text('This saved delivery address will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    widget.addressService.remove(address.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.addressService,
      builder: (context, child) {
        final addresses = widget.addressService.addresses;
        final selected = widget.addressService.selectedAddress;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: FreshKartColors.cream,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Delivery address',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              const Text(
                'Where should we deliver?',
                style: TextStyle(
                  color: FreshKartColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a saved address or add a new delivery location.',
                style: TextStyle(
                  color: FreshKartColors.mutedText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 17),
              OutlinedButton.icon(
                key: const ValueKey('addNewAddress'),
                onPressed: _openForm,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FreshKartColors.green,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: FreshKartColors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (addresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 40,
                        color: FreshKartColors.mutedText,
                      ),
                      SizedBox(height: 9),
                      Text(
                        'No saved addresses yet',
                        style: TextStyle(
                          color: FreshKartColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add a delivery address to continue.',
                        style: TextStyle(color: FreshKartColors.mutedText),
                      ),
                    ],
                  ),
                )
              else
                ...addresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: AddressCard(
                      address: address,
                      selected:
                          widget.addressService.selectedAddressId == address.id,
                      onSelect: () => widget.addressService.select(address.id),
                      onEdit: () => _openForm(address),
                      onDelete: () => _deleteAddress(address),
                      onSetDefault: () =>
                          widget.addressService.setDefault(address.id),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('continueWithAddress'),
                onPressed: selected == null
                    ? null
                    : () => Navigator.of(context).pop(selected),
                style: FilledButton.styleFrom(
                  backgroundColor: FreshKartColors.green,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(widget.continueLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({this.address, super.key});

  final DeliveryAddress? address;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late String _label;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _controllers = {
      'name': TextEditingController(text: address?.fullName ?? ''),
      'mobile': TextEditingController(text: address?.mobileNumber ?? ''),
      'house': TextEditingController(text: address?.houseNumber ?? ''),
      'street': TextEditingController(text: address?.street ?? ''),
      'locality': TextEditingController(text: address?.locality ?? ''),
      'city': TextEditingController(text: address?.city ?? ''),
      'state': TextEditingController(text: address?.state ?? ''),
      'pin': TextEditingController(text: address?.pinCode ?? ''),
      'instructions': TextEditingController(text: address?.instructions ?? ''),
    };
    _label = address?.label ?? 'Home';
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'This field is required.' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final mobile = _controllers['mobile']!.text.replaceAll(RegExp(r'\D'), '');
    Navigator.of(context).pop(
      DeliveryAddress(
        id:
            widget.address?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        fullName: _controllers['name']!.text.trim(),
        mobileNumber: mobile,
        houseNumber: _controllers['house']!.text.trim(),
        street: _controllers['street']!.text.trim(),
        locality: _controllers['locality']!.text.trim(),
        city: _controllers['city']!.text.trim(),
        state: _controllers['state']!.text.trim(),
        pinCode: _controllers['pin']!.text.trim(),
        label: _label,
        instructions: _controllers['instructions']!.text.trim(),
        isDefault: _isDefault,
      ),
    );
  }

  Widget _field({
    required String keyName,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? prefixText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        key: ValueKey('address-$keyName'),
        controller: _controllers[keyName],
        validator: validator ?? _required,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          prefixIcon: Icon(icon, size: 19),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE9EEE7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE9EEE7)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FreshKartColors.cream,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.address == null ? 'Add address' : 'Edit address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          children: [
            _field(
              keyName: 'name',
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              validator: _required,
              keyboardType: TextInputType.name,
            ),
            _field(
              keyName: 'mobile',
              label: 'Mobile number',
              icon: Icons.phone_outlined,
              prefixText: '+91 ',
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              validator: validateIndianMobile,
            ),
            _field(
              keyName: 'house',
              label: 'House / Flat number',
              icon: Icons.home_outlined,
            ),
            _field(
              keyName: 'street',
              label: 'Street name',
              icon: Icons.signpost_outlined,
            ),
            _field(
              keyName: 'locality',
              label: 'Area / Locality',
              icon: Icons.location_on_outlined,
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    keyName: 'city',
                    label: 'City',
                    icon: Icons.location_city_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    keyName: 'state',
                    label: 'State',
                    icon: Icons.map_outlined,
                  ),
                ),
              ],
            ),
            _field(
              keyName: 'pin',
              label: 'Indian PIN code',
              icon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: validateIndianPinCode,
            ),
            _field(
              keyName: 'instructions',
              label: 'Delivery instructions (optional)',
              icon: Icons.edit_note_rounded,
              validator: (_) => null,
              maxLines: 2,
            ),
            DropdownButtonFormField<String>(
              key: const ValueKey('address-label'),
              initialValue: _label,
              decoration: const InputDecoration(labelText: 'Address type'),
              items: const [
                DropdownMenuItem(value: 'Home', child: Text('Home')),
                DropdownMenuItem(value: 'Work', child: Text('Work')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _label = value);
              },
            ),
            SwitchListTile(
              key: const ValueKey('address-default'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as default address'),
              value: _isDefault,
              activeTrackColor: FreshKartColors.green,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('saveAddress'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: FreshKartColors.green,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                widget.address == null ? 'Save Address' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
