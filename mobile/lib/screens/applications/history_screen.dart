import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/application.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/theme/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  ApplicationStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationsAsync = ref.watch(applicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(applicationsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                ...ApplicationStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: s.name.capitalize(),
                        selected: _filterStatus == s,
                        color: _statusColor(s),
                        onTap: () => setState(() => _filterStatus = s),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: applicationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (applications) {
                final filtered = _filterStatus == null
                    ? applications
                    : applications.where((a) => a.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return _EmptyHistory();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ApplicationCard(application: filtered[i])
                      .animate(delay: (i * 60).ms)
                      .fadeIn()
                      .slideY(begin: 0.1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted:
        return AppTheme.success;
      case ApplicationStatus.pending:
        return AppTheme.warning;
      case ApplicationStatus.failed:
        return AppTheme.error;
      case ApplicationStatus.skipped:
        return AppTheme.darkTextSecondary;
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  final JobApplication application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.jobTitle ?? 'Unknown Role',
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (application.companyName != null)
                          Text(
                            application.companyName!,
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: application.status),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                children: [
                  if (application.matchScore != null) ...[
                    Icon(Icons.star_rounded, size: 14, color: _matchColor(application.matchScore!)),
                    const SizedBox(width: 4),
                    Text(
                      '${application.matchScore}% match',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _matchColor(application.matchScore!),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.schedule_rounded, size: 14, color: AppTheme.darkTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(application.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _matchColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ApplicationDetails(application: application),
    );
  }
}

class _ApplicationDetails extends StatelessWidget {
  final JobApplication application;

  const _ApplicationDetails({required this.application});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(application.jobTitle ?? 'Unknown Role', style: theme.textTheme.headlineMedium),
            if (application.companyName != null)
              Text(application.companyName!, style: theme.textTheme.bodyMedium),

            const SizedBox(height: 16),
            _StatusBadge(status: application.status),

            if (application.tailoredSummary != null) ...[
              const SizedBox(height: 24),
              Text('AI-Tailored Summary', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(application.tailoredSummary!, style: theme.textTheme.bodyMedium),
            ],

            if (application.tailoredBullets?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text('Key Achievements', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ...application.tailoredBullets!.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.primary, fontSize: 16)),
                    Expanded(child: Text(b, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
            ],

            if (application.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case ApplicationStatus.submitted:
        color = AppTheme.success;
        icon = Icons.check_circle_rounded;
        break;
      case ApplicationStatus.pending:
        color = AppTheme.warning;
        icon = Icons.schedule_rounded;
        break;
      case ApplicationStatus.failed:
        color = AppTheme.error;
        icon = Icons.error_rounded;
        break;
      case ApplicationStatus.skipped:
        color = AppTheme.darkTextSecondary;
        icon = Icons.skip_next_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.name.capitalize(),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.15) : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? activeColor : AppTheme.darkBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : AppTheme.darkTextSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, size: 80, color: AppTheme.darkBorder),
          const SizedBox(height: 16),
          Text('No applications yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Applied jobs will appear here\nafter you start applying.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

extension StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
