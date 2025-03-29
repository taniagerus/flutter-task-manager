import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav_bar.dart';
import 'schedule_page.dart';
import 'create_category_page.dart';
import 'statistics_page.dart';
import 'user_profile_page.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../data/repositories/task_repository_impl.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  User? get currentUser => FirebaseAuth.instance.currentUser;
  final _categoryRepository = CategoryRepositoryImpl();
  final _taskRepository = TaskRepositoryImpl();
  List<CategoryEntity> _userCategories = [];
  TaskEntity? _upcomingTask;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('HomePage: initState викликано');
    FirebaseAuth.instance.userChanges().listen((User? user) {
      if (mounted) {
        setState(() {});
        _loadCategories();
        _loadUpcomingTask();
      }
    });
    _loadCategories();
    _loadUpcomingTask();
    _createDefaultCategories();
  }

  Future<void> _loadCategories() async {
    print('HomePage: _loadCategories викликано');
    if (currentUser == null) {
      print('HomePage: користувач не авторизований');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await _categoryRepository.getCategories(currentUser!.uid);
      print('Завантажено категорій: ${categories.length}');
      categories.forEach((cat) {
        print('Категорія: ${cat.name}, ID: ${cat.id}, IconData: ${cat.icon}');
      });
      
      setState(() {
        _userCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Помилка завантаження категорій: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultCategories() async {
 
    try {
      // Перевіряємо, чи вже створені стандартні категорії
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isDefault', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        await _categoryRepository.createCategory(
          id: 'health-${currentUser!.uid}',
          name: 'Health',
          color: const Color(0xFFFFE5E5),
          icon: Icons.favorite_outline,
          userId: currentUser!.uid,
          isDefault: true,
        );

        await _categoryRepository.createCategory(
          id: 'personal-${currentUser!.uid}',
          name: 'Personal',
          color: const Color(0xFFE5F1FF),
          icon: Icons.person_outline,
          userId: currentUser!.uid,
          isDefault: true,
        );

        await _categoryRepository.createCategory(
          id: 'work-${currentUser!.uid}',
          name: 'Work',
          color: const Color(0xFFFFF4E5),
          icon: Icons.work_outline,
          userId: currentUser!.uid,
          isDefault: true,
        );

        // Оновлюємо список категорій
        print('HomePage: стандартні категорії створено, завантажуємо їх');
        _loadCategories();
      }
    } catch (e) {
      print('Помилка створення стандартних категорій: $e');
    }
  }

  Future<void> _loadUpcomingTask() async {
    if (currentUser == null) return;

    try {
      // Отримуємо всі завдання користувача
      final tasks = await _taskRepository.getTasks(currentUser!.uid);
      
      // Фільтруємо та сортуємо завдання
      final now = DateTime.now();
      final upcomingTasks = tasks.where((task) {
        // Парсимо дату та час завдання
        final taskDate = task.date;
        final timeComponents = task.startTime.split(':');
        final taskDateTime = DateTime(
          taskDate.year,
          taskDate.month,
          taskDate.day,
          int.parse(timeComponents[0]),
          int.parse(timeComponents[1]),
        );
        
        // Залишаємо тільки майбутні та незавершені завдання
        return taskDateTime.isAfter(now) && !task.isCompleted;
      }).toList();

      // Сортуємо за часом початку
      upcomingTasks.sort((a, b) {
        final aTime = _parseDateTime(a.date, a.startTime);
        final bTime = _parseDateTime(b.date, b.startTime);
        return aTime.compareTo(bTime);
      });

      setState(() {
        _upcomingTask = upcomingTasks.isNotEmpty ? upcomingTasks.first : null;
      });
    } catch (e) {
      print('Помилка при завантаженні найближчого завдання: $e');
    }
  }

  DateTime _parseDateTime(DateTime date, String timeString) {
    final timeComponents = timeString.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeComponents[0]),
      int.parse(timeComponents[1]),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SchedulePage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StatisticsPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfilePage()),
        );
        break;
      default:
        setState(() {
          _currentIndex = index;
        });
    }
  }

  // Конвертує колір з формату HEX в об'єкт Color
  Color _hexToColor(String hexString) {
    final hexColor = hexString.replaceFirst('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  // Конвертує назву іконки в об'єкт IconData
  IconData _getIconData(String iconName) {
    print('Отримана назва іконки: $iconName');
    
    // Перевірка на порожній рядок або null
    if (iconName.isEmpty) {
      print('Порожня назва іконки, використовую іконку за замовчуванням');
      return Icons.category_outlined;
    }
    
    // Фіксовані іконки для стандартних категорій
    // Це безпечний запасний варіант, якщо іконки не визначено правильно
    if (iconName == 'health' || iconName.contains('health')) {
      return Icons.favorite_outline;
    } else if (iconName == 'personal' || iconName.contains('personal')) {
      return Icons.person_outline;
    } else if (iconName == 'work' || iconName.contains('work')) {
      return Icons.work_outline;
    } else if (iconName == 'flight' || iconName.contains('flight')) {
      return Icons.flight_outlined;
    } else if (iconName == 'edit' || iconName.contains('edit')) {
      return Icons.edit_outlined;
    } else if (iconName == 'school' || iconName.contains('school')) {
      return Icons.school_outlined;
    }
    
    // Спрощена версія без лишніх суфіксів
    final simplifiedName = iconName.replaceAll('_outlined', '').replaceAll('_outline', '');
    print('Спрощена назва іконки: $simplifiedName');
    
    switch (simplifiedName) {
      case 'school': return Icons.school_outlined;
      case 'groups': return Icons.groups_outlined;
      case 'home': return Icons.home_outlined;
      case 'favorite': return Icons.favorite_outline;
      case 'flight': return Icons.flight_outlined;
      case 'edit': return Icons.edit_outlined;
      case 'shopping_cart': return Icons.shopping_cart_outlined;
      case 'fastfood': return Icons.fastfood_outlined;
      case 'fitness': 
      case 'fitness_center': return Icons.fitness_center_outlined;
      case 'car': 
      case 'directions_car': return Icons.directions_car_outlined;
      case 'smile': 
      case 'sentiment_satisfied': return Icons.sentiment_satisfied_outlined;
      case 'gift': 
      case 'card_giftcard': return Icons.card_giftcard_outlined;
      case 'person': return Icons.person_outline;
      case 'work': return Icons.work_outline;
      case 'category': return Icons.category_outlined;
      default:
        // Пробуємо обробити оригінальну назву (з суфіксом)
        switch (iconName) {
          case 'school_outlined': return Icons.school_outlined;
          case 'groups_outlined': return Icons.groups_outlined;
          case 'home_outlined': return Icons.home_outlined;
          case 'favorite_outline': return Icons.favorite_outline;
          case 'flight_outlined': return Icons.flight_outlined;
          case 'edit_outlined': return Icons.edit_outlined;
          case 'shopping_cart_outlined': return Icons.shopping_cart_outlined;
          case 'fastfood_outlined': return Icons.fastfood_outlined;
          case 'fitness_center_outlined': return Icons.fitness_center_outlined;
          case 'directions_car_outlined': return Icons.directions_car_outlined;
          case 'sentiment_satisfied_outlined': return Icons.sentiment_satisfied_outlined;
          case 'card_giftcard_outlined': return Icons.card_giftcard_outlined;
          case 'person_outline': return Icons.person_outline;
          case 'work_outline': return Icons.work_outline;
          case 'category_outlined': return Icons.category_outlined;
          default:
            print('Невідома іконка: $iconName, використовую іконку за замовчуванням');
            return Icons.category_outlined;
        }
    }
  }

  // Відображаємо стандартні категорії, коли список порожній
  List<Widget> _buildDefaultCategoryCards() {
    return [
      _CategoryCard(
        icon: Icons.favorite_outline,
        title: 'Health',
        color: const Color(0xFFFFE5E5),
        iconColor: const Color(0xFFFF9B9B),
        tasksLeft: 0,
        tasksDone: 0,
      ),
      _CategoryCard(
        icon: Icons.person_outline,
        title: 'Personal',
        color: const Color(0xFFE5F1FF),
        iconColor: const Color(0xFF2F80ED),
        tasksLeft: 0,
        tasksDone: 0,
      ),
      _CategoryCard(
        icon: Icons.work_outline,
        title: 'Work',
        color: const Color(0xFFFFF4E5),
        iconColor: const Color(0xFFFFB156),
        tasksLeft: 0,
        tasksDone: 0,
      ),
      _AddCategoryCard(
        onCategoryCreated: () {
          _loadCategories();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              
              const SizedBox(height: 32),
              // Greeting
              Text(
                'Hi ${currentUser?.displayName ?? "there"}!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Upcoming task card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _upcomingTask != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming task',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _upcomingTask!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_upcomingTask!.startTime}-${_upcomingTask!.endTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_upcomingTask!.date),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'No upcoming tasks',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              // Categories header
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Categories grid
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: _userCategories.isEmpty 
                      ? GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                          children: _buildDefaultCategoryCards(),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                          itemCount: _userCategories.length + 1, // +1 для кнопки створення нової категорії
                          itemBuilder: (context, index) {
                            // Остання карточка - це кнопка додавання нової категорії
                            if (index == _userCategories.length) {
                              return _AddCategoryCard(
                                onCategoryCreated: () {
                                  print('Викликано _loadCategories після створення категорії');
                                  _loadCategories();
                                },
                              );
                            }
                            
                            // Відображення існуючої категорії
                            final category = _userCategories[index];
                            print('Відображення категорії $index: ${category.name}, іконка: ${category.icon}');
                            
                            // Виправлено: встановлюємо конкретні іконки за назвою категорії
                            IconData iconData;
                            
                            // Визначаємо іконку на основі назви категорії (найбільш надійний спосіб)
                            final lowerCaseName = category.name.toLowerCase();
                            if (lowerCaseName.contains('health')) {
                              iconData = Icons.favorite_outline;
                            } else if (lowerCaseName.contains('personal')) {
                              iconData = Icons.person_outline;
                            } else if (lowerCaseName.contains('work')) {
                              iconData = Icons.work_outline;
                            } else if (lowerCaseName == 'hmhmg') {
                              iconData = Icons.home_outlined;
                            } else if (lowerCaseName.contains('home')) {
                              iconData = Icons.home_outlined;
                            } else if (lowerCaseName.contains('smile')) {
                              iconData = Icons.sentiment_satisfied_outlined;
                            } else if (lowerCaseName.contains('trip') || lowerCaseName.contains('travel')) {
                              iconData = Icons.flight_outlined;
                            } else if (lowerCaseName.contains('edit') || lowerCaseName.contains('write')) {
                              iconData = Icons.edit_outlined;
                            } else if (lowerCaseName.contains('school') || lowerCaseName.contains('study')) {
                              iconData = Icons.school_outlined;
                            } else if (lowerCaseName.contains('shop') || lowerCaseName.contains('cart')) {
                              iconData = Icons.shopping_cart_outlined;
                            } else if (lowerCaseName.contains('food')) {
                              iconData = Icons.fastfood_outlined;
                            } else if (lowerCaseName.contains('fitness') || lowerCaseName.contains('gym')) {
                              iconData = Icons.fitness_center_outlined;
                            } else if (lowerCaseName.contains('car') || lowerCaseName.contains('drive')) {
                              iconData = Icons.directions_car_outlined;
                            } else if (lowerCaseName.contains('gift')) {
                              iconData = Icons.card_giftcard_outlined;
                            } else if (category.icon.isNotEmpty) {
                              // Якщо назва категорії не містить відомих ключових слів, але є значення іконки
                              iconData = _getIconData(category.icon);
                            } else {
                              // Якщо нічого не підходить, використовуємо стандартну іконку
                              iconData = Icons.category_outlined;
                            }
                            
                            // Встановлюємо контрастний колір для іконки
                            Color iconColor;
                            if (lowerCaseName.contains('health')) {
                              iconColor = const Color(0xFFFF9B9B);
                            } else if (lowerCaseName.contains('personal')) {
                              iconColor = const Color(0xFF2F80ED);
                            } else if (lowerCaseName.contains('work')) {
                              iconColor = const Color(0xFFFFB156);
                            } else if (lowerCaseName.contains('trip') || lowerCaseName.contains('travel')) {
                              iconColor = const Color(0xFF56C2FF);
                            } else {
                              // Для інших категорій використовуємо темніший відтінок кольору категорії
                              final baseColor = _hexToColor(category.colour);
                              // Створюємо темніший відтінок для кращого контрасту
                              iconColor = HSLColor.fromColor(baseColor)
                                  .withSaturation(0.8)  // Збільшуємо насиченість
                                  .withLightness(0.4)   // Зменшуємо яскравість для темнішого кольору
                                  .toColor();
                            }
                            
                            print('Використовуємо іконку: $iconData для категорії ${category.name} з кольором $iconColor');
                            
                            return _CategoryCard(
                              icon: iconData,
                              title: category.name,
                              color: _hexToColor(category.colour),
                              iconColor: iconColor,
                              tasksLeft: 2,
                              tasksDone: 2,
                            );
                          },
                        ),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;
  final int tasksLeft;
  final int tasksDone;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.tasksLeft,
    required this.tasksDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TaskCountChip(
                count: tasksLeft,
                label: 'left',
                backgroundColor: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              _TaskCountChip(
                count: tasksDone,
                label: 'done',
                backgroundColor: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCountChip extends StatelessWidget {
  final int count;
  final String label;
  final Color backgroundColor;

  const _TaskCountChip({
    required this.count,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _AddCategoryCard extends StatelessWidget {
  final VoidCallback onCategoryCreated;

  const _AddCategoryCard({
    required this.onCategoryCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateCategoryPage()),
        );
        
        print('Результат після створення категорії: $result');
        
        if (result == true) {
          onCategoryCreated();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }
}
