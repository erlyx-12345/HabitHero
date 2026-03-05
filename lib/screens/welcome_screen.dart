import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'target_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Your preferred color palette
    const Color primaryGreen = Color(0xFF10B981);
    const Color slate900 = Color(0xFF0F172A);
    const Color slate500 = Color(0xFF64748B);
    const Color bgLight = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // Background soft accent
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: primaryGreen.withOpacity(0.05),
            ),
          ),
          
          Column(
            children: [
              // HERO SECTION
              Expanded(
                flex: 5,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 60),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: slate900.withOpacity(0.03),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded, // Energetic, playful icon
                      size: 140,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ),

              // CONTENT SECTION
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      // Branding with Poppins
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Habit",
                              style: GoogleFonts.poppins(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: slate900,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: "Hero",
                              style: GoogleFonts.poppins(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: primaryGreen,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Track your small wins and build a better you, one day at a time.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: slate500,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                      const Spacer(),
                      
                      // THE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 65,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TargetScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "Get Started",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}