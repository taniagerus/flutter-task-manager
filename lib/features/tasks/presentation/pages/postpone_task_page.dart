import 'package:flutter/material.dart';
import '../../domain/entities/task_entity.dart';

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
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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
            onPressed: () {
              // TODO: Implement save logic
              Navigator.pop(context);
            },
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