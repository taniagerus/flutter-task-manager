import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_page.dart';
import 'schedule_page.dart';
import 'user_profile_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _currentIndex = 2; // Statistics tab index

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SchedulePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfilePage()),
        );
        break;
      default:
        setState(() {
          _currentIndex = index;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'This week',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('12', 'Tasks', Colors.blue.shade700),
                  _buildStatItem('8', 'Completed', Colors.green),
                  _buildStatItem('2', 'Overdue', Colors.red),
                  _buildStatItem('2', 'Pending', Colors.amber),
                ],
              ),
              const SizedBox(height: 32),
              _buildCompletionRate(),
              const SizedBox(height: 32),
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildCategoryProgress('Work', 0.50, '50%', const Color(0xFFFFC107)),
              const SizedBox(height: 24),
              _buildCategoryProgress('Health', 0.25, '25%', const Color(0xFFFF9B9B)),
              const SizedBox(height: 24),
              _buildCategoryProgress('Personal', 0.25, '25%', const Color(0xFF2F80ED)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildStatItem(String count, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionRate() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Completion Rate', 
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            )
          ),
          Text(
            '67%',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Основний прогрес з градієнтом
              Container(
                width: MediaQuery.of(context).size.width * 0.67 - 48,
                height: 12,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8ED7C6), Color(0xFF62C4AC)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Ефект внутрішньої тіні зверху
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Ефект світла знизу (для 3D вигляду)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildCategoryProgress(String category, double progress, String label, Color color) {
  // Визначення градієнтів для кожної категорії
  List<Color> gradientColors;
  
  if (category == 'Work') {
    gradientColors = [const Color(0xFFFFD975), const Color(0xFFFFC107)];
  } else if (category == 'Health') {
    gradientColors = [const Color(0xFFFFB5B5), const Color(0xFFFF9B9B)];
  } else if (category == 'Personal') {
    gradientColors = [const Color(0xFF7BAFED), const Color(0xFF2F80ED)];
  } else {
    gradientColors = [color.withOpacity(0.7), color];
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Основний прогрес з градієнтом
              Container(
                width: (MediaQuery.of(context).size.width - 48) * progress,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Ефект внутрішньої тіні зверху
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  width: (MediaQuery.of(context).size.width - 48) * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Ефект світла знизу (для 3D вигляду)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  width: (MediaQuery.of(context).size.width - 48) * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
}
