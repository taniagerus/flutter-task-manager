import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../../../services/notification_service.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({Key? key}) : super(key: key);

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  late final CreateTaskUseCase _createTaskUseCase;
  NotificationService? _notificationService;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeRange _selectedTimeRange = TimeRange(
    startTime: const TimeOfDay(hour: 14, minute: 0),
    endTime: const TimeOfDay(hour: 15, minute: 0),
  );
  
  String _selectedCategory = 'Personal';
  bool _remindMe = false;
  String _repeatOption = 'Weekly';
  
  final List<String> _repeatOptions = ['Daily', 'Weekly', 'Monthly', 'Never'];

  double _reminderTime = 30;

  late final CategoryRepositoryImpl _categoryRepository;
  List<CategoryEntity> _categoriesFromDb = [];

  @override
  void initState() {
    super.initState();
    _createTaskUseCase = CreateTaskUseCase(TaskRepositoryImpl());
    _categoryRepository = CategoryRepositoryImpl();
    _loadCategories();
    _initNotificationService();
  }

  Future<void> _initNotificationService() async {
    _notificationService = await NotificationService.getInstance();
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final categories = await _categoryRepository.getCategories(user.uid);
      setState(() {
        _categoriesFromDb = categories;
      });
    }
  }

  List<String> get _categories {
    List<String> defaultCategories = ['Personal', 'Health', 'Work'];
    
    for (var category in _categoriesFromDb) {
      if (!defaultCategories.contains(category.name)) {
        defaultCategories.add(category.name);
      }
    }
    
    return defaultCategories;
  }

  Color _getCategoryColor(String category) {
    for (var dbCategory in _categoriesFromDb) {
      if (dbCategory.name == category) {
        return _getColorFromHex(dbCategory.colour);
      }
    }
    
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

  bool _isValidReminderTime() {
    final taskDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTimeRange.startTime.hour,
      _selectedTimeRange.startTime.minute,
    ).toUtc();

    final reminderDateTime = taskDateTime.subtract(
      Duration(minutes: _reminderTime.round()),
    );

    return reminderDateTime.isAfter(DateTime.now());
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
          'Create task',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                decoration: const InputDecoration(
                  hintText: 'Task title',
                ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                child: ListView.builder(
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
                onChanged: _remindMe ? (value) {
                  setState(() {
                    _reminderTime = value;
                  });
                } : null,
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
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTimeRange(BuildContext context) async {
    final TimeOfDay now = TimeOfDay.now();
    final bool isToday = _selectedDate.year == DateTime.now().year &&
                         _selectedDate.month == DateTime.now().month &&
                         _selectedDate.day == DateTime.now().day;
    
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: _selectedTimeRange.startTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
    
    if (startTime != null) {
      if (isToday && startTime.hour < now.hour || 
         (startTime.hour == now.hour && startTime.minute < now.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot select past time')),
        );
        return;
      }

      final endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: (startTime.hour + 1) % 24,
          minute: startTime.minute,
        ),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
      );
      
      if (endTime != null) {
        if (endTime.hour < startTime.hour || 
           (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
          return;
        }

        setState(() {
          _selectedTimeRange = TimeRange(startTime: startTime, endTime: endTime);
        });
      }
    }
  }
  
  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Створення локального часу завдання
      final taskLocalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTimeRange.startTime.hour,
        _selectedTimeRange.startTime.minute,
      );
      
      // Конвертація в UTC для збереження
      final taskDateTimeUTC = taskLocalDateTime.toUtc();
      
      // Розрахунок часу нагадування в UTC
      final reminderDateTimeUTC = _remindMe 
          ? taskDateTimeUTC.subtract(Duration(minutes: _reminderTime.round()))
          : null;
      
      final task = TaskEntity(
        id: const Uuid().v4(),
        name: _nameController.text,
        note: _noteController.text,
        date: taskDateTimeUTC,
        startTime: '${_selectedTimeRange.startTime.hour.toString().padLeft(2, '0')}:${_selectedTimeRange.startTime.minute.toString().padLeft(2, '0')}',
        endTime: '${_selectedTimeRange.endTime.hour.toString().padLeft(2, '0')}:${_selectedTimeRange.endTime.minute.toString().padLeft(2, '0')}',
        category: _selectedCategory,
        remindMe: _remindMe,
        reminderMinutes: _reminderTime.round(),
        reminderDateTime: reminderDateTimeUTC,
        repeatOption: _repeatOption,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      
      final result = await _createTaskUseCase(task);
      
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (success) async {
          // Перед плануванням сповіщення спочатку запитуємо дозволи
          if (_remindMe && reminderDateTimeUTC != null) {
            final hasPermission = await _notificationService?.requestNotificationPermissions() ?? false;
            if (hasPermission) {
              try {
                await _notificationService?.showTaskNotification(
                  task.name,
                  'Завдання "${task.name}" починається через ${_reminderTime.round()} хвилин',
                  reminderDateTimeUTC,
                );
                print('Сповіщення заплановано на: ${reminderDateTimeUTC}');
              } catch (e) {
                print('Помилка при плануванні нотифікації: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Помилка при плануванні нагадування: $e')),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Не вдалося отримати дозвіл на сповіщення')),
                );
              }
            }
          }
          
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка при створенні завдання: $e')),
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
  
  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class TimeRange {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  
  TimeRange({required this.startTime, required this.endTime});
}