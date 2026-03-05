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

  final Color primaryGreen = const Color(0xFF10B981);
  final Color deepEmerald = const Color(0xFF064E3B);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color bgLight = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _focusAreasFuture = _controller.fetchFocusAreas();
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
          icon: Icon(Icons.arrow_back_ios_new, color: slate900, size: 20),
          onPressed: () {
            if (_selectedArea != null) {
              setState(() => _selectedArea = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _selectedArea == null ? "SELECT FOCUS" : _selectedArea!.name.toUpperCase(),
          style: GoogleFonts.poppins(
            color: slate900,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedArea == null
            ? _buildFocusGridWithFuture()
            : _buildHabitList(),
      ),
    );
  }

  Widget _buildFocusGridWithFuture() {
    return FutureBuilder<List<FocusArea>>(
      key: const ValueKey('grid_view'),
      future: _focusAreasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryGreen));
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading categories"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No categories found"));
        }

        final areas = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: areas.length,
          itemBuilder: (context, index) {
            final area = areas[index];
            return InkWell(
              onTap: () => setState(() => _selectedArea = area),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: slate900.withOpacity(0.05)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(area.icon, color: primaryGreen, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(area.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: slate900, fontSize: 15)),
                    Text("${area.habits.length} Options", style: GoogleFonts.poppins(fontSize: 11, color: slate400)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHabitList() {
    return ListView.builder(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: _selectedArea!.habits.length,
      itemBuilder: (context, index) {
        final habit = _selectedArea!.habits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              // NAVIGATION ONLY: This is where we go to customization
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HabitDetailsScreen(
                    template: habit,
                    focusArea: _selectedArea!.name,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: slate900.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(16)),
                    child: Icon(habit.icon, color: deepEmerald, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: slate900, fontSize: 15)),
                        Text("${habit.duration} • ${habit.timeOfDay}", style: GoogleFonts.poppins(fontSize: 11, color: slate400, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  // Chevron indicates "click to go to next screen"
                  Icon(Icons.chevron_right, color: slate400, size: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}