import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/user_profile.dart';

class ProfilesNotifier extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() async {
    return _fetchProfiles();
  }

  Future<List<UserProfile>> _fetchProfiles() async {
    final api = ref.read(apiClientProvider);
    final data = await api.getProfiles();
    return data.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProfiles);
  }

  Future<UserProfile?> createProfile(Map<String, dynamic> data) async {
    try {
      final api = ref.read(apiClientProvider);
      final json = await api.createProfile(data);
      final profile = UserProfile.fromJson(json);
      state = AsyncData([...state.valueOrNull ?? [], profile]);
      return profile;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfile(int id, Map<String, dynamic> data) async {
    try {
      final api = ref.read(apiClientProvider);
      final json = await api.updateProfile(id, data);
      final updated = UserProfile.fromJson(json);
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map((p) => p.id == id ? updated : p)
            .toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProfile(int id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.deleteProfile(id);
      state = AsyncData((state.valueOrNull ?? []).where((p) => p.id != id).toList());
      return true;
    } catch (e) {
      return false;
    }
  }
}

final profilesProvider = AsyncNotifierProvider<ProfilesNotifier, List<UserProfile>>(
  ProfilesNotifier.new,
);

final defaultProfileProvider = Provider<UserProfile?>((ref) {
  final profiles = ref.watch(profilesProvider).valueOrNull;
  if (profiles == null || profiles.isEmpty) return null;
  return profiles.firstWhere((p) => p.isDefault, orElse: () => profiles.first);
});
