import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/api/api_client.dart';
import '../../core/models/job.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/job_card.dart';

final _searchKeywordsProvider = StateProvider<String>((ref) => '');
final _remoteFilterProvider = StateProvider<bool>((ref) => false);

final _jobResultsProvider = FutureProvider.autoDispose.family<List<Job>, Map<String, dynamic>>(
  (ref, params) async {
    final api = ref.read(apiClientProvider);
    final profile = ref.read(defaultProfileProvider);
    if (profile == null) return [];

    // Score each job against the user's profile
    // In the future this would call a dedicated search endpoint
    // For now we return mock data that would come from the backend
    return [];
  },
);

class JobSearchScreen extends ConsumerStatefulWidget {
  const JobSearchScreen({super.key});

  @override
  ConsumerState<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends ConsumerState<JobSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'United States');
  bool _remoteOnly = false;
  List<Job> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keywords = _searchCtrl.text.trim();
    if (keywords.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final api = ref.read(apiClientProvider);
      // This calls the backend which orchestrates LinkedIn search + scoring
      final data = await api.dio.get('/jobs/search', queryParameters: {
        'keywords': keywords,
        'location': _locationCtrl.text.trim(),
        'remote_only': _remoteOnly,
        'max_results': 20,
      });
      final jobs = (data.data as List<dynamic>)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort by match score descending
      jobs.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
      setState(() => _results = jobs);
    } catch (_) {
      // Show empty state
      setState(() => _results = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultProfile = ref.watch(defaultProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Jobs'),
        actions: [
          if (defaultProfile != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Icon(Icons.person_rounded, size: 16),
                label: Text(defaultProfile.profileName),
                side: BorderSide.none,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _SearchBar(
            searchCtrl: _searchCtrl,
            locationCtrl: _locationCtrl,
            remoteOnly: _remoteOnly,
            onRemoteChanged: (v) => setState(() => _remoteOnly = v),
            onSearch: _search,
          ),

          // Results
          Expanded(
            child: _isSearching
                ? _ShimmerList()
                : !_hasSearched
                    ? _EmptySearchState()
                    : _results.isEmpty
                        ? _NoResultsState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => JobCard(
                              job: _results[i],
                              onTap: () => context.push(
                                '/jobs/${Uri.encodeComponent(_results[i].url)}',
                                extra: _results[i],
                              ),
                            ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.1),
                          ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final TextEditingController locationCtrl;
  final bool remoteOnly;
  final ValueChanged<bool> onRemoteChanged;
  final VoidCallback onSearch;

  const _SearchBar({
    required this.searchCtrl,
    required this.locationCtrl,
    required this.remoteOnly,
    required this.onRemoteChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Software Engineer, Designer...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                      onPressed: onSearch,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Remote'),
                selected: remoteOnly,
                onSelected: onRemoteChanged,
                selectedColor: AppTheme.primary.withOpacity(0.2),
                checkmarkColor: AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_rounded, size: 80, color: AppTheme.darkBorder),
          const SizedBox(height: 16),
          Text('Search for your next role', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Enter keywords above to find jobs\ntailored to your profile.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, size: 80, color: AppTheme.darkBorder),
          const SizedBox(height: 16),
          Text('No jobs found', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or location.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.darkCard,
        highlightColor: AppTheme.darkBorder,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
