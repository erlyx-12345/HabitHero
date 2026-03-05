import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../components/custom_navbar.dart';
import 'create_habit_screen.dart';
import 'habit_details_screen.dart'; 
import '../models/habit_model.dart';

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
  final DashboardController _controller = DashboardController();
  List<Map<String, dynamic>> _allHabits = [];
  String? _displayName;
  int _navIndex = 0;
  bool _isLoading = true;

  final ScrollController _dateScrollController = ScrollController();

  DateTime _selectedDate = DateTime.now();
  DateTime _installationDate = DateTime.now();
  String _selectedTimeFilter = "All";

  // UI Theme Colors
  final Color primaryGreen = const Color(0xFF10B981);
  final Color deepEmerald = const Color(0xFF064E3B);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate600 = const Color(0xFF475569);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate100 = const Color(0xFFF1F5F9);

  @override
void initState() {
  super.initState();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  _displayName = widget.userName;
  _initAppData(); // This now handles the scroll internally
}
  void _scrollToToday({bool animated = true}) {
  if (!_dateScrollController.hasClients) return;

  final DateTime today = DateTime.now();
  final DateTime start = DateTime(
    _installationDate.year,
    _installationDate.month,
    _installationDate.day,
  );

  final int daysToToday = today.difference(start).inDays;
  
  // Calculation: Card(72) + Margin(12) = 84.0
  final double targetOffset = daysToToday * 84.0;

  if (animated) {
    _dateScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
  } else {
    _dateScrollController.jumpTo(targetOffset);
  }
}

 Future<void> _initAppData() async {
  final startDate = await _controller.getAppStartDate();
  if (mounted) {
    setState(() {
      _installationDate = startDate;
    });

    // We refresh data first
    await _refreshData();

    // Now that _installationDate is set and the list is built, we scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday(animated: false);
    });
  }
}

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final name = await _controller.getUserName();
    final habits = await _controller.getHabitsWithLogs(date: _selectedDate);

    if (mounted) {
      setState(() {
        if (name != null) _displayName = name;
        _allHabits = habits;
        _isLoading = false;
      });
    }
  }

  String _getCurrentTimeframe() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Morning";
    if (hour >= 12 && hour < 17) return "Afternoon";
    if (hour >= 17 && hour <= 23) return "Evening";
    return "Night";
  }

  // --- ACTIONS & DIALOGS ---
  void _showHabitActions(Map<String, dynamic> habit, IconData customIcon, String habitTime) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    elevation: 0,
    isScrollControlled: true, // Allows the sheet to expand properly
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        // Use media query to handle keyboard or unusual screen heights
        padding: EdgeInsets.only(
          left: 24, 
          right: 24, 
          top: 12, 
          bottom: MediaQuery.of(context).viewInsets.bottom + 40
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hugs the content but feels taller due to padding
          children: [
            // Aesthetic Handle
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: slate100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 32),

            // Habit Preview Header (Increases visual height/presence)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24,
                    child: Icon(customIcon, color: slate900),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit['title'], 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: slate900)),
                        Text("Scheduled for $habitTime", 
                          style: GoogleFonts.poppins(fontSize: 12, color: slate400, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Cards
            _buildPremiumAction(
              icon: Icons.edit_note_rounded,
              label: "Edit Configuration",
              subLabel: "Update title, icons, or reminders",
              color: slate900,
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HabitDetailsScreen(
                      template: HabitTemplate(
                        title: habit['title'],
                        icon: customIcon,
                        timeOfDay: habitTime,
                        duration: habit['duration'] ?? "10 mins",
                      ),
                      focusArea: habit['focusArea'] ?? "General",
                      existingHabit: habit,
                    ),
                  ),
                );
                if (result == true) _refreshData();
              },
            ),
            const SizedBox(height: 16),
            _buildPremiumAction(
              icon: Icons.calendar_today_rounded,
              label: "Skip for Today",
              subLabel: "Will reappear tomorrow automatically",
              color: Colors.orange.shade800,
              onTap: () {
                Navigator.pop(context);
                _confirmRemoval(habit);
              },
            ),
            const SizedBox(height: 16),
            _buildPremiumAction(
              icon: Icons.no_crash_rounded,
              label: "End Habit Series",
              subLabel: "Stop future tracking, keep past stats",
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                _confirmPermanentDelete(habit);
              },
            ),
            // Extra spacing at the bottom to ensure it doesn't feel "low"
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

