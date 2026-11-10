import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  @HiveField(2)
  List<DateTime> completedDates;

  @HiveField(3)
  int streakCount;

  @HiveField(4)
  String iconName;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  List<int> repeatingDays;

  @HiveField(7)
  int bestStreak; // Yeh add karna hai

  Habit({
    required this.name,
    required this.description,
    required this.completedDates,
    required this.streakCount,
    required this.iconName,
    required this.colorValue,
    required this.repeatingDays,
    required this.bestStreak, // Constructor mein required
  });
}