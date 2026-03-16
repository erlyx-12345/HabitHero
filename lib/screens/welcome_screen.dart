import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hero_name_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF10B981);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            // 1. BACKGROUND IMAGE
            Positioned.fill(
              child: Image.asset(
                'assets/welcome_image.png',
                fit: BoxFit.cover,
              ),
            ),

            // 2. STRATEGIC GRADIENT OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 0.8, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // 3. CONTENT
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 8),

                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 12.0,
                              color: Colors.black.withOpacity(0.8),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        children: const [
                          TextSpan(text: "Habit", style: TextStyle(color: Colors.white)),
                          TextSpan(text: "Hero", style: TextStyle(color: primaryGreen)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Track your small wins and build a better you, one day at a time.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black.withOpacity(0.9),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // 4. THE BUTTON (FIXED NAVIGATION)
                    Center(
                      child: Container(
                        height: 54, 
                        width: MediaQuery.of(context).size.width * 0.65, 
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25), 
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8), 
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // FIXED: Removed the selectedTargets parameter
                                builder: (context) => const HeroNameScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent, 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            "Get Started",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}