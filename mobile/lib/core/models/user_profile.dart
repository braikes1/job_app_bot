class UserProfile {
  final int id;
  final int userId;
  final String profileName;
  final String fullName;
  final String email;
  final String? phone;
  final String? location;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final String? githubUrl;
  final String? resumeUrl;
  final String? knowledgeBase;
  final List<String> targetRoles;
  final bool preferredRemote;
  final int? salaryMin;
  final int? salaryMax;
  final Map<String, dynamic> extraAnswers;
  final bool isDefault;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.profileName,
    required this.fullName,
    required this.email,
    this.phone,
    this.location,
    this.linkedinUrl,
    this.portfolioUrl,
    this.githubUrl,
    this.resumeUrl,
    this.knowledgeBase,
    this.targetRoles = const [],
    this.preferredRemote = true,
    this.salaryMin,
    this.salaryMax,
    this.extraAnswers = const {},
    this.isDefault = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      profileName: json['profile_name'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      portfolioUrl: json['portfolio_url'] as String?,
      githubUrl: json['github_url'] as String?,
      resumeUrl: json['resume_url'] as String?,
      knowledgeBase: json['knowledge_base'] as String?,
      targetRoles: (json['target_roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferredRemote: json['preferred_remote'] as bool? ?? true,
      salaryMin: json['salary_min'] as int?,
      salaryMax: json['salary_max'] as int?,
      extraAnswers: (json['extra_answers'] as Map<String, dynamic>?) ?? {},
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'profile_name': profileName,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedin_url': linkedinUrl,
        'portfolio_url': portfolioUrl,
        'github_url': githubUrl,
        'knowledge_base': knowledgeBase,
        'target_roles': targetRoles,
        'preferred_remote': preferredRemote,
        'salary_min': salaryMin,
        'salary_max': salaryMax,
        'extra_answers': extraAnswers,
        'is_default': isDefault,
      };

  UserProfile copyWith({
    String? profileName,
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? linkedinUrl,
    String? portfolioUrl,
    String? githubUrl,
    String? resumeUrl,
    String? knowledgeBase,
    List<String>? targetRoles,
    bool? preferredRemote,
    int? salaryMin,
    int? salaryMax,
    Map<String, dynamic>? extraAnswers,
    bool? isDefault,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      profileName: profileName ?? this.profileName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      knowledgeBase: knowledgeBase ?? this.knowledgeBase,
      targetRoles: targetRoles ?? this.targetRoles,
      preferredRemote: preferredRemote ?? this.preferredRemote,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      extraAnswers: extraAnswers ?? this.extraAnswers,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}
