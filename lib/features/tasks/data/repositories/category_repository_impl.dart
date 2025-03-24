import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import 'package:flutter/material.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<CategoryEntity>> getCategories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      print('Отримано ${snapshot.docs.length} категорій з Firestore');

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        print('Дані категорії: $data');
        
        // Отримуємо дату створення, або використовуємо поточну дату якщо немає даних
        DateTime createdAt;
        try {
          createdAt = data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now();
        } catch (e) {
          print('Error parsing createdAt: $e');
          createdAt = DateTime.now();
        }
        
        final categoryEntity = CategoryEntity(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          colour: data['colour'] ?? '#2F80ED',
          icon: data['icon'] ?? 'category_outlined',
          userId: data['userId'] ?? '',
          createdAt: createdAt,
          isDefault: data['isDefault'] ?? false,
        );
        
        print('Створено CategoryEntity: ${categoryEntity.toString()}');
        return categoryEntity;
      }).toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  @override
  Future<void> createCategory({
    required String id,
    required String name,
    required Color color,
    required IconData icon,
    required String userId,
    bool isDefault = false,
  }) async {
    try {
      await _firestore.collection('categories').doc(id).set({
        'id': id,
        'name': name,
        'colour': '#${color.value.toRadixString(16).substring(2)}',
        'icon': _getIconName(icon),
        'userId': userId,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  String _getIconName(IconData icon) {
    print('Конвертація іконки в назву: $icon');
    print('Унікальний код іконки: ${icon.codePoint}');
    
    if (icon == Icons.school_outlined) return 'school_outlined';
    if (icon == Icons.groups_outlined) return 'groups_outlined';
    if (icon == Icons.home_outlined) return 'home_outlined';
    if (icon == Icons.favorite_outline) return 'favorite_outline';
    if (icon == Icons.flight_outlined) return 'flight_outlined';
    if (icon == Icons.edit_outlined) return 'edit_outlined';
    if (icon == Icons.shopping_cart_outlined) return 'shopping_cart_outlined';
    if (icon == Icons.fastfood_outlined) return 'fastfood_outlined';
    if (icon == Icons.fitness_center_outlined) return 'fitness_center_outlined';
    if (icon == Icons.directions_car_outlined) return 'directions_car_outlined';
    if (icon == Icons.sentiment_satisfied_outlined) return 'sentiment_satisfied_outlined';
    if (icon == Icons.card_giftcard_outlined) return 'card_giftcard_outlined';
    if (icon == Icons.person_outline) return 'person_outline';
    if (icon == Icons.work_outline) return 'work_outline';
    
    // Перевіряємо код іконки для альтернативної ідентифікації
    switch (icon.codePoint) {
      case 0xe559: return 'school_outlined';      // Icons.school_outlined
      case 0xe4ef: return 'groups_outlined';      // Icons.groups_outlined
      case 0xe318: return 'home_outlined';        // Icons.home_outlined
      case 0xe25c: return 'favorite_outline';     // Icons.favorite_outline
      case 0xe26f: return 'flight_outlined';      // Icons.flight_outlined
      case 0xe568: return 'edit_outlined';        // Icons.edit_outlined
      case 0xe8cc: return 'shopping_cart_outlined'; // Icons.shopping_cart_outlined
      case 0xe25a: return 'fastfood_outlined';    // Icons.fastfood_outlined
      case 0xe26e: return 'fitness_center_outlined'; // Icons.fitness_center_outlined
      case 0xe1d7: return 'directions_car_outlined'; // Icons.directions_car_outlined
      case 0xe815: return 'sentiment_satisfied_outlined'; // Icons.sentiment_satisfied_outlined
      case 0xe8f6: return 'card_giftcard_outlined'; // Icons.card_giftcard_outlined
      case 0xe7fd: return 'person_outline';       // Icons.person_outline
      case 0xe90a: return 'work_outline';         // Icons.work_outline
    }
    
    print('Невідома іконка, використовую значення за замовчуванням');
    return 'category_outlined';
  }
}
