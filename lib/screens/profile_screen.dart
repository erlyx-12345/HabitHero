import 'dart:io';
import 'package:flutter/material.dart';
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
  final ProfileController _controller = ProfileController();
  
  final Color primaryGreen = const Color(0xFF10B981);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color softRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> userMaps = await db.query('users', limit: 1);
    
    if (userMaps.isNotEmpty) {
      if (mounted) {
        setState(() {
          _userName = userMaps.first['name'];
          
          String? savedPath = userMaps.first['profilePath'];
          if (savedPath != null && savedPath.isNotEmpty) {
            _profileImage = File(savedPath);
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _userName = "New User";
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await _controller.pickProfileImage(_userName);
    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _profileImage = pickedFile;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(color: slate900, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: slate900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildAvatarSection(),
            const SizedBox(height: 12),
            Text(
              _userName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: slate900,
              ),
            ),
            Text(
              "Keep up the great work!",
              style: GoogleFonts.poppins(fontSize: 14, color: slate400),
            ),
            const SizedBox(height: 40),
            _buildActionCard(
              icon: Icons.cloud_done_rounded,
              label: "Back up my data",
              subLabel: "Keep your habits safe",
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.delete_outline_rounded,
              label: "Delete my account",
              subLabel: "Permanently remove your info",
              isDestructive: true,
              onTap: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen, width: 3),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: primaryGreen.withOpacity(0.1),
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null 
                  ? Icon(Icons.person_rounded, size: 60, color: primaryGreen)
                  : null,
            ),
          ),
          GestureDetector(
            onTap: _uploadImage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Icon(Icons.camera_alt_rounded, size: 20, color: slate900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color itemColor = isDestructive ? softRed : primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: itemColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: slate900)),
                  Text(subLabel, style: GoogleFonts.poppins(fontSize: 12, color: slate400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: slate400),
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
        title: Text("Delete Account?", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text("This will erase all progress. This cannot be undone.", style: GoogleFonts.poppins(color: slate400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Go Back", style: GoogleFonts.poppins(color: slate400))),
          TextButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('users'); 
              await db.delete('habits');
              await db.delete('daily_logs');
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text("Delete", style: GoogleFonts.poppins(color: softRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}