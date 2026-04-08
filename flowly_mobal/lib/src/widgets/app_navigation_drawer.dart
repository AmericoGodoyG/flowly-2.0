import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.userType,
    required this.currentRoute,
    required this.onLogout,
  });

  final String userType;
  final String currentRoute;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = userType == 'admin';
    final List<_DrawerItem> items = isAdmin
        ? const <_DrawerItem>[
            _DrawerItem(
              title: 'Geral',
              icon: Icons.dashboard_customize_outlined,
              route: '/admin/geral',
            ),
            _DrawerItem(
              title: 'Dashboard Admin',
              icon: Icons.dashboard_outlined,
              route: '/admin',
            ),
            _DrawerItem(
              title: 'Equipes',
              icon: Icons.groups_outlined,
              route: '/admin/equipes',
            ),
            _DrawerItem(
              title: 'Tarefas',
              icon: Icons.task_outlined,
              route: '/admin/tarefas',
            ),
            _DrawerItem(
              title: 'Criar Equipe',
              icon: Icons.group_add_outlined,
              route: '/admin/equipes/criar',
            ),
            _DrawerItem(
              title: 'Criar Tarefa',
              icon: Icons.playlist_add_outlined,
              route: '/admin/tarefas/criar',
            ),
          ]
        : const <_DrawerItem>[
            _DrawerItem(
              title: 'Dashboard',
              icon: Icons.dashboard_outlined,
              route: '/dashboard',
            ),
            _DrawerItem(
              title: 'Minhas tarefas',
              icon: Icons.task_alt_outlined,
              route: '/user/tarefas',
            ),
            _DrawerItem(
              title: 'Minhas Equipes',
              icon: Icons.groups_outlined,
              route: '/equipes/minhas',
            ),
            _DrawerItem(
              title: 'Meu Perfil',
              icon: Icons.person_outline,
              route: '/perfil',
            ),
          ];

    return Drawer(
      backgroundColor: flowlySurface,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[flowlyPrimary, flowlySecondary],
                ),
              ),
              accountName: Text(
                isAdmin ? 'Administrador' : 'Usuário',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              accountEmail: Text(
                isAdmin ? 'Painel admin' : 'Painel usuário',
                style: const TextStyle(color: Color(0xE6FFFFFF)),
              ),
              currentAccountPicture: CircleAvatar(
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ...items.map((item) {
                    final bool selected = _isSelected(item.route, currentRoute);
                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      selectedTileColor: flowlyPrimary.withValues(alpha: 0.18),
                      selected: selected,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!selected) {
                          context.go(item.route);
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.of(context).pop();
                await onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelected(String itemRoute, String route) {
    if (itemRoute == route) {
      return true;
    }
    return route.startsWith(itemRoute);
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;
}
