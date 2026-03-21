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
          SliverToBoxAdapter(child: _buildStaticHeader()),
          SliverToBoxAdapter(child: _buildQuickStatsGrid()), 
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
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Streaks",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: slate900,
                fontSize: 28,
                letterSpacing: -0.5),
          ),
          Text(
            "Your habit consistency overview",
            style: GoogleFonts.poppins(
                color: slate400, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return FutureBuilder<Map<String, dynamic>>(
        future: _controller.getTodayStats(),
        builder: (context, snapshot) {
          final streak = snapshot.data?['currentStreak'] ?? 0;
          final finished = snapshot.data?['habitsFinished'] ?? 0;
          final rate = snapshot.data?['completionRate'] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth = (constraints.maxWidth - 24) / 3;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCard(
                      "CURRENT\nSTREAK",
                      "$streak",
                      "Active",
                      const Color(0xFF3B82F6),
                      itemWidth,
                      () => _showStatDetailsModal("Ongoing Streaks", _controller.getOngoingStreaks(), true),
                    ),
                    _buildMetricCard(
                      "HABITS\nDONE",
                      "$finished",
                      "Today",
                      const Color(0xFFEF4444),
                      itemWidth,
                      () => _showStatDetailsModal("Finished Today", _controller.getFinishedToday(), false),
                    ),
                    _buildMetricCard(
                      "COMPL.\nRATE",
                      "$rate%",
                      "Progress",
                      const Color(0xFFF59E0B),
                      itemWidth,
                      () => _showStatDetailsModal("Completion Progress", _controller.getCompletionBreakdown(), false, isRate: true),
                    ),
                  ],
                );
              },
            ),
          );
        });
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, double width, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            FittedBox( 
              fit: BoxFit.scaleDown, // FIXED: Changed from Axis.horizontal
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    final IconData habitIcon = habit['iconCode'] != null ? IconData(habit['iconCode'], fontFamily: 'MaterialIcons') : Icons.bolt_rounded;
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
                  Text(
                    habit['title'], 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 16)
                  ),
                  Text(
                    "$streakValue Day Streak • ${_controller.getConsistencyRank(streakValue)}",
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE2E8F0), size: 14),
          ],
        ),
      ),
    );
  }

  void _showStatDetailsModal(String title, Future<List<Map<String, dynamic>>> future, bool showStreak, {bool isRate = false}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Premium light slate background
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0), 
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Header Section: Now supports multi-line text
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Keeps badge aligned to top line
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 22, 
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFF0F172A), 
                          letterSpacing: -0.5,
                          height: 1.2, // Tighter line height for wrapped titles
                        ),
                        // Removed maxLines so the full text shows
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Detailed Overview",
                        style: GoogleFonts.poppins(
                          fontSize: 11, 
                          color: const Color(0xFF94A3B8), 
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRate) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      "DAILY RATE", 
                      style: GoogleFonts.poppins(
                        fontSize: 9, 
                        color: const Color(0xFF64748B), 
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A))
                  );
                }
                if (snapshot.data!.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final habit = snapshot.data![index];
                    final bool isDone = habit['isCompletedToday'] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Status Icon Container
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isDone ? Icons.check_rounded : Icons.radio_button_off_rounded,
                              color: isDone ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Habit Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit['title'], 
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, 
                                    color: const Color(0xFF1E293B), 
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                  ),
                                  // This wraps by default
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isDone ? "Goal reached today" : "Pending completion", 
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, 
                                    color: const Color(0xFF64748B),
                                  )
                                ),
                              ],
                            ),
                          ),
                          
                          if (showStreak) ...[
                            const SizedBox(width: 8),
                            _buildPremiumStreakBadge(habit['liveStreak'] ?? 0),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper for the Streak Badge
Widget _buildPremiumStreakBadge(int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED), 
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFEDD5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt_rounded, color: Color(0xFFF97316), size: 16),
        const SizedBox(width: 2),
        Text(
          "$count",
          style: GoogleFonts.poppins(
            color: const Color(0xFF9A3412), 
            fontWeight: FontWeight.w800, 
            fontSize: 13
          ),
        ),
      ],
    ),
  );
}

// Helper for the Empty State
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_rounded, size: 40, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 12),
        Text(
          "No activity recorded yet", 
          style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)
        )
      ],
    ),
  );
}



Widget _buildSimpleStreak(int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED), 
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 14),
        const SizedBox(width: 4),
        Text(
          "$count",
          style: GoogleFonts.poppins(
            color: const Color(0xFFEA580C), 
            fontWeight: FontWeight.w700, 
            fontSize: 12
          ),
        ),
      ],
    ),
  );
}



  void _showAnalysisModal(Map<String, dynamic> habit, Color habitColor, IconData habitIcon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 20),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _controller.getHabitDeepAnalysis(habit['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
                }

                final data = snapshot.data!;
                final int currentStreak = habit['liveStreak'] ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 24),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit['title'], style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: slate900)),
                            Text("DATA ANALYTICS", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: slate400, letterSpacing: 1.2)),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                _buildStatTile("Peak Streak", "${data['longestStreak']}", Icons.workspace_premium, Colors.amber),
                                const SizedBox(width: 12),
                                _buildStatTile("Current", "$currentStreak", Icons.local_fire_department_rounded, Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatTile("Missed", "${data['missedDays']}", Icons.close_rounded, Colors.redAccent),
                                const SizedBox(width: 12),
                                _buildStatTile("Consistency", "${data['completionRate']}%", Icons.donut_large_rounded, habitColor),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildLongStatTile("Total Successful Days", "${data['totalAccomplished']}", Icons.check_circle_rounded, habitColor),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: slate900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text("Close Analysis", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown, // FIXED: Changed from Axis.horizontal
              child: Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: slate900))
            ),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: slate400)),
          ],
        ),
      ),
    );
  }

  Widget _buildLongStatTile(String label, String value, IconData icon, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: slate900)),
              Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: slate400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: slate400, letterSpacing: 1.5));
  }

  
}