/// User preferences model for local storage
class UserPreferences {
  final String theme; // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final bool autoSyncEnabled;
  final String language; // 'en', 'ur', etc.
  final bool offlineModeEnabled;
  final DateTime? lastUpdated;

  UserPreferences({
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.autoSyncEnabled = true,
    this.language = 'en',
    this.offlineModeEnabled = true,
    this.lastUpdated,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'autoSyncEnabled': autoSyncEnabled,
      'language': language,
      'offlineModeEnabled': offlineModeEnabled,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      autoSyncEnabled: json['autoSyncEnabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      offlineModeEnabled: json['offlineModeEnabled'] as bool? ?? true,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  /// Copy with updated fields
  UserPreferences copyWith({
    String? theme,
    bool? notificationsEnabled,
    bool? autoSyncEnabled,
    String? language,
    bool? offlineModeEnabled,
    DateTime? lastUpdated,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      language: language ?? this.language,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if dark theme is enabled
  bool get isDarkTheme => theme == 'dark';

  /// Check if light theme is enabled
  bool get isLightTheme => theme == 'light';

  /// Check if system theme is enabled
  bool get isSystemTheme => theme == 'system';
}
