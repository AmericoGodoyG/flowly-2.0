import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/services/team_service.dart';
import 'package:meu_app/src/widgets/auth_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TeamService _teamService = TeamService();
  late Future<List<Team>> _teamsFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _teamService.listarEquipes();
  }

  void _reloadTeams() {
    setState(() {
      _teamsFuture = _teamService.listarEquipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Flowly',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: _currentIndex == 0 ? _buildTeamsTab() : _buildProfileTab(),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xCC14141E),
            indicatorColor: flowlyPrimary.withValues(alpha: 0.24),
            labelTextStyle: WidgetStatePropertyAll(
              GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Equipes',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsTab() {
    return FutureBuilder<List<Team>>(
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
                  onPressed: _reloadTeams,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        final teams = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[flowlyPrimary, flowlySecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo!',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gerencie suas equipes e tarefas',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Equipes',
                      count: teams.length,
                      color: flowlyPrimary,
                      icon: Icons.group,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Ativo',
                      count: teams.isNotEmpty ? 1 : 0,
                      color: flowlyAccent,
                      icon: Icons.check_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Teams Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Suas Equipes',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.go('/equipes/minhas');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Ver Todas'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              teams.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.group_off,
                              size: 64,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma equipe',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teams.take(3).length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        return _buildTeamItem(team, context);
                      },
                    ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Text('Perfil - Funcionalidade em desenvolvimento'),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: flowlyBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamItem(Team team, BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: flowlyBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: flowlyPrimary,
          child: Text(
            team.nome[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          team.nome,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${team.membros.length} membros',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.go('/equipes/minhas');
        },
      ),
    );
  }
}
