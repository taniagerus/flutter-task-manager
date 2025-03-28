import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
              print('Помилка перетворення документа: $e');
              return null;
            }
          })
          .where((task) => task != null)
          .cast<TaskEntity>()
          .toList();

      tasks.sort((a, b) => a.date.compareTo(b.date));
      
      return tasks;
    } catch (e) {
      print('Помилка завантаження завдань: $e');
      return [];
    }
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      
      if (task.date.isBefore(today)) {
        throw Exception('Cannot update task with past date');
      }

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
}
