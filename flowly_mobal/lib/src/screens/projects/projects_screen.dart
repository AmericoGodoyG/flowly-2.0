import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/models/project.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/project_service.dart';
import 'package:meu_app/src/services/team_service.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({required this.teamId, super.key});

  final String teamId;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ProjectService _projectService = ProjectService();
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();

  late Future<(Team, List<Project>)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<(Team, List<Project>)> _loadData() async {
    try {
      final team = await _teamService.obterEquipe(widget.teamId);
      final projects = await _projectService.listarProjetos(widget.teamId);
      return (team, projects);
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
    final bool compact = MediaQuery.of(context).size.width < 390;
    return FutureBuilder<(Team, List<Project>)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Projetos')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Projetos')),
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

        final (team, projects) = snapshot.data!;

        return Scaffold(
          drawer: AppNavigationDrawer(
            currentRoute: '/projetos',
            onLogout: _logout,
          ),
          appBar: AppBar(
            title: Text('Projetos - ${team.nome}'),
            centerTitle: true,
            elevation: 0,
          ),
          body: projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.folder_off, size: 64, color: flowlyMutedText),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum projeto criado',
                        style: TextStyle(
                          fontSize: 16,
                          color: flowlyMutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
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
                                team.nome,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Projetos da equipe',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                          CircleAvatar(
                            radius: compact ? 20 : 24,
                            backgroundColor: Colors.white24,
                            child: Text(
                              projects.length.toString(),
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
                    ...projects.map(
                      (Project project) => GestureDetector(
                        onTap: () {
                          context.push('/projetos/${project.id}');
                        },
                        child: Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.nome,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: flowlyText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project.descricao,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: flowlyMutedText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push('/projetos/criar');
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