// Updated Helper with slightly more height/padding for a "chunky" premium feel
Widget _buildPremiumAction({
  required IconData icon,
  required String label,
  required String subLabel,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Increased vertical padding
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
                  Text(subLabel, 
                    style: GoogleFonts.poppins(fontSize: 11, color: color.withOpacity(0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    ),
  );
}
  // Dialog for "Remove for Today"
  void _confirmRemoval(Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Hide for Today?", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Text(
            "Hide '${habit['title']}' for ${DateFormat('MMM d').format(_selectedDate)}? It will return on other days.",
            style: GoogleFonts.poppins(fontSize: 14, color: slate600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: GoogleFonts.poppins(color: slate400, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: slate900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _controller.deleteHabitForDate(habit['id'], _selectedDate);
                _refreshData();
              },
              child: Text("HIDE", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  // Dialog for "Delete Permanently"
 void _confirmPermanentDelete(Map<String, dynamic> habit) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimalist Warning Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_delete_outlined,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Typography - Editorial Style
                Text(
                  "Retire Habit?",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: slate900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Stop '${habit['title']}' from today onwards. Your past logs and streaks will remain safe in your history.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: slate600,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Stacked Buttons for a more modern mobile feel
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        // Using your stopHabitFromToday method
                        await _controller.stopHabitFromToday(habit['id'], _selectedDate); 
                        _refreshData();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${habit['title']} has been retired"),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: slate900,
                            ),
                          );
                        }
                      },
                      child: Text(
                        "STOP FROM TODAY",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        "KEEP TRACKING",
                        style: GoogleFonts.poppins(
                          color: slate400,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- BUILD METHODS ---
   @override
Widget build(BuildContext context) {
  final DateTime now = DateTime.now();
  final String currentTimeframe = _getCurrentTimeframe();

  DateTime selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  DateTime todayDateOnly = DateTime(now.year, now.month, now.day);

  bool isToday = selectedDateOnly.isAtSameMomentAs(todayDateOnly);
  bool isPastDay = selectedDateOnly.isBefore(todayDateOnly);

  final List<Map<String, dynamic>> filteredHabits = _allHabits.where((h) {
    if (_selectedTimeFilter == "All") return true;
    return (h['timeOfDay']?.toString().toLowerCase() == _selectedTimeFilter.toLowerCase());
  }).toList();

  filteredHabits.sort((a, b) {
    int getPriority(String? time) {
      switch (time?.toString().toLowerCase()) {
        case 'morning': return 1;
        case 'afternoon': return 2;
        case 'evening': return 3;
        case 'anytime': return 4;
        default: return 5;
      }
    }
    return getPriority(a['timeOfDay']).compareTo(getPriority(b['timeOfDay']));
  });

  final uncompletedHabits = filteredHabits.where((h) {
    if (h['isCompleted'] == true) return false;
    if (!isToday) return true;
    String habitTime = h['timeOfDay']?.toString() ?? "Morning";
    if (currentTimeframe == "Afternoon" && habitTime == "Morning") return false;
    if (currentTimeframe == "Evening" && (habitTime == "Morning" || habitTime == "Afternoon")) return false;
    if (currentTimeframe == "Night") return false;
    return true;
  }).toList();

  final nextTask = uncompletedHabits.isNotEmpty ? uncompletedHabits.first : null;
  final habitsInList = isToday
      ? filteredHabits.where((h) => h['id'] != nextTask?['id']).toList()
      : filteredHabits;

  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    child: Scaffold(
      backgroundColor: bgLight,
      extendBody: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isToday)
              SizedBox(
                height: 40,
                child: FloatingActionButton.extended(
                  heroTag: "backToToday",
                  onPressed: () {
                    final DateTime today = DateTime.now();
                    
                    // Update state immediately to highlight the "Today" card in the carousel
                    setState(() {
                      _selectedDate = today;
                    });
                    
                    final DateTime start = DateTime(_installationDate.year, _installationDate.month, _installationDate.day);
                    final int daysToToday = today.difference(start).inDays;
                    
                    // Scroll calculation: (Card Width 72 + Margin 12) = 84.0
                    final double targetOffset = daysToToday * 84.0;

                    if (_dateScrollController.hasClients) {
                      _dateScrollController.animateTo(
                        targetOffset,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutQuart,
                      );
                    }
                    
                    // Refresh data to show today's specific habits
                    _refreshData();
                  },
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: slate100)
                  ),
                  icon: Icon(Icons.today_rounded, color: primaryGreen, size: 16),
                  label: Text("TODAY", 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: slate900, fontSize: 10)),
                ),
              ),
            
            if (!isPastDay) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FloatingActionButton.extended(
                  heroTag: "newHabit",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateHabitScreen()),
                    );
                    if (result == true) _refreshData();
                  },
                  backgroundColor: deepEmerald,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: Text("NEW", 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return; 
          setState(() { _navIndex = index; });
        },
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.05), shape: BoxShape.circle),
            ),
          ),
          SafeArea(
            bottom: false,
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 20),
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildDateCarousel(),
                            const SizedBox(height: 16),
                            _buildTimeFilters(),
                            const SizedBox(height: 24),
                            
                            if (isToday) ...[
                              if (filteredHabits.isEmpty)
                                _buildEmptyState()
                              else if (uncompletedHabits.isEmpty && _selectedTimeFilter == "All")
                                _buildAllDoneCard()
                              else if (nextTask != null)
                                _buildPriorityCard(nextTask),
                            ],
                            
                            const SizedBox(height: 32),
                            _buildSectionLabel(isToday
                                ? (uncompletedHabits.isEmpty ? "DAILY LOGS" : "UP NEXT")
                                : DateFormat('EEEE, MMM d').format(_selectedDate).toUpperCase()),
                            
                            const SizedBox(height: 16),
                            if (habitsInList.isNotEmpty)
                              ...habitsInList.map((h) => _buildHabitTile(h))
                            else if (!isToday)
                              _buildEmptyState(),
                              
                            const SizedBox(height: 140), 
                          ]),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryGreen.withOpacity(0.2), width: 2),
            image: const DecorationImage(
              image: NetworkImage("https://ui-avatars.com/api/?name=Marl+Laurence&background=10B981&color=fff"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Good Morning,", style: GoogleFonts.poppins(fontSize: 14, color: slate400)),
              Text(_displayName ?? 'Marl',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: slate900)),
            ],
          ),
        ),
        _buildProgressRing(),
      ],
    );
  }

  Widget _buildProgressRing() {
    double progress = _controller.calculateProgress(_allHabits);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: primaryGreen.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
          ),
        ),
        Text("${(progress * 100).toInt()}%",
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen)),
      ],
    );
  }


 Widget _buildDateCarousel() {
  final DateTime today = DateTime.now();
  final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);

  return SizedBox(
    height: 100,
    child: ListView.builder(
      controller: _dateScrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 365,
      itemBuilder: (context, index) {
        DateTime date = DateTime(
          _installationDate.year, 
          _installationDate.month, 
          _installationDate.day
        ).add(Duration(days: index));
        
        bool isSelected = date.day == _selectedDate.day && 
                          date.month == _selectedDate.month && 
                          date.year == _selectedDate.year;
        
        bool isToday = date.day == todayDateOnly.day && 
                       date.month == todayDateOnly.month && 
                       date.year == todayDateOnly.year;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
            _refreshData();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 72, 
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? deepEmerald : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? deepEmerald : slate100, 
                width: 2
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: deepEmerald.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8)
                )
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10, 
                    fontWeight: FontWeight.w600, 
                    color: isSelected ? Colors.white70 : slate400,
                    letterSpacing: 0.5
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.w700, 
                    color: isSelected ? Colors.white : slate900
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isToday ? "TODAY" : DateFormat('EEE').format(date).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10, 
                    fontWeight: FontWeight.w800, 
                    color: isSelected ? Colors.white70 : (isToday ? primaryGreen : slate400)
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
  Widget _buildTimeFilters() {
    final filters = ["All", "Morning", "Afternoon", "Evening"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((label) {
          bool isSelected = _selectedTimeFilter == label;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedTimeFilter = label),
              selectedColor: deepEmerald,
              backgroundColor: slate100,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : slate400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityCard(Map<String, dynamic> habit) {
    // Check if finished using controller flags
    if (habit['isCompleted'] == true || habit['isMissed'] == true) {
      return _buildAllDoneCard();
    }

    final int currentStreak = habit['streak'] ?? 0;
    final String habitTime = habit['timeOfDay'] ?? "Morning";
    
    final IconData customIcon = habit['iconCode'] != null 
        ? IconData(habit['iconCode'], fontFamily: 'MaterialIcons') 
        : Icons.bolt;
    
    final Color customColor = habit['colorHex'] != null 
        ? Color(habit['colorHex']) 
        : deepEmerald;

    return GestureDetector(
      onTap: () => _showHabitActions(habit, customIcon, habitTime),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: customColor.withOpacity(0.1), 
              blurRadius: 25, 
              offset: const Offset(0, 20)
            )
          ],
          border: Border.all(color: slate100),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: customColor.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, color: customColor, size: 14),
                            const SizedBox(width: 4),
                            Text("$currentStreak DAY STREAK",
                                style: GoogleFonts.poppins(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w800, 
                                  color: customColor
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(habit['title'] ?? "No Title",
                          style: GoogleFonts.poppins(
                            fontSize: 24, 
                            fontWeight: FontWeight.w700, 
                            color: slate900
                          )),
                      Text(
                          "${habitTime.toUpperCase()} • ${habit['focusArea']?.toUpperCase() ?? 'GENERAL'}",
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600, 
                            color: slate400
                          )),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.more_horiz, color: slate400.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: customColor.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(24)
                      ),
                      child: Icon(customIcon, color: customColor, size: 36),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _controller.markHabitAsDone(habit['id'], currentStreak);
                _refreshData();
              },
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text("MARK AS DONE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: customColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildHabitTile(Map<String, dynamic> habit) {
    final bool isDone = habit['isCompleted'] == true;
    final bool isMissed = habit['isMissed'] == true; // Added from controller
    final String habitTime = habit['timeOfDay'] ?? "Morning";
    
    // Logic for icon and color remains yours
    final IconData customIcon = habit['iconCode'] != null ? IconData(habit['iconCode'], fontFamily: 'MaterialIcons') : Icons.psychology;
    final Color customColor = habit['colorHex'] != null ? Color(habit['colorHex']) : primaryGreen;

    return GestureDetector(
      onTap: () {
        if (!isDone && !isMissed) {
          _showHabitActions(habit, customIcon, habitTime);
        } else {
          String message = isDone ? "This habit is already completed." : "This habit was missed and cannot be modified.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: GoogleFonts.poppins(fontSize: 12)),
              backgroundColor: slate900,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Opacity(
        // Opacity now reacts to isMissed as well
        opacity: (isDone || isMissed) ? 0.4 : 1.0, 
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isMissed ? Colors.redAccent.withOpacity(0.2) : (isDone ? customColor.withOpacity(0.3) : slate100)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: isMissed ? Colors.redAccent.withOpacity(0.1) : customColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(isMissed ? Icons.timer_off_outlined : (isDone ? Icons.check_circle : customIcon),
                    color: isMissed ? Colors.redAccent : customColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit['title'],
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: slate900,
                            decoration: (isDone || isMissed) ? TextDecoration.lineThrough : null)),
                    Text(isMissed ? "MISSED ($habitTime)" : (isDone ? "COMPLETED" : "READY TO START"),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMissed ? Colors.redAccent : (isDone ? customColor : slate400))),
                  ],
                ),
              ),
              if (isDone) Icon(Icons.verified, color: customColor, size: 20),
              if (isMissed) const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
              if (!isDone && !isMissed) Icon(Icons.more_vert, color: slate400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: primaryGreen.withOpacity(0.1))),
      child: Column(children: [
        Icon(Icons.check_circle_outline_rounded, color: primaryGreen, size: 32),
        const SizedBox(height: 20),
        Text("All habits completed", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: slate900)),
        const SizedBox(height: 8),
        Text("Rest up for tomorrow's wins.", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: slate400)),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) => Text(label,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: slate400, letterSpacing: 1.5));

  Widget _buildEmptyState() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text("No habits for this selection.", style: GoogleFonts.poppins(color: slate400))));
}