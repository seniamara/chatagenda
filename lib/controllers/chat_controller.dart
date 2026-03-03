import 'package:get/get.dart';
import '../models/task_model.dart';
import '../core/services/task_service.dart';
import '../core/services/auth_service.dart';

class ChatController extends GetxController {
  final TaskService _taskService = Get.find<TaskService>();
  final AuthService _authService = Get.find<AuthService>();
  
  RxList<Map<String, String>> messages = <Map<String, String>>[].obs;
  RxString currentStep = 'initial'.obs;
  RxMap<String, String> tempAppointment = <String, String>{}.obs;
  RxList<TaskModel> userAppointments = <TaskModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _sendBotMessage('Olá! 👋 Sou seu assistente de agendamentos. Como posso ajudar?');
    
    ever(_authService.firebaseUser, (user) {
      if (user != null) {
        _loadUserAppointments(user.uid);
      }
    });
  }

  void _loadUserAppointments(String userId) {
    _taskService.getUserTasks(userId).listen((snapshot) {
      userAppointments.value = snapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    }, onError: (error) {
      print('❌ Erro ao carregar agendamentos: $error');
    });
  }

  void startQuickAppointment(String service) {
    tempAppointment['servico'] = service;
    currentStep.value = 'asking_date';
    _sendBotMessage('Ótimo! Para qual data você quer agendar $service?');
  }

  void _sendBotMessage(String text) {
    messages.add({'sender': 'bot', 'text': text});
  }

  void _sendUserMessage(String text) {
    messages.add({'sender': 'user', 'text': text});
  }

  void processMessage(String userMessage) {
    _sendUserMessage(userMessage);

    switch (currentStep.value) {
      case 'initial':
        _handleInitial(userMessage);
        break;
      case 'asking_service':
        _handleService(userMessage);
        break;
      case 'asking_date':
        _handleDate(userMessage);
        break;
      case 'asking_time':
        _handleTime(userMessage);
        break;
      case 'confirming':
        _handleConfirmation(userMessage);
        break;
      case 'listing':
        _handleListing(userMessage);
        break;
    }
  }

  void _handleInitial(String message) {
    if (message.toLowerCase().contains('agendar') || 
        message.toLowerCase().contains('marcar')) {
      currentStep.value = 'asking_service';
      _sendBotMessage('Qual serviço você deseja agendar? (Ex: Consulta, Reunião, Corte de cabelo)');
    } 
    else if (message.toLowerCase().contains('meus agendamentos') || 
             message.toLowerCase().contains('minhas tarefas')) {
      currentStep.value = 'listing';
      _showUserAppointments();
    }
    else if (message.toLowerCase().contains('horários') || 
             message.toLowerCase().contains('disponíveis')) {
      _showAvailableTimes();
    }
    else {
      _sendBotMessage('Posso ajudar você a agendar um horário. Diga "quero agendar" para começar!');
    }
  }

  void _handleService(String service) {
    tempAppointment['servico'] = service;
    currentStep.value = 'asking_date';
    _sendBotMessage('Ótimo! Para qual data? (Formato: DD/MM/AAAA)');
  }

  void _handleDate(String date) {
    tempAppointment['data'] = date;
    currentStep.value = 'asking_time';
    _sendBotMessage('Horários disponíveis: 09:00, 10:00, 11:00, 14:00, 15:00, 16:00\nQual você prefere?');
  }

  void _handleTime(String time) {
    tempAppointment['hora'] = time;
    currentStep.value = 'confirming';
    
    _sendBotMessage(
      '📋 Resumo do agendamento:\n'
      'Serviço: ${tempAppointment['servico']}\n'
      'Data: ${tempAppointment['data']}\n'
      'Hora: ${tempAppointment['hora']}\n\n'
      'Confirmar agendamento? (sim/não)'
    );
  }

  void _handleConfirmation(String answer) async {
    if (answer.toLowerCase() == 'sim') {
      if (_authService.firebaseUser.value == null) {
        _sendBotMessage('Você precisa estar logado para agendar. Por favor, faça login primeiro.');
        return;
      }

      final task = TaskModel(
        userId: _authService.firebaseUser.value!.uid,
        title: tempAppointment['servico'] ?? 'Agendamento',
        description: 'Agendamento via chat',
        date: _parseDate(tempAppointment['data']!),
        time: tempAppointment['hora'] ?? '12:00',
        category: 'Agendamento',
        priority: 'Média',
        createdAt: DateTime.now(),
        reminderTime: _parseDate(tempAppointment['data']!).subtract(const Duration(hours: 1)),
      );
      
      await _taskService.createTask(task);
      _sendBotMessage('✅ Agendamento confirmado! Enviaremos um lembrete próximo da data.');
      
      currentStep.value = 'initial';
      tempAppointment.clear();
    } else {
      _sendBotMessage('Ok, agendamento cancelado. Posso ajudar com algo mais?');
      currentStep.value = 'initial';
    }
  }

  void _handleListing(String message) {
    _showUserAppointments();
    currentStep.value = 'initial';
  }

  void _showUserAppointments() {
    if (userAppointments.isEmpty) {
      _sendBotMessage('Você não tem agendamentos no momento.');
    } else {
      _sendBotMessage('📅 Seus agendamentos:');
      for (var task in userAppointments.take(5)) {
        _sendBotMessage(
          '• ${task.title}\n'
          '  Data: ${task.date.day}/${task.date.month} às ${task.time}\n'
          '  Status: ${task.isCompleted ? "✅ Concluído" : "⏳ Pendente"}'
        );
      }
    }
  }

  void _showAvailableTimes() {
    _sendBotMessage(
      '📅 Horários disponíveis para hoje:\n'
      '• 09:00\n'
      '• 10:00\n'
      '• 11:00\n'
      '• 14:00\n'
      '• 15:00\n'
      '• 16:00\n'
      '• 17:00'
    );
  }

  DateTime _parseDate(String dateStr) {
    try {
      List<String> parts = dateStr.split('/');
      return DateTime(
        int.parse(parts[2]), 
        int.parse(parts[1]), 
        int.parse(parts[0])
      );
    } catch (e) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }
}