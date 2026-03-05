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

                if (_dropOffs.isNotEmpty) 
                  SliverToBoxAdapter(child: _buildWarningSection()),

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
                      _buildLabel("ELITE PERFORMERS"),
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
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text("LAB_STABILITY_v2.0", 
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: slate500, letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 4),
        Text("System Analytics", 
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: slate900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkGreen, const Color(0xFF065F46)],
        ),
        boxShadow: [
          BoxShadow(color: darkGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("HABIT CONSISTENCY", 
                  style: GoogleFonts.poppins(color: accentGreen.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("${(_score * 100).toInt()}", 
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Text("%", style: GoogleFonts.poppins(color: accentGreen, fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("30 DAYS EFFICIENCY", 
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 65, height: 65, 
                child: CircularProgressIndicator(
                  value: _score, 
                  strokeWidth: 6, 
                  backgroundColor: Colors.white.withOpacity(0.1), 
                  color: accentGreen, 
                  strokeCap: StrokeCap.round
                ),
              ),
              Icon(Icons.analytics_outlined, color: Colors.white.withOpacity(0.9), size: 24),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMomentumBadge() {
    bool isPositive = _momentum >= 0;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: slate100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isPositive ? primaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle
              ),
              child: Icon(isPositive ? Icons.add : Icons.remove, 
                color: isPositive ? primaryGreen : Colors.redAccent, size: 10),
            ),
            const SizedBox(width: 8),
            Text(
              "MOMENTUM INDEX: ${isPositive ? '+' : ''}${(_momentum * 100).toStringAsFixed(1)}%",
              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, 
                color: slate900, letterSpacing: 0.5),
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
    final categories = ["Morning", "Afternoon", "Evening", "Anytime"];
    
    return Row(
      children: categories.map((label) {
        double value = _timeOfDayStats[label] ?? 0.0;
        Color statusColor = value >= 0.8 ? primaryGreen : (value >= 0.5 ? Colors.orange : Colors.redAccent);
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: slate100, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(height: 8),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w800, color: slate500),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${(value * 100).toInt()}%",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: slate900),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: slate900.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Color(h.colorHex).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(IconData(h.iconCode, fontFamily: 'MaterialIcons'), color: Color(h.colorHex), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: slate900)),
              Text("CONSISTENCY UNIT", style: GoogleFonts.poppins(fontSize: 9, color: slate500, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          )),
          Text("${h.streak}", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 28, color: slate900)),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text("DROP-OFF DETECTED: ${_dropOffs.join(', ')}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildLabel(String s) => Text(s, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: slate500, letterSpacing: 2));
}