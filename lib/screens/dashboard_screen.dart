import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/quote_api_service.dart';
import '../services/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final List<String> selectedTargets;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.selectedTargets,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _quote = "Loading motivation...";
  String _author = "";
  List<Map<String, dynamic>> _allHabits = [];
  List<Map<String, dynamic>> _displayedHabits = [];
  DateTime _currentDate = DateTime.now();
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = _currentDate;
    _fetchQuote();
    _generateDates();
    _initDatabaseAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _generateDates() {
    _weekDates = List.generate(
      8,
      (index) => _currentDate.subtract(const Duration(days: 3)).add(Duration(days: index)),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _initDatabaseAndLoad() async {
    final db = await DatabaseHelper.instance.database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM habits');
    int count = countResult.first['count'] as int;

    if (count == 0 && widget.selectedTargets.isNotEmpty) {
      for (String target in widget.selectedTargets) {
        await db.insert('habits', {
          'title': target,
          'description': 'My $target habit',
          'frequency': 'Daily',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }

    await _loadHabitsData();
  }

  Future<void> _loadHabitsData() async {
    final db = await DatabaseHelper.instance.database;
    final habitsData = await db.query('habits');
    
    String dateStr = _formatDate(_selectedDate);
    final logsData = await db.query('daily_logs', where: 'date = ?', whereArgs: [dateStr]);

    Map<int, Map<String, dynamic>> logMap = {};
    for (var log in logsData) {
      logMap[log['habitId'] as int] = log;
    }

    List<Map<String, dynamic>> combined = [];
    for (var habit in habitsData) {
      int habitId = habit['id'] as int;
      var log = logMap[habitId];
      bool isCompleted = log != null ? (log['isCompleted'] == 1) : false;

      combined.add({
        'id': habitId,
        'title': habit['title'],
        'completed': isCompleted,
        'logId': log?['id'],
        'icon': _getIconData(habit['title'] as String),
        'iconColor': _getIconColor(habit['title'] as String),
        'tagColor': const Color(0xFF5B5B5B),
      });
    }

    if (mounted) {
      setState(() {
        _allHabits = combined;
        _filterHabits(_searchController.text);
      });
    }
  }

  void _filterHabits(String query) {
    if (query.isEmpty) {
      setState(() {
        _displayedHabits = List.from(_allHabits);
      });
    } else {
      setState(() {
        _displayedHabits = _allHabits.where((habit) {
          final title = habit['title'].toString().toLowerCase();
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _toggleHabitCompletion(Map<String, dynamic> habit) async {
    final db = await DatabaseHelper.instance.database;
    int habitId = habit['id'];
    bool currentStatus = habit['completed'];
    int? logId = habit['logId'];
    String dateStr = _formatDate(_selectedDate);

    if (logId == null) {
      await db.insert('daily_logs', {
        'habitId': habitId,
        'date': dateStr,
        'isCompleted': currentStatus ? 0 : 1,
      });
    } else {
      await db.update('daily_logs', {
        'isCompleted': currentStatus ? 0 : 1,
      }, where: 'id = ?', whereArgs: [logId]);
    }

    await _loadHabitsData();
  }

  IconData _getIconData(String title) {
    if (title == 'Sports') return Icons.directions_bike;
    if (title == 'Art') return Icons.palette;
    if (title == 'Laptop') return Icons.laptop_mac;
    if (title == 'Live Healthier') return Icons.favorite;
    if (title == 'Meditation') return Icons.self_improvement;
    if (title == 'Study') return Icons.menu_book;
    return Icons.star;
  }

  Color _getIconColor(String title) {
    if (title == 'Live Healthier') return Colors.red;
    if (title == 'Study') return Colors.brown;
    return const Color(0xFF0F5A42);
  }

  Future<void> _fetchQuote() async {
    try {
      final quoteData = await QuoteApiService.getQuote();
      if (mounted) {
        setState(() {
          _quote = quoteData['quote'] ?? "The secret of your future is hidden in your daily routine.";
          _author = quoteData['author'] ?? "Mike Murdock";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quote = "The secret of your future is hidden in your daily routine.";
          _author = "Mike Murdock";
        });
      }
    }
  }

  Future<void> _showAddHabitDialog() async {
    final TextEditingController newHabitController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Habit"),
          content: TextField(
            controller: newHabitController,
            decoration: const InputDecoration(hintText: "Enter habit title"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5A42)),
              onPressed: () async {
                if (newHabitController.text.isNotEmpty) {
                  final db = await DatabaseHelper.instance.database;
                  await db.insert('habits', {
                    'title': newHabitController.text.trim(),
                    'description': 'Custom habit',
                    'frequency': 'Daily',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("ADD", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    
    await _loadHabitsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.menu,
                size: 32,
                color: Color(0xFF0F5A42),
              ),
              const SizedBox(height: 16),
              Text(
                "Hi, ${widget.userName}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's make habits together!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weekDates.length,
                  itemBuilder: (context, index) {
                    final date = _weekDates[index];
                    final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                        _loadHabitsData();
                      },
                      child: _buildDateCard(
                        date.day.toString(),
                        DateFormat('E').format(date).toUpperCase(),
                        isSelected ? const Color(0xFF0F5A42) : const Color(0xFF319573),
                        isSelected: isSelected,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Today's Motivation",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F5A42),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5A42),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '"$_quote"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _author.isNotEmpty ? "-$_author" : "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Habits",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black87, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterHabits,
                  decoration: const InputDecoration(
                    hintText: 'Search here',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: Icon(Icons.search, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_displayedHabits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                        child: Text(
                          "No habits found. Add one!",
                          style: TextStyle(color: Colors.black54),
                        ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _displayedHabits.length,
                  itemBuilder: (context, index) {
                    final habit = _displayedHabits[_displayedHabits.length - 1 - index];
                    return _buildHabitCard(habit);
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F5A42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF0F5A42),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.calendar_today, "Today", true),
            _buildNavItem(Icons.show_chart, "Progress", false),
            _buildNavItem(Icons.grid_view, "Categories", false),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(String date, String day, Color color, {bool isSelected = false}) {
    return Container(
      width: 50,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: habit['iconColor'], width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(habit['icon'], color: habit['iconColor']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: habit['tagColor'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Habit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toggleHabitCompletion(habit),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                habit['completed'] ? Icons.check : Icons.circle,
                color: habit['completed'] ? Colors.black87 : Colors.grey.shade300,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.more_vert, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 30,
            color: Colors.white,
          ),
      ],
    );
  }
}