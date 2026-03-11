class Job {
  final String title;
  final String company;
  final String? location;
  final String url;
  final String? description;
  final int? matchScore;
  final bool isEasyApply;

  const Job({
    required this.title,
    required this.company,
    this.location,
    required this.url,
    this.description,
    this.matchScore,
    this.isEasyApply = false,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String?,
      url: json['url'] as String,
      description: json['description'] as String?,
      matchScore: json['match_score'] as int?,
      isEasyApply: json['is_easy_apply'] as bool? ?? false,
    );
  }
}

class TailoredResume {
  final String summary;
  final List<String> bullets;
  final List<String> skills;
  final int matchScore;

  const TailoredResume({
    required this.summary,
    required this.bullets,
    required this.skills,
    required this.matchScore,
  });

  factory TailoredResume.fromJson(Map<String, dynamic> json) {
    return TailoredResume(
      summary: json['summary'] as String? ?? '',
      bullets: (json['bullets'] as List<dynamic>?)?.cast<String>() ?? [],
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      matchScore: json['match_score'] as int? ?? 0,
    );
  }
}
