import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/task_service.dart';
import 'package:meu_app/src/widgets/auth_background.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TasksUserScreen extends StatefulWidget {
  const TasksUserScreen({super.key});

  @override
  State<TasksUserScreen> createState() => _TasksUserScreenState();
}

class _TasksUserScreenState extends State<TasksUserScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  Future<List<Task>>? _tasksFuture;
  Timer? _ticker;
  final Map<String, int> _liveSeconds = <String, int>{};

  @override
  void initState() {
    super.initState();
    _tasksFuture = _taskService.listarMinhasTarefas();
    _startTicker();
  }

  Future<void> _reload() async {
    setState(() {
      _tasksFuture = _taskService.listarMinhasTarefas();
    });
    final List<Task> tasks = await _tasksFuture ?? <Task>[];
    _seedTimers(tasks);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_liveSeconds.isEmpty) return;
      setState(() {
        final List<String> keys = _liveSeconds.keys.toList();
        for (final String key in keys) {
          _liveSeconds[key] = (_liveSeconds[key] ?? 0) + 1;
        }
      });
    });
  }

  void _seedTimers(List<Task> tasks) {
    _liveSeconds.clear();
    final DateTime now = DateTime.now();
    for (final Task task in tasks) {
      if (!task.cronometroAtivo) {
        continue;
      }
      final int baseSeconds = task.tempoGasto * 60;
      final int extra = task.ultimaAtualizacaoCronometro == null
          ? 0
          : now
                .difference(task.ultimaAtualizacaoCronometro!)
                .inSeconds
                .clamp(0, 315360000);
      _liveSeconds[task.id] = baseSeconds + extra;
    }
  }

  String _formatSeconds(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  Future<void> _toggleTimer(Task task) async {
    try {
      final Task updated = await _taskService.controlarCronometro(
        tarefaId: task.id,
        iniciar: !task.cronometroAtivo,
      );
      if (!mounted) return;

      if (updated.cronometroAtivo) {
        _liveSeconds[updated.id] = updated.tempoGasto * 60;
      } else {
        _liveSeconds.remove(updated.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.cronometroAtivo
                ? 'Cronômetro iniciado.'
                : 'Cronômetro pausado.',
          ),
        ),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao controlar cronômetro: $error')),
      );
    }
  }

  Future<void> _exportTaskPdf(Task task) async {
    final pw.Document pdf = pw.Document();
    final String title = task.nome.isEmpty ? task.descricao : task.nome;
    final int tempoAtualSegundos = task.cronometroAtivo
        ? (_liveSeconds[task.id] ?? task.tempoGasto * 60)
        : task.tempoGasto * 60;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'Relatório da Tarefa',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Nome: $title'),
              pw.SizedBox(height: 6),
              pw.Text(
                'Descrição: ${task.descricao.isEmpty ? '-' : task.descricao}',
              ),
              pw.SizedBox(height: 6),
              pw.Text('Status: ${task.status.label}'),
              pw.SizedBox(height: 6),
              pw.Text('Prioridade: ${task.prioridade.label}'),
              pw.SizedBox(height: 6),
              pw.Text('Equipe: ${task.equipeNome ?? 'Não informada'}'),
              pw.SizedBox(height: 6),
              pw.Text(
                'Tempo estimado: ${task.tempoEstimado == null ? '-' : _formatSeconds(task.tempoEstimado! * 60)}',
              ),
              pw.SizedBox(height: 6),
              pw.Text('Tempo gasto: ${_formatSeconds(tempoAtualSegundos)}'),
              pw.SizedBox(height: 6),
              if (task.prazo != null)
                pw.Text(
                  'Data de entrega: ${task.prazo!.day.toString().padLeft(2, '0')}/${task.prazo!.month.toString().padLeft(2, '0')}/${task.prazo!.year}',
                ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'tarefa_${task.id}.pdf',
    );
  }

  Future<void> _updateStatus(Task task, TaskStatus status) async {
    try {
      await _taskService.atualizarStatusTarefa(
        tarefaId: task.id,
        status: status,
      );
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status atualizado para ${status.label}.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar status: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 390;
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AppNavigationDrawer(
          userType: 'user',
          currentRoute: '/user/tarefas',
          onLogout: _logout,
        ),
        appBar: AppBar(title: const Text('Minhas tarefas')),
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
                    Center(child: Text('Nenhuma tarefa atribuída no momento.')),
                  ],
                ),
              );
            }

            if (_liveSeconds.isEmpty &&
                tasks.any((Task task) => task.cronometroAtivo)) {
              _seedTimers(tasks);
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
                        colors: <Color>[Color(0xFF7E57C2), Color(0xFFFF3366)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Minhas tarefas',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Acompanhe seu trabalho diário',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
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
                    final String title = task.nome.isEmpty
                        ? task.descricao
                        : task.nome;
                    final int seconds = task.cronometroAtivo
                        ? (_liveSeconds[task.id] ?? task.tempoGasto * 60)
                        : task.tempoGasto * 60;

                    return Card(
                      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ListTile(
                              onTap: () =>
                                  context.push('/user/tarefas/${task.id}'),
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.task_alt),
                              title: Text(title),
                              subtitle: Text(
                                'Prioridade: ${task.prioridade.label} • Status: ${task.status.label}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                            if (task.tempoEstimado != null ||
                                task.tempoGasto > 0 ||
                                task.cronometroAtivo)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Tempo: ${_formatSeconds(seconds)}${task.tempoExcedido ? ' (excedido)' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            DropdownButtonFormField<TaskStatus>(
                              initialValue: task.status,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Status da tarefa',
                              ),
                              items: TaskStatus.values
                                  .map(
                                    (status) => DropdownMenuItem<TaskStatus>(
                                      value: status,
                                      child: Text(
                                        status.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (TaskStatus? status) {
                                if (status == null || status == task.status) {
                                  return;
                                }
                                _updateStatus(task, status);
                              },
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                if (task.tempoEstimado != null)
                                  OutlinedButton.icon(
                                    onPressed: () => _toggleTimer(task),
                                    icon: Icon(
                                      task.cronometroAtivo
                                          ? Icons.pause_circle_outline
                                          : Icons.play_circle_outline,
                                    ),
                                    label: Text(
                                      task.cronometroAtivo
                                          ? 'Pausar'
                                          : 'Iniciar',
                                    ),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => _exportTaskPdf(task),
                                  icon: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                  ),
                                  label: const Text('PDF'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
