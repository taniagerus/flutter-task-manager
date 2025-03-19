import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<void> createTask(TaskEntity task);
  Future<List<TaskEntity>> getTasks(String userId);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String taskId);
}
