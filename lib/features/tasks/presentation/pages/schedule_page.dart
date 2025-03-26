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

  // Map to store tasks by date for quick lookup
  Map<DateTime, List<TaskEntity>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();

    // Initialize animation controller for calendar toggle
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final tasks = await _repository.getTasks(user.uid);

        // Group tasks by date for more efficient lookup
        final Map<DateTime, List<TaskEntity>> tasksByDate = {};
        for (var task in tasks) {
          final date = DateTime(task.date.year, task.date.month, task.date.day);
          if (tasksByDate[date] == null) {
            tasksByDate[date] = [];
          }
          tasksByDate[date]!.add(task);
        }

        setState(() {
          _tasksByDate = tasksByDate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<TaskEntity> get _currentDayTasks {
    final selectedDateKey =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _tasksByDate[selectedDateKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _toggleCalendar() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
      if (_isCalendarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                // Ideally implement undo functionality here
                _loadTasks();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleTaskCompletion(TaskEntity task) async {
    try {
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
      _loadTasks();
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
                            DateFormat('MMMM y').format(_selectedDate),
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
                                    markersMaxCount: 3,
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
                  if (_isLoading)
                    Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(4),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Tasks list
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _currentDayTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _currentDayTasks.length,
                            itemBuilder: (context, index) {
                              final task = _currentDayTasks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TaskItem(
                                  task: Task(
                                    title: task.name,
                                    time: '${task.startTime} - ${task.endTime}',
                                    category: task.category,
                                    color: _getCategoryColor(task.category),
                                    isDone: task.isCompleted,
                                  ),
                                  onToggle: () => _toggleTaskCompletion(task),
                                  onDelete: () => _deleteTask(task.id),
                                  onEdit: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostponeTaskPage(
                                          taskTitle: task.name,
                                        ),
                                      ),
                                    ).then((_) => _loadTasks());
                                  },
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
          _loadTasks();
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Loading your tasks...",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

    // Get Monday of the current week
    final monday =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final date = monday.add(Duration(days: i));
          final isSelected = isSameDay(date, _selectedDate);
          final hasTasks =
              _tasksByDate[DateTime(date.year, date.month, date.day)]
                      ?.isNotEmpty ??
                  false;
          final isToday = isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => _onDaySelected(date, date),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekDays[i],
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
                    width: 36,
                    height: 36,
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
                  if (hasTasks)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2F80ED),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTaskPage()),
              ).then((_) => _loadTasks());
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TaskItem({
    required this.task,
    required this.onToggle,
    this.onDelete,
    this.onEdit,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Icons.person;
      case 'health':
        return Icons.favorite;
      case 'work':
        return Icons.work;
      case 'hmhmg':
        return Icons.home_work;
      case 'smile':
        return Icons.sentiment_satisfied;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsPage(task: task),
          ),
        );
      },
      child: Dismissible(
        key: Key(task.title), // Ideally use a unique ID for each task
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.red),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // Show bottom sheet with options
            showModalBottomSheet(
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
                      leading: const Icon(Icons.schedule, color: Colors.blue),
                      title: const Text('Postpone'),
                      onTap: () {
                        Navigator.pop(context); // Close bottom sheet
                        if (onEdit != null) {
                          onEdit!(); // Call postpone function
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context); // Close bottom sheet
                        if (onDelete != null) {
                          onDelete!(); // Call delete function
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
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
            );
            return false; // Don't automatically dismiss
          }
          return false;
        },
        child: Card(
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: task.color.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Category color indicator and icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: task.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(task.category),
                    color: task.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Task details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.time,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: task.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isDone
                                    ? Colors.grey
                                    : task.color.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Completion toggle
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isDone
                            ? const Color(0xFF2F80ED)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: task.isDone
                          ? const Color(0xFF2F80ED)
                          : Colors.transparent,
                    ),
                    child: task.isDone
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

class Task {
  final String title;
  final String time;
  final String category;
  final Color color;
  final bool isDone;

  const Task({
    required this.title,
    required this.time,
    required this.category,
    required this.color,
    required this.isDone,
  });

  Task copyWith({
    String? title,
    String? time,
    String? category,
    Color? color,
    bool? isDone,
  }) {
    return Task(
      title: title ?? this.title,
      time: time ?? this.time,
      category: category ?? this.category,
      color: color ?? this.color,
      isDone: isDone ?? this.isDone,
    );
  }
}
