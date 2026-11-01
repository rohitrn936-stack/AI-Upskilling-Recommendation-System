class AppSettings {
  final String? themeMode; // 'system', 'light', 'dark'
  final bool? notificationsEnabled;
  final bool? progressTrackingEnabled;
  final int? dailyLearningMinutes;

  const AppSettings({
    this.themeMode,
    this.notificationsEnabled,
    this.progressTrackingEnabled,
    this.dailyLearningMinutes,
  });

  factory AppSettings.mock({ThemeMode? themeMode}) {
    return AppSettings(
      themeMode: themeMode.toString().split('.').last,
    );
  }
}