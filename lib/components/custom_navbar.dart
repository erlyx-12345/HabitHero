import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    // Trigger the callback first so the parent state updates
    onTap(index);

    // Then handle the actual route switching
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/labs');
        break;
      case 2:
        // Navigator.pushReplacementNamed(context, '/circles');
        break;
      case 3:
        // Navigator.pushReplacementNamed(context, '/setup');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF10B981);
    const Color slate400 = Color(0xFF94A3B8);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.track_changes_rounded, "Target", 0, primaryGreen, slate400),
              _buildNavItem(context, Icons.show_chart_rounded, "Labs", 1, primaryGreen, slate400),
              _buildNavItem(context, Icons.group_rounded, "Circles", 2, primaryGreen, slate400),
              _buildNavItem(context, Icons.settings_rounded, "Setup", 3, primaryGreen, slate400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, Color activeColor, Color inactiveColor) {
    final bool active = currentIndex == index;
    final color = active ? activeColor : inactiveColor;
    
    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10, 
                fontWeight: active ? FontWeight.w700 : FontWeight.w500, 
                color: color,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: active ? 4 : 0,
              decoration: BoxDecoration(
                color: activeColor, 
                shape: BoxShape.circle,
              ),
            )
          ],
        ),
      ),
    );
  }
}