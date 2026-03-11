import 'package:flutter/material.dart';

import '../core/models/job.dart';
import '../core/theme/app_theme.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        job.company.isNotEmpty ? job.company[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primary),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title + company
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.company,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Match score badge
                  if (job.matchScore != null)
                    _MatchBadge(score: job.matchScore!),
                ],
              ),

              if (job.location != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.darkTextSecondary),
                    const SizedBox(width: 4),
                    Text(job.location!, style: theme.textTheme.bodySmall),
                    if (job.isEasyApply) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.warning),
                      const SizedBox(width: 2),
                      Text('Easy Apply', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.warning)),
                    ],
                  ],
                ),
              ],

              if (job.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  job.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final int score;

  const _MatchBadge({required this.score});

  Color get _color {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: _color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
