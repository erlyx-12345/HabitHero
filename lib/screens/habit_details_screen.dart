import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit_model.dart';
import '../controllers/createhabit_controller.dart';
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
  
  late IconData _selectedIcon;
  late Color _selectedColor;
  String _selectedTime = "Anytime";
  bool _remindersEnabled = false;
  DateTime? _endDate;

  final List<Color> _palette = [
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFF0F172A), // Slate
  ];

  bool get isEditMode => widget.existingHabit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final habit = widget.existingHabit!;
      _selectedIcon = IconData(habit['iconCode'], fontFamily: 'MaterialIcons');
      _selectedColor = Color(habit['colorHex']);
      _selectedTime = habit['timeOfDay'] ?? "Anytime";
      _remindersEnabled = habit['reminder'] == 1;
      if (habit['endDate'] != null) {
        _endDate = DateTime.parse(habit['endDate']);
      }
    } else {
      _selectedIcon = widget.template.icon;
      _selectedColor = const Color(0xFF10B981);
      _selectedTime = widget.template.timeOfDay;
    }
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
            _buildSettingsToggle("Daily Reminder", _remindersEnabled, (v) => setState(() => _remindersEnabled = v)),
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
                Text(
                  widget.template.title, 
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))
                ),
                const SizedBox(height: 2),
                Text(
                  "${widget.focusArea.toUpperCase()} • TARGET", 
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700, letterSpacing: 0.5)
                ),
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _selectedColor == color ? const Color(0xFF0F172A) : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
        ),
      )).toList(),
    );
  }

  Widget _buildTimeOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ["Anytime", "Morning", "Afternoon", "Evening"].map((time) {
        bool isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _selectedColor : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time, 
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : const Color(0xFF475569), 
                fontSize: 13, 
                fontWeight: FontWeight.w600
              )
            ),
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
        Transform.scale(
          scale: 0.8,
          child: Switch.adaptive(value: value, activeColor: _selectedColor, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildEndDateTile() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context, 
          initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)), 
          firstDate: DateTime.now(), 
          lastDate: DateTime(2100)
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
              Text(
                _endDate == null ? "Continuous habit" : "Ends on ${DateFormat('MMM dd, yyyy').format(_endDate!)}", 
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))
              ),
            ],
          ),
          Icon(Icons.calendar_today_outlined, size: 18, color: _selectedColor),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () async {
        if (isEditMode) {
          await _controller.updateHabit(
            id: widget.existingHabit!['id'],
            title: widget.template.title,
            focusArea: widget.focusArea,
            timeOfDay: _selectedTime,
            iconCode: _selectedIcon.codePoint,
            colorHex: _selectedColor.value,
            reminder: _remindersEnabled ? 1 : 0,
            endDate: _endDate?.toIso8601String(),
          );
        } else {
          await _controller.addCustomizedHabit(
            title: widget.template.title,
            focusArea: widget.focusArea,
            timeOfDay: _selectedTime,
            iconCode: _selectedIcon.codePoint,
            colorHex: _selectedColor.value,
            reminder: _remindersEnabled ? 1 : 0,
            endDate: _endDate?.toIso8601String(),
          );

          // Show late-creation feedback
          final hour = DateTime.now().hour;
          bool willStartTomorrow = (_selectedTime == "Morning" && hour >= 12) ||
                                   (_selectedTime == "Afternoon" && hour >= 17) ||
                                   (_selectedTime == "Evening" && hour >= 22);

          if (mounted && willStartTomorrow) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Habit starts tomorrow because today's $_selectedTime is over."),
                backgroundColor: _selectedColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
  );
}