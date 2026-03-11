import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/application.dart';

class ApplicationsNotifier extends AsyncNotifier<List<JobApplication>> {
  @override
  Future<List<JobApplication>> build() async {
    return _fetchApplications();
  }

  Future<List<JobApplication>> _fetchApplications({String? status}) async {
    final api = ref.read(apiClientProvider);
    final data = await api.getApplications(status: status);
    return data.map((e) => JobApplication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchApplications);
  }
}

final applicationsProvider = AsyncNotifierProvider<ApplicationsNotifier, List<JobApplication>>(
  ApplicationsNotifier.new,
);

// Current apply task state
class ApplyTaskState {
  final String step;
  final String message;
  final int progress;
  final bool done;
  final bool? success;
  final String? error;

  const ApplyTaskState({
    required this.step,
    required this.message,
    required this.progress,
    required this.done,
    this.success,
    this.error,
  });
}

final applyTaskProvider = StateProvider<ApplyTaskState?>((ref) => null);
