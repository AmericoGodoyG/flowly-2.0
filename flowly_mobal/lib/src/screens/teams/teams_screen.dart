import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/core/network/api_client.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/team_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();

  List<Team> _teams = <Team>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      final List<Team> teams = await _teamService.listarEquipes();
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = teams;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.mapError(error).message)),
      );
    }
  }

  Future<void> _joinWithCode() async {
    final TextEditingController codeController = TextEditingController();
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Entrar em uma equipe'),
          content: TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: const TextStyle(color: flowlyText),
            cursorColor: flowlyPrimary,
            decoration: const InputDecoration(
              hintText: 'Código de 4 dígitos',
              counterText: '',
              hintStyle: TextStyle(color: flowlyMutedText),
              counterStyle: TextStyle(color: flowlyMutedText),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, codeController.text.trim()),
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );

    if (!mounted || code == null || code.isEmpty) {
      return;
    }

    if (code.length != 4 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O código deve ter 4 números.')),
      );
      return;
    }

    final Team? team = await _teamService.obterEquipePorCodigo(code);
    if (!mounted) {
      return;
    }

    if (team == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma equipe encontrada para este código.'),
        ),
      );
      return;
    }

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar entrada'),
              content: Text('Entrar na equipe ${team.nome}?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Entrar'),
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
      await _teamService.entrarNaEquipe(team.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Você entrou na equipe ${team.nome}!')),
      );
      await _loadTeams();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.mapError(error).message)),
      );
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
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: flowlyDark,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Olá',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Como podemos ajudar hoje?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF0B1F4D),
                      Color(0xFF1E4FA8),
                      Color(0xFF38D5E5),
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              IconButton(
                onPressed: _logout,
                tooltip: 'Sair',
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            sliver: SliverList.list(
              children: <Widget>[
                _ActionCard(
                  title: 'Minhas equipes',
                  subtitle: 'Veja as equipes que você já participa.',
                  icon: Icons.groups_rounded,
                  onTap: _loadTeams,
                ),
                _ActionCard(
                  title: 'Criar uma nova equipe',
                  subtitle: 'Crie uma equipe diretamente pelo app.',
                  icon: Icons.add_circle_outline_rounded,
                  onTap: () => context.go('/equipes/criar'),
                ),
                _ActionCard(
                  title: 'Entrar em uma equipe com código',
                  subtitle:
                      'Use o código de 4 dígitos para entrar rapidamente.',
                  icon: Icons.tag_rounded,
                  onTap: _joinWithCode,
                ),
                const SizedBox(height: 18),
                Text(
                  'Equipes disponíveis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_teams.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDEE6FA)),
                    ),
                    child: const Text(
                      'Nenhuma equipe encontrada para sua conta.',
                    ),
                  )
                else
                  ..._teams.map((Team team) => _TeamTile(team: team)),
                const SizedBox(height: 84),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (int index) {
          if (index == 1) {
            _joinWithCode();
          }
          if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil em migração para Flutter.')),
            );
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Código',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Conta',
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDEE6FA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x11073370),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0x13337BFF),
          foregroundColor: flowlySecondary,
          child: Icon(icon),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7F8)),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF337BFF), Color(0xFF38D5E5)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.groups_rounded, color: Colors.white),
        ),
        title: Text(team.nome.isEmpty ? 'Equipe sem nome' : team.nome),
        subtitle: Text(
          team.descricao.isEmpty ? 'Sem descrição' : team.descricao,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: team.code.isEmpty
            ? null
            : Chip(
                label: Text(team.code),
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}
