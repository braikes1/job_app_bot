import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_profile.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profilesAsync = ref.watch(profilesProvider);
    final authState = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profiles/new'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Profile'),
      ),
      body: Column(
        children: [
          // User info banner
          if (authState?.user != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF4A45D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      (authState!.user!['full_name'] as String).substring(0, 1).toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.user!['full_name'] as String,
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      Text(
                        authState.user!['email'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

          // Profiles list
          Expanded(
            child: profilesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (profiles) => profiles.isEmpty
                  ? _EmptyProfiles(onTap: () => context.push('/profiles/new'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: profiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ProfileCard(
                        profile: profiles[i],
                        onEdit: () => context.push('/profiles/${profiles[i].id}/edit'),
                        onUploadResume: () => context.push('/profiles/${profiles[i].id}/resume'),
                        onDelete: () => _confirmDelete(context, ref, profiles[i]),
                      ).animate(delay: (i * 80).ms).fadeIn().slideY(begin: 0.1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, UserProfile profile) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Delete "${profile.profileName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profilesProvider.notifier).deleteProfile(profile.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onUploadResume;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.onEdit,
    required this.onUploadResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(profile.profileName, style: theme.textTheme.titleLarge),
                          if (profile.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Default',
                                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.accent),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(profile.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'resume') onUploadResume();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'resume', child: Text('Upload Resume')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),

            if (profile.targetRoles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: profile.targetRoles
                    .take(3)
                    .map((r) => Chip(label: Text(r, style: theme.textTheme.bodySmall)))
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                _InfoPill(
                  icon: profile.resumeUrl != null
                      ? Icons.description_rounded
                      : Icons.upload_file_rounded,
                  label: profile.resumeUrl != null ? 'Resume uploaded' : 'No resume',
                  color: profile.resumeUrl != null ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: profile.preferredRemote
                      ? Icons.home_work_rounded
                      : Icons.location_on_rounded,
                  label: profile.preferredRemote ? 'Remote' : 'On-site',
                  color: AppTheme.darkTextSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyProfiles({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_add_rounded, size: 80, color: AppTheme.darkBorder),
          const SizedBox(height: 16),
          Text('No profiles yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Create your first application profile\nto start applying.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }
}
