import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/team_service.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';

class TeamsAdminScreen extends StatefulWidget {
  const TeamsAdminScreen({super.key});

  @override
  State<TeamsAdminScreen> createState() => _TeamsAdminScreenState();
}

class _TeamsAdminScreenState extends State<TeamsAdminScreen> {
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();

  Future<List<Team>>? _teamsFuture;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _teamService.listarEquipes();
  }

  Future<void> _reload() async {
    setState(() {
      _teamsFuture = _teamService.listarEquipes();
    });
    await _teamsFuture;
  }

  Future<void> _deleteTeam(Team team) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Excluir equipe'),
              content: Text('Tem certeza que deseja excluir ${team.nome}?'),
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
      await _teamService.excluirEquipe(team.id);
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipe excluida com sucesso!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir equipe: $error')),
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
    return Scaffold(
      drawer: AppNavigationDrawer(
        userType: 'admin',
        currentRoute: '/admin/equipes',
        onLogout: _logout,
      ),
      appBar: AppBar(title: const Text('Admin - Equipes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/equipes/criar'),
        icon: const Icon(Icons.add),
        label: const Text('Criar equipe'),
      ),
      body: FutureBuilder<List<Team>>(
        future: _teamsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Team>> snapshot) {
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
                    Text('Erro ao carregar equipes: ${snapshot.error}'),
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

          final List<Team> teams = snapshot.data ?? <Team>[];
          if (teams.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: const <Widget>[
                  SizedBox(height: 160),
                  Center(child: Text('Nenhuma equipe cadastrada.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (BuildContext context, int index) {
                final Team team = teams[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => context.go('/admin/equipes/editar/${team.id}'),
                    leading: const Icon(Icons.groups_rounded),
                    title: Text(team.nome),
                    subtitle: Text(
                      team.descricao.isEmpty ? 'Sem descricao' : team.descricao,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'edit') {
                          context.go('/admin/equipes/editar/${team.id}');
                        }
                        if (value == 'chat') {
                          context.push(
                            '/equipes/${team.id}/chat?nome=${Uri.encodeComponent(team.nome)}',
                          );
                        }
                        if (value == 'tasks') {
                          context.go('/admin/tarefas');
                        }
                        if (value == 'delete') {
                          _deleteTeam(team);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'tasks',
                              child: Text('Ver tarefas'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'chat',
                              child: Text('Abrir chat'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Excluir'),
                            ),
                          ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
