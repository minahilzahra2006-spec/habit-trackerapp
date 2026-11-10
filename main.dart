import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'habit.dart';
import 'habit_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HabitAdapter());
  await Hive.openBox<Habit>('habits_box');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: habitProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavigationScreen(),
    );
  }
}

// --- MAIN NAVIGATION CONTAINER ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const TodayHabitsScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- 1. TODAY SCREEN ---
class TodayHabitsScreen extends StatelessWidget {
  const TodayHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final todayHabits = habitProvider.getTodayHabits();

    int totalToday = todayHabits.length;
    int completedToday = todayHabits.where((habit) {
      final today = DateTime.now();
      return habit.completedDates.any((d) =>
      d.year == today.year && d.month == today.month && d.day == today.day);
    }).length;

    double progress = totalToday == 0 ? 0 : completedToday / totalToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today Habits Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (totalToday > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today Progress: $completedToday of $totalToday done',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
          Expanded(
            child: todayHabits.isEmpty
                ? const Center(
              child: Text(
                'No habits scheduled for today!\nTap + to add a new habit.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: todayHabits.length,
              itemBuilder: (context, index) {
                final habit = todayHabits[index];
                final today = DateTime.now();
                bool isCompletedToday = habit.completedDates.any((d) =>
                d.year == today.year &&
                    d.month == today.month &&
                    d.day == today.day);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HabitDetailScreen(habit: habit),
                        ),
                      );
                    },
                    leading: Checkbox(
                      value: isCompletedToday,
                      onChanged: (bool? value) {
                        habitProvider.toggleHabitCompletion(habit, today);
                      },
                    ),
                    title: Text(
                      habit.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompletedToday
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                        '${habit.description}\nStreak: ${habit.streakCount} 🔥 | Best: ${habit.bestStreak} 🏆'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(context, habitProvider, habit),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, HabitProvider provider, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteHabit(habit);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddHabitModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Habit'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Habit Name *'),
                    maxLength: 30,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Repeating Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (index) {
                      int dayNum = index + 1;
                      String dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
                      bool isSelected = selectedDays.contains(dayNum);
                      return FilterChip(
                        label: Text(dayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(dayNum);
                            } else {
                              selectedDays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (selectedDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select at least one day!')),
                    );
                    return;
                  }
                  Provider.of<HabitProvider>(context, listen: false).addHabit(
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    iconName: 'default',
                    colorValue: Colors.deepPurple.value,
                    repeatingDays: selectedDays,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Habit'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. HABIT DETAIL SCREEN (Monthly Calendar Heatmap) ---
class HabitDetailScreen extends StatelessWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final startingWeekday = firstDayOfMonth.weekday - 1;

    int completedThisMonth = habit.completedDates.where((d) =>
    d.year == now.year && d.month == now.month).length;
    double monthCompletionRate = (completedThisMonth / daysInMonth) * 100;

    return Scaffold(
      appBar: AppBar(title: Text(habit.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${habit.description.isEmpty ? "No description" : habit.description}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Current Streak: ${habit.streakCount} 🔥 | Best Streak: ${habit.bestStreak} 🏆',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('This Month Completion Rate: ${monthCompletionRate.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16, color: Colors.deepPurple)),
            const Divider(height: 30),
            const Text('Monthly Calendar Heatmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: daysInMonth + startingWeekday,
                itemBuilder: (context, index) {
                  if (index < startingWeekday) {
                    return Container(); // Empty slots for previous month
                  }
                  int dayNum = index - startingWeekday + 1;
                  DateTime targetDate = DateTime(now.year, now.month, dayNum);
                  bool isCompleted = habit.completedDates.any((d) =>
                  d.year == targetDate.year &&
                      d.month == targetDate.month &&
                      d.day == targetDate.day);

                  return Container(
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isCompleted ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. STATISTICS & CHARTS SCREEN ---
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final topHabit = habitProvider.getTopHabitThisMonth();

    // Last 7 days check-ins calculation for Bar Chart
    List<FlSpot> spots = [];
    List<String> dayLabels = [];
    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      int count = habitProvider.habits.where((habit) =>
          habit.completedDates.any((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day)).length;
      spots.add(FlSpot((6 - i).toDouble(), count.toDouble()));
      dayLabels.add(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics & Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Last 7 Days Check-ins Bar Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < dayLabels.length) {
                            return Text(dayLabels[idx]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: spots.map((spot) {
                    return BarChartGroupData(
                      x: spot.x.toInt(),
                      barRods: [
                        BarChartRodData(
                          toY: spot.y,
                          color: Colors.deepPurple,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 40),
            const Text('Top Habit This Month', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  topHabit != null
                      ? '${topHabit.name} (${topHabit.streakCount} 🔥)'
                      : 'No habits completed this month yet.',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. SETTINGS SCREEN ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle light and dark theme'),
            value: habitProvider.isDarkMode,
            onChanged: (val) {
              habitProvider.toggleTheme();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Delete all habits and history permanently'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data'),
                  content: const Text('Are you sure you want to delete all habits? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        habitProvider.clearAllData();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}