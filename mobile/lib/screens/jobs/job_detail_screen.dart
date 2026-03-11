import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../core/api/api_client.dart';
import '../../core/models/job.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobUrl;

  const JobDetailScreen({super.key, required this.jobUrl});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  TailoredResume? _tailored;
  bool _isTailoring = false;
  String? _error;

  Future<void> _tailorResume() async {
    final profile = ref.read(defaultProfileProvider);
    if (profile == null) {
      setState(() => _error = 'Please create a profile first');
      return;
    }

    setState(() {
      _isTailoring = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final data = await api.tailorResume({
        'profile_id': profile.id,
        'job_url': widget.jobUrl,
        'job_description': 'Job listing from ${widget.jobUrl}',
      });
      setState(() => _tailored = TailoredResume.fromJson(data));
    } catch (e) {
      setState(() => _error = 'Failed to tailor resume. Please try again.');
    } finally {
      setState(() => _isTailoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job URL card
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application URL', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    widget.jobUrl,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Tailor button or result
            if (_tailored == null) ...[
              AppButton(
                label: 'Tailor Resume with AI',
                icon: Icons.auto_awesome_rounded,
                isLoading: _isTailoring,
                onPressed: _tailorResume,
              ).animate(delay: 100.ms).fadeIn(),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: AppTheme.error)),
              ],
            ] else ...[
              _TailoredResult(tailored: _tailored!),

              const SizedBox(height: 16),

              AppButton(
                label: 'Apply Now',
                icon: Icons.rocket_launch_rounded,
                onPressed: () {
                  final profile = ref.read(defaultProfileProvider);
                  if (profile == null || profile.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No profile found. Please create a profile before applying.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.push('/apply', extra: {
                    'profile_id': profile.id,
                    'job_url': widget.jobUrl,
                    'tailored_summary': _tailored!.summary,
                    'tailored_bullets': _tailored!.bullets,
                    'tailored_skills': _tailored!.skills,
                  });
                },
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _tailorResume,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Re-tailor'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TailoredResult extends StatelessWidget {
  final TailoredResume tailored;

  const _TailoredResult({required this.tailored});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match score
        Row(
          children: [
            CircularPercentIndicator(
              radius: 36,
              lineWidth: 6,
              percent: tailored.matchScore / 100,
              center: Text(
                '${tailored.matchScore}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _scoreColor(tailored.matchScore),
                ),
              ),
              progressColor: _scoreColor(tailored.matchScore),
              backgroundColor: AppTheme.darkBorder,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Match Score', style: theme.textTheme.headlineSmall),
                  Text(
                    tailored.matchScore >= 80
                        ? 'Excellent fit!'
                        : tailored.matchScore >= 60
                            ? 'Good match'
                            : 'Moderate match',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(),

        const SizedBox(height: 20),

        // Summary
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('AI-Tailored Summary', style: theme.textTheme.titleMedium),
              ]),
              const SizedBox(height: 10),
              Text(tailored.summary, style: theme.textTheme.bodyMedium),
            ],
          ),
        ).animate(delay: 100.ms).fadeIn(),

        const SizedBox(height: 12),

        // Bullets
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.format_list_bulleted_rounded, size: 18, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text('Key Achievements', style: theme.textTheme.titleMedium),
              ]),
              const SizedBox(height: 10),
              ...tailored.bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.primary, fontSize: 16)),
                    Expanded(child: Text(b, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn(),

        const SizedBox(height: 12),

        // Skills
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.psychology_rounded, size: 18, color: Color(0xFFFFB547)),
                const SizedBox(width: 8),
                Text('Highlighted Skills', style: theme.textTheme.titleMedium),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tailored.skills
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: child,
    );
  }
}
