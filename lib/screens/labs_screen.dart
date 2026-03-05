import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/labs_controller.dart';
import '../models/habit_model.dart';
import '../components/custom_navbar.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final LabController _controller = LabController();
  
  // High-End Light Palette
  final Color primaryGreen = const Color(0xFF10B981);
  final Color bgLight = const Color(0xFFF8FAFC); 
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate100 = const Color(0xFFE2E8F0);

  final Color darkGreen = const Color(0xFF064E3B); // Deep Emerald
  final Color cardGreen = const Color(0xFF065F46); // Lighter Emerald for cards
  final Color accentGreen = const Color(0xFF34D399);

  bool _isLoading = true;
  String _activeTab = "Overall";
  double _score = 0.0;
  double _momentum = 0.0;
  List<Habit> _elites = [];
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _difficultyData = [];
  Map<String, double> _timeOfDayStats = {};
  List<String> _dropOffs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Optimized load data to prevent screen flickering
  Future<void> _loadData({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() => _isLoading = true);
    }

    // Use Future.wait to fetch all data in parallel for speed
    final results = await Future.wait([
      _controller.getCompletionRate(),
      _controller.getEliteHabits(),
      _controller.getFilteredChartData(_activeTab),
      _controller.getMomentumScore(),
      _controller.getHabitDifficulty(),
      _controller.getTimeOfDayComparison(),
      _controller.getDropOffs(),
    ]);
    
    if (mounted) {
      setState(() {
        _score = results[0] as double;
        _elites = results[1] as List<Habit>;
        _chartData = results[2] as List<Map<String, dynamic>>;
        _momentum = results[3] as double;
        _difficultyData = results[4] as List<Map<String, dynamic>>;
        _timeOfDayStats = results[5] as Map<String, double>;
        _dropOffs = results[6] as List<String>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      bottomNavigationBar: CustomNavBar(currentIndex: 1, onTap: (i) {}),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : CustomScrollView(
              key: const ValueKey("lab_content_scroll"), // Prevents scroll reset
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  sliver: SliverToBoxAdapter(child: _buildHeader()),
                ),
                
                SliverToBoxAdapter(child: _buildHeroCard()),
                
                SliverToBoxAdapter(child: _buildMomentumBadge()),

                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(child: _buildChartSection()),
                ),

               
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildLabel("NEURAL TIMELINE STABILITY"),
                      const SizedBox(height: 16),
                      _buildTimeComparison(),
                      const SizedBox(height: 32),
                      _buildLabel("DIFFICULTY INDEX (LOAD)"),
                      const SizedBox(height: 16),
                      ..._difficultyData.map((d) => _buildDifficultyRow(d)),
                      const SizedBox(height: 32),
                      _buildLabel("CURRENT STREAKS"),
                      const SizedBox(height: 16),
                      ..._elites.map((h) => _buildStreakCard(h)),
                      const SizedBox(height: 120),
                    ]),
                  ),
                )
              ],
            ),
      ),
    );
  }

 Widget _buildHeader() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // Thinner, shorter bar for a more delicate touch
          Container(
            width: 3,
            height: 12, 
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "ANALYTICS", 
            style: GoogleFonts.poppins(
              fontSize: 9, 
              fontWeight: FontWeight.w600, 
              color: Colors.grey[400], 
              letterSpacing: 1.2
            )
          ),
        ],
      ),
      const SizedBox(height: 2), // Tightened gap
      Text(
        "Habit Performance", 
        style: GoogleFonts.poppins(
          fontSize: 22, // Reduced from 28
          fontWeight: FontWeight.w600, 
          color: const Color(0xFF1A1A1A), 
          letterSpacing: -0.4
        )
      ),
    ],
  );
}

