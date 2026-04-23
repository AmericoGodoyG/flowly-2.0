import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/team_service.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';
import 'package:meu_app/src/widgets/auth_background.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();

  Future<List<Team>>? _teamsFuture;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _teamService.listarMinhasEquipes();
  }

  Future<void> _reload() async {
    setState(() {
      _teamsFuture = _teamService.listarMinhasEquipes();
    });
    await _teamsFuture;
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
          currentRoute: '/chats',
          onLogout: _logout,
        ),
        appBar: AppBar(title: const Text('Chats')),
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
                      Text('Erro ao carregar chats: ${snapshot.error}'),
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
                    Center(child: Text('Você não participa de nenhuma equipe.')),
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Chats das equipes',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Converse com os membros em um lugar só',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: compact ? 20 : 24,
                          backgroundColor: Colors.white24,
                          child: Text(
                            teams.length.toString(),
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
                  ...teams.map((Team team) {
                    return Card(
                      margin: EdgeInsets.only(bottom: compact ? 12 : 14),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E4FA8).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.forum_outlined),
                        ),
                        title: Text(team.nome),
                        subtitle: Text('${team.membros.length} membros'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/chats/${team.id}?nome=${Uri.encodeComponent(team.nome)}',
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
