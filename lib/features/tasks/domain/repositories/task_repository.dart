import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<void> createTask(TaskEntity task);
  Future<List<TaskEntity>> getTasks(String userId);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String taskId);
  Future<Map<String, dynamic>> getTaskStatistics(String userId, {DateTime? startDate, DateTime? endDate});
  Future<Map<String, dynamic>> getTaskCompletionTrends(String userId, int days);
}
