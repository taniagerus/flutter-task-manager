import 'package:flutter/material.dart';

class PostponeTaskPage extends StatefulWidget {
  final String taskTitle;

  const PostponeTaskPage({
    Key? key,
    required this.taskTitle,
  }) : super(key: key);

  @override
  State<PostponeTaskPage> createState() => _PostponeTaskPageState();
}

class _PostponeTaskPageState extends State<PostponeTaskPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String repeatOption = 'Never';

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Postpone Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taskTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            const Text('Select date'),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2025),
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
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(selectedDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select time'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
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
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(startTime.format(context)),
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
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(endTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Repeat'),
            Row(
              children: [
                Radio(
                  value: 'Never',
                  groupValue: repeatOption,
                  onChanged: (value) => setState(() => repeatOption = value!),
                ),
                const Text('Never'),
                Radio(
                  value: 'Daily',
                  groupValue: repeatOption,
                  onChanged: (value) => setState(() => repeatOption = value!),
                ),
                const Text('Daily'),
                Radio(
                  value: 'Weekly',
                  groupValue: repeatOption,
                  onChanged: (value) => setState(() => repeatOption = value!),
                ),
                const Text('Weekly'),
                Radio(
                  value: 'Monthly',
                  groupValue: repeatOption,
                  onChanged: (value) => setState(() => repeatOption = value!),
                ),
                const Text('Monthly'),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // TODO: Implement save logic
                  Navigator.pop(context);
                },
                child: const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 