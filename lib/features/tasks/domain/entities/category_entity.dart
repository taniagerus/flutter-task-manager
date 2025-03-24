import 'package:flutter/material.dart';

class CategoryEntity {
  final String id;
  final String name;
  final String colour;
  final String icon;
  final String userId;
  final DateTime createdAt;
  final bool isDefault;

  CategoryEntity({
    required this.id,
    required this.name,
    required this.colour,
    required this.icon,
    required this.userId,
    required this.createdAt,
    this.isDefault = false,
  });

  @override
  String toString() {
    return 'CategoryEntity(id: $id, name: $name, colour: $colour, icon: $icon, userId: $userId, createdAt: $createdAt, isDefault: $isDefault)';
  }
}
