import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({
    required this.api,
    required this.onLogout,
    super.key,
  });

  final OwnerApiClient api;
  final VoidCallback onLogout;

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _hours = TextEditingController();
  final _serviceArea = TextEditingController();
  final _picker = ImagePicker();
  late Future<Map<String, dynamic>> _profile;
  Map<String, dynamic>? _loaded;
  XFile? _logo;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final profile = await widget.api.getObject('/owner/profile/');
    _loaded = profile;
    _name.text = '${profile['shop_name'] ?? ''}';
    _description.text = '${profile['description'] ?? ''}';
    _address.text = '${profile['address'] ?? ''}';
    _phone.text = '${profile['phone'] ?? ''}';
    _hours.text = '${profile['opening_hours'] ?? ''}';
    _serviceArea.text = '${profile['delivery_service_area'] ?? ''}';
    return profile;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _phone.dispose();
    _hours.dispose();
    _serviceArea.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 88,
    );
    if (image == null) return;
    final extension = image.name.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension) ||
        await image.length() > 5 * 1024 * 1024) {
      setState(() => _error = 'Choose a JPEG, PNG, or WebP logo up to 5 MB.');
      return;
    }
    setState(() {
      _logo = image;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving ||
        _name.text.trim().isEmpty ||
        _address.text.trim().isEmpty) {
      setState(() => _error = 'Shop name and address are required.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final fields = <String, String>{
      'shop_name': _name.text.trim(),
      'description': _description.text.trim(),
      'address': _address.text.trim(),
      'phone': _phone.text.trim(),
      'opening_hours': _hours.text.trim(),
      'delivery_service_area': _serviceArea.text.trim(),
    };
    try {
      final updated = _logo == null
          ? await widget.api.patch('/owner/profile/', fields)
          : await widget.api.upload(
              '/owner/profile/',
              fields,
              method: 'PATCH',
              imageField: 'logo',
              imageName: _logo!.name,
              imageBytes: await _logo!.readAsBytes(),
            );
      if (mounted) {
        setState(() {
          _loaded = updated;
          _logo = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shop profile updated.')));
      }
    } on OwnerApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final warning = await widget.api.logout();
    if (mounted) {
      widget.onLogout();
      if (warning != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(warning)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Shop profile',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: FreshKartColors.cream,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => setState(() => _profile = _loadProfile()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = _loaded ?? snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: [
            Center(
              child: InkWell(
                onTap: _pickLogo,
                borderRadius: BorderRadius.circular(50),
                child: CircleAvatar(
                  radius: 43,
                  backgroundColor: FreshKartColors.paleGreen,
                  backgroundImage: _logo == null
                      ? (profile['logo'] is String &&
                                (profile['logo'] as String).isNotEmpty
                            ? NetworkImage(profile['logo'] as String)
                            : null)
                      : null,
                  child: _logo == null
                      ? (profile['logo'] is String &&
                                (profile['logo'] as String).isNotEmpty
                            ? null
                            : const Icon(
                                Icons.storefront_rounded,
                                size: 37,
                                color: FreshKartColors.green,
                              ))
                      : FutureBuilder<List<int>>(
                          future: _logo!.readAsBytes(),
                          builder: (context, snapshot) => snapshot.hasData
                              ? ClipOval(
                                  child: Image.memory(
                                    Uint8List.fromList(snapshot.data!),
                                    width: 86,
                                    height: 86,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const CircularProgressIndicator(),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${profile['owner_name'] ?? 'Shop owner'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: FreshKartColors.text,
              ),
            ),
            Text(
              '${profile['owner_email'] ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: FreshKartColors.mutedText),
            ),
            const SizedBox(height: 20),
            _field(_name, 'Shop name'),
            _field(_description, 'Description', maxLines: 3),
            _field(_address, 'Shop address', maxLines: 3),
            _field(
              _phone,
              'Shop phone number',
              keyboardType: TextInputType.phone,
            ),
            _field(_hours, 'Opening hours'),
            _field(_serviceArea, 'Delivery service area', maxLines: 2),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: FreshKartColors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save profile'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
