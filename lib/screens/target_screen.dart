import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hero_name_screen.dart';
import '../controllers/target_controller.dart'; // Import Controller

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final Set<String> _selectedTargets = {};
  final TargetController _targetController = TargetController(); // MVC
  bool _isSaving = false;

  // Colors remain the same...
  final Color primaryGreen = const Color(0xFF10B981);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color bgLight = const Color(0xFFF8FAFC);

  final List<Map<String, dynamic>> _targets = [
    {'title': 'Vitality', 'icon': Icons.auto_awesome_rounded},
    {'title': 'Performance', 'icon': Icons.bolt_rounded},
    {'title': 'Creativity', 'icon': Icons.blur_on_rounded},
    {'title': 'Mindfulness', 'icon': Icons.bubble_chart_rounded},
    {'title': 'Knowledge', 'icon': Icons.auto_stories_rounded},
    {'title': 'Technical', 'icon': Icons.terminal_rounded},
  ];

  void _toggleSelection(String title) {
    setState(() {
      if (_selectedTargets.contains(title)) {
        _selectedTargets.remove(title);
      } else {
        _selectedTargets.add(title);
      }
    });
  }

  // UPDATED: Handle the database save and navigation
  Future<void> _handleContinue() async {
    setState(() => _isSaving = true);

    final targetList = _selectedTargets.toList();
    bool success = await _targetController.saveSelectedTargets(targetList);

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HeroNameScreen(
            selectedTargets: targetList,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save targets. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left_rounded, color: slate900, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: slate900.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                "Choose Focus",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w800, color: slate900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "What habits are we optimizing today?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: slate500, fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.2,
                  ),
                  itemCount: _targets.length,
                  itemBuilder: (context, index) {
                    final target = _targets[index];
                    final isSelected = _selectedTargets.contains(target['title']);
                    return GestureDetector(
                      onTap: () => _toggleSelection(target['title']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryGreen : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? primaryGreen.withOpacity(0.25) : Colors.black.withOpacity(0.03),
                              blurRadius: 15, offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                target['icon'],
                                size: 26,
                                color: isSelected ? Colors.white : primaryGreen,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                target['title'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : slate900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 180, height: 54,
                  child: ElevatedButton(
                    onPressed: (_selectedTargets.isEmpty || _isSaving) ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: slate900,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: slate900.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Continue", style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}