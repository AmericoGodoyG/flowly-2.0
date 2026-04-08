import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/core/constants/storage_keys.dart';
import 'package:meu_app/src/screens/auth/login_screen.dart';
import 'package:meu_app/src/screens/auth/register_screen.dart';
import 'package:meu_app/src/screens/auth/verify_email_screen.dart';
import 'package:meu_app/src/screens/admin/dashboard_admin_screen.dart';
import 'package:meu_app/src/screens/admin/admin_general_screen.dart';
import 'package:meu_app/src/screens/admin/create_task_admin_screen.dart';
import 'package:meu_app/src/screens/admin/teams_admin_screen.dart';
import 'package:meu_app/src/screens/admin/tasks_admin_screen.dart';
import 'package:meu_app/src/screens/home/home_screen.dart';
import 'package:meu_app/src/screens/profile/profile_screen.dart';
import 'package:meu_app/src/screens/profile/user_settings_screen.dart';
import 'package:meu_app/src/screens/tasks/task_detail_screen.dart';
import 'package:meu_app/src/screens/teams/create_team_screen.dart';
import 'package:meu_app/src/screens/teams/my_teams_screen.dart';
import 'package:meu_app/src/screens/teams/team_chat_screen.dart';
import 'package:meu_app/src/screens/user/dashboard_user_screen.dart';
import 'package:meu_app/src/screens/user/tasks_user_screen.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();

final GoRouter flowlyRouter = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) async {
    final String? token = await _storage.read(key: StorageKeys.jwtToken);
    final String? userType = await _storage.read(key: StorageKeys.userType);
    final bool isLoggedIn = token != null && token.isNotEmpty;
    final String? tokenUserType = _extractUserTypeFromJwt(token);
    final bool isAdmin =
        (tokenUserType ?? userType ?? '').toLowerCase() == 'admin';
    final String defaultRoute = isAdmin ? '/admin' : '/dashboard';

    final bool isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/verify-email';
    final bool isAdminRoute = state.matchedLocation.startsWith('/admin');
    final bool isUserRoute =
        state.matchedLocation == '/dashboard' ||
        state.matchedLocation.startsWith('/user');

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    if (isLoggedIn && isAuthRoute) {
      return defaultRoute;
    }

    if (isLoggedIn && isAdmin && isUserRoute) {
      return '/admin';
    }

    if (isLoggedIn && !isAdmin && isAdminRoute) {
      return '/dashboard';
    }

    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Erro')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Erro: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Voltar'),
          ),
        ],
      ),
    ),
  ),
  routes: <RouteBase>[
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        final String? initialEmail = state.uri.queryParameters['email'];
        return LoginScreen(initialEmail: initialEmail);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) =>
          const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (BuildContext context, GoRouterState state) {
        final String email = state.uri.queryParameters['email'] ?? '';
        return VerifyEmailScreen(email: email);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) =>
          const DashboardAdminScreen(),
    ),
    GoRoute(
      path: '/admin/geral',
      builder: (BuildContext context, GoRouterState state) =>
          const AdminGeneralScreen(),
    ),
    GoRoute(
      path: '/admin/equipes',
      builder: (BuildContext context, GoRouterState state) =>
          const TeamsAdminScreen(),
    ),
    GoRoute(
      path: '/admin/equipes/criar',
      builder: (BuildContext context, GoRouterState state) =>
          const CreateTeamScreen(),
    ),
    GoRoute(
      path: '/admin/equipes/editar/:teamId',
      builder: (BuildContext context, GoRouterState state) {
        final String teamId = state.pathParameters['teamId'] ?? '';
        return CreateTeamScreen(teamId: teamId);
      },
    ),
    GoRoute(
      path: '/admin/tarefas',
      builder: (BuildContext context, GoRouterState state) =>
          const TasksAdminScreen(),
    ),
    GoRoute(
      path: '/admin/tarefas/criar',
      builder: (BuildContext context, GoRouterState state) =>
          const CreateTaskAdminScreen(),
    ),
    GoRoute(
      path: '/admin/tarefas/editar/:taskId',
      builder: (BuildContext context, GoRouterState state) {
        final String taskId = state.pathParameters['taskId'] ?? '';
        return CreateTaskAdminScreen(taskId: taskId);
      },
    ),
    GoRoute(
      path: '/admin/tarefas/:taskId',
      builder: (BuildContext context, GoRouterState state) {
        final String taskId = state.pathParameters['taskId'] ?? '';
        return TaskDetailScreen(taskId: taskId, userType: 'admin');
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const DashboardUserScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (BuildContext context, GoRouterState state) =>
          const ProfileScreen(),
    ),
    GoRoute(
      path: '/perfil/configuracoes',
      builder: (BuildContext context, GoRouterState state) =>
          const UserSettingsScreen(),
    ),
    GoRoute(
      path: '/equipes/minhas',
      builder: (BuildContext context, GoRouterState state) =>
          const MyTeamsScreen(),
    ),
    GoRoute(
      path: '/equipes/:teamId/chat',
      builder: (BuildContext context, GoRouterState state) {
        final String teamId = state.pathParameters['teamId'] ?? '';
        final String teamName = state.uri.queryParameters['nome'] ?? 'Equipe';
        return TeamChatScreen(teamId: teamId, teamName: teamName);
      },
    ),
    GoRoute(
      path: '/equipes/criar',
      builder: (BuildContext context, GoRouterState state) =>
          const CreateTeamScreen(),
    ),
    GoRoute(
      path: '/equipes/editar/:teamId',
      builder: (BuildContext context, GoRouterState state) {
        final String teamId = state.pathParameters['teamId'] ?? '';
        return CreateTeamScreen(teamId: teamId);
      },
    ),
    GoRoute(
      path: '/user/tarefas',
      builder: (BuildContext context, GoRouterState state) =>
          const TasksUserScreen(),
    ),
    GoRoute(
      path: '/user/tarefas/:taskId',
      builder: (BuildContext context, GoRouterState state) {
        final String taskId = state.pathParameters['taskId'] ?? '';
        return TaskDetailScreen(taskId: taskId, userType: 'user');
      },
    ),
  ],
);

String? _extractUserTypeFromJwt(String? token) {
  if (token == null || token.isEmpty) {
    return null;
  }

  try {
    final List<String> parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    final String payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final Object? decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final String type = (decoded['tipo'] ?? decoded['role'] ?? '')
        .toString()
        .trim();
    return type.isEmpty ? null : type;
  } catch (_) {
    return null;
  }
}
