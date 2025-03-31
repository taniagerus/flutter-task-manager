import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pages/schedule_page.dart';
import '../../../../services/notification_service.dart';
import '../../domain/repositories/task_repository.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskDetailsPage extends StatefulWidget {
  final TaskEntity task;

  const TaskDetailsPage({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late TimeRange _selectedTimeRange;
  late String _selectedCategory;
  bool _remindMe = true;
  String _repeatOption = 'Weekly';
  double _reminderTime = 30;
  bool _isLoadingCategories = true;

  final List<String> _defaultCategories = ['Personal', 'Health', 'Work'];
  final List<String> _repeatOptions = ['Daily', 'Weekly', 'Monthly', 'Never'];
  List<CategoryEntity> _categoriesFromDb = [];
  NotificationService? _notificationService;
  late final TaskRepository _repository;
  late final CategoryRepository _categoryRepository;

  @override
  void initState() {
    super.initState();
    _initServices().then((_) {
      _loadCategories();
    });
    
    _nameController = TextEditingController(text: widget.task.name);
    _noteController = TextEditingController(text: widget.task.note);
    _selectedDate = widget.task.date;

    // Парсимо час початку та кінця
    final startTime = _parseTimeString(widget.task.startTime);
    final endTime = _parseTimeString(widget.task.endTime);

    _selectedTimeRange = TimeRange(startTime: startTime, endTime: endTime);
    _selectedCategory = widget.task.category;

    // Initialize reminder settings from task
    _remindMe = widget.task.remindMe;
    _reminderTime = widget.task.reminderMinutes.toDouble();
    _repeatOption = widget.task.repeatOption;
  }

  Future<void> _initServices() async {
    try {
      _notificationService = await NotificationService.getInstance();
      _repository = TaskRepositoryImpl();
      _categoryRepository = CategoryRepositoryImpl();
    } catch (e) {
      print('Помилка при ініціалізації сервісів: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Помилка при налаштуванні сервісів'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final categories = await _categoryRepository.getCategories(user.uid);
        setState(() {
          _categoriesFromDb = categories;
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Помилка при завантаженні категорій: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Помилка при завантаженні категорій'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    // Parse "HH:mm" format
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _deleteTask() async {
    try {
      if (_notificationService == null) {
        _notificationService = await NotificationService.getInstance();
      }

      // Скасовуємо нотифікацію
      try {
        await _notificationService!
            .cancelNotification(widget.task.name.hashCode);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Помилка при скасуванні нагадування: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Видаляємо завдання
      await _repository.deleteTask(widget.task.name);

      if (mounted) {
        Navigator.pop(context, true); // Повертаємо true при видаленні
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Завдання успішно видалено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка при видаленні завдання: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isValidReminderTime() {
    final taskDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTimeRange.startTime.hour,
      _selectedTimeRange.startTime.minute,
    );

    final reminderDateTime = taskDateTime.subtract(
      Duration(minutes: _reminderTime.round()),
    );

    return reminderDateTime.isAfter(DateTime.now());
  }

  Future<void> _saveChanges() async {
    try {
      if (_notificationService == null) {
        _notificationService = await NotificationService.getInstance();
      }

      // Створюємо оновлене завдання
      final updatedTask = TaskEntity(
        id: widget.task.id,
        name: _nameController.text,
        note: _noteController.text,
        date: _selectedDate,
        startTime:
            _selectedTimeRange.startTime.format(context).replaceAll(' ', ''),
        endTime: _selectedTimeRange.endTime.format(context).replaceAll(' ', ''),
        category: _selectedCategory,
        remindMe: _remindMe,
        reminderMinutes: _reminderTime.round(),
        repeatOption: _repeatOption,
        userId: widget.task.userId,
        isCompleted: widget.task.isCompleted,
        createdAt: widget.task.createdAt,
      );

      // Якщо нагадування увімкнено, перевіряємо час
      if (_remindMe && !_isValidReminderTime()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Час нагадування не може бути в минулому'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Скасовуємо старе нагадування
      if (widget.task.remindMe) {
        await _notificationService!
            .cancelNotification(widget.task.name.hashCode);
      }

      // Оновлюємо завдання в базі даних
      await _repository.updateTask(updatedTask);

      // Встановлюємо нове нагадування, якщо потрібно
      if (_remindMe) {
        final taskDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTimeRange.startTime.hour,
          _selectedTimeRange.startTime.minute,
        );

        final reminderDateTime = taskDateTime.subtract(
          Duration(minutes: _reminderTime.round()),
        );

        await _notificationService!.showTaskNotification(
          'Нагадування: ${updatedTask.name}',
          'Завдання розпочнеться через ${_reminderTime.round()} хвилин',
          reminderDateTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Зміни успішно збережено')),
        );
        Navigator.pop(context, true); // Повертаємо true при збереженні змін
      }
    } catch (e) {
      print('Помилка при збереженні змін: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка при збереженні змін: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Task title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Note',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTimeRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${_selectedTimeRange.startTime.format(context).replaceAll(' ', '')} - ${_selectedTimeRange.endTime.format(context).replaceAll(' ', '')}',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: _isLoadingCategories 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? _getCategoryColor(category).withOpacity(0.2) 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _getCategoryColor(category)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? _getCategoryColor(category)
                                  : Colors.grey.shade800,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remind me before task starts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: _remindMe,
                  onChanged: (value) {
                    setState(() {
                      _remindMe = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              value: _reminderTime,
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: Colors.blue,
              inactiveColor: Colors.blue.withOpacity(0.2),
              label: '${_reminderTime.round()} minutes before',
              onChanged: _remindMe
                  ? (value) {
                      setState(() {
                        _reminderTime = value;
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Repeat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.repeat, size: 16, color: Colors.grey.shade700),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _repeatOptions.map((option) {
                final isSelected = option == _repeatOption;

                return Row(
                  children: [
                    Radio<String>(
                      value: option,
                      groupValue: _repeatOption,
                      onChanged: (value) {
                        setState(() {
                          _repeatOption = value!;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey.shade800,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text(
                                'Are you sure you want to delete this task?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  _deleteTask(); // Delete task and notification
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[100],
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTimeRange(BuildContext context) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: _selectedTimeRange.startTime,
    );

    if (startTime != null) {
      // Add one hour for end time by default
      final endHour = (startTime.hour + 1) % 24;
      final endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: endHour, minute: startTime.minute),
      );

      if (endTime != null) {
        setState(() {
          _selectedTimeRange =
              TimeRange(startTime: startTime, endTime: endTime);
        });
      }
    }
  }

  List<String> get _categories {
    List<String> categories = List.from(_defaultCategories);
    
    // Додаємо категорії з бази даних
    for (var category in _categoriesFromDb) {
      if (!categories.contains(category.name)) {
        categories.add(category.name);
      }
    }
    
    // Додаємо поточну категорію завдання, якщо її ще немає
    if (!categories.contains(widget.task.category)) {
      categories.add(widget.task.category);
    }
    
    return categories;
  }

  Color _getCategoryColor(String category) {
    // Спочатку перевіряємо, чи є категорія в базі даних
    for (var dbCategory in _categoriesFromDb) {
      if (dbCategory.name == category) {
        return _getColorFromHex(dbCategory.colour);
      }
    }
    
    // Потім перевіряємо стандартні категорії
    switch (category) {
      case 'Personal':
        return const Color(0xFF2F80ED); // Blue
      case 'Health':
        return const Color(0xFFFF9B9B); // Pink/Red
      case 'Work':
        return const Color(0xFFFFB156); // Orange
      default:
        return Colors.blue;
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class TimeRange {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeRange({required this.startTime, required this.endTime});
}


