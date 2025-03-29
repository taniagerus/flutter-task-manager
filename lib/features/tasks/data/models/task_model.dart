import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  TaskModel({
    required super.id,
    required super.name,
    required super.note,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.category,
    required super.remindMe,
    required super.reminderMinutes,
    super.reminderDateTime,
    required super.repeatOption,
    required super.userId,
    required super.isCompleted,
    required super.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      name: json['name'] as String,
      note: json['note'] as String,
      date: (json['date'] as Timestamp).toDate(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      category: json['category'] as String,
      remindMe: json['remindMe'] as bool,
      reminderMinutes: json['reminderMinutes'] as int,
      reminderDateTime: json['reminderDateTime'] != null 
          ? (json['reminderDateTime'] as Timestamp).toDate()
          : null,
      repeatOption: json['repeatOption'] as String,
      userId: json['userId'] as String,
      isCompleted: json['isCompleted'] as bool,
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
      'reminderDateTime': reminderDateTime != null 
          ? Timestamp.fromDate(reminderDateTime!)
          : null,
      'repeatOption': repeatOption,
      'userId': userId,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskModel copyWith({
    String? id,
    String? name,
    String? note,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? category,
    bool? remindMe,
    int? reminderMinutes,
    DateTime? reminderDateTime,
    String? repeatOption,
    String? userId,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      remindMe: remindMe ?? this.remindMe,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      repeatOption: repeatOption ?? this.repeatOption,
      userId: userId ?? this.userId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
