import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';
import '../core/services/task_service.dart';
import '../core/services/auth_service.dart';

class TaskController extends GetxController {
  final TaskService _taskService = Get.find<TaskService>();
  final AuthService _authService = Get.find<AuthService>();
  
  RxList<TaskModel> tasks = <TaskModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    ever(_authService.firebaseUser, (user) {
      if (user != null) {
        loadTasks();
      } else {
        tasks.clear();
      }
    });
  }

  Future<void> loadTasks() async {
    if (_authService.firebaseUser.value == null) return;
    
    isLoading.value = true;
    print('📥 Carregando tarefas...');
    
    try {
      _taskService.getUserTasks(_authService.firebaseUser.value!.uid)
          .listen((snapshot) {
        tasks.value = snapshot.docs.map((doc) {
          return TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        isLoading.value = false;
        print('✅ Tarefas carregadas: ${tasks.length}');
      }, onError: (error) {
        print('❌ Erro ao carregar tarefas: $error');
        isLoading.value = false;
        
        // Se for erro de índice, mostrar mensagem amigável
        if (error.toString().contains('index')) {
          Get.snackbar(
            'Atenção',
            'Configurando banco de dados... As tarefas aparecerão em instantes.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      });
    } catch (e) {
      print('❌ Erro: $e');
      isLoading.value = false;
    }
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? date,
    String? time,
    String? category,
    String? priority,
    String? location,
    int? colorValue,
  }) async {
    if (_authService.firebaseUser.value == null) return;
    
    final newTask = TaskModel(
      userId: _authService.firebaseUser.value!.uid,
      title: title,
      description: description,
      date: date ?? DateTime.now(),
      time: time ?? '${DateTime.now().hour}:00',
      category: category ?? 'Geral',
      priority: priority ?? 'Média',
      location: location,
      createdAt: DateTime.now(),
      colorValue: colorValue,
    );
    
    await _taskService.createTask(newTask);
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index].isCompleted = !tasks[index].isCompleted;
      tasks.refresh();
      
      await _taskService.updateTaskStatus(taskId, tasks[index].isCompleted);
    }
  }

  Future<void> deleteTask(String taskId) async {
    tasks.removeWhere((t) => t.id == taskId);
    await _taskService.deleteTask(taskId);
  }

  Future<void> editTask(TaskModel updatedTask) async {
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      tasks.refresh();
      await _taskService.updateTask(updatedTask);
    }
  }
}