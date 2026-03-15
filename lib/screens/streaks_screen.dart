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
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMomentumCard(),
                  const SizedBox(height: 32),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text("Performance", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: slate900, fontSize: 18)),
      ),
    );
  }

  Widget _buildMomentumCard() {
    return FutureBuilder<double>(
      future: _controller.calculateMomentumScore(),
      builder: (context, snapshot) {
        final score = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: slate900,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: slate900.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("GLOBAL MOMENTUM", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text("${score.toInt()}%", style: GoogleFonts.poppins(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
                ],
              ),
              const Icon(Icons.auto_graph_rounded, color: Color(0xFF10B981), size: 48),
            ],
          ),
        );
      },
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
  // Extract dynamic assigned color and icon
  final Color habitColor = habit['colorHex'] != null ? Color(habit['colorHex']) : const Color(0xFF10B981);
  final IconData habitIcon = habit['iconCode'] != null 
      ? IconData(habit['iconCode'], fontFamily: 'MaterialIcons') 
      : Icons.bolt_rounded;
  
  // Fix: Access the actual streak value from the database map
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
                // Displaying the actual streakValue instead of a hardcoded string
              // Inside _buildHabitCard
 // Use the liveStreak we just calculated

// The specific line you pointed out:
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
      height: MediaQuery.of(context).size.height * 0.75, // Explicit height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _controller.getHabitDeepAnalysis(habit['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          final int currentStreak = habit['streak'] ?? 0;

          return Column(
            children: [
              // Handle bar
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              
              // FIX: Wrapping content in Expanded + SingleChildScrollView to prevent overflow
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit['title'], style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      Text("THOROUGH DATA ANALYSIS", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text("Done", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          );
        },
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