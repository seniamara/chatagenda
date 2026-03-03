import 'package:chatboot/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TaskService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _tasks => _firestore.collection('tasks');

  Future<void> createTask(TaskModel task) async {
    try {
      await _tasks.add(task.toMap());
      Get.snackbar(
        'Sucesso', 
        'Agendamento realizado!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro', 
        'Falha ao agendar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Stream<QuerySnapshot> getUserTasks(String userId) {
    return _tasks
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true) // CORRIGIDO: 'data' para 'date'
        .snapshots();
  }

  // CORRIGIDO: Aceita bool e atualiza o campo correto
  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    try {
      await _tasks.doc(taskId).update({'isCompleted': isCompleted});
    } catch (e) {
      print('❌ Erro ao atualizar status: $e');
      Get.snackbar(
        'Erro',
        'Falha ao atualizar tarefa',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ADICIONADO: Método deleteTask
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasks.doc(taskId).delete();
      Get.snackbar(
        'Sucesso',
        'Tarefa excluída!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Erro ao excluir tarefa: $e');
      Get.snackbar(
        'Erro',
        'Falha ao excluir tarefa',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ADICIONADO: Método para atualizar tarefa completa
  Future<void> updateTask(TaskModel task) async {
    try {
      await _tasks.doc(task.id).update(task.toMap());
    } catch (e) {
      print('❌ Erro ao atualizar tarefa: $e');
    }
  }
}