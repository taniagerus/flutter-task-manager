import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_page.dart';
import 'create_task_page.dart';
import 'postpone_task_page.dart';
import 'task_details_page.dart';
import 'statistics_page.dart';
import 'user_profile_page.dart';
import '../../domain/entities/task_entity.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../../../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _currentIndex = 1;
  bool _isLoading = true;
  final _repository = TaskRepositoryImpl();
  bool _isCalendarExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late ScrollController _weekScrollController;
  DateTime _visibleMonth = DateTime.now();

  // Map to store tasks by date for quick lookup
  Map<DateTime, List<TaskEntity>> _tasksByDate = {};

  NotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _visibleMonth = _selectedDate;
    _weekScrollController = ScrollController();
    // Initial scroll to current week
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedWeek();
    });

    // Initialize animation controller for calendar toggle
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize notification service
    _initNotificationService();
  }

  Future<void> _initNotificationService() async {
    try {
      _notificationService = await NotificationService.getInstance();
    } catch (e) {
      print('Error initializing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error setting up notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _weekScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _repository.getTasks(FirebaseAuth.instance.currentUser!.uid);
      
      // Sort tasks by date and time
      tasks.sort((a, b) {
        // First compare dates
        final dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;
        
        // If dates are the same, compare start times
        final aStartComponents = a.startTime.split(':');
        final bStartComponents = b.startTime.split(':');
        
        final aStartHour = int.parse(aStartComponents[0]);
        final bStartHour = int.parse(bStartComponents[0]);
        
        if (aStartHour != bStartHour) return aStartHour.compareTo(bStartHour);
        
        final aStartMinute = int.parse(aStartComponents[1]);
        final bStartMinute = int.parse(bStartComponents[1]);
        
        return aStartMinute.compareTo(bStartMinute);
      });

      // Group tasks by date for more efficient lookup
      final Map<DateTime, List<TaskEntity>> tasksByDate = {};
      
      for (var task in tasks) {
        // Add original task
        final date = DateTime(task.date.year, task.date.month, task.date.day);
        if (tasksByDate[date] == null) {
          tasksByDate[date] = [];
        }
        tasksByDate[date]!.add(task);

        // Handle repeating tasks
        if (task.repeatOption != 'Never') {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          DateTime nextDate = date;

          // Generate next 30 occurrences for repeating tasks
          for (int i = 0; i < 30; i++) {
            switch (task.repeatOption) {
              case 'Daily':
                nextDate = nextDate.add(const Duration(days: 1));
                break;
              case 'Weekly':
                nextDate = nextDate.add(const Duration(days: 7));
                break;
              case 'Monthly':
                nextDate = DateTime(
                  nextDate.year,
                  nextDate.month + 1,
                  nextDate.day,
                );
                break;
              default:
                continue;
            }

            // Only add future dates
            if (nextDate.isAfter(today) || isSameDay(nextDate, today)) {
              final futureDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
              if (tasksByDate[futureDate] == null) {
                tasksByDate[futureDate] = [];
              }
              
              // Create a copy of the task with a new date
              final repeatedTask = TaskEntity(
                id: '${task.id}_${DateFormat('yyyyMMdd').format(futureDate)}',
                name: task.name,
                note: task.note, 
                date: DateTime(
                  futureDate.year,
                  futureDate.month,
                  futureDate.day,
                  task.date.hour,
                  task.date.minute,
                ),
                startTime: task.startTime,
                endTime: task.endTime,
                category: task.category,
                remindMe: task.remindMe,
                reminderMinutes: task.reminderMinutes,
                repeatOption: task.repeatOption,
                userId: task.userId,
                isCompleted: false,
                createdAt: task.createdAt,
              );
              
              tasksByDate[futureDate]!.add(repeatedTask);
            }
          }
        }
      }
      
      // Sort tasks for the current day separately
      final selectedDateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final todayTasks = tasksByDate[selectedDateKey] ?? [];
      
      // Sort by start time (from earliest to latest)
      todayTasks.sort((a, b) {
        final aStartComponents = a.startTime.split(':');
        final bStartComponents = b.startTime.split(':');
        
        final aStartHour = int.parse(aStartComponents[0]);
        final bStartHour = int.parse(bStartComponents[0]);
        
        if (aStartHour != bStartHour) return aStartHour.compareTo(bStartHour);
        
        final aStartMinute = int.parse(aStartComponents[1]);
        final bStartMinute = int.parse(bStartComponents[1]);
        
        return aStartMinute.compareTo(bStartMinute);
      });

      // Update the task map, which will automatically update the _currentDayTasks getter
      setState(() {
        _tasksByDate = tasksByDate;
        _isLoading = false;
      });
      
      print('Loaded ${tasks.length} tasks');
      print('Tasks for ${DateFormat('yyyy-MM-dd').format(_selectedDate)}: ${_currentDayTasks.length}');
      
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TaskEntity> get _currentDayTasks {
    final selectedDateKey =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    final tasks = _tasksByDate[selectedDateKey] ?? [];
    
    // Additionally sort on each getter access to ensure correct order
    if (tasks.isNotEmpty) {
      tasks.sort((a, b) {
        final aStartComponents = a.startTime.split(':');
        final bStartComponents = b.startTime.split(':');
        
        final aStartHour = int.parse(aStartComponents[0]);
        final bStartHour = int.parse(bStartComponents[0]);
        
        if (aStartHour != bStartHour) return aStartHour.compareTo(bStartHour);
        
        final aStartMinute = int.parse(aStartComponents[1]);
        final bStartMinute = int.parse(bStartComponents[1]);
        
        return aStartMinute.compareTo(bStartMinute);
      });
    }
    
    return tasks;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDay = focusedDay;
      _visibleMonth = focusedDay;
    });
    
    // Reload tasks for selected day
    final selectedDateKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    
    // Sort by start time (from earliest to latest)
    final dayTasks = _tasksByDate[selectedDateKey] ?? [];
    if (dayTasks.isNotEmpty) {
      dayTasks.sort((a, b) {
        final aStartComponents = a.startTime.split(':');
        final bStartComponents = b.startTime.split(':');
        
        final aStartHour = int.parse(aStartComponents[0]);
        final bStartHour = int.parse(bStartComponents[0]);
        
        if (aStartHour != bStartHour) return aStartHour.compareTo(bStartHour);
        
        final aStartMinute = int.parse(aStartComponents[1]);
        final bStartMinute = int.parse(bStartComponents[1]);
        
        return aStartMinute.compareTo(bStartMinute);
      });
      
      // Update the task map so the _currentDayTasks getter returns a sorted list
      setState(() {
        _tasksByDate[selectedDateKey] = dayTasks;
      });
    }
    
    _scrollToSelectedWeek();
  }

  void _scrollToSelectedWeek() {
    if (!_isCalendarExpanded) {
      final now = DateTime.now();
      final thisWeekMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final startDate = thisWeekMonday.subtract(const Duration(days: 7));
      
      final daysDifference = _selectedDate.difference(startDate).inDays;
      final initialOffset = daysDifference * 68.0;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_weekScrollController.hasClients) {
          _weekScrollController.animateTo(
            initialOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _toggleCalendar() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
      if (_isCalendarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _visibleMonth = _selectedDate;
        _scrollToSelectedWeek();
      }
    });
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final task = _currentDayTasks.firstWhere((t) => t.id == taskId);
      
      if (_notificationService == null) {
        _notificationService = await NotificationService.getInstance();
      }
      
      // Cancel notification
      try {
        await _notificationService!.cancelNotification(task.name.hashCode);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error canceling reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Delete task
      await _repository.deleteTask(taskId);
      _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task successfully deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(TaskEntity task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                task.repeatOption != 'Never' 
                    ? 'Delete Task?' 
                    : 'Delete Task?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Subtitle for repeating tasks
            if (task.repeatOption != 'Never')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  'This task repeats ${task.repeatOption.toLowerCase()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
            const SizedBox(height: 24),
            
            // Button options
            if (task.repeatOption != 'Never') ...[
              _buildDeleteButton(
                context,
                'Delete this occurrence',
                'Delete only this event',
                Icons.event_busy,
                () {
                  Navigator.pop(context);
                  _deleteTask(task.id);
                },
              ),
              const SizedBox(height: 12),
              _buildDeleteButton(
                context,
                'Delete all occurrences',
                'Delete all ${task.repeatOption.toLowerCase()} occurrences',
                Icons.delete_forever,
                () {
                  Navigator.pop(context);
                  _deleteTask(task.id.split('_')[0]);
                },
                isDestructive: true,
              ),
            ] else
              _buildDeleteButton(
                context,
                'Delete task',
                'This task will be permanently deleted',
                Icons.delete_outline,
                () {
                  Navigator.pop(context);
                  _deleteTask(task.id);
                },
              ),
            
            const SizedBox(height: 16),
            
            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF2F80ED),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context, 
    String title, 
    String subtitle, 
    IconData icon, 
    VoidCallback onPressed, 
    {bool isDestructive = false}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
          foregroundColor: isDestructive ? Colors.red : Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDestructive ? Colors.red.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFF2F80ED),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTaskCompletion(TaskEntity task) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      
      // Create a copy of the task with updated status
      final updatedTask = TaskEntity(
        id: task.id,
        name: task.name,
        note: task.note,
        date: task.date,
        startTime: task.startTime,
        endTime: task.endTime,
        category: task.category,
        remindMe: task.remindMe,
        reminderMinutes: task.reminderMinutes,
        repeatOption: task.repeatOption,
        userId: task.userId,
        isCompleted: !task.isCompleted,
        createdAt: task.createdAt,
      );

      await _repository.updateTask(updatedTask);
      
      // Use _refreshTasksAfterUpdate instead of _loadTasks to ensure proper UI refresh
      // and to update statistics
      _refreshTasksAfterUpdate();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedTask.isCompleted ? 'Task marked as completed' : 'Task marked as not completed'),
            backgroundColor: updatedTask.isCompleted ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F80ED),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2F80ED)),
            onPressed: _loadTasks,
            tooltip: 'Refresh tasks',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar section
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Calendar header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM y').format(_visibleMonth),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          InkWell(
                            onTap: _toggleCalendar,
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RotationTransition(
                                turns: _animation,
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF2F80ED),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Expanded calendar view
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _isCalendarExpanded
                            ? Container(
                                margin: const EdgeInsets.only(top: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: TableCalendar(
                                  firstDay: DateTime.now()
                                      .subtract(const Duration(days: 365)),
                                  lastDay: DateTime.now()
                                      .add(const Duration(days: 365 * 2)),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) =>
                                      isSameDay(_selectedDate, day),
                                  onDaySelected: _onDaySelected,
                                  onPageChanged: (focusedDay) {
                                    setState(() {
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  calendarFormat: CalendarFormat.month,
                                  eventLoader: (day) {
                                    final date =
                                        DateTime(day.year, day.month, day.day);
                                    return _tasksByDate[date] ?? [];
                                  },
                                  headerVisible: false,
                                  daysOfWeekStyle: const DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(
                                        color: Color(0xFF555555),
                                        fontWeight: FontWeight.w500),
                                    weekendStyle: TextStyle(
                                        color: Color(0xFF999999),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  calendarStyle: CalendarStyle(
                                    defaultTextStyle: const TextStyle(
                                        color: Color(0xFF333333)),
                                    weekendTextStyle: const TextStyle(
                                        color: Color(0xFF666666)),
                                    outsideTextStyle: const TextStyle(
                                        color: Color(0xFFCCCCCC)),
                                    selectedDecoration: const BoxDecoration(
                                      color: Color(0xFF2F80ED),
                                      shape: BoxShape.circle,
                                    ),
                                    todayDecoration: BoxDecoration(
                                      color: const Color(0xFF2F80ED)
                                          .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    markerDecoration: const BoxDecoration(
                                      color: Color(0xFF2F80ED),
                                      shape: BoxShape.circle,
                                    ),
                                    markerSize: 6,
                                    markersMaxCount: 1,
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    markerBuilder: (context, date, events) {
                                      if (events.isNotEmpty) {
                                        final tasks = events as List<TaskEntity>;
                                        final now = DateTime.now();
                                        final today = DateTime(now.year, now.month, now.day);
                                        final isPastDate = date.isBefore(today);
                                        final hasUncompletedTasks = tasks.any((task) => !task.isCompleted);
                                        
                                        return Positioned(
                                          bottom: 1,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: hasUncompletedTasks && isPastDate 
                                                  ? Colors.red 
                                                  : const Color(0xFF2F80ED).withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${tasks.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.only(top: 12),
                                child: _buildWeekDays(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tasks header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks for ${DateFormat('MMMM d, y').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tasks list
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading tasks...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _currentDayTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _currentDayTasks.length,
                            itemBuilder: (context, index) {
                              final task = _currentDayTasks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TaskItem(
                                  task: task,
                                  onToggle: () => _toggleTaskCompletion(task),
                                  onDelete: () => _showDeleteConfirmation(task),
                                  onTaskUpdate: () => _refreshTasksAfterUpdate(),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskPage()),
          );
          _refreshTasksAfterUpdate();
        },
        backgroundColor: const Color(0xFF2F80ED),
        elevation: 4,
        tooltip: 'Create new task',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildWeekDays() {
    final List<String> weekDays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    // Get the start date for the calendar view
    final now = DateTime.now();
    final thisWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startDate = thisWeekMonday.subtract(const Duration(days: 7));

    // Add scroll listener to update visible month
    if (!_weekScrollController.hasListeners) {
      _weekScrollController.addListener(() {
        if (_weekScrollController.hasClients) {
          final scrollPosition = _weekScrollController.position.pixels;
          final itemWidth = 68.0; // Width of each day item (60 + margins)
          final visibleDayIndex = (scrollPosition / itemWidth).floor();
          final visibleDate = startDate.add(Duration(days: visibleDayIndex));
          
          if (mounted && !isSameMonth(visibleDate, _visibleMonth)) {
            setState(() {
              _visibleMonth = visibleDate;
            });
          }
        }
      });
    }

    return Container(
      height: 100,
      child: ListView.builder(
        controller: _weekScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 28, // Show 4 weeks
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final isSelected = isSameDay(date, _selectedDate);
          final tasks = _tasksByDate[DateTime(date.year, date.month, date.day)] ?? [];
          final isPastDate = date.isBefore(DateTime(now.year, now.month, now.day));
          final hasUncompletedTasks = tasks.any((task) => !task.isCompleted);
          final isToday = isSameDay(date, now);

          return GestureDetector(
            onTap: () => _onDaySelected(date, date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekDays[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF2F80ED)
                          : isToday
                              ? Colors.black
                              : Colors.grey[600],
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF2F80ED)
                          : isToday
                              ? const Color(0xFFE6F0FF)
                              : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: const Color(0xFF2F80ED), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF2F80ED)
                                  : Colors.black87,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (tasks.isNotEmpty)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasUncompletedTasks && isPastDate 
                            ? Colors.red 
                            : const Color(0xFF2F80ED).withOpacity(0.9),
                      ),
                      child: Center(
                        child: Text(
                          '${tasks.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return const Color(0xFF98E7EF);
      case 'health':
        return const Color(0xFFFFCCCC);
      case 'work':
        return const Color(0xFFFDEAAC);
      case 'hmhmg':
        return const Color(0xFFD4A5FF);
      case 'smile':
        return const Color(0xFFA5FFB8);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 50,
              color: Color(0xFF2F80ED),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No tasks scheduled",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Create a new task to organize your day better",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7A7A7A),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
        ],
      ),
    );
  }

  Future<void> _refreshTasksAfterUpdate() async {
    print('Updating tasks after editing/postponing');
    await _loadTasks();
    
    // Scroll to current day (in case task date has changed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedWeek();
    });
    
    // Send notification about task changes so other pages (like HomePage) can update
    try {
      // Call global task update event if you have EventBus
      // Or you can use SharedPreferences to set a flag
      // which will lead to task updates when HomePage is next opened
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tasks_updated', true);
      await prefs.setInt('last_update_time', DateTime.now().millisecondsSinceEpoch);
      print('Task update flag set');
    } catch (e) {
      print('Error trying to update task flag: $e');
    }
  }
}

class _TaskItem extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback onTaskUpdate;

  const _TaskItem({
    required this.task,
    required this.onToggle,
    required this.onTaskUpdate,
    this.onDelete,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return const Color(0xFF98E7EF);
      case 'health':
        return const Color(0xFFFFCCCC);
      case 'work':
        return const Color(0xFFFDEAAC);
      case 'hmhmg':
        return const Color(0xFFD4A5FF);
      case 'smile':
        return const Color(0xFFA5FFB8);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  bool _isOverdue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    
    // For today's tasks, check end time
    if (taskDate.isAtSameMomentAs(today)) {
      final endTimeParts = task.endTime.split(':');
      final endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);
      final taskEndTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        endHour,
        endMinute,
      );
      return !task.isCompleted && now.isAfter(taskEndTime);
    }
    
    // If task is postponed (has '_' in ID)
    if (task.id.contains('_')) {
      // For postponed tasks check only the new date
      return !task.isCompleted && taskDate.isBefore(today);
    }
    
    // For regular tasks check if they're in the past
    return !task.isCompleted && taskDate.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = _isOverdue();
    
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Show menu with options
        return await showModalBottomSheet<bool>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.update, color: Color(0xFF2F80ED)),
                  title: const Text('Postpone task'),
                  onTap: () async {
                    Navigator.pop(context, false); // Close menu
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostponeTaskPage(task: task),
                      ),
                    );
                    // Update list after return if changes were made
                    if (result == true) {
                      onTaskUpdate();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete task'),
                  onTap: () {
                    // Close menu without confirming dismissible
                    Navigator.pop(context, false); 
                    // Call delete method directly
                    if (onDelete != null) {
                      onDelete!();
                    }
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) ?? false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.more_horiz,
          color: Colors.red,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TaskDetailsPage(task: task),
            ),
          );
          
          if (result == true) {
            onTaskUpdate();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(task.category),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted 
                              ? Colors.grey 
                              : (isOverdue ? Colors.red.withOpacity(0.8) : Colors.black),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.startTime} - ${task.endTime}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.category.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(task.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: task.isCompleted
                                  ? Colors.grey
                                  : _getCategoryColor(task.category).withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Always show the complete button for all tasks, including overdue ones
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? const Color(0xFF2F80ED)
                            : isOverdue 
                                ? Colors.red[400]!
                                : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? const Color(0xFF2F80ED)
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
