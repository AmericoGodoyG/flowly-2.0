import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/core/config/api_config.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/models/task_comment.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/task_service.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    required this.taskId,
    required this.userType,
    super.key,
  });

  final String taskId;
  final String userType;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();

  Task? _task;
  List<TaskComment> _comments = <TaskComment>[];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    try {
      final data = await _taskService.obterDetalhesCompletos(widget.taskId);
      if (!mounted) {
        return;
      }
      setState(() {
        _task = data.task;
        _comments = data.comentarios;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar tarefa: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _addComment() async {
    final String text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _taskService.adicionarComentario(
        tarefaId: widget.taskId,
        texto: text,
      );
      _commentController.clear();
      await _loadDetails();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao comentar: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addSubtask() async {
    final String text = _subtaskController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    try {
      final Task task = await _taskService.adicionarSubtarefa(
        tarefaId: widget.taskId,
        descricao: text,
      );
      _subtaskController.clear();
      setState(() => _task = task);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar subtarefa: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleSubtask(String subId) async {
    try {
      final Task task = await _taskService.toggleSubtarefa(
        tarefaId: widget.taskId,
        subId: subId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _task = task);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar subtarefa: $error')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAttachment() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _taskService.adicionarAnexo(
        tarefaId: widget.taskId,
        file: File(result.files.single.path!),
      );
      await _loadDetails();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar anexo: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openAttachment(String relativeOrAbsoluteUrl) async {
    final String finalUrl = relativeOrAbsoluteUrl.startsWith('http')
        ? relativeOrAbsoluteUrl
        : '${ApiConfig.baseUrl}$relativeOrAbsoluteUrl';
    final Uri uri = Uri.parse(finalUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 390;
    final Task? task = _task;

    if (_loading && task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tarefa')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tarefa')),
        body: Center(
          child: FilledButton(
            onPressed: _loadDetails,
            child: const Text('Recarregar'),
          ),
        ),
      );
    }

    final bool isAdmin = widget.userType == 'admin';

    return Scaffold(
      drawer: AppNavigationDrawer(
        userType: widget.userType,
        currentRoute: isAdmin
            ? '/admin/tarefas/${task.id}'
            : '/user/tarefas/${task.id}',
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: const Text('Detalhes da Tarefa'),
        actions: <Widget>[
          if (isAdmin)
            IconButton(
              onPressed: () => context.go('/admin/tarefas/editar/${task.id}'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar tarefa',
            ),
          IconButton(
            onPressed: _loadDetails,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: ListView(
          padding: EdgeInsets.all(compact ? 12 : 16),
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(compact ? 14 : 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF0B1F4D), Color(0xFF7E57C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(label: Text(task.status.label)),
                      Chip(label: Text(task.prioridade.label)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.nome,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.descricao,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                    const SizedBox(height: 8),
                    _infoRow('Status', task.status.label),
                    _infoRow('Prioridade', task.prioridade.label),
                    _infoRow('Urgência', task.urgencia),
                    if (task.prazo != null)
                      _infoRow(
                        'Entrega',
                        '${task.prazo!.day.toString().padLeft(2, '0')}/${task.prazo!.month.toString().padLeft(2, '0')}/${task.prazo!.year}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Anexos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickAndUploadAttachment,
                          icon: const Icon(Icons.attach_file_rounded),
                          label: const Text('Anexar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (task.anexos.isEmpty)
                      const Text('Nenhum anexo ainda.')
                    else
                      ...task.anexos.map(
                        (TaskAttachment item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(item.nomeOriginal),
                          subtitle: Text(item.mimetype ?? 'Arquivo'),
                          trailing: const Icon(Icons.open_in_new_rounded),
                          onTap: () => _openAttachment(item.url),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Subtarefas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _subtaskController,
                            decoration: const InputDecoration(
                              hintText: 'Adicionar subtarefa',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _saving ? null : _addSubtask,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (task.subtarefas.isEmpty)
                      const Text('Sem subtarefas no momento.')
                    else
                      ...task.subtarefas.map(
                        (TaskSubtask sub) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: sub.concluida,
                          title: Text(sub.descricao),
                          onChanged: (_) => _toggleSubtask(sub.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Comentários',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Escreva um comentário',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _saving ? null : _addComment,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_comments.isEmpty)
                      const Text('Sem comentários ainda.')
                    else
                      ..._comments.map(
                        (TaskComment comment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.person, size: 16),
                          ),
                          title: Text(
                            comment.userName.isEmpty
                                ? 'Usuário'
                                : comment.userName,
                          ),
                          subtitle: Text(comment.texto),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: flowlyMutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: flowlyText)),
          ),
        ],
      ),
    );
  }
}
