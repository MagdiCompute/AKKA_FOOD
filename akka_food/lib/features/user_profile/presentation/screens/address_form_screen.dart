import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/map_picker_screen.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../domain/entities/delivery_address.dart';
import '../notifiers/address_notifier.dart';

/// Screen for adding a new delivery address or editing an existing one.
///
/// - When [addressId] is `null` → "Add Address" mode: creates a new address
///   via [AddressNotifier.addAddress].
/// - When [addressId] is provided → "Edit Address" mode: pre-populates fields
///   from [addressNotifierProvider] and persists changes via
///   [AddressNotifier.updateAddress].
///
/// Fields:
/// - Label (required) — e.g. "Home", "Office", "Other"
/// - Street Address (required)
/// - City (required)
/// - Latitude (optional, numeric)
/// - Longitude (optional, numeric)
///
/// A "Pick on Map" placeholder button shows a snackbar indicating that map
/// integration is coming soon.
///
/// Satisfies Requirements 4.1, 4.2, 4.3.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  /// The ID of the address to edit, or `null` when adding a new address.
  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  /// Whether the form fields have been initialised from the existing address
  /// (edit mode only).
  bool _initialised = false;

  bool get _isEditing => widget.addressId != null;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Pre-populate fields in edit mode (once)
  // ---------------------------------------------------------------------------

  void _initFieldsFromAddress(List<DeliveryAddress> addresses) {
    if (_initialised || !_isEditing) return;

    final address = addresses.where((a) => a.id == widget.addressId).firstOrNull;
    if (address == null) return;

    _labelController.text = address.label;
    _streetController.text = address.streetAddress;
    _cityController.text = address.city;
    _latController.text = address.latitude?.toString() ?? '';
    _lngController.text = address.longitude?.toString() ?? '';
    _initialised = true;
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  /// Requirement 4.2 — label is required.
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis.';
    }
    return null;
  }

  /// Validates an optional numeric coordinate field.
  String? _validateCoordinate(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName doit être un nombre valide.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Save action
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final label = _labelController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final latText = _latController.text.trim();
    final lngText = _lngController.text.trim();

    final latitude = latText.isNotEmpty ? double.tryParse(latText) : null;
    final longitude = lngText.isNotEmpty ? double.tryParse(lngText) : null;

    if (_isEditing) {
      // Edit mode — find the existing address to preserve id, uid, isDefault,
      // and createdAt.
      final addresses =
          ref.read(addressNotifierProvider).valueOrNull ?? [];
      final existing =
          addresses.where((a) => a.id == widget.addressId).firstOrNull;

      if (existing == null) {
        _showErrorSnackBar('Adresse introuvable. Elle a peut-être été supprimée.');
        return;
      }

      final updated = existing.copyWith(
        label: label,
        streetAddress: street,
        city: city,
        latitude: latitude,
        longitude: longitude,
      );

      await ref
          .read(addressNotifierProvider.notifier)
          .updateAddress(updated);
    } else {
      // Add mode — create a new address with a temporary id; the repository
      // will assign the real Firestore document id.
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        _showErrorSnackBar('Non connecté. Veuillez vous connecter.');
        return;
      }

      final newAddress = DeliveryAddress(
        id: '',
        uid: currentUser.uid,
        label: label,
        streetAddress: street,
        city: city,
        latitude: latitude,
        longitude: longitude,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await ref
          .read(addressNotifierProvider.notifier)
          .addAddress(newAddress);
    }
  }

  // ---------------------------------------------------------------------------
  // Map picker — simple location selection dialog
  // ---------------------------------------------------------------------------

  void _onPickOnMap() async {
    final initialLat = double.tryParse(_latController.text);
    final initialLng = double.tryParse(_lngController.text);

    final result = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
        ),
      ),
    );

    if (result != null && mounted) {
      _latController.text = result['lat']!.toStringAsFixed(5);
      _lngController.text = result['lng']!.toStringAsFixed(5);
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // Side-effect listener
  // ---------------------------------------------------------------------------

  void _handleAddressStateChange(
    AsyncValue<List<DeliveryAddress>>? previous,
    AsyncValue<List<DeliveryAddress>> next,
  ) {
    if (!mounted) return;

    // Transition from loading → data means the save succeeded.
    final wasLoading = previous?.isLoading ?? false;
    if (wasLoading && next.hasValue && !next.hasError) {
      Navigator.of(context).pop();
      return;
    }

    // Show error snackbar on failure.
    if (next.hasError && (previous?.isLoading ?? false)) {
      final message = next.error?.toString() ??
          (_isEditing ? 'Échec de la mise à jour de l\'adresse.' : 'Échec de l\'ajout de l\'adresse.');
      _showErrorSnackBar(message);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(addressNotifierProvider, _handleAddressStateChange);

    final addressAsync = ref.watch(addressNotifierProvider);

    // Pre-populate fields once data is available in edit mode.
    addressAsync.whenData(_initFieldsFromAddress);

    final isLoading = addressAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'adresse' : 'Ajouter une adresse'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Label ──────────────────────────────────────────────
                TextFormField(
                  controller: _labelController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _validateRequired(v, 'Libellé'),
                  decoration: const InputDecoration(
                    labelText: 'Libellé',
                    hintText: 'ex. Maison, Bureau, Autre',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Street Address ─────────────────────────────────────
                TextFormField(
                  controller: _streetController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => _validateRequired(v, 'Adresse'),
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'ex. 12 Rue de la Paix',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // ── City ───────────────────────────────────────────────
                TextFormField(
                  controller: _cityController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _validateRequired(v, 'Ville'),
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    hintText: 'ex. Ouagadougou',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Coordinates section header ─────────────────────────
                Text(
                  'Coordonnées (optionnel)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),

                // ── Latitude ───────────────────────────────────────────
                TextFormField(
                  controller: _latController,
                  textInputAction: TextInputAction.next,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^-?\d*\.?\d*'),
                    ),
                  ],
                  validator: (v) => _validateCoordinate(v, 'Latitude'),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'ex. 12.3647',
                    prefixIcon: Icon(Icons.explore_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Longitude ──────────────────────────────────────────
                TextFormField(
                  controller: _lngController,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^-?\d*\.?\d*'),
                    ),
                  ],
                  validator: (v) => _validateCoordinate(v, 'Longitude'),
                  onFieldSubmitted: (_) => isLoading ? null : _save(),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'ex. -1.5332',
                    prefixIcon: Icon(Icons.explore_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Pick on Map placeholder ────────────────────────────
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _onPickOnMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Choisir sur la carte'),
                ),
                const SizedBox(height: 32),

                // ── Save button / loading indicator ────────────────────
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Enregistrement',
                    ),
                  )
                else
                  FilledButton(
                    onPressed: _save,
                    child: Text(
                      _isEditing ? 'Enregistrer' : 'Ajouter une adresse',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// _LocationOption — preset location for the simple picker dialog
// ---------------------------------------------------------------------------

class _LocationOption extends StatelessWidget {
  const _LocationOption({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.of(context).pop({'lat': lat, 'lng': lng}),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
