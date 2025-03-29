import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/repositories/category_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category_entity.dart';

class CreateCategoryPage extends StatefulWidget {
  const CreateCategoryPage({Key? key}) : super(key: key);

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFFFFCCCC);
  IconData _selectedIcon = Icons.flight_outlined;
  bool _isLoading = false;
  final _categoryRepository = CategoryRepositoryImpl();

  final List<Color> _colors = [
    const Color(0xFFFFCCCC), // Pink
    const Color(0xFFB8F5D4), // Green
    const Color(0xFF98E7EF), // Blue
    const Color(0xFFE5D1FA), // Purple
    const Color(0xFFFFE5CC), // Orange
    const Color(0xFFFDEAAC), // Yellow
    const Color(0xFFFFD6E5), // Rose
    const Color(0xFFE0E0E0), // Grey
  ];

  final List<IconData> _icons = [
    Icons.school_outlined,
    Icons.groups_outlined,
    Icons.home_outlined,
    Icons.favorite_outline,
    Icons.flight_outlined,
    Icons.edit_outlined,
    Icons.shopping_cart_outlined,
    Icons.fastfood_outlined,
    Icons.fitness_center_outlined,
    Icons.directions_car_outlined,
    Icons.sentiment_satisfied_outlined,
    Icons.card_giftcard_outlined,
  ];

  Future<void> _saveCategory() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final categoryId = const Uuid().v4();
      
      // Зберігаємо в репозиторії
      await _categoryRepository.createCategory(
        id: categoryId,
        name: _nameController.text,
        color: _selectedColor,
        icon: _selectedIcon,
        userId: user.uid,
        isDefault: false,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Помилка при створенні категорії: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create category: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Create category',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Trip',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Colour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _colors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: color == _selectedColor
                                    ? Border.all(color: const Color(0xFF2F80ED), width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Icon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: _icons.length,
                        itemBuilder: (context, index) {
                          final icon = _icons[index];
                          final isSelected = icon == _selectedIcon;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? _selectedColor : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? _selectedColor : Colors.grey[600],
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F80ED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}