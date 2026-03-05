import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import '../controllers/user_controller.dart';

class HeroNameScreen extends StatefulWidget {
  final List<String> selectedTargets;
  const HeroNameScreen({super.key, required this.selectedTargets});

  @override
  State<HeroNameScreen> createState() => _HeroNameScreenState();
}

class _HeroNameScreenState extends State<HeroNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final UserController _userController = UserController(); // MVC Controller
  bool _isLoading = false;

  static const Color primaryGreen = Color(0xFF10B981);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate500 = Color(0xFF64748B);
  static const Color bgLight = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleStartJourney() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar("Every hero needs a name!", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    // Save via Controller
    bool success = await _userController.saveHeroName(name);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            userName: name,
            selectedTargets: widget.selectedTargets,
          ),
        ),
      );
    } else {
      _showSnackBar("Database error. Please try again.", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: slate900),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.face_retouching_natural_rounded,
                      size: 60, color: primaryGreen),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "The Hero's Name",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: slate900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Every legend starts with a name. \nWhat should we call you?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: slate500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: slate900.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: slate900,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Your name here...",
                    hintStyle: GoogleFonts.poppins(
                      color: slate500.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: primaryGreen, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleStartJourney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Start My Journey",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.rocket_launch_rounded),
                          ],
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