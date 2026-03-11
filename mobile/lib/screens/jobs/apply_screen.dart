import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> jobData;

  const ApplyScreen({super.key, required this.jobData});

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  List<_StatusStep> _steps = [];
  bool _isStarted = false;
  bool _isDone = false;
  bool? _success;
  WebSocketChannel? _channel;
  int _progress = 0;

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _startApply() async {
    setState(() => _isStarted = true);

    try {
      final api = ref.read(apiClientProvider);
      final result = await api.startApply(widget.jobData);
      final taskId = result['task_id'] as String;

      // Connect WebSocket
      final wsUri = Uri.parse(ApiConstants.wsUrl(taskId));
      _channel = WebSocketChannel.connect(wsUri);

      _addStep('connecting', 'Starting application...', 0);

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          final step = data['step'] as String;
          final msg = data['message'] as String;
          final progress = data['progress'] as int;
          final done = data['done'] as bool? ?? false;
          final success = data['success'] as bool?;

          setState(() {
            _progress = progress;
            _addStep(step, msg, progress);
            if (done) {
              _isDone = true;
              _success = success;
            }
          });
        },
        onError: (e) {
          setState(() {
            _isDone = true;
            _success = false;
            _addStep('error', 'Connection error: $e', 0);
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDone = true;
        _success = false;
        _addStep('error', 'Failed to start: $e', 0);
      });
    }
  }

  void _addStep(String step, String message, int progress) {
    _steps = [
      ..._steps,
      _StatusStep(step: step, message: message, progress: progress),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applying'),
        leading: _isDone
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress ring
            if (_isStarted) ...[
              _ProgressRing(progress: _progress, success: _success, done: _isDone),
              const SizedBox(height: 24),
            ],

            // Status message
            if (_isDone) ...[
              Icon(
                _success == true ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 64,
                color: _success == true ? AppTheme.success : AppTheme.error,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                _success == true ? 'Application Submitted!' : 'Application Failed',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _success == true ? AppTheme.success : AppTheme.error,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn(),
              const SizedBox(height: 32),
              if (_success == true)
                ElevatedButton.icon(
                  onPressed: () => context.go('/applications'),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View Application History'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Try Again'),
                ),
            ] else if (!_isStarted) ...[
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.rocket_launch_rounded, size: 48, color: Colors.white),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text('Ready to Apply?', style: theme.textTheme.displayMedium),
              const SizedBox(height: 12),
              Text(
                'The bot will open the application form, fill in your details using AI, and submit automatically.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _startApply,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Applying'),
              ),
            ],

            // Step log
            if (_steps.isNotEmpty) ...[
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: ListView.builder(
                    itemCount: _steps.length,
                    itemBuilder: (_, i) {
                      final step = _steps[i];
                      final isLast = i == _steps.length - 1;
                      return _StepRow(step: step, isActive: isLast && !_isDone)
                          .animate(delay: (i * 100).ms)
                          .fadeIn()
                          .slideX(begin: -0.1);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusStep {
  final String step;
  final String message;
  final int progress;

  const _StatusStep({
    required this.step,
    required this.message,
    required this.progress,
  });
}

class _ProgressRing extends StatelessWidget {
  final int progress;
  final bool? success;
  final bool done;

  const _ProgressRing({required this.progress, this.success, required this.done});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 8,
            backgroundColor: AppTheme.darkBorder,
            valueColor: AlwaysStoppedAnimation(
              done
                  ? (success == true ? AppTheme.success : AppTheme.error)
                  : AppTheme.primary,
            ),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '$progress%',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final _StatusStep step;
  final bool isActive;

  const _StepRow({required this.step, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isActive)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            )
          else
            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive ? AppTheme.darkTextPrimary : AppTheme.darkTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
