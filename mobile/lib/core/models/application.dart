enum ApplicationStatus { pending, submitted, failed, skipped }

class JobApplication {
  final int id;
  final int userId;
  final int? profileId;
  final String? jobTitle;
  final String? companyName;
  final String jobUrl;
  final String? jobDescription;
  final String? tailoredSummary;
  final List<String>? tailoredBullets;
  final List<String>? tailoredSkills;
  final int? matchScore;
  final ApplicationStatus status;
  final String? errorMessage;
  final DateTime? appliedAt;
  final DateTime createdAt;

  const JobApplication({
    required this.id,
    required this.userId,
    this.profileId,
    this.jobTitle,
    this.companyName,
    required this.jobUrl,
    this.jobDescription,
    this.tailoredSummary,
    this.tailoredBullets,
    this.tailoredSkills,
    this.matchScore,
    required this.status,
    this.errorMessage,
    this.appliedAt,
    required this.createdAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      profileId: json['profile_id'] as int?,
      jobTitle: json['job_title'] as String?,
      companyName: json['company_name'] as String?,
      jobUrl: json['job_url'] as String,
      jobDescription: json['job_description'] as String?,
      tailoredSummary: json['tailored_summary'] as String?,
      tailoredBullets: (json['tailored_bullets'] as List<dynamic>?)?.cast<String>(),
      tailoredSkills: (json['tailored_skills'] as List<dynamic>?)?.cast<String>(),
      matchScore: json['match_score'] as int?,
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      errorMessage: json['error_message'] as String?,
      appliedAt: json['applied_at'] != null
          ? DateTime.parse(json['applied_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get statusLabel {
    switch (status) {
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.failed:
        return 'Failed';
      case ApplicationStatus.skipped:
        return 'Skipped';
    }
  }
}
