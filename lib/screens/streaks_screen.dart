import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../controllers/streaks_controller.dart';
import '../components/custom_navbar.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  final StreaksController _controller = StreaksController();
  
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate100 = const Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Static Header replacing the SliverAppBar
          SliverToBoxAdapter(child: _buildStaticHeader()),
          
          // New Quick Stats Cards Section
          SliverToBoxAdapter(child: _buildQuickStatsRow()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("ALL HABIT STATS"),
                  const SizedBox(height: 16),
                  _buildAllHabitsList(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildStaticHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800, 
              color: slate900, 
              fontSize: 28,
              letterSpacing: -0.5
            ),
          ),
          Text(
            "Your habit consistency overview",
            style: GoogleFonts.poppins(
              color: slate400,
              fontSize: 13,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _controller.getTodayStats(), // Ensure this method exists in your controller
      builder: (context, snapshot) {
        final streak = snapshot.data?['currentStreak'] ?? 0;
        final finished = snapshot.data?['habitsFinished'] ?? 0;
        final rate = snapshot.data?['completionRate'] ?? 0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _buildMetricCard(
                "CURRENT\nSTREAK", 
                "$streak", 
                "Best Streak: $streak", 
                const Color(0xFF3B82F6)
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "HABIT\nFINISHED", 
                "$finished", 
                "This week: $finished", 
                const Color(0xFFEF4444)
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "COMPLETION\nRATE", 
                "$rate%", 
                "Today's Progress", 
                const Color(0xFFF59E0B)
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllHabitsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _controller.getAllHabitStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return _buildEmptyState();

        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final habit = snapshot.data![index];
            return _buildHabitCard(habit);
          },
        );
      },
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    final Color habitColor = habit['colorHex'] != null ? Color(habit['colorHex']) : const Color(0xFF10B981);
    final IconData habitIcon = habit['iconCode'] != null 
        ? IconData(habit['iconCode'], fontFamily: 'MaterialIcons') 
        : Icons.bolt_rounded;
    
    final int streakValue = habit['liveStreak'] ?? 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showAnalysisModal(habit, habitColor, habitIcon);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                color: habitColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(habitIcon, color: habitColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 16)),
                  Text(
                    "$streakValue Day Streak • ${_controller.getConsistencyRank(streakValue)}",
                    style: GoogleFonts.poppins(
                      fontSize: 11, 
                      color: const Color(0xFF94A3B8), 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE2E8F0), size: 16),
          ],
        ),
      ),
    );
  }

  void _showAnalysisModal(Map<String, dynamic> habit, Color habitColor, IconData habitIcon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // Use a max height but allow the content to dictate size
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        // Added SafeArea to prevent bottom cutoff on gesture-based navigation (iOS/Android)
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 20),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _controller.getHabitDeepAnalysis(habit['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final data = snapshot.data!;
                final int currentStreak = habit['liveStreak'] ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min, // Vital: shrinks modal to fit content
                  children: [
                    Container(
                      width: 40, 
                      height: 4, 
                      decoration: BoxDecoration(
                        color: Colors.grey[200], 
                        borderRadius: BorderRadius.circular(10)
                      )
                    ),
                    const SizedBox(height: 24),
                    // Wrap the scrollable part in Flexible so the "Done" button stays at bottom
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(habit['title'], 
                              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                            Text("THOROUGH DATA ANALYSIS", 
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                _buildStatTile("Longest Streak", "${data['longestStreak']}", Icons.workspace_premium, Colors.amber),
                                const SizedBox(width: 12),
                                _buildStatTile("Current Streak", "$currentStreak", Icons.local_fire_department_rounded, Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatTile("Days Missed", "${data['missedDays']}", Icons.close_rounded, Colors.redAccent),
                                const SizedBox(width: 12),
                                _buildStatTile("Consistency", "${data['completionRate']}%", Icons.donut_large_rounded, habitColor),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildLongStatTile("Total Accomplished", "${data['totalAccomplished']} Days", Icons.check_circle_rounded, habitColor),
                            const SizedBox(height: 20), // Spacing before button
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text("Done", 
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 16),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: slate900)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: slate400)),
          ],
        ),
      ),
    );
  }

  Widget _buildLongStatTile(String label, String value, IconData icon, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: slate900)),
              Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: slate400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: slate400, letterSpacing: 1.5));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text("No habits created yet.", style: GoogleFonts.poppins(color: slate400)),
      ),
    );
  }
}