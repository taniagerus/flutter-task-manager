class TaskEntity {
  final String id;
  final String name;
  final String note;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String category;
  final bool remindMe;
  final int reminderMinutes;
  final DateTime? reminderDateTime;
  final String repeatOption;
  final String userId;
  final bool isCompleted;
  final DateTime createdAt;

  TaskEntity({
    required this.id,
    required this.name,
    required this.note,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.remindMe,
    required this.reminderMinutes,
    this.reminderDateTime,
    required this.repeatOption,
    required this.userId,
    required this.isCompleted,
    required this.createdAt,
  });

  DateTime? calculateReminderDateTime() {
    if (!remindMe) return null;
    
    try {
      final [hours, minutes] = startTime.split(':').map(int.parse).toList();
      final taskDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hours,
        minutes,
      );
      
      return taskDateTime.subtract(Duration(minutes: reminderMinutes));
    } catch (e) {
      print('Помилка при розрахунку часу нагадування: $e');
      return null;
    }
  }
}