Widget _buildHeroCard() {
  const Color obsidianBlack = Color(0xFF000000); // Pure Black
  const Color emeraldGreen = Color(0xFF2ECC71); // Vibrant Emerald

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    constraints: const BoxConstraints(minHeight: 140),
    decoration: BoxDecoration(
      color: obsidianBlack,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          offset: const Offset(0, 8),
        )
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Subtle glow effect in the corner
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: emeraldGreen.withOpacity(0.04),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AVERAGE CONSISTENCY",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "${(_score * 100).toInt()}",
                            style: GoogleFonts.poppins(
                              color: emeraldGreen,
                              fontSize: 42,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "%",
                            style: GoogleFonts.poppins(
                              color: emeraldGreen.withOpacity(0.4),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Status Badge in Emerald
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: emeraldGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: emeraldGreen.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_graph_rounded, color: emeraldGreen, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              "PERFORMANCE STABLE",
                              style: GoogleFonts.poppins(
                                color: emeraldGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: CircularProgressIndicator(
                        value: _score,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        color: emeraldGreen,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(
                      Icons.bolt_rounded,
                      color: emeraldGreen.withOpacity(0.2),
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _buildMomentumBadge() {
  bool isPositive = _momentum >= 0;
  return Center(
    child: Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Geometric corners
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down, 
            color: isPositive ? const Color(0xFF1B4332) : Colors.red[700], 
            size: 16
          ),
          const SizedBox(width: 10),
          Text(
            "Momentum Delta: ${isPositive ? '+' : ''}${(_momentum * 100).toStringAsFixed(1)}%",
            style: GoogleFonts.poppins(
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              color: const Color(0xFF333333)
            ),
          )
        ],
      ),
    ),
  );
}

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 24, 16, 16), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: slate100),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ["Overall", "Morning", "Afternoon", "Evening"].map((tab) {
                bool active = _activeTab == tab;
                return GestureDetector(
                  onTap: () { 
                    if (_activeTab == tab) return;
                    setState(() { 
                      _activeTab = tab; 
                      // Removed _isLoading = true here to prevent screen flickering
                    }); 
                    _loadData(isBackground: true); 
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(tab, style: GoogleFonts.poppins(
                      fontSize: 13, 
                      fontWeight: FontWeight.bold, 
                      color: active ? primaryGreen : slate500
                    )),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(height: 220, child: LineChart(_buildChartData())),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) => FlLine(color: slate100, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 35,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: GoogleFonts.poppins(fontSize: 10, color: slate500, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index < 0 || index >= _chartData.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _chartData[index]['day'].toString().toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 9, color: slate900, fontWeight: FontWeight.w900),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['rate'] * 100)).toList(),
          isCurved: true, 
          color: primaryGreen,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Colors.white,
              strokeWidth: 3,
              strokeColor: primaryGreen,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryGreen.withOpacity(0.2), Colors.transparent],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTimeComparison() {
  final categories = ["Morning", "Afternoon", "Evening"];
  
  // Icon mapping for a more visual, playful experience
  final Map<String, IconData> categoryIcons = {
    "Morning": Icons.wb_sunny_rounded,
    "Afternoon": Icons.wb_cloudy_rounded,
    "Evening": Icons.dark_mode_rounded,
  };

  return Row(
    children: categories.map((label) {
      double value = _timeOfDayStats[label] ?? 0.0;
      
      // Using the requested Dark Green for high performance
      Color accentColor = value >= 0.8 
          ? const Color(0xFF1B4332) 
          : (value >= 0.5 ? Colors.orangeAccent : Colors.redAccent.withOpacity(0.8));
      
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32), // Bubbly, extra-rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Playful Time Icon with tinted background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcons[label],
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 14),
              
              // 2. The Percentage with Bold Playful Type
              Text(
                "${(value * 100).toInt()}%",
                style: GoogleFonts.poppins(
                  fontSize: 20, 
                  fontWeight: FontWeight.w800, 
                  color: const Color(0xFF2D3142), // Soft charcoal blue
                  height: 1.1
                ),
              ),
              
              const SizedBox(height: 4),
              
              // 3. Simple Label
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.grey[400],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 4. Bubbly Progress Indicator (Small bar at the bottom)
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.1, 1.0), // Ensure it's always slightly visible
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
 Widget _buildDifficultyRow(Map<String, dynamic> data) {
  // 1. Calculate Difficulty
  double successRate = (data['successRate'] as num?)?.toDouble() ?? 0.0;
  double difficultyRate = (100.0 - successRate).clamp(0.0, 100.0);
  
  // 2. Times Done Logic
  int timesDone = data['completedCount'] ?? 0;
  if (timesDone == 0 && successRate > 0) {
    timesDone = (30 * (successRate / 100)).round();
  }

  Color barColor = Color(data['colorHex'] ?? 0xFF10B981);

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Reduced horizontal padding
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: slate100, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                data['title'] ?? "Unknown Task",
                overflow: TextOverflow.ellipsis, // Prevents long titles from breaking layout
                style: GoogleFonts.poppins(
                  fontSize: 15, 
                  color: slate900, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: slate900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${difficultyRate.toInt()}% DIFF",
                style: GoogleFonts.poppins(
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.white
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress Bar
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: slate100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (difficultyRate / 100).clamp(0.05, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // FIXED BOTTOM ROW: Added Expanded and FittedBox to prevent overflow
        Row(
          children: [
            Icon(Icons.history_rounded, size: 12, color: slate500),
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown, // Shrinks text slightly if it hits the limit
                alignment: Alignment.centerLeft,
                child: Text(
                  timesDone > 0 
                      ? "Consistency confirmed over $timesDone sessions"
                      : "Baseline analysis in progress",
                  style: GoogleFonts.poppins(
                    fontSize: 11, 
                    color: slate500, 
                    fontWeight: FontWeight.w500
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8), // Buffer space
            Text(
              difficultyRate > 70 ? "CRITICAL LOAD" : "STABLE UNIT",
              style: GoogleFonts.poppins(
                fontSize: 9, 
                fontWeight: FontWeight.w900, 
                color: difficultyRate > 70 ? Colors.redAccent : primaryGreen,
                letterSpacing: 0.5
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

 Widget _buildStreakCard(Habit h) {
  final Color habitColor = Color(h.colorHex);
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      // Soft, slightly tinted white for a friendly feel
      color: Colors.white, 
      borderRadius: BorderRadius.circular(28), // Extra rounded "bubbly" corners
      boxShadow: [
        BoxShadow(
          color: habitColor.withOpacity(0.08), 
          blurRadius: 20, 
          offset: const Offset(0, 8)
        )
      ],
    ),
    child: Row(
      children: [
        // 1. Playful Gradient Icon
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            // Adds a subtle gradient glow for better depth
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1B4332).withOpacity(0.12),
                const Color(0xFF1B4332).withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle, 
          ),
          child: Icon(
            IconData(h.iconCode, fontFamily: 'MaterialIcons'), 
            // Also subtly tint the icon to match the playful dark green
            color: const Color(0xFF1B4332), 
            size: 28, // Sized up slightly
          ),
        ),
        const SizedBox(width: 16),
        
        // 2. Habit Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.title, 
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, 
                  fontSize: 15,
                  color: const Color(0xFF2D3142), // Soft dark blue instead of harsh black
                )
              ),
              const SizedBox(height: 2),
              Text(
                "You're doing great!", 
                style: GoogleFonts.poppins(
                  fontSize: 11, 
                  color: Colors.grey[500], 
                  fontWeight: FontWeight.w500,
                )
              ),
            ],
          ),
        ),
        
        // 3. The Streak "Badge"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4332), // Dark green color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.fireplace_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                "${h.streak}", 
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16, 
                  color: Colors.white,
                )
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
 
  Widget _buildLabel(String s) => Text(s, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: slate500, letterSpacing: 2));
}