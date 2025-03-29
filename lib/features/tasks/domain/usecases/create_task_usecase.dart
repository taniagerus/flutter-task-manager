import 'package:dartz/dartz.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../../../../core/error/failures.dart';

class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  Future<Either<Failure, void>> call(TaskEntity task) async {
    try {
      await repository.createTask(task);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Помилка при створенні завдання: $e'));
    }
  }
}















