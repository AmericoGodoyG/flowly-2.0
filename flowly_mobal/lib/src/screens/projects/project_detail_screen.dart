import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/models/project.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/project_service.dart';
import 'package:meu_app/src/services/task_service.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';
import 'package:meu_app/src/widgets/task_card.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  late Future<(Project, List<Task>)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<(Project, List<Task>)> _loadData() async {
    try {
      final project = await _projectService.obterProjeto(widget.projectId);
      final tasks = await _taskService.listarTarefas(
        projetoId: widget.projectId,
      );
      return (project, tasks);
    } catch (e) {
      rethrow;
    }
  }

  void _reloadData() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Project, List<Task>)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Projeto')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Projeto')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reloadData,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final (project, tasks) = snapshot.data!;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            drawer: AppNavigationDrawer(
              userType: 'admin',
              currentRoute: '/admin/projetos/${project.id}',
              onLogout: _logout,
            ),
            appBar: AppBar(
              title: Text(project.nome),
              centerTitle: true,
              elevation: 0,
              actions: <Widget>[
                IconButton(
                  onPressed: () =>
                      context.go('/admin/projetos/editar/${project.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar projeto',
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Tarefas'),
                  Tab(text: 'Estatísticas'),
                  Tab(text: 'Detalhes'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Tasks Tab
                _buildTasksTab(project, tasks),
                // Statistics Tab
                _buildStatisticsTab(tasks),
                // Details Tab
                _buildDetailsTab(project),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                context.go('/admin/tarefas/criar?projectId=${project.id}');
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab(Project project, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.task_alt, size: 64, color: flowlyMutedText),
            SizedBox(height: 16),
            Text(
              'Nenhuma tarefa criada',
              style: TextStyle(
                fontSize: 16,
                color: flowlyMutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () {
            context.go('/admin/tarefas/${task.id}');
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab(List<Task> tasks) {
    final bool compact = MediaQuery.of(context).size.width < 390;
    final pendentes = tasks
        .where((t) => t.status == TaskStatus.pendente)
        .length;
    final emAndamento = tasks
        .where((t) => t.status == TaskStatus.emAndamento)
        .length;
    final concluidas = tasks
        .where((t) => t.status == TaskStatus.concluido)
        .length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 12 : 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF0B1F4D), Color(0xFF1E4FA8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Resumo do Projeto',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total de tarefas: ${tasks.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (compact) ...<Widget>[
            _StatCard(
              title: 'Pendentes',
              count: pendentes,
              color: Colors.orange,
              icon: Icons.schedule,
            ),
            const SizedBox(height: 10),
            _StatCard(
              title: 'Em Andamento',
              count: emAndamento,
              color: Colors.blue,
              icon: Icons.running_with_errors,
            ),
            const SizedBox(height: 10),
            _StatCard(
              title: 'Concluídas',
              count: concluidas,
              color: const Color(0xFF0D9C6E),
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 10),
            _StatCard(
              title: 'Total',
              count: tasks.length,
              color: flowlyMutedText,
              icon: Icons.list_alt,
            ),
          ] else ...<Widget>[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pendentes',
                    count: pendentes,
                    color: Colors.orange,
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Em Andamento',
                    count: emAndamento,
                    color: Colors.blue,
                    icon: Icons.running_with_errors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Concluídas',
                    count: concluidas,
                    color: const Color(0xFF0D9C6E),
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Total',
                    count: tasks.length,
                    color: flowlyMutedText,
                    icon: Icons.list_alt,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Project project) {
    final bool compact = MediaQuery.of(context).size.width < 390;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 12 : 16),
            decoration: BoxDecoration(
              color: flowlySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: flowlyBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Descrição',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  project.descricao,
                  style: const TextStyle(fontSize: 14, color: flowlyText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Informações',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('ID', project.id),
                  _buildInfoRow(
                    'Criado em',
                    project.criadoEm != null
                        ? '${project.criadoEm!.day}/${project.criadoEm!.month}/${project.criadoEm!.year}'
                        : 'N/A',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: flowlyMutedText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: flowlyMutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
