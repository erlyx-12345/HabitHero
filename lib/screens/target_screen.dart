import 'package:flutter/material.dart';
import 'hero_name_screen.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final Set<String> _selectedTargets = {'Sports', 'Art', 'Laptop'};

  final List<Map<String, dynamic>> _targets = [
    {'title': 'Live Healthier', 'icon': Icons.favorite, 'color': Colors.red},
    {'title': 'Sports', 'icon': Icons.directions_bike, 'color': const Color(0xFF0F5A42)},
    {'title': 'Art', 'icon': Icons.palette, 'color': const Color(0xFF0F5A42)},
    {'title': 'Meditation', 'icon': Icons.self_improvement, 'color': const Color(0xFF0F5A42)},
    {'title': 'Study', 'icon': Icons.menu_book, 'color': Colors.brown},
    {'title': 'Laptop', 'icon': Icons.laptop_mac, 'color': const Color(0xFF0F5A42)},
  ];

  void _toggleSelection(String title) {
    setState(() {
      if (_selectedTargets.contains(title)) {
        _selectedTargets.remove(title);
      } else {
        _selectedTargets.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F5A42)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "What's your target?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Help us understand your needs better.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: _targets.length,
                  itemBuilder: (context, index) {
                    final target = _targets[index];
                    final isSelected = _selectedTargets.contains(target['title']);

                    return GestureDetector(
                      onTap: () => _toggleSelection(target['title']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F5A42) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: const Color(0xFF0F5A42),
                                  width: 3,
                                ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    target['icon'],
                                    size: 40,
                                    color: isSelected ? Colors.white : target['color'],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    target['title'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 12,
                                right: 12,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 32.0, top: 10.0),
                child: ElevatedButton(
                  onPressed: _selectedTargets.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HeroNameScreen(
                                selectedTargets: _selectedTargets.toList(),
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTargets.isEmpty
                        ? Colors.grey
                        : const Color(0xFF0F5A42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: _selectedTargets.isEmpty ? 0 : 4,
                  ),
                  child: const Text(
                    "NEXT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}