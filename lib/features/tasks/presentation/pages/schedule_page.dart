import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _SchedulePageState extends State<SchedulePage> {
  DateTime _selectedDate = DateTime.now();
  int _currentIndex = 1;
  List<TaskEntity> _tasks = [];
  bool _isLoading = true;
  final _repository = TaskRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final tasks = await _repository.getTasks(user.uid);
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка завантаження завдань: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TaskEntity> get _currentDayTasks {
    return _tasks.where((task) {
      final taskDate = DateFormat('yyyy-MM-dd').format(task.date);
      final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      return taskDate == selectedDate;
    }).toList();
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      _loadTasks(); // Перезавантажуємо список після видалення
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка видалення завдання: $e')),
      );
    }
  }

  void _toggleTaskCompletion(TaskEntity task) async {
    try {
      // Створюємо копію завдання з оновленим статусом
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
      _loadTasks(); // Перезавантажуємо список
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка оновлення завдання: $e')),
      );
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
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildWeekDays(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(4),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(
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
                      )
                    : _currentDayTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _currentDayTasks.length,
                            itemBuilder: (context, index) {
                              final task = _currentDayTasks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
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
                                    );
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
          _loadTasks(); // Перезавантажуємо після створення нового завдання
        },
        backgroundColor: const Color(0xFF2F80ED),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Personal':
        return const Color(0xFF98E7EF);
      case 'Health':
        return const Color(0xFFFFCCCC);
      case 'Work':
        return const Color(0xFFFDEAAC);
      default:
        return Colors.grey;
    }
  }

  List<Widget> _buildWeekDays() {
    final List<String> weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final List<Widget> days = [];

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - i - 1),
      );
      final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                         DateFormat('yyyy-MM-dd').format(_selectedDate);

      days.add(
        GestureDetector(
          onTap: () => _onDaySelected(date),
          child: Column(
            children: [
              Text(
                weekDays[i],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFF2F80ED) : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF2F80ED) : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    date.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return days;
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
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // Показуємо нижню панель з опціями
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
                    ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.blue),
                      title: const Text('Відтермінувати'),
                      onTap: () {
                        Navigator.pop(context); // Закриваємо bottom sheet
                        if (onEdit != null) {
                          onEdit!(); // Викликаємо функцію відтермінування
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Видалити', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context); // Закриваємо bottom sheet
                        if (onDelete != null) {
                          onDelete!(); // Викликаємо функцію видалення
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Завдання видалено'),
                              duration: Duration(seconds: 2),
                            ),
                          );
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
                          child: const Text('Скасувати'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            return false; // Не видаляємо елемент автоматично
          }
          return false;
        },
        child: Row(
          children: [
            Container(
              width: 4,
              height: 64,
              decoration: BoxDecoration(
                color: task.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: task.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                              color: task.isDone ? Colors.grey : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.time,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: task.color.withOpacity(task.isDone ? 0.5 : 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isDone ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 2,
                          ),
                          color: task.isDone ? const Color(0xFF2F80ED) : Colors.transparent,
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
          ],
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