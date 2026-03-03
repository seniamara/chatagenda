import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String uid;
  String? nome;
  String? email;
  String? telefone;
  String? fotoURL;
  DateTime? createdAt;
  int? taskStreak;
  int? totalTasks;

  UserModel({
    required this.uid,
    this.nome,
    this.email,
    this.telefone,
    this.fotoURL,
    this.createdAt,
    this.taskStreak = 0,
    this.totalTasks = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoURL': fotoURL,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : Timestamp.now(),
      'taskStreak': taskStreak,
      'totalTasks': totalTasks,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nome: map['nome'],
      email: map['email'],
      telefone: map['telefone'],
      fotoURL: map['fotoURL'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      taskStreak: map['taskStreak'] ?? 0,
      totalTasks: map['totalTasks'] ?? 0,
    );
  }

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      nome: user.displayName,
      email: user.email,
      fotoURL: user.photoURL,
      createdAt: DateTime.now(),
    );
  }
}