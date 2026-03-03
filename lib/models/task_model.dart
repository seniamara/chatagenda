import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String? id;
  String userId;
  String title;
  String? description;
  DateTime date;
  String time;
  bool isCompleted;
  String priority;
  String category;
  DateTime? createdAt;
  DateTime? reminderTime;
  String? location;
  List<String>? participants;
  String? notes;
  int? duration;
  int? colorValue;

  TaskModel({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.isCompleted = false,
    this.priority = 'Média',
    this.category = 'Geral',
    this.createdAt,
    this.reminderTime,
    this.location,
    this.participants,
    this.notes,
    this.duration = 60,
    this.colorValue,
  });

  Color? get color => colorValue != null ? Color(colorValue!) : null;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date), // CORRIGIDO: Salvar como Timestamp
      'time': time,
      'isCompleted': isCompleted,
      'priority': priority,
      'category': category,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : Timestamp.now(),
      'reminderTime': reminderTime != null 
          ? Timestamp.fromDate(reminderTime!) 
          : null,
      'location': location,
      'participants': participants,
      'notes': notes,
      'duration': duration,
      'colorValue': colorValue,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    // CORRIGIDO: Tratar Timestamp corretamente
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return TaskModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      date: parseDate(map['date']),
      time: map['time'] ?? '12:00',
      isCompleted: map['isCompleted'] ?? false,
      priority: map['priority'] ?? 'Média',
      category: map['category'] ?? 'Geral',
      createdAt: parseDate(map['createdAt']),
      reminderTime: parseDate(map['reminderTime']),
      location: map['location'],
      participants: map['participants'] != null 
          ? List<String>.from(map['participants']) 
          : null,
      notes: map['notes'],
      duration: map['duration'] ?? 60,
      colorValue: map['colorValue'],
    );
  }
}