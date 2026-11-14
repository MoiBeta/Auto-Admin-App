enum TaskFrequency {
  none,

  /// Done a single time: shown on one day at a time, moving to the next day
  /// until it is completed, and only on the day it was completed afterwards.
  once,
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  /// Frequencies the backend can schedule.
  static const supported = [once, daily, weekly, monthly, yearly];
}
