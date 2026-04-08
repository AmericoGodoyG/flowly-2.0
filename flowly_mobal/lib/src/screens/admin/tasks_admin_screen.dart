import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/task_service.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';

class TasksAdminScreen extends StatefulWidget {
  const TasksAdminScreen({super.key});

  @override
  State<TasksAdminScreen> createState() => _TasksAdminScreenState();
}

class _TasksAdminScreenState extends State<TasksAdminScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  Future<List<Task>>? _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _taskService.listarTarefas();
  }

  Future<void> _reload() async {
    setState(() {
      _tasksFuture = _taskService.listarTarefas();
    });
    await _tasksFuture;
  }

  Future<void> _deleteTask(Task task) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Excluir tarefa'),
              content: Text('Tem certeza que deseja excluir ${task.nome.isEmpty ? task.descricao : task.nome}?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await _taskService.excluirTarefa(task.id);
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarefa excluída com sucesso!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir tarefa: $error')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 390;
    return Scaffold(
      drawer: AppNavigationDrawer(
        userType: 'admin',
        currentRoute: '/admin/tarefas',
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: const Text('Admin - Tarefas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/tarefas/criar'),
        icon: const Icon(Icons.add),
        label: const Text('Criar tarefa'),
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Erro ao carregar tarefas: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<Task> tasks = snapshot.data ?? <Task>[];
          if (tasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: const <Widget>[
                  SizedBox(height: 160),
                  Center(child: Text('Nenhuma tarefa cadastrada ainda.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.all(compact ? 12 : 16),
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(compact ? 14 : 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF0B1F4D), Color(0xFF1E4FA8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Tarefas Admin',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gerencie todas as tarefas',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: compact ? 20 : 24,
                        backgroundColor: Colors.white24,
                        child: Text(
                          tasks.length.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 10 : 14),
                ...tasks.map((Task task) {
                  final String title = task.nome.isEmpty ? task.descricao : task.nome;
                  final Color statusColor = task.status == TaskStatus.concluido
                      ? const Color(0xFF0D9C6E)
                      : task.status == TaskStatus.emAndamento
                          ? Colors.blue
                          : Colors.orange;

                  return Card(
                    margin: EdgeInsets.only(bottom: compact ? 8 : 10),
                    child: InkWell(
                      onTap: () => context.go('/admin/tarefas/${task.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 10 : 12),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 4,
                              height: 56,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: compact ? 6 : 8,
                                    children: <Widget>[
                                      Chip(
                                        label: Text(task.status.label),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      Chip(
                                        label: Text(task.dificuldade.label),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (String value) {
                                if (value == 'edit') {
                                  context.go('/admin/tarefas/editar/${task.id}');
                                }
                                if (value == 'delete') {
                                  _deleteTask(task);
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem<String>(value: 'delete', child: Text('Excluir')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
