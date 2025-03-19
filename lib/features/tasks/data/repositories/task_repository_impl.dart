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
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
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
}
