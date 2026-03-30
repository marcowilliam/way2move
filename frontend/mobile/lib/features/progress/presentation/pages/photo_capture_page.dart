import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/progress_photo.dart';
import '../providers/progress_providers.dart';

class PhotoCapturePage extends ConsumerStatefulWidget {
  const PhotoCapturePage({super.key});

  @override
  ConsumerState<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends ConsumerState<PhotoCapturePage> {
  final _picker = ImagePicker();
  final _notesController = TextEditingController();

  File? _pickedFile;
  PhotoAngle? _selectedAngle;
  bool _isUploading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(PhotoAngle angle) async {
    final result = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    final picked = await _picker.pickImage(source: result, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _pickedFile = File(picked.path);
      _selectedAngle = angle;
    });
  }

  Future<void> _save() async {
    final file = _pickedFile;
    final angle = _selectedAngle;
    if (file == null || angle == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isUploading = true);

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    await ref
        .read(photoTimelineNotifierProvider.notifier)
        .addPhotoFromFile(file, angle, userId, notes: notes);

    setState(() {
      _isUploading = false;
      _pickedFile = null;
      _selectedAngle = null;
      _notesController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved!')),
      );
    }
  }

  void _retake() => setState(() {
        _pickedFile = null;
        _selectedAngle = null;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.photoCaptureAngleGrid,
      appBar: AppBar(title: const Text('Progress Photos')),
      body: Stack(
        children: [
          _pickedFile != null ? _buildPreview(theme) : _buildAngleGrid(theme),
          if (_isUploading)
            const ColoredBox(
              color: Color(0x80000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAngleGrid(ThemeData theme) {
    const angles = [
      (PhotoAngle.front, Icons.person, 'Front'),
      (PhotoAngle.sideLeft, Icons.arrow_back, 'Side L'),
      (PhotoAngle.sideRight, Icons.arrow_forward, 'Side R'),
      (PhotoAngle.back, Icons.person_outline, 'Back'),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select angle to capture', style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: angles.map((entry) {
                final (angle, icon, label) = entry;
                return _AngleButton(
                  angle: angle,
                  icon: icon,
                  label: label,
                  onTap: () => _pickImage(angle),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _pickedFile!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedAngle != null)
            Text(
              _angleLabel(_selectedAngle!),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retake,
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: AppKeys.photoSaveButton,
                  onPressed: _isUploading ? null : _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _angleLabel(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return 'Front';
      case PhotoAngle.sideLeft:
        return 'Side L';
      case PhotoAngle.sideRight:
        return 'Side R';
      case PhotoAngle.back:
        return 'Back';
    }
  }
}

class _AngleButton extends StatelessWidget {
  final PhotoAngle angle;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AngleButton({
    required this.angle,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: Key('angle_button_${angle.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
