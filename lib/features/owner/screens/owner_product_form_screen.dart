import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';

class OwnerProductFormScreen extends StatefulWidget {
  const OwnerProductFormScreen({required this.api, this.product, super.key});

  final OwnerApiClient api;
  final Map<String, dynamic>? product;

  @override
  State<OwnerProductFormScreen> createState() => _OwnerProductFormScreenState();
}

class _OwnerProductFormScreenState extends State<OwnerProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _sellingPrice = TextEditingController();
  final _originalPrice = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _lowStock = TextEditingController(text: '5');
  final _minimum = TextEditingController(text: '1');
  final _maximum = TextEditingController(text: '50');
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  String _unit = 'kg';
  bool _active = true;
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  XFile? _selectedImage;
  String? _imageError;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = '${product['name'] ?? ''}';
      _description.text = '${product['description'] ?? ''}';
      _sellingPrice.text = '${product['selling_price'] ?? ''}';
      _originalPrice.text = '${product['original_price'] ?? ''}';
      _lowStock.text = '${product['low_stock_threshold'] ?? 5}';
      _minimum.text = '${product['minimum_order_quantity'] ?? 1}';
      _maximum.text = '${product['maximum_order_quantity'] ?? 50}';
      _categoryId = '${product['category_id']}';
      _unit = '${product['unit'] ?? 'kg'}';
      _active = product['is_active'] == true;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sellingPrice.dispose();
    _originalPrice.dispose();
    _stock.dispose();
    _lowStock.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.api.getList('/categories/');
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (_categoryId == null ||
            !_categories.any(
              (category) => '${category['id']}' == _categoryId,
            )) {
          _categoryId = categories.isEmpty ? null : '${categories.first['id']}';
        }
        _isLoadingCategories = false;
      });
    } on OwnerApiException catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _error = error.message;
        });
      }
    }
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 88,
    );
    if (image == null) return;
    final extension = image.name.split('.').last.toLowerCase();
    final bytes = await image.length();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      setState(() => _imageError = 'Choose a JPEG, PNG, or WebP image.');
      return;
    }
    if (bytes > 5 * 1024 * 1024) {
      setState(() => _imageError = 'Image must be 5 MB or smaller.');
      return;
    }
    setState(() {
      _selectedImage = image;
      _imageError = null;
    });
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  String? _positivePrice(String? value, String label) {
    if (_required(value, label) != null) return '$label is required.';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Enter a valid $label greater than zero.';
    }
    return null;
  }

  String? _nonNegativeInteger(String? value, String label) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 0 ? 'Enter a valid $label.' : null;
  }

  String? _positiveInteger(String? value, String label) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 1 ? 'Enter a valid $label.' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    final stock = int.parse(_stock.text);
    final minimum = int.parse(_minimum.text);
    final maximum = int.parse(_maximum.text);
    if (!_isEditing && stock > 0 && stock < minimum) {
      setState(
        () => _error = 'Initial stock must meet the minimum order quantity.',
      );
      return;
    }
    if (maximum < minimum) {
      setState(
        () => _error = 'Maximum order quantity must be at least minimum.',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final fields = <String, String>{
      'category_id': _categoryId!,
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'selling_price': _sellingPrice.text.trim(),
      'original_price': _originalPrice.text.trim(),
      'unit': _unit,
      'is_active': '$_active',
      'low_stock_threshold': _lowStock.text.trim(),
      'minimum_order_quantity': _minimum.text.trim(),
      'maximum_order_quantity': _maximum.text.trim(),
      if (!_isEditing) 'stock_quantity': _stock.text.trim(),
    };
    try {
      await widget.api.upload(
        _isEditing
            ? '/owner/products/${widget.product!['id']}/'
            : '/owner/products/',
        fields,
        method: _isEditing ? 'PATCH' : 'POST',
        imageName: _selectedImage?.name,
        imageBytes: _selectedImage == null
            ? null
            : await _selectedImage!.readAsBytes(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on OwnerApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product?['image'];
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'Add product'),
        backgroundColor: FreshKartColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error ?? 'Add a category before creating products.',
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _ImagePickerCard(
                    selectedImage: _selectedImage,
                    imageUrl: imageUrl is String ? imageUrl : null,
                    error: _imageError,
                    onTap: _chooseImage,
                  ),
                  const SizedBox(height: 17),
                  _section('Product information'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _name,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _required(value, 'Product name'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: '${category['id']}',
                            child: Text('${category['name']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) =>
                        value == null ? 'Select a category.' : null,
                  ),
                  const SizedBox(height: 20),
                  _section('Pricing and unit'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Selling price (₹)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              _positivePrice(value, 'selling price'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _originalPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Original price (₹)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              _positivePrice(value, 'original price'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Product unit',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'kg',
                              'g',
                              'litre',
                              'ml',
                              'packet',
                              'dozen',
                              'piece',
                            ]
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _unit = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  _section('Inventory'),
                  const SizedBox(height: 10),
                  if (!_isEditing) ...[
                    _numberField(
                      _stock,
                      'Initial stock quantity',
                      validator: (value) =>
                          _nonNegativeInteger(value, 'stock quantity'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          _lowStock,
                          'Low-stock threshold',
                          validator: (value) =>
                              _nonNegativeInteger(value, 'low-stock threshold'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _numberField(
                          _minimum,
                          'Minimum quantity',
                          validator: (value) =>
                              _positiveInteger(value, 'minimum quantity'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _numberField(
                    _maximum,
                    'Maximum quantity',
                    validator: (value) =>
                        _positiveInteger(value, 'maximum quantity'),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _active,
                    activeTrackColor: FreshKartColors.green,
                    title: const Text('Active for customer purchase'),
                    subtitle: const Text(
                      'Products with zero stock remain unavailable.',
                    ),
                    onChanged: (value) => setState(() => _active = value),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      key: const ValueKey('productFormError'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('saveOwnerProduct'),
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
                        : Text(_isEditing ? 'Save changes' : 'Add product'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String title) => Text(
    title,
    style: const TextStyle(
      color: FreshKartColors.text,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required FormFieldValidator<String> validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: validator,
  );
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.selectedImage,
    required this.imageUrl,
    required this.error,
    required this.onTap,
  });

  final XFile? selectedImage;
  final String? imageUrl;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (selectedImage != null) {
      image = FutureBuilder<List<int>>(
        future: selectedImage!.readAsBytes(),
        builder: (context, snapshot) => snapshot.hasData
            ? Image.memory(
                Uint8List.fromList(snapshot.data!),
                fit: BoxFit.cover,
              )
            : const Center(child: CircularProgressIndicator()),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
      );
    } else {
      image = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 33),
          SizedBox(height: 5),
          Text('Add product image'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 155,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: FreshKartColors.paleGreen,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCE8DC)),
            ),
            child: image,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'JPEG, PNG or WebP · up to 5 MB',
          style: TextStyle(color: FreshKartColors.mutedText, fontSize: 12),
        ),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }
}
