import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/core/utils/responsive_helper.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/services/team_service.dart';
import 'package:meu_app/src/widgets/team_card.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  final TeamService _teamService = TeamService();
  Future<List<Team>>? _teamsFuture;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  void _loadTeams() {
    setState(() {
      _teamsFuture = _teamService.listarMinhasEquipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Equipes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Team>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTeams,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          final teams = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Suas equipes'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Teams List
                if (teams.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.group_off,
                            size: 64,
                            color: flowlyMutedText,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Você não está em nenhuma equipe',
                            style: TextStyle(
                              fontSize: 16,
                              color: flowlyMutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.getGridColumns(context),
                      childAspectRatio: ResponsiveHelper.isTablet(context)
                          ? 1.0
                          : 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final Team team = teams[index];
                      return TeamCard(
                        team: team,
                        onTap: () => context.push(
                          '/equipes/${team.id}/chat?nome=${Uri.encodeComponent(team.nome)}',
                        ),
                        onEdit: null,
                        onDelete: null,
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
