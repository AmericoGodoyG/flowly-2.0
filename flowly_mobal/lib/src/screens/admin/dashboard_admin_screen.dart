import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/core/constants/storage_keys.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/team_service.dart';
import 'package:meu_app/src/widgets/auth_background.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<Team>>? _teamsFuture;
  String _adminName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final String? savedName = await _storage.read(key: StorageKeys.userName);
    if (!mounted) {
      return;
    }
    setState(() {
      _adminName = savedName ?? '';
      _teamsFuture = _teamService.listarEquipes();
    });
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
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AppNavigationDrawer(
          currentRoute: '/admin',
          onLogout: _logout,
        ),
        appBar: AppBar(
          title: const Text('Painel Admin'),
          actions: <Widget>[
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
            ),
          ],
        ),
        body: _teamsFuture == null
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<List<Team>>(
                future: _teamsFuture,
                builder:
                    (BuildContext context, AsyncSnapshot<List<Team>> snapshot) {
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
                                Text(
                                  'Erro ao carregar equipes: ${snapshot.error}',
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _loadDashboard,
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final List<Team> teams = snapshot.data ?? <Team>[];

                      return RefreshIndicator(
                        onRefresh: _loadDashboard,
                        child: ListView(
                          padding: EdgeInsets.all(compact ? 12 : 16),
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.all(compact ? 14 : 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF7E57C2),
                                    Color(0xFFFF3366),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _adminName.isEmpty
                                        ? 'Painel do Admin'
                                        : 'Bem-vindo(a), $_adminName!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gerencie equipes e tarefas.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 14),
                            Card(
                              margin: EdgeInsets.only(bottom: compact ? 12 : 14),
                              child: ListTile(
                                leading: const Icon(Icons.groups),
                                title: const Text('Número de equipes'),
                                trailing: Text(
                                  '${teams.length}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 14),
                            Text(
                              'Equipes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            if (teams.isEmpty)
                              Card(
                                margin: EdgeInsets.only(
                                  bottom: compact ? 12 : 14,
                                ),
                                child: const ListTile(
                                  title: Text('Nenhuma equipe cadastrada'),
                                ),
                              )
                            else
                              ...teams.map(
                                (Team team) => Card(
                                  margin: EdgeInsets.only(
                                    bottom: compact ? 12 : 14,
                                  ),
                                  child: ListTile(
                                    title: Text(team.nome),
                                    subtitle: Text(
                                      team.descricao.isEmpty
                                          ? 'Sem descrição'
                                          : team.descricao,
                                    ),
                                  ),
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
