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
    required this.repeatOption,
    required this.userId,
    this.isCompleted = false,
    required this.createdAt,
  });
}
