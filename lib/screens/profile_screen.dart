import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  File? _profileImage;
  
  // Track achievement vs visual selection
  int _maxUnlockedLevel = 1; 
  int _selectedLevel = 1; 

  final ProfileController _controller = ProfileController();
  
  final Color primaryGreen = const Color(0xFF10B981);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color softRed = const Color(0xFFEF4444);

  final List<Map<String, dynamic>> _borderLibrary = [
    {'name': 'DEFAULT', 'level': 1, 'colors': [Colors.brown, Colors.blueGrey]},
    {'name': '20% CONSISTENCY', 'level': 2, 'colors': [Color(0xFF3B82F6), Color(0xFF2DD4BF)]},
    {'name': '30% CONSISTENCY', 'level': 3, 'colors': [Color(0xFFF59E0B), Color(0xFFFCD34D)]},
    {'name': '50% CONSISTENCY', 'level': 4, 'colors': [Color(0xFF10B981), Color(0xFFD1FAE5)]},
    {'name': '70% CONSISTENCY', 'level': 5, 'colors': [Color(0xFF8B5CF6), Color(0xFFD8B4FE)]},
    {'name': '85% CONSISTENCY', 'level': 6, 'colors': [Color(0xFFEF4444), Color(0xFFFCA5A5)]},
    {'name': '95% CONSISTENCY', 'level': 7, 'colors': [Color(0xFFFFD700), Color(0xFF8B5CF6), Color(0xFF0F172A)]},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
  final data = await ProfileController.fetchUserData();
  
  // 1. Get the real-time completion rate from DatabaseHelper
  double rating = await DatabaseHelper.instance.getCompletionRate(days: 7);
  int calculatedLevel = 1;

  // 2. Map the rating to your levels
  if (rating >= 0.95) {
    calculatedLevel = 7;
  } else if (rating >= 0.85) {
    calculatedLevel = 6;
  } else if (rating >= 0.70) {
    calculatedLevel = 5;
  } else if (rating >= 0.50) {
    calculatedLevel = 4;
  } else if (rating >= 0.30) {
    calculatedLevel = 3;
  } else if (rating >= 0.20) {
    calculatedLevel = 2;
  } else {
    calculatedLevel = 1;
  }

  if (mounted && data != null) {
    // 3. Check if the calculated level is higher than what's saved
    int savedMaxLevel = data['maxLevel'] ?? 1;
    
    if (calculatedLevel > savedMaxLevel) {
      // Update the database so the unlock "sticks"
      await ProfileController.updateMaxLevel(calculatedLevel);
      savedMaxLevel = calculatedLevel;
    }

    setState(() {
      _userName = data['name'];
      _maxUnlockedLevel = savedMaxLevel; // Now it uses the logic
      _selectedLevel = data['selectedLevel'] ?? 1;
      if (data['profilePath'] != null && data['profilePath'].isNotEmpty) {
        _profileImage = File(data['profilePath']);
      }
    });
  }
}

  Future<void> _uploadImage() async {
    final pickedFile = await _controller.pickProfileImage(_userName);
    if (pickedFile != null && mounted) setState(() => _profileImage = pickedFile);
  }

  void _showEditNameDialog() {
    final TextEditingController nameEditController = TextEditingController(text: _userName);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center, 
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Update Name",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: slate900),
                  ),
                  const SizedBox(height: 8),
                  Text("Enter your new display name below",
                    style: GoogleFonts.poppins(fontSize: 12, color: slate400),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameEditController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: slate900),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: bgLight,
                      hintText: "Username",
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primaryGreen, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slate900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        bool success = await _controller.updateUserName(nameEditController.text);
                        if (success && mounted) {
                          setState(() => _userName = nameEditController.text);
                          Navigator.pop(context);
                        }
                      },
                      child: Text("CONFIRM", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: GoogleFonts.poppins(color: slate400, fontSize: 13)),
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 0.1), end: const Offset(0, 0)).animate(anim1),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("MY PROFILE", style: GoogleFonts.poppins(fontSize: 14, color: slate900, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: slate900, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildAvatarSection(),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showEditNameDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 24),
                  Text(_userName.toUpperCase(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: slate900)),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_note_rounded, color: primaryGreen, size: 22),
                ],
              ),
            ),
            Text("Keep up the great work!", style: GoogleFonts.poppins(fontSize: 13, color: slate400)),
            const SizedBox(height: 32),
            _buildBorderGallery(),
            const SizedBox(height: 32),
            _buildActionCard(icon: Icons.cloud_done_rounded, label: "Back up my data", subLabel: "Keep your habits safe", onTap: () {}),
            const SizedBox(height: 12),
            _buildActionCard(icon: Icons.delete_outline_rounded, label: "Delete my account", subLabel: "Permanently remove your info", isDestructive: true, onTap: () => _showDeleteConfirmation(context)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    // Get the currently selected border from your library
    var currentBorder = _borderLibrary.firstWhere(
      (b) => b['level'] == _selectedLevel, 
      orElse: () => _borderLibrary[0]
    );

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // THE FIX: Increased size to 160x160. 
          // High-level borders (70%+) have "spikes" that go outside 140px.
          SizedBox(
            width: 160, 
            height: 160,
            child: CustomPaint(
              painter: MLBBBorderPainter(
                colors: List<Color>.from(currentBorder['colors']), 
                level: _selectedLevel
              ),
            ),
          ),

          // The Profile Image Container
          CircleAvatar(
            radius: 52, // Outer white ring
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 48, // Inner image area
              backgroundColor: bgLight,
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null 
                  ? Icon(Icons.person_rounded, size: 45, color: slate400) 
                  : null,
            ),
          ),

          // The Camera Upload Button
          Positioned(
            bottom: 15,
            right: 15,
            child: GestureDetector(
              onTap: _uploadImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: slate900, 
                  shape: BoxShape.circle, 
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Text("EQUIP ACHIEVEMENT BORDER", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: slate900, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _borderLibrary.length,
            itemBuilder: (context, index) {
              final border = _borderLibrary[index];
              bool isLocked = _maxUnlockedLevel < border['level'];
              bool isSelected = _selectedLevel == border['level'];

              return GestureDetector(
                onTap: isLocked ? null : () async {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedLevel = border['level']);
                  await ProfileController.updateSelectedBorder(border['level']);
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? primaryGreen : Colors.transparent, width: 2),
                    boxShadow: [if(!isSelected) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: isLocked ? 0.2 : 1.0,
                        child: CustomPaint(
                          painter: MLBBBorderPainter(colors: border['colors'], level: border['level']),
                          size: const Size(55, 55), 
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(border['name'], 
                        style: GoogleFonts.poppins(fontSize: 8, color: isLocked ? slate400 : slate900, fontWeight: FontWeight.w800), 
                        textAlign: TextAlign.center
                      ),
                      const SizedBox(height: 4),
                      if (isSelected) 
                        Text("EQUIPPED", style: GoogleFonts.poppins(fontSize: 8, color: primaryGreen, fontWeight: FontWeight.w900))
                      else if (isLocked)
                        const Icon(Icons.lock_outline, size: 12, color: Colors.grey)
                      else
                        Text("SELECT", style: GoogleFonts.poppins(fontSize: 8, color: slate400, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String label, required String subLabel, required VoidCallback onTap, bool isDestructive = false}) {
    final Color itemColor = isDestructive ? softRed : primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: itemColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: slate900)),
                  Text(subLabel, style: GoogleFonts.poppins(fontSize: 12, color: slate400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: slate400, size: 22),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Delete Account?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
        content: Text("This will wipe all your habit progress forever.", style: GoogleFonts.poppins(fontSize: 14, color: slate400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Go Back", style: GoogleFonts.poppins(color: slate400, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('users'); await db.delete('habits'); await db.delete('daily_logs');
              if (context.mounted) { Navigator.pop(context); Navigator.pop(context); }
            },
            child: Text("Delete", style: GoogleFonts.poppins(color: softRed, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class MLBBBorderPainter extends CustomPainter {
  final List<Color> colors;
  final int level;
  MLBBBorderPainter({required this.colors, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = SweepGradient(colors: [...colors, colors.first]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final Path path = Path();
    int points = 4 + (level);
    for (int i = 0; i <= 360; i++) {
      double angle = i * math.pi / 180;
      double variation = math.cos(angle * points).abs() * (level * 1.5); 
      double r = radius - 8 + variation;
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawShadow(path, colors.first.withOpacity(0.3), 6.0, true);
    canvas.drawPath(path, paint);

    if (level >= 5) {
      final gemPaint = Paint()..color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(Offset(center.dx, center.dy - radius + 4), 3, gemPaint);
      canvas.drawCircle(Offset(center.dx, center.dy + radius - 4), 3, gemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}