import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import '../controllers/user_controller.dart';

class HeroNameScreen extends StatefulWidget {
  const HeroNameScreen({super.key});

  @override
  State<HeroNameScreen> createState() => _HeroNameScreenState();
}

class _HeroNameScreenState extends State<HeroNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final UserController _userController = UserController();
  bool _isLoading = false;

  // Simple Light Mode Palette
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textSub = Color(0xFF64748B);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color inputGrey = Color(0xFFF1F5F9);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleStartJourney() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar("Please enter a name first.");
      return;
    }

    setState(() => _isLoading = true);
    bool success = await _userController.saveHeroName(name);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(userName: name)),
      );
    } else {
      _showSnackBar("Something went wrong. Try again.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: textMain,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgWhite,
      // White status bar icons for light mode
      appBar: AppBar(
        backgroundColor: bgWhite,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Smaller, cleaner header
              Text(
                "What's your name?",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This is how you will appear in the app.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSub,
                ),
              ),
              
              const SizedBox(height: 32),

              // Simple Input Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: inputGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: GoogleFonts.inter(
                    color: textMain,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Enter your name...",
                    hintStyle: TextStyle(color: Colors.black26),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const Spacer(),

              // Simple, solid button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleStartJourney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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