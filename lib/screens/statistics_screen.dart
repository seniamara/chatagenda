import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../widgets/custom.dart';
import '../../controllers/task_controller.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> 
    with SingleTickerProviderStateMixin {
  
  final TaskController _taskController = Get.find<TaskController>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedPeriod = 'Semana';
  final List<String> _periods = ['Dia', 'Semana', 'Mês'];
  
  int _streakDays = 7;
  final String _quote = '“O sucesso é a soma de pequenos esforços repetidos dia após dia.”';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _animationController.forward();
    
    _loadStatistics();
  }

  void _loadStatistics() {
    // TODO: Carregar do Firebase
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, int> _getCategoryStats() {
    final stats = <String, int>{};
    
    for (var task in _taskController.tasks) {
      stats[task.category] = (stats[task.category] ?? 0) + 1;
    }
    
    return stats;
  }

  Map<String, int> _getCompletedCategoryStats() {
    final stats = <String, int>{};
    
    for (var task in _taskController.tasks) {
      if (task.isCompleted) {
        stats[task.category] = (stats[task.category] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final categoryStats = _getCategoryStats();
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
    ];
    
    int index = 0;
    return categoryStats.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: entry.key,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    final totalTasks = _taskController.tasks.length;
    final completedTasks = _taskController.tasks.where((t) => t.isCompleted).length;
    final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Estatísticas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtro de período
                Center(
                  child: SegmentedButton<String>(
                    segments: _periods.map((p) => 
                      ButtonSegment(value: p, label: Text(p))
                    ).toList(),
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _selectedPeriod = selected.first;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Progresso geral
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Progresso Geral',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$completedTasks',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Concluídas'),
                              ],
                            ),
                            CircularPercentIndicator(
                              radius: 50,
                              lineWidth: 10,
                              percent: completionRate,
                              center: Text(
                                '${(completionRate * 100).toInt()}%',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              progressColor: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                            ),
                            Column(
                              children: [
                                Text(
                                  '$totalTasks',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Total'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Gráfico de categorias
                if (_getCategoryStats().isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Por Categoria',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieChartSections(),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._getCategoryStats().entries.map((entry) {
                            final total = entry.value;
                            final completed = _getCompletedCategoryStats()[entry.key] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text('$completed/$total concluídas'),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Sequência
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_streakDays dias',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sequência de produtividade',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _quote,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}//