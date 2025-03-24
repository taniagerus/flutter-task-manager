import '../entities/category_entity.dart';
import 'package:flutter/material.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories(String userId);
  Future<void> createCategory({
    required String id,
    required String name,
    required Color color,
    required IconData icon,
    required String userId,
    bool isDefault = false,
  });
}
