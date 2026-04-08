import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/services/task_service.dart';
import 'package:meu_app/src/widgets/flowly_button.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({required this.projectId, this.taskId, super.key});

  final String projectId;
  final String? taskId;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TaskService _taskService = TaskService();

  DateTime? _selectedDate;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.definir;
  TaskPriority _selectedPriority = TaskPriority.definir;
  bool _isVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _loadTask();
    }
  }

  Future<void> _loadTask() async {
    try {
      final task = await _taskService.obterTarefa(widget.taskId!);
      _nameController.text = task.nome;
      _descriptionController.text = task.descricao;
      _selectedDate = task.prazo;
      _selectedDifficulty = task.dificuldade;
      _selectedPriority = task.prioridade;
      _isVisible = task.visivelAtodos;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.taskId == null) {
        // Create
        await _taskService.criarTarefa(
          nome: _nameController.text,
          descricao: _descriptionController.text,
          projetoId: widget.projectId,
          prazo: _selectedDate,
          dificuldade: _selectedDifficulty,
          prioridade: _selectedPriority,
          visivelAtodos: _isVisible,
        );
      } else {
        // Edit
        await _taskService.editarTarefa(
          tarefaId: widget.taskId!,
          nome: _nameController.text,
          descricao: _descriptionController.text,
          prazo: _selectedDate,
          dificuldade: _selectedDifficulty,
          prioridade: _selectedPriority,
          visivelAtodos: _isVisible,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.taskId == null ? 'Tarefa criada!' : 'Tarefa atualizada!',
            ),
            backgroundColor: const Color(0xFF0D9C6E),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskId == null ? 'Criar Tarefa' : 'Editar Tarefa'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Título da Tarefa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.task),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o título da tarefa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              // Date Picker
              GestureDetector(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Prazo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Selecionar data',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Difficulty
              DropdownButtonFormField<TaskDifficulty>(
                initialValue: _selectedDifficulty,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Dificuldade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.trending_up),
                ),
                items: TaskDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(
                      difficulty.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(
                    () => _selectedDifficulty = value ?? TaskDifficulty.definir,
                  );
                },
              ),
              const SizedBox(height: 16),
              // Priority
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Prioridade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(
                      priority.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(
                    () => _selectedPriority = value ?? TaskPriority.definir,
                  );
                },
              ),
              const SizedBox(height: 16),
              // Visibility Toggle
              SwitchListTile(
                title: const Text('Visível para todos'),
                value: _isVisible,
                onChanged: (value) => setState(() => _isVisible = value),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FlowlyButton(
                  onPressed: _submit,
                  isLoading: _isLoading,
                  label: widget.taskId == null ? 'Criar' : 'Salvar',
                  color: const Color(0xFF0D9C6E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
