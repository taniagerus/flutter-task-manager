import 'package:flutter/material.dart';
import '../../domain/entities/task_entity.dart';
import '../pages/postpone_task_page.dart';
import '../pages/task_details_page.dart';

class TaskItem extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback onTaskUpdate;

  const TaskItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onTaskUpdate,
    this.onDelete,
  }) : super(key: key);

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return const Color(0xFF98E7EF);
      case 'health':
        return const Color(0xFFFFCCCC);
      case 'work':
        return const Color(0xFFFDEAAC);
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