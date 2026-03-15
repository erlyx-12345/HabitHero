import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/createhabit_controller.dart';
import '../models/habit_model.dart';
import 'habit_details_screen.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final CreateHabitController _controller = CreateHabitController();
  FocusArea? _selectedArea;
  late Future<List<FocusArea>> _focusAreasFuture;

  final Color accentGreen = const Color(0xFF10B981);
  final Color deepNavy = const Color(0xFF0F172A);
  final Color softText = const Color(0xFF64748B);
  final Color bgSurface = const Color(0xFFF8FAFC);
  final Color cardWhite = Colors.white;
  final Color borderStroke = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _refreshFocusAreas();
  }

  void _refreshFocusAreas() {
    setState(() {
      _focusAreasFuture = _controller.fetchFocusAreas();
    });
  }

  void _showModernSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFEF4444) : deepNavy,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isError ? const Color(0xFFEF4444) : deepNavy).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOutCubic,
                child: _selectedArea == null
                    ? _buildFocusGridWithFuture()
                    : _buildHabitList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (_selectedArea != null) {
                setState(() => _selectedArea = null);
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: deepNavy, size: 20),
          ),
          Text(
            _selectedArea == null ? "SELECT FOCUS" : _selectedArea!.name.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: deepNavy,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFocusGridWithFuture() {
    return FutureBuilder<List<FocusArea>>(
      key: const ValueKey('grid_view'),
      future: _focusAreasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: accentGreen));
        }
        final areas = snapshot.data ?? [];
        return GridView.builder(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.88,
          ),
          itemCount: areas.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildAddCategoryCard();
            return _buildCategoryCard(areas[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(FocusArea area) {
  // Logic to identify built-in vs custom focus areas
  final List<String> builtInNames = ["Fitness", "Productivity", "Mindfulness"];
  final bool isBuiltIn = builtInNames.contains(area.name);

  return Container(
    decoration: BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderStroke, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: deepNavy.withOpacity(0.02),
          blurRadius: 15,
          offset: const Offset(0, 8),
        )
      ],
    ),
    child: InkWell(
      onTap: () => setState(() => _selectedArea = area),
      // Long press and deletion are disabled for built-in categories
      onLongPress: isBuiltIn ? null : () => _showDeleteConfirmation(area),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(area.icon, color: accentGreen, size: 22),
                ),
                // Only show the menu icon if the category can be deleted
                if (!isBuiltIn)
                  Icon(Icons.more_vert_rounded, color: softText.withOpacity(0.5), size: 18),
              ],
            ),
            const Spacer(),
            Text(
              area.name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: deepNavy,
                fontSize: 15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${area.habits.length} options",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: softText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildAddCategoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderStroke, width: 1.2),
      ),
      child: InkWell(
        onTap: _showNewCategoryDialog,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: accentGreen, size: 28),
            const SizedBox(height: 8),
            Text(
              "NEW FOCUS",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: accentGreen,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitList() {
    final List<HabitTemplate> displayList = [
      HabitTemplate(
        title: "Create Custom Habit",
        duration: "Flexible daily parameters",
        icon: Icons.auto_awesome_rounded,
        timeOfDay: "Anytime",
      ),
      ..._selectedArea!.habits,
    ];

    return ListView.builder(
      key: const ValueKey('list_view'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final habit = displayList[index];
        final bool isCustom = index == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isCustom ? deepNavy : cardWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCustom ? Colors.transparent : borderStroke,
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HabitDetailsScreen(
                      template: isCustom
                          ? HabitTemplate(
                              title: "",
                              duration: "",
                              icon: Icons.star_rounded,
                              timeOfDay: "Anytime")
                          : habit,
                      focusArea: _selectedArea!.name,
                    ),
                  ),
                );

                if (result == true) {
                  final updatedAreas = await _controller.fetchFocusAreas();
                  setState(() {
                    _focusAreasFuture = Future.value(updatedAreas);
                    _selectedArea = updatedAreas.firstWhere(
                      (area) => area.name == _selectedArea!.name,
                      orElse: () => _selectedArea!,
                    );
                  });
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isCustom ? Colors.white.withOpacity(0.1) : bgSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        habit.icon,
                        color: isCustom ? Colors.white : accentGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: isCustom ? Colors.white : deepNavy,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCustom ? "Build a unique routine" : habit.duration,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isCustom ? Colors.white60 : softText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isCustom ? Colors.white30 : softText.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(FocusArea area) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 12,
          left: 24,
          right: 24,
          // Fixed bottom padding to lift it above the navigation bar
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: borderStroke, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(
              "Delete Focus Area?",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: deepNavy),
            ),
            const SizedBox(height: 12),
            Text(
              "This will remove the '${area.name}' category. Habits already created with this focus won't be deleted.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: softText, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CANCEL", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: softText)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      await _controller.dbHelper.deleteCustomFocusArea(area.name);
                      if (mounted) {
                        Navigator.pop(context);
                        _refreshFocusAreas();
                        _showModernSnackBar("Focus area deleted");
                      }
                    },
                    child: Text("DELETE", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNewCategoryDialog() {
    final nameController = TextEditingController();
    int selectedIconCode = Icons.category_rounded.codePoint;

    final List<IconData> availableIcons = [
      Icons.category_rounded,
      Icons.fitness_center,
      Icons.code,
      Icons.book,
      Icons.brush,
      Icons.attach_money,
      Icons.favorite,
      Icons.self_improvement
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            top: 12,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderStroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Create Custom Focus",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: deepNavy,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: deepNavy,
                ),
                decoration: InputDecoration(
                  hintText: "Focus Name (e.g. Wellness)",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: softText,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: bgSurface,
                  contentPadding: const EdgeInsets.all(18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "SELECT ICON",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: softText,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableIcons.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setModalState(
                        () => selectedIconCode = availableIcons[i].codePoint),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      width: 56,
                      decoration: BoxDecoration(
                        color: selectedIconCode == availableIcons[i].codePoint
                            ? deepNavy
                            : bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderStroke),
                      ),
                      child: Icon(
                        availableIcons[i],
                        color: selectedIconCode == availableIcons[i].codePoint
                            ? Colors.white
                            : softText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      _showModernSnackBar("Please enter a focus name",
                          isError: true);
                      return;
                    }

                    try {
                      await _controller.createCustomCategory(
                        name,
                        selectedIconCode,
                        accentGreen.value,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        _refreshFocusAreas();
                        _showModernSnackBar("'$name' focus area created!");
                      }
                    } catch (e) {
                      if (e.toString().contains("UNIQUE constraint failed")) {
                        _showModernSnackBar("Focus '$name' already exists!",
                            isError: true);
                      } else {
                        _showModernSnackBar("Error saving focus area",
                            isError: true);
                      }
                    }
                  },
                  child: Text(
                    "SAVE FOCUS",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}