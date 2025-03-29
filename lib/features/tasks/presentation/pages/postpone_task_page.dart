import 'package:flutter/material.dart';
import '../../domain/entities/task_entity.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../../../services/notification_service.dart';

class PostponeTaskPage extends StatefulWidget {
  final TaskEntity task;

  const PostponeTaskPage({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<PostponeTaskPage> createState() => _PostponeTaskPageState();
}

class _PostponeTaskPageState extends State<PostponeTaskPage> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late String repeatOption;
  late TextEditingController titleController;
  bool _remindMe = true;
  double _reminderTime = 30;

  bool _isValidReminderTime() {
    final taskDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );

    final reminderDateTime = taskDateTime.subtract(
      Duration(minutes: _reminderTime.round()),
    );

    return reminderDateTime.isAfter(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.task.date;
    startTime = TimeOfDay.fromDateTime(
      DateTime.parse('2023-01-01 ${widget.task.startTime}:00'),
    );
    endTime = TimeOfDay.fromDateTime(
      DateTime.parse('2023-01-01 ${widget.task.endTime}:00'),
    );
    repeatOption = widget.task.repeatOption;
    titleController = TextEditingController(text: widget.task.name);
    _remindMe = widget.task.remindMe;
    _reminderTime = widget.task.reminderMinutes.toDouble();
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _saveChanges() async {
    try {
      if (_remindMe && !_isValidReminderTime()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Час нагадування не може бути в минулому'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Створюємо оновлене завдання
      final updatedTask = TaskEntity(
        id: widget.task.id,
        name: titleController.text,
        note: widget.task.note,
        date: selectedDate,
        startTime: startTime.format(context).replaceAll(' ', ''),
        endTime: endTime.format(context).replaceAll(' ', ''),
        category: widget.task.category,
        remindMe: _remindMe,
        reminderMinutes: _reminderTime.round(),
        repeatOption: repeatOption,
        userId: widget.task.userId,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Оновлюємо завдання в базі даних
      final repository = TaskRepositoryImpl();
      await repository.updateTask(updatedTask);

      // Оновлюємо нагадування
      if (_remindMe) {
        final notificationService = await NotificationService.getInstance();
        
        // Скасовуємо старе нагадування
        await notificationService.cancelNotification(widget.task.name.hashCode);

        // Встановлюємо нове нагадування
        final taskDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          startTime.hour,
          startTime.minute,
        );

        final reminderDateTime = taskDateTime.subtract(
          Duration(minutes: _reminderTime.round()),
        );

        await notificationService.showTaskNotification(
          'Нагадування: ${updatedTask.name}',
          'Завдання розпочнеться через ${_reminderTime.round()} хвилин',
          reminderDateTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Завдання успішно оновлено')),
        );
        Navigator.pop(context, true);
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Postpone Task',
          style: TextStyle(
            color: Color(0xFF2F80ED),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Enter task title',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2F80ED)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime now = DateTime.now();
                final DateTime today = DateTime(now.year, now.month, now.day);
                
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.isBefore(today) ? today : selectedDate,
                  firstDate: today,
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF2F80ED),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF2F80ED),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2F80ED),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          startTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF2F80ED),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            startTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('-'),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2F80ED),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          endTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF2F80ED),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            endTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildRepeatOption('Never'),
                  _buildRepeatOption('Daily'),
                  _buildRepeatOption('Weekly'),
                  _buildRepeatOption('Monthly'),
                ],
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
                    color: Color(0xFF333333),
                  ),
                ),
                Switch(
                  value: _remindMe,
                  onChanged: (value) {
                    setState(() {
                      _remindMe = value;
                    });
                  },
                  activeColor: const Color(0xFF2F80ED),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Slider(
              value: _reminderTime,
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: const Color(0xFF2F80ED),
              inactiveColor: const Color(0xFF2F80ED).withOpacity(0.2),
              label: '${_reminderTime.round()} minutes before',
              onChanged: _remindMe ? (value) {
                setState(() {
                  _reminderTime = value;
                });
              } : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saveChanges,
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
    );
  }

  Widget _buildRepeatOption(String option) {
    return InkWell(
      onTap: () => setState(() => repeatOption = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: option != 'Monthly'
                ? BorderSide(color: Colors.grey[300]!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(
              repeatOption == option
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: const Color(0xFF2F80ED),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              option,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 