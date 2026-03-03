import 'package:chatboot/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Configurações
  bool _notificationsEnabled = true;
  bool _taskReminders = true;
  bool _dailySummary = false;
  bool _notificationSound = true;
  
  // Metas pessoais
  final TextEditingController _goalController = TextEditingController();
  final List<Map<String, dynamic>> _userGoals = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    _loadGoals();
  }

  void _loadGoals() {
    _userGoals.addAll([
      {'id': '1', 'title': 'Completar 5 tarefas por dia', 'progress': 0.6},
      {'id': '2', 'title': 'Estudar Flutter 1h por dia', 'progress': 0.3},
      {'id': '3', 'title': 'Academia 3x por semana', 'progress': 0.8},
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _addGoal() {
    if (_goalController.text.isNotEmpty) {
      setState(() {
        _userGoals.add({
          'id': DateTime.now().toString(),
          'title': _goalController.text,
          'progress': 0.0,
        });
        _goalController.clear();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _removeGoal(String id) {
    setState(() {
      _userGoals.removeWhere((goal) => goal['id'] == id);
    });
    HapticFeedback.lightImpact();
  }

  void _updateGoalProgress(String id, double value) {
    setState(() {
      final index = _userGoals.indexWhere((g) => g['id'] == id);
      if (index != -1) {
        _userGoals[index]['progress'] = value;
      }
    });
  }

  void _toggleTheme(bool value) {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
    HapticFeedback.lightImpact();
  }

  void _showDeleteAccountDialog() {
    final AuthController authController = Get.find();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Excluir Conta',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tem certeza? Esta ação é irreversível e removerá todos os seus dados permanentemente.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authController.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conta excluída com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção: Aparência
              _buildSectionTitle('Aparência', Icons.palette),
              _buildCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, 
                                color: theme.colorScheme.primary),
                  ),
                  title: const Text('Modo Escuro'),
                  subtitle: Text(isDark ? 'Ativado' : 'Desativado'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: _toggleTheme,
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Seção: Notificações
              _buildSectionTitle('Notificações', Icons.notifications),
              _buildCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Ativar notificações'),
                      value: _notificationsEnabled,
                      onChanged: (value) => 
                          setState(() => _notificationsEnabled = value),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.notifications_active, 
                                         color: Colors.blue),
                      ),
                    ),
                    if (_notificationsEnabled) ...[
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Lembretes de tarefas'),
                        value: _taskReminders,
                        onChanged: (value) => 
                            setState(() => _taskReminders = value),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: const Icon(Icons.task_alt, 
                                           color: Colors.green),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Resumo diário'),
                        value: _dailySummary,
                        onChanged: (value) => 
                            setState(() => _dailySummary = value),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: const Icon(Icons.summarize, 
                                           color: Colors.orange),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Som'),
                        value: _notificationSound,
                        onChanged: (value) => 
                            setState(() => _notificationSound = value),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(Icons.volume_up, 
                                           color: Colors.purple),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Seção: Metas Pessoais
              _buildSectionTitle('Metas Pessoais', Icons.flag),
              _buildCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _goalController,
                              decoration: InputDecoration(
                                hintText: 'Nova meta...',
                                prefixIcon: const Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.1),
                              ),
                              onSubmitted: (_) => _addGoal(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            onPressed: _addGoal,
                            backgroundColor: theme.colorScheme.primary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    ..._userGoals.map((goal) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag, color: Colors.amber, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  goal['title'],
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () => _removeGoal(goal['id']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: goal['progress'],
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              goal['progress'] >= 0.7 
                                  ? Colors.green 
                                  : goal['progress'] >= 0.3 
                                      ? Colors.orange 
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Seção: Integrações
              _buildSectionTitle('Integrações', Icons.link),
              _buildCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        child: const Icon(Icons.calendar_today, 
                                         color: Colors.red),
                      ),
                      title: const Text('Google Calendar'),
                      subtitle: const Text('Sincronize seus eventos'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.mail, 
                                         color: Colors.blue),
                      ),
                      title: const Text('Outlook'),
                      subtitle: const Text('Conecte sua agenda'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Seção: Dados
              _buildSectionTitle('Dados', Icons.storage),
              _buildCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: const Icon(Icons.cloud_download, 
                                         color: Colors.green),
                      ),
                      title: const Text('Exportar dados'),
                      subtitle: const Text('Baixe suas informações'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: const Icon(Icons.backup, 
                                         color: Colors.orange),
                      ),
                      title: const Text('Fazer backup'),
                      subtitle: const Text('Proteja seus dados'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botão de perigo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showDeleteAccountDialog,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Excluir Conta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Text(
                'Versão 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Em breve! 🚀'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}