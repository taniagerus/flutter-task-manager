import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  TaskModel({
    required String id,
    required String name,
    required String note,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String category,
    required bool remindMe,
    required int reminderMinutes,
    required String repeatOption,
    required String userId,
    bool isCompleted = false,
    required DateTime createdAt,
  }) : super(
          id: id,
          name: name,
          note: note,
          date: date,
          startTime: startTime,
          endTime: endTime,
          category: category,
          remindMe: remindMe,
          reminderMinutes: reminderMinutes,
          repeatOption: repeatOption,
          userId: userId,
          isCompleted: isCompleted,
          createdAt: createdAt,
        );

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      note: json['note'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      category: json['category'] ?? '',
      remindMe: json['remindMe'] ?? false,
      reminderMinutes: json['reminderMinutes'] ?? 0,
      repeatOption: json['repeatOption'] ?? '',
      userId: json['userId'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'category': category,
      'remindMe': remindMe,
      'reminderMinutes': reminderMinutes,
      'repeatOption': repeatOption,
      'userId': userId,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
