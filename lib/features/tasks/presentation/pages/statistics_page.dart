import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_page.dart';
import 'schedule_page.dart';
import 'user_profile_page.dart';
import '../../data/repositories/task_repository_impl.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _currentIndex = 2; // Statistics tab index
  final _taskRepository = TaskRepositoryImpl();
  bool _isLoading = true;
  
  // Statistics data
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _overdueTasks = 0;
  int _pendingTasks = 0;
  int _completionRate = 0;
  List<Map<String, dynamic>> _categoryStats = [];
  
  // Date range for statistics
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _dateRangeText = 'This week';

  @override
  void initState() {
    super.initState();
    _initDateRange();
    _loadStatistics();
  }
  
  void _initDateRange() {
    // Calculate Monday and Sunday of current week
    final now = DateTime.now();
    
    // Визначаємо понеділок поточного тижня
    // weekday повертає 1 для понеділка, 7 для неділі
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    // Визначаємо початок дня для понеділка (00:00:00)
    _startDate = DateTime(monday.year, monday.month, monday.day);
    
    // Визначаємо кінець дня для неділі (23:59:59)
    final sunday = _startDate.add(const Duration(days: 6));
    _endDate = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
    
    // Встановлюємо текст діапазону дат
    _dateRangeText = 'This week';
  }

  Future<void> _loadStatistics() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _taskRepository.getTaskStatistics(
        FirebaseAuth.instance.currentUser!.uid,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      setState(() {
        _totalTasks = stats['totalTasks'];
        _completedTasks = stats['completedTasks'];
        _overdueTasks = stats['overdueTasks'];
        _pendingTasks = stats['pendingTasks'];
        _completionRate = stats['completionRate'];
        _categoryStats = List<Map<String, dynamic>>.from(stats['categoryStats']);
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2F80ED),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        // Встановлюємо початок і кінець дня для вибраного діапазону
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        
        // Update date range text
        if (_startDate.year == _endDate.year && 
            _startDate.month == _endDate.month && 
            _startDate.day == _endDate.day) {
          // Same day
          _dateRangeText = DateFormat('MMM d, yyyy').format(_startDate);
        } else if (_startDate.year == _endDate.year && 
                  _startDate.month == _endDate.month) {
          // Same month
          _dateRangeText = '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('d, yyyy').format(_endDate)}';
        } else if (_startDate.year == _endDate.year) {
          // Same year
          _dateRangeText = '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}';
        } else {
          // Different years
          _dateRangeText = '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}';
        }
      });
      
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F80ED),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2F80ED)),
            onPressed: _loadStatistics,
            tooltip: 'Refresh statistics',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _showDateRangePicker,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF7FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _dateRangeText,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2F80ED),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Color(0xFF2F80ED),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Додаємо швидкі кнопки для вибору періодів
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuickDateButton('Today', _selectToday),
                        const SizedBox(width: 8),
                        _buildQuickDateButton('This week', _selectThisWeek),
                        const SizedBox(width: 8),
                        _buildQuickDateButton('This month', _selectThisMonth),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('$_totalTasks', 'Tasks', Colors.blue.shade700),
                        _buildStatItem('$_completedTasks', 'Completed', Colors.green),
                        _buildStatItem('$_overdueTasks', 'Overdue', Colors.red),
                        _buildStatItem('$_pendingTasks', 'Pending', Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildCompletionRate(),
                    const SizedBox(height: 32),
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_categoryStats.isEmpty)
                      _buildEmptyCategories()
                    else
                      ..._categoryStats.take(5).map((category) => Column(
                        children: [
                          _buildCategoryProgress(
                            category['name'],
                            category['percentage'] / 100,
                            '${category['percentage']}%',
                            _getCategoryColor(category['name']),
                          ),
                          const SizedBox(height: 24),
                        ],
                      )).toList(),
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

  Widget _buildEmptyCategories() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No category data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create tasks with categories to see stats',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return const Color(0xFF2F80ED);
      case 'health':
        return const Color(0xFFFF9B9B);
      case 'work':
        return const Color(0xFFFFC107);
      case 'hmhmg':
        return const Color(0xFFD4A5FF);
      case 'smile':
        return const Color(0xFFA5FFB8);
      default:
        return Colors.grey;
    }
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
              '$_completionRate%',
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
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade300,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Main progress bar with gradient
                if (_completionRate > 0)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth * _completionRate / 100,
                        height: 12,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8ED7C6), Color(0xFF62C4AC)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      );
                    }
                  ),
                // Top inner shadow effect
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
                // Bottom light effect (for 3D look)
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
    // Define gradients for each category
    List<Color> gradientColors;
    
    if (category.toLowerCase() == 'work') {
      gradientColors = [const Color(0xFFFFD975), const Color(0xFFFFC107)];
    } else if (category.toLowerCase() == 'health') {
      gradientColors = [const Color(0xFFFFB5B5), const Color(0xFFFF9B9B)];
    } else if (category.toLowerCase() == 'personal') {
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
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade300,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Main progress with gradient
                if (progress > 0)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth * progress,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      );
                    }
                  ),
                // Top inner shadow effect
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
                // Bottom light effect (for 3D look)
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

  // Додаємо методи для швидкого вибору періодів
  void _selectToday() {
    setState(() {
      final now = DateTime.now();
      // Встановлюємо початок і кінець поточного дня
      _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      _dateRangeText = 'Today';
    });
    _loadStatistics();
  }
  
  void _selectThisWeek() {
    // Повторно використовуємо логіку з _initDateRange
    setState(() {
      final now = DateTime.now();
      
      // Визначаємо понеділок поточного тижня
      final monday = now.subtract(Duration(days: now.weekday - 1));
      
      // Встановлюємо початок і кінець тижня
      _startDate = DateTime(monday.year, monday.month, monday.day);
      final sunday = _startDate.add(const Duration(days: 6));
      _endDate = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
      
      _dateRangeText = 'This week';
    });
    _loadStatistics();
  }
  
  void _selectThisMonth() {
    setState(() {
      final now = DateTime.now();
      
      // Перший день поточного місяця
      _startDate = DateTime(now.year, now.month, 1);
      
      // Останній день поточного місяця
      // Визначаємо перший день наступного місяця і віднімаємо 1 день
      final lastDay = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1))
          : DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1));
      
      _endDate = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
      _dateRangeText = 'This month';
    });
    _loadStatistics();
  }
  
  // Виджет кнопки для швидкого вибору періоду
  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _dateRangeText == label 
            ? const Color(0xFF2F80ED) 
            : const Color(0xFFEEF7FF),
        foregroundColor: _dateRangeText == label 
            ? Colors.white 
            : const Color(0xFF2F80ED),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
