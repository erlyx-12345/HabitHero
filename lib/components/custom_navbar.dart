import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback
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
    
    // Premium Haptic Touch
    HapticFeedback.lightImpact();
    
    onTap(index);

    final routes = {
      0: '/dashboard',
      1: '/streaks',
      2: '/labs',
    };

    if (routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF10B981);
    const Color slate400 = Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.adjust_rounded, "Targets", 0, primaryGreen, slate400),
              _buildNavItem(context, Icons.local_fire_department_rounded, "Streaks", 1, primaryGreen, slate400),
              _buildNavItem(context, Icons.biotech_rounded, "Labs", 2, primaryGreen, slate400),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Subtle emerald glow behind the active icon
          color: active ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: active ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1.0 + (value * 0.15), // Smooth 15% pop effect
                  child: Icon(icon, color: color, size: 26),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}