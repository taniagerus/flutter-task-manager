import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_manager/features/auth/presentation/pages/welcome_page.dart';
import 'package:task_manager/services/auth_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_page.dart';
import 'schedule_page.dart';
import 'statistics_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:task_manager/services/notification_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _currentIndex = 3;
  bool _notificationsEnabled = true;
  User? get currentUser => FirebaseAuth.instance.currentUser;
  NotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    _initNotificationService();
  }

  Future<void> _initNotificationService() async {
    try {
      _notificationService = await NotificationService.getInstance();
      
      // Синхронізуємо стан нотифікацій з сервісом
      setState(() {
        _notificationsEnabled = _notificationService!.isNotificationsEnabled();
      });
      
    } catch (e) {
      print('Помилка при ініціалізації нотифікацій: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Помилка при налаштуванні нотифікацій'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
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
      default:
        setState(() {
          _currentIndex = index;
        });
    }
  }

  void _toggleNotifications(bool value) async {
    try {
      if (_notificationService == null) {
        _notificationService = await NotificationService.getInstance();
      }

      if (value) {
        // Запитуємо дозволи для нотифікацій
        final granted = await _notificationService!.requestNotificationPermissions();
        if (!granted) {
          throw Exception('Дозвіл на нотифікації не надано');
        }
      } else {
        // Скасовуємо всі нотифікації
        await _notificationService!.cancelAllNotifications();
      }
      
      // Встановлюємо стан нотифікацій у сервісі
      _notificationService!.setNotificationsEnabled(value);

      setState(() {
        _notificationsEnabled = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Нотифікації увімкнено' : 'Нотифікації вимкнено'),
            backgroundColor: value ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка при зміні налаштувань нотифікацій: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2F80ED),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF2F80ED).withOpacity(0.1),
                            child: Text(
                              currentUser?.displayName?[0].toUpperCase() ?? 
                              currentUser?.email?[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F80ED),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
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
                          child: Column(
                            children: [
                              _buildSettingItem(
                                'Notifications',
                                _notificationsEnabled,
                                _toggleNotifications,
                              ),
                              const Divider(height: 1),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Sign Out'),
                                        content: const Text('Are you sure you want to sign out?'),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              try {
                                                final authService = AuthService();
                                                await authService.signOut();
                                                if (context.mounted) {
                                                  context.read<AuthBloc>().add(SignOutRequested());
                                                  Navigator.of(context).pushAndRemoveUntil(
                                                    MaterialPageRoute(
                                                      builder: (context) => const WelcomePage(),
                                                    ),
                                                    (route) => false,
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        e.toString().replaceAll('Exception: ', ''),
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                      backgroundColor: Colors.red,
                                                      behavior: SnackBarBehavior.floating,
                                                      margin: const EdgeInsets.all(16),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Sign Out'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.logout_rounded,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Sign Out',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey.shade400,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildSettingItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF2F80ED),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2F80ED),
          ),
        ],
      ),
    );
  }
}