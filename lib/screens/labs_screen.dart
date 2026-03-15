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

  final Color primaryGreen = const Color(0xFF10B981);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate100 = const Color(0xFFE2E8F0);

  final Color darkGreen = const Color(0xFF064E3B);
  final Color cardGreen = const Color(0xFF065F46);
  final Color accentGreen = const Color(0xFF34D399);

  bool _isLoading = true;
  String _activeTab = "Overall";
  double _score = 0.0;
  double _momentum = 0.0;
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _difficultyData = [];
  Map<String, double> _timeOfDayStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() => _isLoading = true);
    }

    try {
      await _controller.syncStreaks();

      final results = await Future.wait([
        _controller.getCompletionRate(),
        _controller.getEliteHabits(),
        _controller.getFilteredChartData(_activeTab),
        _controller.getMomentumScore(),
        _controller.getHabitDifficulty(),
        _controller.getTimeOfDayComparison(),
      ]);

      if (mounted) {
        setState(() {
          _score = results[0] as double;
          _chartData = results[2] as List<Map<String, dynamic>>;
          _momentum = results[3] as double;
          _difficultyData = results[4] as List<Map<String, dynamic>>;
          _timeOfDayStats = results[5] as Map<String, double>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading analytics: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      bottomNavigationBar: CustomNavBar(currentIndex: 2, onTap: (i) {}),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : CustomScrollView(
                key: const ValueKey("lab_content_scroll"),
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
                        _buildLabel("TIME OF DAY DISTRIBUTION"),
                        const SizedBox(height: 16),
                        _buildTimeComparison(),
                        const SizedBox(height: 32),
                        _buildLabel("DIFFICULTY INDEX (LOAD)"),
                        const SizedBox(height: 16),
                        ..._difficultyData.map((d) => _buildDifficultyRow(d)),
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
    return Padding(
      // Top 60 keeps it below the status bar, Left 24 aligns with your cards
      padding: const EdgeInsets.fromLTRB(1, 1, 15, 20), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Your habit consistency overview",
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    const Color brandBlue = Color(0xFF4A6EDD);
    const Color emeraldGreen = Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 1),
      decoration: BoxDecoration(
        color: brandBlue,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "NEURAL LABS",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${(_score * 100).toInt()}",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "%",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                "PERFORMANCE STABLE",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 85,
                        height: 85,
                        child: CircularProgressIndicator(
                          value: _score,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          color: Colors.white,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? const Color(0xFF1B4332) : Colors.red[700], size: 16),
            const SizedBox(width: 10),
            Text(
              "Momentum Delta: ${isPositive ? '+' : ''}${(_momentum * 100).toStringAsFixed(1)}%",
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
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
                    child: Text(tab,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: active ? primaryGreen : slate500)),
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
                  style: GoogleFonts.poppins(
                      fontSize: 9, color: slate900, fontWeight: FontWeight.w900),
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
    final Map<String, IconData> categoryIcons = {
      "Morning": Icons.wb_sunny_rounded,
      "Afternoon": Icons.wb_cloudy_rounded,
      "Evening": Icons.dark_mode_rounded,
    };

    return Row(
      children: categories.map((label) {
        double value = _timeOfDayStats[label] ?? 0.0;
        Color accentColor = value >= 0.8
            ? const Color(0xFF1B4332)
            : (value >= 0.5 ? Colors.orangeAccent : Colors.redAccent.withOpacity(0.8));

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(categoryIcons[label], size: 18, color: accentColor),
                ),
                const SizedBox(height: 14),
                Text(
                  "${(value * 100).toInt()}%",
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2D3142),
                      height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 24,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value.clamp(0.1, 1.0),
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
    double successRate = (data['successRate'] as num?)?.toDouble() ?? 0.0;
    double difficultyRate = (100.0 - successRate).clamp(0.0, 100.0);
    int timesDone = data['completedCount'] ?? 0;
    if (timesDone == 0 && successRate > 0) {
      timesDone = (30 * (successRate / 100)).round();
    }
    Color barColor = Color(data['colorHex'] ?? 0xFF10B981);

    return GestureDetector(
      onTap: () => _showDiagnosticSheet(context, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: slate900, fontWeight: FontWeight.bold),
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
                        fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            Row(
              children: [
                Icon(Icons.history_rounded, size: 12, color: slate500),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      timesDone > 0
                          ? "Consistency confirmed over $timesDone sessions"
                          : "Baseline analysis in progress",
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: slate500, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  difficultyRate > 70 ? "CRITICAL LOAD" : "STABLE UNIT",
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: difficultyRate > 70 ? Colors.redAccent : primaryGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 
 void _showDiagnosticSheet(BuildContext context, Map<String, dynamic> data) async {
  final analysis = await _controller.getHabitAnalysis(data['id'] ?? 0);
  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final double systemBottom = MediaQuery.of(context).padding.bottom;
      
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, systemBottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "NEURAL DIAGNOSTIC",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: primaryGreen,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['title'] ?? 'Analysis',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: slate900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: slate100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.orangeAccent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Friction Point",
                                    style: GoogleFonts.poppins(
                                      color: slate500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    analysis['frictionPoint'] ?? "Analyzing Patterns...",
                                    style: GoogleFonts.poppins(
                                      color: slate900,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "Analysis Summary",
                        style: GoogleFonts.poppins(
                          color: slate900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        analysis['advice'] ?? "Your habit consistency is being tracked for deeper insights.",
                        style: GoogleFonts.poppins(
                          color: slate500,
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                        children: [
                          _buildGridStat("Consistency", "${(analysis['completionRate'] ?? 0).toInt()}%", Icons.shutter_speed_rounded),
                          _buildGridStat("Frequency", "${analysis['missedCount'] ?? 0} Missed", Icons.calendar_today_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildGridStat(String label, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: slate900,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  Widget _buildLabel(String s) => Text(s,
      style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w900, color: slate500, letterSpacing: 2));
}