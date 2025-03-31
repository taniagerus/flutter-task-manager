import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createTask(TaskEntity task) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      
      if (task.date.isBefore(today)) {
        throw Exception('Cannot create task with past date');
      }

      await _firestore.collection('tasks').doc(task.id).set({
        'id': task.id,
        'name': task.name,
        'note': task.note,
        'date': task.date,
        'startTime': task.startTime,
        'endTime': task.endTime,
        'category': task.category,
        'remindMe': task.remindMe,
        'repeatOption': task.repeatOption,
        'userId': task.userId,
        'isCompleted': task.isCompleted,
        'createdAt': task.createdAt,
        'reminderMinutes': task.reminderMinutes,
      });
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  @override
  Future<List<TaskEntity>> getTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final tasks = snapshot.docs
          .map((doc) {
            try {
              return TaskModel.fromJson(doc.data());
            } catch (e) {
              print('Error converting document: $e');
              return null;
            }
          })
          .where((task) => task != null)
          .cast<TaskEntity>()
          .toList();

      tasks.sort((a, b) => a.date.compareTo(b.date));
      
      return tasks;
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    try {
      final taskModel = TaskModel(
        id: task.id,
        name: task.name,
        note: task.note,
        date: task.date,
        startTime: task.startTime,
        endTime: task.endTime,
        category: task.category,
        remindMe: task.remindMe,
        repeatOption: task.repeatOption,
        userId: task.userId,
        isCompleted: task.isCompleted,
        createdAt: task.createdAt,
        reminderMinutes: task.reminderMinutes,
      );

      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(taskModel.toJson());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<Map<String, dynamic>> getTaskStatistics(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Set default date range to current week if not provided
      startDate ??= today.subtract(Duration(days: today.weekday - 1)); // Monday of current week
      endDate ??= startDate.add(const Duration(days: 6)); // Sunday of current week
      
      // Get all tasks for the user
      final tasks = await getTasks(userId);
      
      // Filter tasks within date range
      final tasksInRange = tasks.where((task) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        return (taskDate.isAfter(startDate!) || taskDate.isAtSameMomentAs(startDate)) && 
               (taskDate.isBefore(endDate!) || taskDate.isAtSameMomentAs(endDate));
      }).toList();
      
      // Group tasks by category
      final Map<String, List<TaskEntity>> tasksByCategory = {};
      for (var task in tasksInRange) {
        if (!tasksByCategory.containsKey(task.category)) {
          tasksByCategory[task.category] = [];
        }
        tasksByCategory[task.category]!.add(task);
      }
      
      // Calculate statistics
      final totalTasks = tasksInRange.length;
      final completedTasks = tasksInRange.where((task) => task.isCompleted).length;
      
      // Calculate overdue tasks (past tasks that are not completed)
      final overdueTasks = tasksInRange.where((task) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        
        if (taskDate.isAtSameMomentAs(today)) {
          // For today's tasks, check if end time has passed
          final endTimeParts = task.endTime.split(':');
          final endHour = int.parse(endTimeParts[0]);
          final endMinute = int.parse(endTimeParts[1]);
          
          final endDateTime = DateTime(
            today.year, today.month, today.day, endHour, endMinute
          );
          
          return !task.isCompleted && now.isAfter(endDateTime);
        }
        
        // For past dates
        return !task.isCompleted && taskDate.isBefore(today);
      }).length;
      
      // Pending tasks are those not completed and not overdue
      final pendingTasks = totalTasks - completedTasks - overdueTasks;
      
      // Calculate completion rate
      final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
      
      // Calculate category statistics
      final List<Map<String, dynamic>> categoryStats = [];
      tasksByCategory.forEach((category, categoryTasks) {
        final total = categoryTasks.length;
        final completed = categoryTasks.where((task) => task.isCompleted).length;
        final percentage = total > 0 ? (completed / total * 100).round() : 0;
        
        categoryStats.add({
          'name': category,
          'total': total,
          'completed': completed,
          'percentage': percentage,
        });
      });
      
      // Sort categories by total tasks (descending)
      categoryStats.sort((a, b) => b['total'].compareTo(a['total']));
      
      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'overdueTasks': overdueTasks,
        'pendingTasks': pendingTasks,
        'completionRate': completionRate,
        'categoryStats': categoryStats,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      rethrow;
    }
  }

  // Calculate task completion trends over time
  Future<Map<String, dynamic>> getTaskCompletionTrends(String userId, int days) async {
    try {
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day);
      final startDate = endDate.subtract(Duration(days: days - 1));
      
      final tasks = await getTasks(userId);
      
      final Map<String, Map<String, int>> dailyStats = {};
      
      // Initialize daily stats
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        dailyStats[dateStr] = {
          'total': 0,
          'completed': 0,
          'overdue': 0,
        };
      }
      
      // Calculate daily stats
      for (var task in tasks) {
        final taskDate = DateFormat('yyyy-MM-dd').format(task.date);
        if (dailyStats.containsKey(taskDate)) {
          dailyStats[taskDate]!['total'] = (dailyStats[taskDate]!['total'] ?? 0) + 1;
          
          if (task.isCompleted) {
            dailyStats[taskDate]!['completed'] = (dailyStats[taskDate]!['completed'] ?? 0) + 1;
          } else {
            final dateTime = DateTime(task.date.year, task.date.month, task.date.day);
            if (dateTime.isBefore(endDate)) {
              dailyStats[taskDate]!['overdue'] = (dailyStats[taskDate]!['overdue'] ?? 0) + 1;
            }
          }
        }
      }
      
      return {
        'dailyStats': dailyStats,
      };
    } catch (e) {
      print('Error getting task completion trends: $e');
      rethrow;
    }
  }
}
