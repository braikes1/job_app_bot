import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_profile.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final int? profileId;

  const EditProfileScreen({super.key, this.profileId});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Controllers
  final _profileNameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _knowledgeBaseCtrl = TextEditingController();
  final _targetRolesCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();

  bool _preferredRemote = true;
  bool _isDefault = false;
  UserProfile? _existingProfile;

  @override
  void initState() {
    super.initState();
    if (widget.profileId != null) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    final profiles = ref.read(profilesProvider).valueOrNull;
    final profile = profiles?.firstWhere(
      (p) => p.id == widget.profileId,
      orElse: () => throw Exception('Profile not found'),
    );
    if (profile != null) {
      _existingProfile = profile;
      _profileNameCtrl.text = profile.profileName;
      _fullNameCtrl.text = profile.fullName;
      _emailCtrl.text = profile.email;
      _phoneCtrl.text = profile.phone ?? '';
      _locationCtrl.text = profile.location ?? '';
      _linkedinCtrl.text = profile.linkedinUrl ?? '';
      _portfolioCtrl.text = profile.portfolioUrl ?? '';
      _githubCtrl.text = profile.githubUrl ?? '';
      _knowledgeBaseCtrl.text = profile.knowledgeBase ?? '';
      _targetRolesCtrl.text = profile.targetRoles.join(', ');
      _salaryMinCtrl.text = profile.salaryMin?.toString() ?? '';
      _salaryMaxCtrl.text = profile.salaryMax?.toString() ?? '';
      _preferredRemote = profile.preferredRemote;
      _isDefault = profile.isDefault;
    }
  }

  @override
  void dispose() {
    for (final ctrl in [
      _profileNameCtrl, _fullNameCtrl, _emailCtrl, _phoneCtrl,
      _locationCtrl, _linkedinCtrl, _portfolioCtrl, _githubCtrl,
      _knowledgeBaseCtrl, _targetRolesCtrl, _salaryMinCtrl, _salaryMaxCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final roles = _targetRolesCtrl.text
        .split(',')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    final data = {
      'profile_name': _profileNameCtrl.text.trim(),
      'full_name': _fullNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'linkedin_url': _linkedinCtrl.text.trim(),
      'portfolio_url': _portfolioCtrl.text.trim(),
      'github_url': _githubCtrl.text.trim(),
      'knowledge_base': _knowledgeBaseCtrl.text.trim(),
      'target_roles': roles,
      'preferred_remote': _preferredRemote,
      'salary_min': int.tryParse(_salaryMinCtrl.text),
      'salary_max': int.tryParse(_salaryMaxCtrl.text),
      'is_default': _isDefault,
    };

    bool success;
    if (widget.profileId != null) {
      success = await ref.read(profilesProvider.notifier).updateProfile(widget.profileId!, data);
    } else {
      final profile = await ref.read(profilesProvider.notifier).createProfile(data);
      success = profile != null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.profileId != null ? 'Profile updated!' : 'Profile created!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.profileId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Profile' : 'New Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(label: 'Profile Details'),
            AppTextField(
              controller: _profileNameCtrl,
              label: 'Profile Name',
              hint: 'e.g. Software Engineer',
              prefixIcon: Icons.label_outline_rounded,
              validator: (v) => v!.isNotEmpty ? null : 'Required',
            ).animate(delay: 50.ms).fadeIn(),

            const SizedBox(height: 16),
            _SectionHeader(label: 'Personal Information'),

            AppTextField(
              controller: _fullNameCtrl,
              label: 'Full Name',
              hint: 'Bryan Raikes',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => v!.isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) => v!.contains('@') ? null : 'Enter valid email',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneCtrl,
              label: 'Phone',
              hint: '+1 (555) 000-0000',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _locationCtrl,
              label: 'Location',
              hint: 'Davie, FL',
              prefixIcon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 16),
            _SectionHeader(label: 'Online Presence'),

            AppTextField(
              controller: _linkedinCtrl,
              label: 'LinkedIn URL',
              hint: 'https://linkedin.com/in/...',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.link_rounded,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _portfolioCtrl,
              label: 'Portfolio URL',
              hint: 'https://yoursite.com',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.web_rounded,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _githubCtrl,
              label: 'GitHub URL',
              hint: 'https://github.com/username',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.code_rounded,
            ),

            const SizedBox(height: 16),
            _SectionHeader(label: 'Knowledge Base'),

            AppTextField(
              controller: _knowledgeBaseCtrl,
              label: 'Skills, Experience & Preferences',
              hint: 'e.g. 5 years Python, React, FastAPI. Led a team of 3. '
                  'Looking for remote roles. Open to startup culture...',
              maxLines: 6,
              validator: null,
            ),

            const SizedBox(height: 16),
            _SectionHeader(label: 'Job Preferences'),

            AppTextField(
              controller: _targetRolesCtrl,
              label: 'Target Roles (comma separated)',
              hint: 'Software Engineer, Full Stack Developer',
              prefixIcon: Icons.work_outline_rounded,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _salaryMinCtrl,
                    label: 'Min Salary',
                    hint: '80000',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _salaryMaxCtrl,
                    label: 'Max Salary',
                    hint: '150000',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              value: _preferredRemote,
              onChanged: (v) => setState(() => _preferredRemote = v),
              title: Text('Prefer Remote', style: theme.textTheme.titleMedium),
              subtitle: Text('Only target remote job listings', style: theme.textTheme.bodySmall),
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: Text('Set as Default Profile', style: theme.textTheme.titleMedium),
              subtitle: Text(
                'This profile will be used for AI tailoring and quick apply',
                style: theme.textTheme.bodySmall,
              ),
              activeColor: AppTheme.accent,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            AppButton(
              label: isEditing ? 'Save Changes' : 'Create Profile',
              isLoading: _isSaving,
              onPressed: _save,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primary,
            ),
      ),
    );
  }
}
