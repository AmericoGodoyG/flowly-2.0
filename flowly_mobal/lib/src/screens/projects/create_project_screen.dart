import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/services/project_service.dart';
import 'package:meu_app/src/widgets/flowly_button.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({this.teamId, this.projectId, super.key});

  final String? teamId;
  final String? projectId;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ProjectService _projectService = ProjectService();

  bool _isLoading = false;
  String? _resolvedTeamId;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadProject();
    }
  }

  Future<void> _loadProject() async {
    try {
      final project = await _projectService.obterProjeto(widget.projectId!);
      _nameController.text = project.nome;
      _descriptionController.text = project.descricao;
      _resolvedTeamId = widget.teamId ?? project.equipeId;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? teamId = widget.teamId ?? _resolvedTeamId;
      if (teamId == null || teamId.isEmpty) {
        throw Exception('Equipe não informada');
      }

      if (widget.projectId == null) {
        // Create
        await _projectService.criarProjeto(
          nome: _nameController.text,
          descricao: _descriptionController.text,
          equipeId: teamId,
        );
      } else {
        // Edit
        await _projectService.editarProjeto(
          projetoId: widget.projectId!,
          nome: _nameController.text,
          descricao: _descriptionController.text,
          equipeId: teamId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.projectId == null
                  ? 'Projeto criado!'
                  : 'Projeto atualizado!',
            ),
            backgroundColor: const Color(0xFF0D9C6E),
          ),
        );
        if (widget.projectId != null) {
          context.pop();
        } else {
          context.go('/projetos');
        }
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
        title: Text(
          widget.projectId == null ? 'Criar Projeto' : 'Editar Projeto',
        ),
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
                style: const TextStyle(color: flowlyText),
                cursorColor: flowlyPrimary,
                decoration: InputDecoration(
                  labelText: 'Nome do Projeto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.folder, color: flowlyMutedText),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome do projeto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: flowlyText),
                cursorColor: flowlyPrimary,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.description,
                    color: flowlyMutedText,
                  ),
                ),
                minLines: 3,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FlowlyButton(
                  onPressed: _submit,
                  isLoading: _isLoading,
                  label: widget.projectId == null ? 'Criar' : 'Salvar',
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
