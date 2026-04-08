import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/core/constants/storage_keys.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/services/task_service.dart';
import 'package:meu_app/src/widgets/auth_background.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';

class DashboardUserScreen extends StatefulWidget {
  const DashboardUserScreen({super.key});

  @override
  State<DashboardUserScreen> createState() => _DashboardUserScreenState();
}

class _DashboardUserScreenState extends State<DashboardUserScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<Task>>? _tasksFuture;
  String _userName = '';

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
      _userName = savedName ?? '';
      _tasksFuture = _taskService.listarMinhasTarefas();
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
          userType: 'user',
          currentRoute: '/dashboard',
          onLogout: _logout,
        ),
        appBar: AppBar(
          title: const Text('Dashboard Usuario'),
          actions: <Widget>[
            IconButton(
              onPressed: () => context.go('/user/tarefas'),
              icon: const Icon(Icons.task_alt_outlined),
              tooltip: 'Minhas tarefas',
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
            ),
          ],
        ),
        body: _tasksFuture == null
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<List<Task>>(
                future: _tasksFuture,
                builder:
                    (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
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
                                  'Erro ao carregar tarefas: ${snapshot.error}',
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

                      final List<Task> tasks = snapshot.data ?? <Task>[];

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
                                    _userName.isEmpty
                                        ? 'Painel do Usuário'
                                        : 'Bem-vindo(a), $_userName!',
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
                                    'Acompanhe suas tarefas e progresso.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 14),
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.task_alt),
                                title: const Text('Quantidade de tarefas'),
                                trailing: Text(
                                  '${tasks.length}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.arrow_forward),
                                title: const Text(
                                  'Ver lista completa de tarefas',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.go('/user/tarefas'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (tasks.isEmpty)
                              const Card(
                                child: ListTile(
                                  title: Text('Nenhuma tarefa atribuída'),
                                ),
                              )
                            else
                              ...tasks.map(
                                (Task task) => Card(
                                  child: ListTile(
                                    title: Text(
                                      task.nome.isEmpty
                                          ? task.descricao
                                          : task.nome,
                                    ),
                                    subtitle: Text(
                                      'Status: ${task.status.label}',
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
