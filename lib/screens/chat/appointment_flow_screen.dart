import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/task_controller.dart';


class AppointmentFlowScreen extends StatefulWidget {
  const AppointmentFlowScreen({super.key});

  @override
  State<AppointmentFlowScreen> createState() => _AppointmentFlowScreenState();
}

class _AppointmentFlowScreenState extends State<AppointmentFlowScreen> {
  final ChatController _chatController = Get.find();
  final TaskController _taskController = Get.find();
  
  int _currentStep = 0;
  final Map<String, dynamic> _appointmentData = {};

  final List<Step> _steps = [
    Step(
      title: const Text('Serviço'),
      content: const ServiceSelector(),
      isActive: true,
    ),
    Step(
      title: const Text('Data'),
      content: const DateTimePicker(),
      isActive: false,
    ),
    Step(
      title: const Text('Horário'),
      content: const TimeSelector(),
      isActive: false,
    ),
    Step(
      title: const Text('Confirmar'),
      content: const ConfirmationView(),
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _currentStep < _steps.length - 1 
            ? () {
                setState(() {
                  _currentStep++;
                });
                HapticFeedback.lightImpact();
              }
            : null,
        onStepCancel: _currentStep > 0
            ? () {
                setState(() {
                  _currentStep--;
                });
              }
            : null,
        onStepTapped: (step) {
          setState(() {
            _currentStep = step;
          });
        },
        steps: _steps.map((step) {
          return Step(
            title: step.title,
            content: step.content,
            isActive: _steps.indexOf(step) <= _currentStep,
            state: _steps.indexOf(step) < _currentStep 
                ? StepState.complete 
                : StepState.indexed,
          );
        }).toList(),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Voltar'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == _steps.length - 1
                        ? () => _confirmAppointment()
                        : details.onStepContinue,
                    child: Text(_currentStep == _steps.length - 1 
                        ? 'Confirmar' 
                        : 'Continuar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmAppointment() async {
    // Salvar no Firebase
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    Navigator.pop(context); // Fecha o dialog
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Agendamento realizado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context); // Fecha a tela de fluxo
  }
}

// Widgets auxiliares para cada passo
class ServiceSelector extends StatelessWidget {
  const ServiceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'icon': Icons.medical_services, 'name': 'Consulta Médica', 'color': Colors.blue},
      {'icon': Icons.cut, 'name': 'Corte de Cabelo', 'color': Colors.purple},
      {'icon': Icons.meeting_room, 'name': 'Reunião', 'color': Colors.orange},
      {'icon': Icons.fitness_center, 'name': 'Treino', 'color': Colors.green},
      {'icon': Icons.spa, 'name': 'Massagem', 'color': Colors.teal},
      {'icon': Icons.pets, 'name': 'Veterinário', 'color': Colors.brown},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return InkWell(
          onTap: () {
            // Selecionar serviço
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: (service['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (service['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  service['icon'] as IconData,
                  size: 40,
                  color: service['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  service['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DateTimePicker extends StatelessWidget {
  const DateTimePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Selecione uma data',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)),
            onDateChanged: (date) {
              // Data selecionada
            },
          ),
        ),
      ],
    );
  }
}

class TimeSelector extends StatelessWidget {
  const TimeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final times = ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'];
    
    return Column(
      children: [
        const Text(
          'Horários disponíveis',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            return ChoiceChip(
              label: Text(time),
              selected: false,
              onSelected: (selected) {},
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ConfirmationView extends StatelessWidget {
  const ConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          'Revise as informações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildConfirmRow(Icons.medical_services, 'Serviço', 'Consulta Médica'),
                const Divider(),
                _buildConfirmRow(Icons.calendar_today, 'Data', '15/03/2024'),
                const Divider(),
                _buildConfirmRow(Icons.access_time, 'Horário', '14:00'),
                const Divider(),
                _buildConfirmRow(Icons.person, 'Profissional', 'Dr. Silva'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}// isso est feioe o usueio deveri poder perdsonlir  su tref