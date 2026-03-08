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

  const HabitDetailsScreen({
    super.key,
    required this.template,
    required this.focusArea,
    this.existingHabit,
  });

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  final CreateHabitController _controller = CreateHabitController();
  final NotificationService _notificationService = NotificationService();

  late IconData _selectedIcon;
  late Color _selectedColor;
  bool _remindersEnabled = false;
  String? _reminderTimeLabel;
  DateTime? _endDate;
  
  // LOGIC FIX: Store raw TimeOfDay to avoid String parsing errors
  TimeOfDay? _pickedReminderTime; 
  dynamic _selectedTimePeriod; // Stores "Morning", "Afternoon", etc.

  final List<Color> _palette = [
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFF0F172A),
  ];

  bool get isEditMode => widget.existingHabit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final habit = widget.existingHabit!;
      _selectedIcon = IconData(habit['iconCode'], fontFamily: 'MaterialIcons');
      _selectedColor = Color(habit['colorHex']);
      _selectedTimePeriod = habit['timeOfDay'] ?? "Anytime";
      _remindersEnabled = habit['reminder'] == 1;
      _reminderTimeLabel = habit['reminderTime'];
      
      // Try to reconstruct _pickedReminderTime if editing
      if (_reminderTimeLabel != null) {
        // Simple fallback: If it's a string from DB, we extract numbers if possible 
        // or just set to default to avoid crash.
        _pickedReminderTime = _getDefaultStartTime();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 32),
            _buildSectionLabel("VISUAL STYLE"),
            _buildColorPicker(),
            const SizedBox(height: 32),
            _buildSectionLabel("SCHEDULE"),
            _buildTimeOptions(),
            const SizedBox(height: 32),
            _buildSectionLabel("ADVANCED SETTINGS"),
            
            _buildSettingsToggle(
              _remindersEnabled ? "Reminder set for $_reminderTimeLabel" : "Set a Reminder", 
              _remindersEnabled, 
              (v) async {
                if (v) {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _getDefaultStartTime(),
                    helpText: "SELECT ${_selectedTimePeriod.toString().toUpperCase()} REMINDER",
                  );

                  if (picked != null) {
                    if (_isValidTimeSelection(picked)) {
                      setState(() {
                        _remindersEnabled = true;
                        _pickedReminderTime = picked;
                        _reminderTimeLabel = picked.format(context);
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
                    _reminderTimeLabel = null;
                    _pickedReminderTime = null;
                  });
                }
              }
            ),

            const Divider(color: Color(0xFFF1F5F9), height: 32),
            _buildEndDateTile(),
            const SizedBox(height: 48),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () async {
        if (!isEditMode) {
          bool alreadyExists = await _controller.doesHabitExist(widget.template.title, _selectedTimePeriod);
          if (alreadyExists) {
            _showExistDialog();
            return;
          }
        }

        int habitId;
        if (isEditMode) {
          habitId = widget.existingHabit!['id'];
          await _controller.updateHabit(
            id: habitId,
            title: widget.template.title,
            focusArea: widget.focusArea,
            timeOfDay: _selectedTimePeriod,
            iconCode: _selectedIcon.codePoint,
            colorHex: _selectedColor.value,
            reminder: _remindersEnabled ? 1 : 0,
            reminderTime: _reminderTimeLabel,
            endDate: _endDate?.toIso8601String(),
          );
        } else {
          habitId = await _controller.addCustomizedHabit(
            title: widget.template.title,
            focusArea: widget.focusArea,
            timeOfDay: _selectedTimePeriod,
            iconCode: _selectedIcon.codePoint,
            colorHex: _selectedColor.value,
            reminder: _remindersEnabled ? 1 : 0,
            reminderTime: _reminderTimeLabel,
            endDate: _endDate?.toIso8601String(),
          );
        }

        // --- NOTIFICATION FIX ---
        if (_remindersEnabled && _pickedReminderTime != null) {
          // Pass raw hour and minute integers directly to service
          await _notificationService.scheduleHabitReminder(
            habitId, 
            widget.template.title, 
            _pickedReminderTime!.hour,
            _pickedReminderTime!.minute
          );
        } else {
          await _notificationService.cancelReminder(habitId);
        }
        
        if (mounted) {
          Navigator.pop(context, true);
          if (!isEditMode) Navigator.pop(context, true);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(
        isEditMode ? "UPDATE HABIT" : "CREATE HABIT",
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(_selectedIcon, color: _selectedColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.template.title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text("${widget.focusArea.toUpperCase()} • TARGET", style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _palette.map((color) => GestureDetector(
        onTap: () => setState(() => _selectedColor = color),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            border: Border.all(color: _selectedColor == color ? const Color(0xFF0F172A) : Colors.transparent, width: 2.5),
          ),
          child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
        ),
      )).toList(),
    );
  }

  Widget _buildTimeOptions() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: ["Anytime", "Morning", "Afternoon", "Evening"].map((time) {
        bool isSelected = _selectedTimePeriod == time;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedTimePeriod = time;
            _remindersEnabled = false;
            _reminderTimeLabel = null;
            _pickedReminderTime = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _selectedColor : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(time, style: GoogleFonts.poppins(color: isSelected ? Colors.white : const Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Already Exist", style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        content: Text("You currently have this habit for the ${_selectedTimePeriod.toString().toLowerCase()}."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: GoogleFonts.poppins(color: _selectedColor, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
  );
}