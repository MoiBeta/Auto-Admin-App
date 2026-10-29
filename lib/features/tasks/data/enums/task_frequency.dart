enum TaskFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  /// Frequencies the backend can schedule.
  static const supported = [daily, weekly, monthly, yearly];
}
