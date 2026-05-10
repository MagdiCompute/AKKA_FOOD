import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/meal_image_upload_service.dart';
import '../notifiers/admin_meal_form_notifier.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides a singleton [MealImageUploadService].
final _mealImageUploadServiceProvider = Provider<MealImageUploadService>(
  (ref) => MealImageUploadService(),
);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Displays existing meal images as thumbnails and allows adding/removing
/// images (1–5 total) with upload progress feedback.
///
/// Satisfies Requirements 2.2 and 2.3 (image upload for meal create/edit).
class MealImageUploadWidget extends ConsumerStatefulWidget {
  const MealImageUploadWidget({
    super.key,
    required this.mealId,
  });

  /// The meal ID used as the Firebase Storage folder name.
  /// For new meals this should be a temporary UUID generated before the form
  /// is shown; it will be replaced by the real ID on save if needed.
  final String mealId;

  @override
  ConsumerState<MealImageUploadWidget> createState() =>
      _MealImageUploadWidgetState();
}

class _MealImageUploadWidgetState extends ConsumerState<MealImageUploadWidget> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // ── Pick & upload ─────────────────────────────────────────────────────────

  Future<void> _pickAndUpload() async {
    final formState = ref.read(adminMealFormNotifierProvider);
    if (formState.imageUrls.length >= 5) return;

    // Pick image from gallery.
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;

    final notifier = ref.read(adminMealFormNotifierProvider.notifier);
    final uploadService = ref.read(_mealImageUploadServiceProvider);

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    notifier.setUploadProgress(0.0);

    try {
      final task = await uploadService.createUploadTask(
        widget.mealId,
        picked,
      );

      // Listen to progress events.
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (!mounted) return;
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() => _uploadProgress = progress);
        notifier.setUploadProgress(progress);
      });

      // Wait for completion.
      final snapshot = await task;
      final downloadUrl = await uploadService.getDownloadUrl(snapshot);

      if (!mounted) return;
      notifier.addImageUrl(downloadUrl);
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
        notifier.setUploadProgress(null);
      }
    }
  }

  // ── Remove image ──────────────────────────────────────────────────────────

  Future<void> _removeImage(String url) async {
    final notifier = ref.read(adminMealFormNotifierProvider.notifier);
    final uploadService = ref.read(_mealImageUploadServiceProvider);

    // Remove from state immediately for responsive UI.
    notifier.removeImageUrl(url);

    // Best-effort delete from Storage; ignore errors.
    try {
      await uploadService.deleteImage(url);
    } catch (_) {
      // Deletion failure is non-critical; URL is already removed from state.
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final imageUrls =
        ref.watch(adminMealFormNotifierProvider.select((s) => s.imageUrls));
    final colorScheme = Theme.of(context).colorScheme;
    final canAddMore = imageUrls.length < 5 && !_isUploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image count label ───────────────────────────────────────────────
        Text(
          '${imageUrls.length}/5 images',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),

        // ── Thumbnails row ──────────────────────────────────────────────────
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Existing image thumbnails.
              ...imageUrls.map(
                (url) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ImageThumbnail(
                    url: url,
                    onRemove: _isUploading ? null : () => _removeImage(url),
                  ),
                ),
              ),

              // "Add Image" button (only when < 5 images and not uploading).
              if (canAddMore)
                _AddImageButton(onTap: _pickAndUpload),

              // Upload-in-progress placeholder.
              if (_isUploading)
                _UploadingThumbnail(progress: _uploadProgress),
            ],
          ),
        ),

        // ── Linear progress indicator ───────────────────────────────────────
        if (_isUploading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 4),
          Text(
            'Uploading… ${(_uploadProgress * 100).toStringAsFixed(0)}%',
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
