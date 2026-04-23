import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/task_service.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';
import 'package:meu_app/src/widgets/auth_background.dart';

class KanbanUserScreen extends StatefulWidget {
  const KanbanUserScreen({super.key});

  @override
  State<KanbanUserScreen> createState() => _KanbanUserScreenState();
}

class _KanbanUserScreenState extends State<KanbanUserScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  Future<List<Task>>? _tasksFuture;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _taskService.listarMinhasTarefas();
  }

  Future<void> _reload() async {
    setState(() {
      _tasksFuture = _taskService.listarMinhasTarefas();
    });
    await _tasksFuture;
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  Future<void> _updateTaskStatus({
    required Task task,
    required TaskStatus nextStatus,
  }) async {
    if (_updatingStatus || nextStatus == task.status) {
      return;
    }

    setState(() {
      _updatingStatus = true;
    });

    try {
      await _taskService.atualizarStatusTarefa(
        tarefaId: task.id,
        status: nextStatus,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarefa movida para ${nextStatus.label}.')),
      );
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao mover tarefa: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AppNavigationDrawer(currentRoute: '/kanban', onLogout: _logout),
        appBar: AppBar(
          title: const Text('Kanban'),
          actions: <Widget>[
            IconButton(
              onPressed: _updatingStatus ? null : _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
            ),
          ],
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
                      Text('Erro ao carregar kanban: ${snapshot.error}'),
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
            final List<Task> pendentes = tasks
                .where((Task task) => task.status == TaskStatus.pendente)
                .toList();
            final List<Task> emAndamento = tasks
                .where((Task task) => task.status == TaskStatus.emAndamento)
                .toList();
            final List<Task> concluidas = tasks
                .where((Task task) => task.status == TaskStatus.concluido)
                .toList();

            if (tasks.isEmpty) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  children: const <Widget>[
                    SizedBox(height: 180),
                    Center(child: Text('Nenhuma tarefa para exibir no Kanban.')),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF7E57C2), Color(0xFFFF3366)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Quadro Kanban',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organize e atualize o status das suas tarefas.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.open_with_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Arraste e solte os cards entre as colunas para mudar o status.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _KanbanColumn(
                          title: 'Pendente',
                          color: const Color(0xFF6C757D),
                          columnStatus: TaskStatus.pendente,
                          tasks: pendentes,
                          updating: _updatingStatus,
                          onOpenTask: (Task task) => context.push('/user/tarefas/${task.id}'),
                          onStatusChanged: (Task task, TaskStatus next) =>
                              _updateTaskStatus(task: task, nextStatus: next),
                        ),
                        const SizedBox(width: 12),
                        _KanbanColumn(
                          title: 'Em Andamento',
                          color: const Color(0xFF1E88E5),
                          columnStatus: TaskStatus.emAndamento,
                          tasks: emAndamento,
                          updating: _updatingStatus,
                          onOpenTask: (Task task) => context.push('/user/tarefas/${task.id}'),
                          onStatusChanged: (Task task, TaskStatus next) =>
                              _updateTaskStatus(task: task, nextStatus: next),
                        ),
                        const SizedBox(width: 12),
                        _KanbanColumn(
                          title: 'Concluído',
                          color: const Color(0xFF2E7D32),
                          columnStatus: TaskStatus.concluido,
                          tasks: concluidas,
                          updating: _updatingStatus,
                          onOpenTask: (Task task) => context.push('/user/tarefas/${task.id}'),
                          onStatusChanged: (Task task, TaskStatus next) =>
                              _updateTaskStatus(task: task, nextStatus: next),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.columnStatus,
    required this.tasks,
    required this.updating,
    required this.onOpenTask,
    required this.onStatusChanged,
  });

  final String title;
  final Color color;
  final TaskStatus columnStatus;
  final List<Task> tasks;
  final bool updating;
  final void Function(Task task) onOpenTask;
  final void Function(Task task, TaskStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DragTarget<Task>(
                hitTestBehavior: HitTestBehavior.translucent,
                onWillAcceptWithDetails: (DragTargetDetails<Task> details) {
                  return !updating && details.data.status != columnStatus;
                },
                onAcceptWithDetails: (DragTargetDetails<Task> details) {
                  onStatusChanged(details.data, columnStatus);
                },
                builder:
                    (
                      BuildContext context,
                      List<Task?> candidateData,
                      List<dynamic> rejectedData,
                    ) {
                      final bool isDraggingOver = candidateData.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDraggingOver
                                ? color.withValues(alpha: 0.9)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          color: isDraggingOver
                              ? color.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: tasks.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: 18,
                                  bottom: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    isDraggingOver
                                        ? 'Solte aqui para mover'
                                        : 'Sem tarefas nesta coluna.\nArraste uma tarefa para cá.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Column(
                                children: tasks
                                    .map(
                                      (Task task) => _TaskKanbanCard(
                                        task: task,
                                        updating: updating,
                                        onOpen: () => onOpenTask(task),
                                        onStatusChanged: (TaskStatus status) =>
                                            onStatusChanged(task, status),
                                      ),
                                    )
                                    .toList(),
                              ),
                      );
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskKanbanCard extends StatelessWidget {
  const _TaskKanbanCard({
    required this.task,
    required this.updating,
    required this.onOpen,
    required this.onStatusChanged,
  });

  final Task task;
  final bool updating;
  final VoidCallback onOpen;
  final ValueChanged<TaskStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final String title = task.nome.isEmpty ? task.descricao : task.nome;

    Widget buildTaskCard({bool dragging = false}) {
      return Opacity(
        opacity: dragging ? 0.8 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: dragging ? 0.08 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.drag_indicator, size: 18, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    'Arraste',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onOpen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.descricao,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Prioridade: ${task.prioridade.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (task.equipeNome != null && task.equipeNome!.isNotEmpty)
                      Text(
                        'Equipe: ${task.equipeNome}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskStatus>(
                initialValue: task.status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mover para'),
                items: TaskStatus.values
                    .map(
                      (TaskStatus status) => DropdownMenuItem<TaskStatus>(
                        value: status,
                        child: Text(status.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: updating
                    ? null
                    : (TaskStatus? status) {
                        if (status == null || status == task.status) {
                          return;
                        }
                        onStatusChanged(status);
                      },
              ),
            ],
          ),
        ),
      );
    }

    return Draggable<Task>(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 290, child: buildTaskCard(dragging: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: buildTaskCard()),
      child: buildTaskCard(),
    );
  }
}
