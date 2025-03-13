import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({Key? key}) : super(key: key);

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
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
  
  final List<String> _categories = ['Personal', 'Health', 'Work'];
  final List<String> _repeatOptions = ['Daily', 'Weekly', 'Monthly', 'Never'];

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              value: 30,
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: Colors.blue,
              inactiveColor: Colors.blue.withOpacity(0.2),
              onChanged: (value) {
                // Handle slider change
              },
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
                onPressed: () {
                  // Create task logic here
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
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
          _selectedTimeRange = TimeRange(startTime: startTime, endTime: endTime);
        });
      }
    }
  }
  
  Color _getCategoryColor(String category) {
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