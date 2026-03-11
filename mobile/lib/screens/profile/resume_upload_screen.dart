import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';

class ResumeUploadScreen extends ConsumerStatefulWidget {
  final int profileId;

  const ResumeUploadScreen({super.key, required this.profileId});

  @override
  ConsumerState<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;
  bool _isDone = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _isDone = false;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFilePath == null) return;

    setState(() => _isUploading = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.uploadResume(widget.profileId, _selectedFilePath!);
      await ref.read(profilesProvider.notifier).refresh();
      setState(() => _isDone = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded and parsed successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profiles = ref.watch(profilesProvider).valueOrNull;
    final profile = profiles?.firstWhere(
      (p) => p.id == widget.profileId,
      orElse: () => profiles!.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Resume'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current resume status
            if (profile?.resumeUrl != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Resume already uploaded for this profile',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.success),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            const SizedBox(height: 32),

            Text('Upload Your Resume', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Upload a PDF to give the AI full context about your experience, skills, and background.',
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 32),

            // File drop zone
            GestureDetector(
              onTap: _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: _selectedFilePath != null
                      ? AppTheme.primary.withOpacity(0.08)
                      : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFilePath != null ? AppTheme.primary : AppTheme.darkBorder,
                    width: _selectedFilePath != null ? 2 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFilePath != null
                          ? Icons.description_rounded
                          : Icons.upload_file_rounded,
                      size: 48,
                      color: _selectedFilePath != null ? AppTheme.primary : AppTheme.darkTextSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFileName ?? 'Tap to select PDF',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _selectedFilePath != null
                            ? AppTheme.primary
                            : AppTheme.darkTextSecondary,
                      ),
                    ),
                    if (_selectedFilePath == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'PDF files only',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            if (_selectedFilePath != null) ...[
              AppButton(
                label: _isDone ? 'Uploaded!' : 'Upload Resume',
                icon: _isDone ? Icons.check_rounded : Icons.cloud_upload_rounded,
                isLoading: _isUploading,
                onPressed: _isDone ? null : _upload,
              ).animate().fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Choose Different File'),
              ),
            ] else ...[
              AppButton(
                label: 'Choose PDF File',
                icon: Icons.folder_open_rounded,
                onPressed: _pickFile,
              ),
            ],

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your resume text is extracted and stored securely. '
                      'It\'s used by GPT-4 to tailor your applications. '
                      'The original file is stored encrypted in the cloud.',
                      style: theme.textTheme.bodySmall,
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
