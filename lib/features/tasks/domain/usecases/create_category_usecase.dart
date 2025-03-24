import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';
import 'package:flutter/material.dart';

class CreateCategoryUseCase {
  final CategoryRepository repository;

  CreateCategoryUseCase(this.repository);

  Future<void> call({
    required String id,
    required String name,
    required Color color,
    required IconData icon,
    required String userId,
    bool isDefault = false,
  }) async {
    return await repository.createCategory(
      id: id,
      name: name,
      color: color,
      icon: icon,
      userId: userId,
      isDefault: isDefault,
    );
  }
}
