import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/models/user.dart';
import 'package:meu_app/src/services/team_service.dart';
import 'package:meu_app/src/widgets/flowly_button.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({this.teamId, super.key});

  final String? teamId;

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TeamService _teamService = TeamService();

  List<User> _users = <User>[];
  final Set<String> _selectedMemberIds = <String>{};
  bool _isLoading = false;
  bool _loadingInitialData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final List<User> loadedUsers = (await _teamService.listarUsuarios())
          .where((User user) => (user.tipo ?? 'user').toLowerCase() != 'admin')
          .toList();

      Team? loadedTeam;
      if (widget.teamId != null) {
        loadedTeam = await _teamService.obterEquipe(widget.teamId!);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _users = loadedUsers;
        if (loadedTeam != null) {
          _nameController.text = loadedTeam.nome;
          _selectedMemberIds
            ..clear()
            ..addAll(
              loadedTeam.membros.map((TeamMember member) => member.userId),
            );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingInitialData = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.teamId == null) {
        // Create
        await _teamService.criarEquipe(
          nome: _nameController.text,
          membros: _selectedMemberIds.toList(),
        );
      } else {
        // Edit
        await _teamService.editarEquipe(
          equipeId: widget.teamId!,
          nome: _nameController.text,
          membros: _selectedMemberIds.toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.teamId == null ? 'Equipe criada!' : 'Equipe atualizada!',
            ),
            backgroundColor: const Color(0xFF0D9C6E),
          ),
        );
        context.go('/admin/equipes');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInitialData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamId == null ? 'Criar Equipe' : 'Editar Equipe'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome da Equipe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome da equipe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Membros da equipe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: flowlySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: flowlyBorder),
                ),
                child: _users.isEmpty
                    ? Text(
                        'Nenhum usuário disponível para seleção.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: flowlyMutedText,
                        ),
                      )
                    : Column(
                        children: _users
                            .map(
                              (User user) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: _selectedMemberIds.contains(user.id),
                                title: Text(
                                  user.nome,
                                  style: const TextStyle(color: flowlyText),
                                ),
                                subtitle: Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: flowlyMutedText,
                                  ),
                                ),
                                onChanged: _isLoading
                                    ? null
                                    : (bool? checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedMemberIds.add(user.id);
                                          } else {
                                            _selectedMemberIds.remove(user.id);
                                          }
                                        });
                                      },
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 24),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FlowlyButton(
                  onPressed: _submit,
                  isLoading: _isLoading,
                  label: widget.teamId == null ? 'Criar' : 'Salvar',
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
