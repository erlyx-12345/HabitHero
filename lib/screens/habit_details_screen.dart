import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit_model.dart';
import '../controllers/createhabit_controller.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class HabitDetailsScreen extends StatefulWidget {
  final HabitTemplate template;
  final String focusArea;
  final Map<String, dynamic>? existingHabit;
  final DateTime? initialStartDate;

  const HabitDetailsScreen({
    super.key,
    required this.template,
    required this.focusArea,
    this.existingHabit,
    this.initialStartDate,
  });

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  final CreateHabitController _controller = CreateHabitController();
  final NotificationService _notificationService = NotificationService();

  late TextEditingController _titleController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  bool _remindersEnabled = false;
  DateTime? _endDate;
  TimeOfDay? _pickedReminderTime; 
  dynamic _selectedTimePeriod;
  bool _isIconPickerExpanded = false;

  final List<Color> _palette = [
    const Color(0xFF10B981),
    const Color(0xFF064E3B),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFF43F5E),
    const Color(0xFFF59E0B),
    const Color(0xFF0F172A),
    const Color(0xFF14B8A6),
  ];

  final List<IconData> _iconLibrary = [
    Icons.star_rounded, Icons.favorite_rounded, Icons.fitness_center_rounded, 
    Icons.book_rounded, Icons.water_drop_rounded, Icons.self_improvement_rounded, 
    Icons.directions_run_rounded, Icons.bedtime_rounded, Icons.lightbulb_rounded, 
    Icons.restaurant_rounded, Icons.code_rounded, Icons.payments_rounded, 
    Icons.psychology_rounded, Icons.pets_rounded, Icons.wb_sunny_rounded,
    Icons.brush_rounded, Icons.medication_rounded, Icons.timer_rounded,
    Icons.church_rounded, Icons.hiking_rounded, Icons.laptop_mac_rounded,
    Icons.spa_rounded, Icons.coffee_rounded, Icons.shutter_speed_rounded,
  ];

  bool get isEditMode => widget.existingHabit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.template.title);
    
    if (isEditMode) {
      final habit = widget.existingHabit!;
      _selectedIcon = IconData(habit['iconCode'], fontFamily: 'MaterialIcons');
      _selectedColor = Color(habit['colorHex']);
      _selectedTimePeriod = habit['timeOfDay'] ?? "Anytime";
      _remindersEnabled = habit['reminder'] == 1;
      
      String? rawTime = habit['reminderTime'];
      if (rawTime != null && rawTime.contains(':')) {
        final parts = rawTime.split(':');
        _pickedReminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (habit['endDate'] != null) {
        _endDate = DateTime.parse(habit['endDate']);
      }
    } else {
      _selectedIcon = widget.template.icon;
      _selectedColor = const Color(0xFF10B981);
      _selectedTimePeriod = widget.template.timeOfDay;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool _isValidTimeSelection(TimeOfDay picked) {
    int hour = picked.hour;
    if (_selectedTimePeriod == "Morning") return (hour >= 4 && hour < 12);
    if (_selectedTimePeriod == "Afternoon") return (hour >= 12 && hour < 17);
    if (_selectedTimePeriod == "Evening") return (hour >= 17 && hour <= 23);
    return true;
  }

  TimeOfDay _getDefaultStartTime() {
    if (_selectedTimePeriod == "Morning") return const TimeOfDay(hour: 8, minute: 0);
    if (_selectedTimePeriod == "Afternoon") return const TimeOfDay(hour: 14, minute: 0);
    if (_selectedTimePeriod == "Evening") return const TimeOfDay(hour: 19, minute: 0);
    return TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    final String timeLabel = _pickedReminderTime?.format(context) ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEditMode ? "EDIT HABIT" : "CUSTOMIZE",
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.5)
        ),
        leading: const BackButton(color: Color(0xFF0F172A))
      ),
      extendBody: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomNameInput(),
                  const SizedBox(height: 32),
                  _buildSectionLabel("VISUAL STYLE"),
                  _buildExpandableIconPicker(),
                  const SizedBox(height: 16),
                  _buildColorPicker(),
                  const SizedBox(height: 32),
                  _buildSectionLabel("SCHEDULE"),
                  _buildTimeOptions(),
                  const SizedBox(height: 32),
                  _buildSectionLabel("ADVANCED SETTINGS"),
                  _buildSettingsToggle(
                    _remindersEnabled ? "Reminder set for $timeLabel" : "Set a Reminder", 
                    _remindersEnabled, 
                    (v) async {
                      if (v) {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _pickedReminderTime ?? _getDefaultStartTime(),
                          helpText: "SELECT ${_selectedTimePeriod.toString().toUpperCase()} REMINDER",
                        );

                        if (picked != null) {
                          if (_isValidTimeSelection(picked)) {
                            setState(() {
                              _remindersEnabled = true;
                              _pickedReminderTime = picked;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Please pick a time within the '$_selectedTimePeriod' range."),
                              backgroundColor: Colors.redAccent,
                            ));
                          }
                        }
                      } else {
                        setState(() {
                          _remindersEnabled = false;
                          _pickedReminderTime = null;
                        });
                      }
                    }
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 32),
                  _buildEndDateTile(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildSaveButtonAction(),
        ],
      ),
    );
  }

  Widget _buildSaveButtonAction() {
    return Container(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: ElevatedButton(
            onPressed: _handleSaveProcess,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: Text(
              isEditMode ? "UPDATE HABIT" : "CREATE HABIT",
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("HABIT NAME"),
        TextField(
          controller: _titleController,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: "E.g. Morning Yoga",
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            prefixIcon: Icon(_selectedIcon, color: _selectedColor),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableIconPicker() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: ExpansionTile(
          onExpansionChanged: (val) => setState(() => _isIconPickerExpanded = val),
          leading: Icon(Icons.palette_outlined, color: _selectedColor),
          title: Text("Select Habit Icon", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          trailing: Icon(_isIconPickerExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10,
                ),
                itemCount: _iconLibrary.length,
                itemBuilder: (context, index) {
                  final icon = _iconLibrary[index];
                  bool isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? _selectedColor : const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 20),
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

  Widget _buildColorPicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _palette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final color = _palette[index];
          bool isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF0F172A) : Colors.transparent, width: 3),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeOptions() {
    return Row(
      children: ["Anytime", "Morning", "Afternoon", "Evening"].map((time) {
        bool isSelected = _selectedTimePeriod == time;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedTimePeriod = time;
              _remindersEnabled = false;
              _pickedReminderTime = null;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _selectedColor : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(time, style: GoogleFonts.poppins(color: isSelected ? Colors.white : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

 Future<void> _handleSaveProcess() async {
    final String finalTitle = _titleController.text.trim();
    if (finalTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Habit name cannot be empty")),
      );
      return;
    }

    if (!isEditMode) {
      bool exists = await _controller.doesHabitExist(finalTitle, _selectedTimePeriod);
      if (exists) {
        _showExistDialog();
        return;
      }
    }

    // Format the reminder time for database storage (HH:mm)
    String? dbTime = _pickedReminderTime != null 
      ? "${_pickedReminderTime!.hour.toString().padLeft(2, '0')}:${_pickedReminderTime!.minute.toString().padLeft(2, '0')}" 
      : null;

    // Format the end date for database storage (yyyy-MM-dd)
    final String? formattedEndDate = _endDate != null 
        ? DateFormat('yyyy-MM-dd').format(_endDate!) 
        : null;

    // Determine the corrected Start Date
    DateTime? finalStartDate = widget.initialStartDate;

    if (!isEditMode) {
      final now = DateTime.now();
      bool timePassed = false;
      
      // Check if the current hour has passed the threshold for the selected slot
      int hour = now.hour;
      switch (_selectedTimePeriod.toString().toLowerCase()) {
        case 'morning': 
          if (hour >= 12) timePassed = true; 
          break;
        case 'afternoon': 
          if (hour >= 18) timePassed = true; 
          break;
        case 'evening': 
          if (hour >= 23) timePassed = true; 
          break;
      }

      // If the slot is done for today, shift start date to tomorrow and notify user
      if (timePassed) {
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final requestedStartStr = finalStartDate != null 
            ? DateFormat('yyyy-MM-dd').format(finalStartDate) 
            : todayStr;

        // Only shift if the requested start was actually for today
        if (requestedStartStr == todayStr) {
          finalStartDate = now.add(const Duration(days: 1));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "$_selectedTimePeriod is already done for today. Habit set for tomorrow.",
                style: GoogleFonts.poppins(
                  fontSize: 13, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.white
                ),
              ),
              backgroundColor: _selectedColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    int? habitId; 
    try {
      if (isEditMode) {
        habitId = widget.existingHabit!['id'];
        await _controller.updateHabit(
          id: habitId!,
          title: finalTitle,
          focusArea: widget.focusArea,
          timeOfDay: _selectedTimePeriod,
          iconCode: _selectedIcon.codePoint,
          colorHex: _selectedColor.value,
          reminder: _remindersEnabled ? 1 : 0,
          reminderTime: dbTime,
          endDate: formattedEndDate,
        );
      } else {
        habitId = await _controller.addCustomizedHabit(
          title: finalTitle,
          focusArea: widget.focusArea,
          timeOfDay: _selectedTimePeriod,
          iconCode: _selectedIcon.codePoint,
          colorHex: _selectedColor.value,
          reminder: _remindersEnabled ? 1 : 0,
          reminderTime: dbTime,
          endDate: formattedEndDate,
          customStartDate: finalStartDate, // Pass the corrected date
        );
      }

      // Handle individual Notification scheduling
      if (habitId != null && habitId != 0) {
        if (_remindersEnabled && _pickedReminderTime != null) {
          await _notificationService.scheduleHabitReminder(
            habitId, 
            finalTitle, 
            _pickedReminderTime!.hour, 
            _pickedReminderTime!.minute
          );
        } else {
          await _notificationService.cancelReminder(habitId);
        }
      }

      if (mounted) {
        // Return true to trigger a refresh on the dashboard
        Navigator.pop(context, true); 
        if (!isEditMode) Navigator.pop(context, true); 
      }
    } catch (e) {
      debugPrint("Save Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save habit. Please try again.")),
        );
      }
    }
  }
  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
  );

  Widget _buildSettingsToggle(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        Transform.scale(scale: 0.8, child: Switch.adaptive(value: value, activeColor: _selectedColor, onChanged: onChanged)),
      ],
    );
  }

  Widget _buildEndDateTile() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(), lastDate: DateTime(2100)
        );
        if (date != null) setState(() => _endDate = date);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("End Date", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
              Text(_endDate == null ? "Continuous habit" : "Ends on ${DateFormat('MMM dd, yyyy').format(_endDate!)}", style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
            ],
          ),
          Icon(Icons.calendar_today_outlined, size: 18, color: _selectedColor),
        ],
      ),
    );
  }

  void _showExistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Already Exist", style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        content: Text("You currently have this habit for the ${_selectedTimePeriod.toString().toLowerCase()}."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: GoogleFonts.poppins(color: _selectedColor, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}