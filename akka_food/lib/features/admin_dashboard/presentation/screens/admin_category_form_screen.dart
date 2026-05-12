import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/category_image_upload_service.dart';
import '../notifiers/admin_category_form_notifier.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides a singleton [CategoryImageUploadService].
final _categoryImageUploadServiceProvider =
    Provider<CategoryImageUploadService>(
  (ref) => CategoryImageUploadService(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Create / edit form for a single category.
///
/// Pass [categoryId] == null to create a new category; pass a non-null
/// [categoryId] to edit an existing one.
///
/// Satisfies Requirements 3.2, 3.3, and 3.4.
class AdminCategoryFormScreen extends ConsumerStatefulWidget {
  const AdminCategoryFormScreen({super.key, this.categoryId});

  /// `null` → create mode; non-null → edit mode.
  final String? categoryId;

  @override
  ConsumerState<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState
    extends ConsumerState<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // For new categories, generate a temporary ID used as the Firebase Storage
  // folder. This is replaced by the real Firestore ID after the category is
  // saved.
  late final String _effectiveCategoryId;

  late final TextEditingController _nameController;

  bool _controllersInitialised = false;

  // Image upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _effectiveCategoryId = widget.categoryId ??
        'temp_${DateTime.now().millisecondsSinceEpoch}';

    _nameController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.categoryId != null) {
        ref
            .read(adminCategoryFormNotifierProvider.notifier)
            .loadCategory(widget.categoryId!);
      } else {
        ref.read(adminCategoryFormNotifierProvider.notifier).initCreate();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Sync controllers from notifier state (edit mode load) ─────────────────

  void _syncControllers(AdminCategoryFormState formState) {
    if (_controllersInitialised) return;
    if (formState.isLoading) return;
    if (formState.isEditMode && formState.name.isEmpty) return;

    _nameController.text = formState.name;
    _controllersInitialised = true;
  }

  // ── Image upload ──────────────────────────────────────────────────────────

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;

    final notifier = ref.read(adminCategoryFormNotifierProvider.notifier);
    final uploadService = ref.read(_categoryImageUploadServiceProvider);

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final task = await uploadService.createUploadTask(
        _effectiveCategoryId,
        picked,
      );

      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (!mounted) return;
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await task;
      final downloadUrl = await uploadService.getDownloadUrl(snapshot);

      if (!mounted) return;
      notifier.setImageUrl(downloadUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _removeImage(String url) async {
    final notifier = ref.read(adminCategoryFormNotifierProvider.notifier);
    final uploadService = ref.read(_categoryImageUploadServiceProvider);

    // Remove from state immediately for responsive UI.
    notifier.setImageUrl(null);

    // Best-effort delete from Storage; ignore errors.
    try {
      await uploadService.deleteImage(url);
    } catch (_) {
      // Deletion failure is non-critical; URL is already removed from state.
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(adminCategoryFormNotifierProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.categoryId == null
                ? 'Category created successfully.'
                : 'Category updated successfully.',
          ),
        ),
      );
      context.pop();
    } else {
      final error =
          ref.read(adminCategoryFormNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Failed to save category. Please try again.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _onSave,
          ),
        ),
      );
    }
  }

  // ── Toggle active ─────────────────────────────────────────────────────────

  Future<void> _onToggleActive(bool newValue) async {
    final notifier = ref.read(adminCategoryFormNotifierProvider.notifier);
    final success = await notifier.toggleActive();

    if (!mounted) return;

    if (!success) {
      final error =
          ref.read(adminCategoryFormNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Failed to update category status. Please try again.',
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(adminCategoryFormNotifierProvider);
    final notifier = ref.read(adminCategoryFormNotifierProvider.notifier);

    // Sync text controllers once the category data is loaded.
    _syncControllers(formState);

    final isEditMode = widget.categoryId != null;
    final isBusy = formState.isSaving || formState.isLoading || _isUploading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Category' : 'New Category'),
        actions: [
          isBusy
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _onSave,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // ── Name ─────────────────────────────────────────────────
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: notifier.setName,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Image ─────────────────────────────────────────────────
                  _SectionHeader(label: 'Image'),
                  const SizedBox(height: 8),
                  // Image URL text field with live preview
                  TextFormField(
                    initialValue: formState.imageUrl ?? '',
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      border: const OutlineInputBorder(),
                      hintText: 'https://images.unsplash.com/...',
                      suffixIcon: formState.imageUrl != null && formState.imageUrl!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                notifier.setImageUrl(null);
                              },
                            )
                          : null,
                    ),
                    onChanged: (url) {
                      final trimmed = url.trim();
                      notifier.setImageUrl(trimmed.isEmpty ? null : trimmed);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Live image preview (only when URL starts with http)
                  if (formState.imageUrl != null &&
                      formState.imageUrl!.startsWith('http'))
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        formState.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, ___) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, color: Theme.of(context).colorScheme.error),
                              const SizedBox(height: 4),
                              Text(
                                'Cannot preview (CORS). Image will still be saved.',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('No image — paste a URL above'),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Active toggle (edit mode only) ────────────────────────
                  if (isEditMode) ...[
                    _SectionHeader(label: 'Visibility'),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text(
                        'Active categories are visible to customers',
                      ),
                      value: formState.isActive,
                      onChanged: isBusy ? null : _onToggleActive,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category image upload widget
// ---------------------------------------------------------------------------

/// Displays the current category image (if any) and allows picking/removing
/// a single image.
class _CategoryImageUpload extends StatelessWidget {
  const _CategoryImageUpload({
    required this.imageUrl,
    required this.isUploading,
    required this.uploadProgress,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final String? imageUrl;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback? onPickImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 96,
          child: Row(
            children: [
              // Existing image thumbnail.
              if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ImageThumbnail(
                    url: imageUrl!,
                    onRemove: onRemoveImage,
                  ),
                ),

              // "Add Image" button (only when no image and not uploading).
              if (imageUrl == null && !isUploading)
                _AddImageButton(onTap: onPickImage ?? () {}),

              // Upload-in-progress placeholder.
              if (isUploading)
                _UploadingThumbnail(progress: uploadProgress),
            ],
          ),
        ),

        // Linear progress indicator while uploading.
        if (isUploading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: uploadProgress),
          const SizedBox(height: 4),
          Text(
            'Uploading… ${(uploadProgress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Image thumbnail
// ---------------------------------------------------------------------------

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.url,
    required this.onRemove,
  });

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        // Remove (X) button.
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add image button
// ---------------------------------------------------------------------------

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Uploading placeholder thumbnail
// ---------------------------------------------------------------------------

class _UploadingThumbnail extends StatelessWidget {
  const _UploadingThumbnail({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 3,
          ),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
