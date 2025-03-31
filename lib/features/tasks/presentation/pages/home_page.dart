import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav_bar.dart';
import 'schedule_page.dart';
import 'create_category_page.dart';
import 'statistics_page.dart';
import 'user_profile_page.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../data/repositories/task_repository_impl.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  User? get currentUser => FirebaseAuth.instance.currentUser;
  final _categoryRepository = CategoryRepositoryImpl();
  final _taskRepository = TaskRepositoryImpl();
  List<CategoryEntity> _userCategories = [];
  TaskEntity? _upcomingTask;
  bool _isLoading = true;
  Timer? _upcomingTaskTimer;

  @override
  void initState() {
    super.initState();
    print('HomePage: initState called');
    FirebaseAuth.instance.userChanges().listen((User? user) {
      if (mounted) {
        setState(() {});
        _loadCategories();
        _loadUpcomingTask();
      }
    });
    _loadCategories();
    _loadUpcomingTask();
    _createDefaultCategories();
    
    // Start timer for regular upcoming task update
    _startUpcomingTaskRefreshTimer();
    
    // Check if there were task updates from other pages
    _checkForTaskUpdates();
  }

  @override
  void dispose() {
    _upcomingTaskTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    print('HomePage: _loadCategories called');
    if (currentUser == null) {
      print('HomePage: user not logged in');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await _categoryRepository.getCategories(currentUser!.uid);
      print('Loaded categories: ${categories.length}');
      categories.forEach((cat) {
        print('Category: ${cat.name}, ID: ${cat.id}, IconData: ${cat.icon}');
      });
      
      setState(() {
        _userCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultCategories() async {
 
    try {
      // Check if default categories are already created
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isDefault', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        await _categoryRepository.createCategory(
          id: 'health-${currentUser!.uid}',
          name: 'Health',
          color: const Color(0xFFFFE5E5),
          icon: Icons.favorite_outline,
          userId: currentUser!.uid,
          isDefault: true,
        );

        await _categoryRepository.createCategory(
          id: 'personal-${currentUser!.uid}',
          name: 'Personal',
          color: const Color(0xFFE5F1FF),
          icon: Icons.person_outline,
          userId: currentUser!.uid,
          isDefault: true,
        );

        await _categoryRepository.createCategory(
          id: 'work-${currentUser!.uid}',
          name: 'Work',
          color: const Color(0xFFFFF4E5),
          icon: Icons.work_outline,
          userId: currentUser!.uid,
          isDefault: true,
        );

        // Update category list
        print('HomePage: default categories created, loading them');
        _loadCategories();
      }
    } catch (e) {
      print('Error creating default categories: $e');
    }
  }

  Future<void> _loadUpcomingTask() async {
    if (currentUser == null) return;

    try {
      // Get all user tasks
      final tasks = await _taskRepository.getTasks(currentUser!.uid);
      
      // Filter and sort tasks
      final now = DateTime.now();
      print('Current time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}');
      
      // Find the beginning of the current day
      final today = DateTime(now.year, now.month, now.day);
      
      final upcomingTasks = tasks.where((task) {
        // Parse task date and time to DateTime
        final taskDateTime = _parseDateTime(task.date, task.startTime);
        
        // Check if the task is not completed
        final isNotCompleted = !task.isCompleted;
        
        // Determine if the task is in the future (relative to current time)
        // This applies to both future days and current day but later than current time
        final isInFuture = taskDateTime.isAfter(now);
        
        // Determine if the task is scheduled for today
        final isToday = taskDateTime.year == today.year && 
                        taskDateTime.month == today.month && 
                        taskDateTime.day == today.day;
        
        // For today's tasks, check that they haven't started yet (for tasks in progress)
        final isTodayAndNotStarted = isToday && taskDateTime.isAfter(now);
        
        // For tasks currently in progress (start in the past, but end in the future)
        final taskEndDateTime = _parseDateTime(task.date, task.endTime);
        final isCurrentlyActive = isToday && 
                                  taskDateTime.isBefore(now) && 
                                  taskEndDateTime.isAfter(now) && 
                                  isNotCompleted;
        
        // Task qualifies as upcoming if it's in the future or happening right now
        final isUpcoming = (isInFuture || isTodayAndNotStarted || isCurrentlyActive) && isNotCompleted;
        
        print('Task: ${task.name}, Time: ${DateFormat('yyyy-MM-dd HH:mm').format(taskDateTime)}, ' +
              'End: ${DateFormat('HH:mm').format(taskEndDateTime)}, ' +
              'In future: $isInFuture, Today: $isToday, Currently active: $isCurrentlyActive, ' +
              'Upcoming: $isUpcoming');
        
        return isUpcoming;
      }).toList();

      // Sort by start time (nearest first)
      upcomingTasks.sort((a, b) {
        final aStartDateTime = _parseDateTime(a.date, a.startTime);
        final bStartDateTime = _parseDateTime(b.date, b.startTime);
        
        // Check if any of the tasks is happening right now
        final now = DateTime.now();
        final aEndDateTime = _parseDateTime(a.date, a.endTime);
        final bEndDateTime = _parseDateTime(b.date, b.endTime);
        
        final aIsActive = aStartDateTime.isBefore(now) && aEndDateTime.isAfter(now);
        final bIsActive = bStartDateTime.isBefore(now) && bEndDateTime.isAfter(now);
        
        // Active tasks have priority
        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;
        
        // If both are active or both are not active, sort by start time
        return aStartDateTime.compareTo(bStartDateTime);
      });

      final previousTask = _upcomingTask;
      final newUpcomingTask = upcomingTasks.isNotEmpty ? upcomingTasks.first : null;
      
      setState(() {
        _upcomingTask = newUpcomingTask;
      });
      
      if (newUpcomingTask != null) {
        final taskStartTime = _parseDateTime(newUpcomingTask.date, newUpcomingTask.startTime);
        final taskEndTime = _parseDateTime(newUpcomingTask.date, newUpcomingTask.endTime);
        final isActive = taskStartTime.isBefore(now) && taskEndTime.isAfter(now);
        
        print('Selected upcoming task: ${newUpcomingTask.name}');
        print('Start time: ${DateFormat('yyyy-MM-dd HH:mm').format(taskStartTime)}');
        print('End time: ${DateFormat('yyyy-MM-dd HH:mm').format(taskEndTime)}');
        print('Status: ${isActive ? "In progress" : "Scheduled"}');
        
        if (previousTask?.id != newUpcomingTask.id) {
          print('Upcoming task changed: ${previousTask?.name} -> ${newUpcomingTask.name}');
          
          // Restart the timer if the upcoming task has changed
          _startUpcomingTaskRefreshTimer();
        }
      } else {
        print('No upcoming tasks');
        
        // If there are no upcoming tasks now, but there were before - restart the timer
        if (previousTask != null) {
          _startUpcomingTaskRefreshTimer();
        }
      }
    } catch (e) {
      print('Error loading upcoming task: $e');
    }
  }

  DateTime _parseDateTime(DateTime date, String timeString) {
    final timeComponents = timeString.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeComponents[0]),
      int.parse(timeComponents[1]),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SchedulePage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StatisticsPage()),
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

  // Convert color from HEX format to Color object
  Color _hexToColor(String hexString) {
    final hexColor = hexString.replaceFirst('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  // Convert icon name to IconData object
  IconData _getIconData(String iconName) {
    print('Received icon name: $iconName');
    
    // Check for empty string or null
    if (iconName.isEmpty) {
      print('Empty icon name, using default icon');
      return Icons.category_outlined;
    }
    
    // Fixed icons for standard categories
    // This is a safe fallback option if icons are not defined correctly
    if (iconName == 'health' || iconName.contains('health')) {
      return Icons.favorite_outline;
    } else if (iconName == 'personal' || iconName.contains('personal')) {
      return Icons.person_outline;
    } else if (iconName == 'work' || iconName.contains('work')) {
      return Icons.work_outline;
    } else if (iconName == 'flight' || iconName.contains('flight')) {
      return Icons.flight_outlined;
    } else if (iconName == 'edit' || iconName.contains('edit')) {
      return Icons.edit_outlined;
    } else if (iconName == 'school' || iconName.contains('school')) {
      return Icons.school_outlined;
    }
    
    // Simplified version without extra suffixes
    final simplifiedName = iconName.replaceAll('_outlined', '').replaceAll('_outline', '');
    print('Simplified icon name: $simplifiedName');
    
    switch (simplifiedName) {
      case 'school': return Icons.school_outlined;
      case 'groups': return Icons.groups_outlined;
      case 'home': return Icons.home_outlined;
      case 'favorite': return Icons.favorite_outline;
      case 'flight': return Icons.flight_outlined;
      case 'edit': return Icons.edit_outlined;
      case 'shopping_cart': return Icons.shopping_cart_outlined;
      case 'fastfood': return Icons.fastfood_outlined;
      case 'fitness': 
      case 'fitness_center': return Icons.fitness_center_outlined;
      case 'car': 
      case 'directions_car': return Icons.directions_car_outlined;
      case 'smile': 
      case 'sentiment_satisfied': return Icons.sentiment_satisfied_outlined;
      case 'gift': 
      case 'card_giftcard': return Icons.card_giftcard_outlined;
      case 'person': return Icons.person_outline;
      case 'work': return Icons.work_outline;
      case 'category': return Icons.category_outlined;
      default:
        // Try to handle original name (with suffix)
        switch (iconName) {
          case 'school_outlined': return Icons.school_outlined;
          case 'groups_outlined': return Icons.groups_outlined;
          case 'home_outlined': return Icons.home_outlined;
          case 'favorite_outline': return Icons.favorite_outline;
          case 'flight_outlined': return Icons.flight_outlined;
          case 'edit_outlined': return Icons.edit_outlined;
          case 'shopping_cart_outlined': return Icons.shopping_cart_outlined;
          case 'fastfood_outlined': return Icons.fastfood_outlined;
          case 'fitness_center_outlined': return Icons.fitness_center_outlined;
          case 'directions_car_outlined': return Icons.directions_car_outlined;
          case 'sentiment_satisfied_outlined': return Icons.sentiment_satisfied_outlined;
          case 'card_giftcard_outlined': return Icons.card_giftcard_outlined;
          case 'person_outline': return Icons.person_outline;
          case 'work_outline': return Icons.work_outline;
          case 'category_outlined': return Icons.category_outlined;
          default:
            print('Unknown icon: $iconName, using default icon');
            return Icons.category_outlined;
        }
    }
  }

  // Build default category cards when list is empty
  List<Widget> _buildDefaultCategoryCards() {
    if (currentUser == null) {
      return [];
    }
    
    return [
      _CategoryCard(
        id: 'health-${currentUser!.uid}',
        icon: Icons.favorite_outline,
        title: 'Health',
        color: const Color(0xFFFFE5E5),
        iconColor: const Color(0xFFFF9B9B),
        tasksLeft: 0,
        tasksDone: 0,
        isDefault: true,
      ),
      _CategoryCard(
        id: 'personal-${currentUser!.uid}',
        icon: Icons.person_outline,
        title: 'Personal',
        color: const Color(0xFFE5F1FF),
        iconColor: const Color(0xFF2F80ED),
        tasksLeft: 0,
        tasksDone: 0,
        isDefault: true,
      ),
      _CategoryCard(
        id: 'work-${currentUser!.uid}',
        icon: Icons.work_outline,
        title: 'Work',
        color: const Color(0xFFFFF4E5),
        iconColor: const Color(0xFFFFB156),
        tasksLeft: 0,
        tasksDone: 0,
        isDefault: true,
      ),
      _AddCategoryCard(
        onCategoryCreated: () {
          _loadCategories();
        },
      ),
    ];
  }

  void _startUpcomingTaskRefreshTimer() {
    // Cancel the existing timer if it exists
    _upcomingTaskTimer?.cancel();
    
    // Calculate time until next update
    Duration timeToNextUpdate = _calculateTimeToNextUpdate();
    print('Scheduled upcoming task update in ${timeToNextUpdate.inSeconds} seconds');
    
    // Create a new timer that will trigger at the exact required time
    _upcomingTaskTimer = Timer(timeToNextUpdate, () {
      if (mounted) {
        print('Updating upcoming task according to schedule');
        _loadUpcomingTask();
        
        // Start the timer again after updating tasks
        _startUpcomingTaskRefreshTimer();
      }
    });
  }

  Duration _calculateTimeToNextUpdate() {
    final now = DateTime.now();
    
    // If there's no upcoming task, check once per hour
    if (_upcomingTask == null) {
      return Duration(minutes: 60 - now.minute);
    }
    
    // Parse the time of the upcoming task
    final taskStartDateTime = _parseDateTime(_upcomingTask!.date, _upcomingTask!.startTime);
    final taskEndDateTime = _parseDateTime(_upcomingTask!.date, _upcomingTask!.endTime);
    
    // Check if the task is happening right now
    final isActive = taskStartDateTime.isBefore(now) && taskEndDateTime.isAfter(now);
    
    // If the task is active now, the next update should be at its end time
    if (isActive) {
      final timeToEnd = taskEndDateTime.difference(now);
      print('Task is active, update in ${timeToEnd.inMinutes} minutes at its completion');
      
      // But not less often than once a minute
      return timeToEnd <= Duration.zero
          ? const Duration(minutes: 1)
          : (timeToEnd <= const Duration(minutes: 5)
              ? timeToEnd
              : const Duration(minutes: 5));
    }
    
    // If the task hasn't started yet, update at its start time
    if (taskStartDateTime.isAfter(now)) {
      final timeToStart = taskStartDateTime.difference(now);
      print('Task is scheduled, update in ${timeToStart.inMinutes} minutes at its start');
      
      // But not less often than according to the rules below
      if (timeToStart <= const Duration(minutes: 1)) {
        return timeToStart;
      } else if (timeToStart <= const Duration(minutes: 10)) {
        return const Duration(minutes: 1);
      } else if (timeToStart <= const Duration(hours: 1)) {
        // Update at the beginning of every 5 minutes
        int minutesToNext = 5 - (now.minute % 5);
        if (minutesToNext == 0) minutesToNext = 5;
        
        // But not later than the start time
        final regularUpdate = Duration(minutes: minutesToNext);
        return regularUpdate < timeToStart ? regularUpdate : timeToStart;
      } else if (timeToStart <= const Duration(days: 1)) {
        // Update at the beginning of the hour
        final hourlyUpdate = Duration(minutes: 60 - now.minute, seconds: -now.second);
        return hourlyUpdate < timeToStart ? hourlyUpdate : timeToStart;
      } else {
        // In other cases, update once every 6 hours
        int hoursToNext = 6 - (now.hour % 6);
        if (hoursToNext == 0) hoursToNext = 6;
        
        final regularUpdate = Duration(hours: hoursToNext, minutes: -now.minute, seconds: -now.second);
        return regularUpdate < timeToStart ? regularUpdate : timeToStart;
      }
    }
    
    // If the task has already passed, update in a minute to find the next one
    return const Duration(minutes: 1);
  }

  // Check if there were task updates from other pages
  Future<void> _checkForTaskUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksUpdated = prefs.getBool('tasks_updated') ?? false;
      
      if (tasksUpdated) {
        print('Detected task updates from other pages');
        // Reset the flag and update tasks
        await prefs.setBool('tasks_updated', false);
        _loadUpcomingTask();
      }
    } catch (e) {
      print('Error checking for task updates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              
              const SizedBox(height: 32),
              // Greeting
              Text(
                'Hi ${currentUser?.displayName ?? "there"}!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Upcoming task card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _upcomingTask != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Upcoming task',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              _getTaskStatusWidget(_upcomingTask!),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _upcomingTask!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_upcomingTask!.startTime}-${_upcomingTask!.endTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_upcomingTask!.date),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'No upcoming tasks',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              // Categories header
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Categories grid
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: _userCategories.isEmpty 
                      ? GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                          children: _buildDefaultCategoryCards(),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                          itemCount: _userCategories.length + 1, // +1 for add new category button
                          itemBuilder: (context, index) {
                            // Last card - this is the add new category button
                            if (index == _userCategories.length) {
                              return _AddCategoryCard(
                                onCategoryCreated: () {
                                  print('Called _loadCategories after category creation');
                                  _loadCategories();
                                },
                              );
                            }
                            
                            // Display existing category
                            final category = _userCategories[index];
                            print('Displaying category $index: ${category.name}, icon: ${category.icon}');
                            
                            // Corrected: set specific icons based on category name
                            IconData iconData;
                            
                            // Determine icon based on category name (most reliable way)
                            final lowerCaseName = category.name.toLowerCase();
                            if (lowerCaseName.contains('health')) {
                              iconData = Icons.favorite_outline;
                            } else if (lowerCaseName.contains('personal')) {
                              iconData = Icons.person_outline;
                            } else if (lowerCaseName.contains('work')) {
                              iconData = Icons.work_outline;
                            } else if (lowerCaseName == 'hmhmg') {
                              iconData = Icons.home_outlined;
                            } else if (lowerCaseName.contains('home')) {
                              iconData = Icons.home_outlined;
                            } else if (lowerCaseName.contains('smile')) {
                              iconData = Icons.sentiment_satisfied_outlined;
                            } else if (lowerCaseName.contains('trip') || lowerCaseName.contains('travel')) {
                              iconData = Icons.flight_outlined;
                            } else if (lowerCaseName.contains('edit') || lowerCaseName.contains('write')) {
                              iconData = Icons.edit_outlined;
                            } else if (lowerCaseName.contains('school') || lowerCaseName.contains('study')) {
                              iconData = Icons.school_outlined;
                            } else if (lowerCaseName.contains('shop') || lowerCaseName.contains('cart')) {
                              iconData = Icons.shopping_cart_outlined;
                            } else if (lowerCaseName.contains('food')) {
                              iconData = Icons.fastfood_outlined;
                            } else if (lowerCaseName.contains('fitness') || lowerCaseName.contains('gym')) {
                              iconData = Icons.fitness_center_outlined;
                            } else if (lowerCaseName.contains('car') || lowerCaseName.contains('drive')) {
                              iconData = Icons.directions_car_outlined;
                            } else if (lowerCaseName.contains('gift')) {
                              iconData = Icons.card_giftcard_outlined;
                            } else if (category.icon.isNotEmpty) {
                              // If category name doesn't contain known keywords but has icon value
                              iconData = _getIconData(category.icon);
                            } else {
                              // If nothing matches, use default icon
                              iconData = Icons.category_outlined;
                            }
                            
                            // Set contrasting color for the icon
                            Color iconColor;
                            if (lowerCaseName.contains('health')) {
                              iconColor = const Color(0xFFFF9B9B);
                            } else if (lowerCaseName.contains('personal')) {
                              iconColor = const Color(0xFF2F80ED);
                            } else if (lowerCaseName.contains('work')) {
                              iconColor = const Color(0xFFFFB156);
                            } else if (lowerCaseName.contains('trip') || lowerCaseName.contains('travel')) {
                              iconColor = const Color(0xFF56C2FF);
                            } else {
                              // For other categories, use darker shade of category color
                              final baseColor = _hexToColor(category.colour);
                              // Create darker shade for better contrast
                              iconColor = HSLColor.fromColor(baseColor)
                                  .withSaturation(0.8)  // Increase saturation
                                  .withLightness(0.4)   // Decrease lightness for darker color
                                  .toColor();
                            }
                            
                            print('Using icon: $iconData for category ${category.name} with color $iconColor');
                            
                            return _CategoryCard(
                              id: category.id,
                              icon: iconData,
                              title: category.name,
                              color: _hexToColor(category.colour),
                              iconColor: iconColor,
                              tasksLeft: 2,
                              tasksDone: 2,
                              isDefault: category.isDefault,
                              onDelete: () => _deleteCategory(category),
                            );
                          },
                        ),
                    ),
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

  // Returns the task status widget
  Widget _getTaskStatusWidget(TaskEntity task) {
    final now = DateTime.now();
    final taskStartDateTime = _parseDateTime(task.date, task.startTime);
    final taskEndDateTime = _parseDateTime(task.date, task.endTime);
    
    final isActive = taskStartDateTime.isBefore(now) && taskEndDateTime.isAfter(now);
    
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2F80ED).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'In progress',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2F80ED),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  Future<void> _deleteCategory(CategoryEntity category) async {
    if (category.isDefault) {
      // Don't allow deleting default categories
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default categories cannot be deleted')),
      );
      return;
    }
    
    // Check if there are tasks assigned to this category
    final taskCount = await _taskRepository.countTasksByCategory(currentUser!.uid, category.name);
    
    if (taskCount > 0) {
      // There are tasks using this category, ask for confirmation
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Category?'),
          content: Text('This category has $taskCount task${taskCount > 1 ? 's' : ''}. Deleting it will also delete all associated tasks.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (result != true) {
        return; // User canceled the operation
      }
      
      // Delete all tasks in this category
      try {
        final tasks = await _taskRepository.getTasks(currentUser!.uid);
        final tasksToDelete = tasks.where((task) => task.category == category.name).toList();
        
        for (var task in tasksToDelete) {
          await _taskRepository.deleteTask(task.id);
        }
      } catch (e) {
        print('Error deleting tasks for category: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting tasks: $e')),
        );
        return;
      }
    } else {
      // No tasks, but still ask for confirmation
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Category?'),
          content: const Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (result != true) {
        return; // User canceled the operation
      }
    }
    
    // Delete the category
    try {
      await _categoryRepository.deleteCategory(category.id);
      
      // Reload categories
      _loadCategories();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category successfully deleted')),
      );
    } catch (e) {
      print('Error deleting category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String? id;
  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;
  final int tasksLeft;
  final int tasksDone;
  final bool isDefault;
  final VoidCallback? onDelete;

  const _CategoryCard({
    this.id,
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.tasksLeft,
    required this.tasksDone,
    this.isDefault = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: id != null && !isDefault && onDelete != null 
          ? () => onDelete!() 
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
                if (id != null && !isDefault)
                  Tooltip(
                    message: 'Long press to delete',
                    child: Icon(
                      Icons.delete_outline,
                      color: iconColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TaskCountChip(
                  count: tasksLeft,
                  label: 'left',
                  backgroundColor: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                _TaskCountChip(
                  count: tasksDone,
                  label: 'done',
                  backgroundColor: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCountChip extends StatelessWidget {
  final int count;
  final String label;
  final Color backgroundColor;

  const _TaskCountChip({
    required this.count,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _AddCategoryCard extends StatelessWidget {
  final VoidCallback onCategoryCreated;

  const _AddCategoryCard({
    required this.onCategoryCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateCategoryPage()),
        );
        
        print('Result after category creation: $result');
        
        if (result == true) {
          onCategoryCreated();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }
}
