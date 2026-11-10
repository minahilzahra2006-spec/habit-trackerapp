import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'habit.dart';

class HabitProvider extends ChangeNotifier {
  final Box<Habit> _habitBox = Hive.box<Habit>('habits_box');
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  List<Habit> get habits => _habitBox.values.toList();

  List<Habit> getTodayHabits() {
    final todayWeekday = DateTime.now().weekday;
    return habits.where((habit) => habit.repeatingDays.contains(todayWeekday)).toList();
  }

  Future<void> addHabit({
    required String name,
    required String description,
    required String iconName,
    required int colorValue,
    required List<int> repeatingDays,
  }) async {
    final newHabit = Habit(
      name: name,
      description: description,
      completedDates: [],
      streakCount: 0,
      bestStreak: 0,
      iconName: iconName,
      colorValue: colorValue,
      repeatingDays: repeatingDays,
    );
    await _habitBox.add(newHabit);
    notifyListeners();
  }

  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final index = habit.completedDates.indexWhere((d) =>
    d.year == normalizedDate.year &&
        d.month == normalizedDate.month &&
        d.day == normalizedDate.day);

    if (index >= 0) {
      habit.completedDates.removeAt(index);
      habit.streakCount = habit.streakCount > 0 ? habit.streakCount - 1 : 0;
    } else {
      habit.completedDates.add(normalizedDate);
      habit.streakCount += 1;
      if (habit.streakCount > habit.bestStreak) {
        habit.bestStreak = habit.streakCount;
      }
    }

    await habit.save();
    notifyListeners();
  }

  Future<void> deleteHabit(Habit habit) async {
    await habit.delete();
    notifyListeners();
  }

  // Clear all data function
  Future<void> clearAllData() async {
    await _habitBox.clear();
    notifyListeners();
  }

  // Top habit for this month
  Habit? getTopHabitThisMonth() {
    if (habits.isEmpty) return null;
    final now = DateTime.now();
    Habit? topHabit;
    int maxCompletions = -1;

    for (var habit in habits) {
      int monthCompletions = habit.completedDates.where((d) =>
      d.year == now.year && d.month == now.month).length;
      if (monthCompletions > maxCompletions) {
        maxCompletions = monthCompletions;
        topHabit = habit;
      }
    }
    return topHabit;
  }
}