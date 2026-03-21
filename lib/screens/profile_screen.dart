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
  int _maxUnlockedLevel = 1;
  int _selectedLevel = 1;

  final ProfileController _controller = ProfileController();

  final Color primaryGreen = const Color(0xFF10B981);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color softRed = const Color(0xFFEF4444);

  final List<Map<String, dynamic>> _borderLibrary = [
    {'name': 'DEFAULT', 'level': 1, 'colors': [Colors.brown, Colors.blueGrey]},
    {'name': '20% • 3D', 'level': 2, 'colors': [const Color(0xFF3B82F6), const Color(0xFF2DD4BF)]},
    {'name': '30% • 5D', 'level': 3, 'colors': [const Color(0xFFF59E0B), const Color(0xFFFCD34D)]},
    {'name': '50% • 1W', 'level': 4, 'colors': [const Color(0xFF10B981), const Color(0xFFD1FAE5)]},
    {'name': '70% • 1.5W', 'level': 5, 'colors': [const Color(0xFF8B5CF6), const Color(0xFFD8B4FE)]},
    {'name': '85% • 2W', 'level': 6, 'colors': [const Color(0xFFEF4444), const Color(0xFFFCA5A5)]},
    {'name': '98% • 2W', 'level': 7, 'colors': [const Color(0xFFFFD700), const Color(0xFF8B5CF6), const Color(0xFF0F172A)]},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final data = await ProfileController.fetchUserData();
    double rating = await DatabaseHelper.instance.getCompletionRate(days: 7);
    int calculatedLevel = 1;

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
      int savedMaxLevel = data['maxLevel'] ?? 1;
      if (calculatedLevel > savedMaxLevel) {
        await ProfileController.updateMaxLevel(calculatedLevel);
        savedMaxLevel = calculatedLevel;
      }

      setState(() {
        _userName = data['name'];
        _maxUnlockedLevel = savedMaxLevel;
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
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Update Name", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: slate900)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameEditController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: bgLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: slate900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        bool success = await _controller.updateUserName(nameEditController.text);
                        if (success && mounted) {
                          setState(() => _userName = nameEditController.text);
                          Navigator.pop(context);
                        }
                      },
                      child: Text("CONFIRM", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// --- UPDATED DELETE LOGIC ---
  void _showDeleteConfirmation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              "DELETE ACCOUNT?",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: slate900, letterSpacing: 1.1),
            ),
            content: Text(
              "This action is permanent. All your habits, logs, and progress will be deleted, and the app will close.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: slate500),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: softRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        // 1. Wipe the physical database file
                        await DatabaseHelper.instance.deleteFullDatabase();

                        if (context.mounted) {
                          // 2. Exit the application completely
                          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                        }
                      },
                      child: Text("YES, DELETE ALL", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CANCEL", style: GoogleFonts.poppins(color: slate400, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
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
        title: Text("MY PROFILE", style: GoogleFonts.poppins(fontSize: 13, color: slate900, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: slate900, size: 16), onPressed: () => Navigator.pop(context)),
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
                  Text(_userName.toUpperCase(), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: slate900)),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_note_rounded, color: primaryGreen, size: 20),
                ],
              ),
            ),
            Text("Keep up the great work!", style: GoogleFonts.poppins(fontSize: 11, color: slate400)),
            const SizedBox(height: 24),
            _buildBorderGallery(),
            const SizedBox(height: 24),
            _buildActionCard(
                icon: Icons.delete_outline_rounded,
                label: "Delete my account",
                subLabel: "Permanently remove your info",
                isDestructive: true,
                onTap: () => _showDeleteConfirmation(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    var currentBorder = _borderLibrary.firstWhere((b) => b['level'] == _selectedLevel, orElse: () => _borderLibrary[0]);
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 135,
            height: 135,
            child: CustomPaint(painter: MLBBBorderPainter(colors: List<Color>.from(currentBorder['colors']), level: _selectedLevel)),
          ),
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 41,
              backgroundColor: bgLight,
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null ? Icon(Icons.person_rounded, size: 40, color: slate400) : null,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _uploadImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: slate900, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
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
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
            const SizedBox(width: 6),
            Text("EQUIP ACHIEVEMENT BORDER", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: slate900)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _borderLibrary.length,
            itemBuilder: (context, index) {
              final border = _borderLibrary[index];
              bool isLocked = _maxUnlockedLevel < border['level'];
              bool isSelected = _selectedLevel == border['level'];

              return GestureDetector(
                onTap: isLocked
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedLevel = border['level']);
                        await ProfileController.updateSelectedBorder(border['level']);
                      },
                child: Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? primaryGreen : Colors.transparent, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: isLocked ? 0.3 : 1.0,
                        child: CustomPaint(painter: MLBBBorderPainter(colors: border['colors'], level: border['level']), size: const Size(40, 40)),
                      ),
                      const SizedBox(height: 8),
                      Text(border['name'],
                          style: GoogleFonts.poppins(fontSize: 7, color: isLocked ? slate400 : slate900, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      if (isLocked)
                        Icon(Icons.lock_outline, size: 10, color: slate400)
                      else
                        Text(isSelected ? "EQUIPPED" : "SELECT",
                            style: GoogleFonts.poppins(
                                fontSize: 7, color: isSelected ? primaryGreen : slate400, fontWeight: FontWeight.w900)),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: itemColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: slate900)),
                  Text(subLabel, style: GoogleFonts.poppins(fontSize: 11, color: slate400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: slate400, size: 18),
          ],
        ),
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
      double variation = math.cos(angle * points).abs() * (level * 1.1);
      double r = radius - 5 + variation;
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (level >= 5) {
      final gemPaint = Paint()..color = Colors.white.withOpacity(0.8);
      canvas.drawCircle(Offset(center.dx, center.dy - radius + 3), 2, gemPaint);
      canvas.drawCircle(Offset(center.dx, center.dy + radius - 3), 2, gemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}