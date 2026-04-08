import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/core/network/api_client.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/widgets/app_navigation_drawer.dart';

class AdminGeneralScreen extends StatefulWidget {
  const AdminGeneralScreen({super.key});

  @override
  State<AdminGeneralScreen> createState() => _AdminGeneralScreenState();
}

class _AdminGeneralScreenState extends State<AdminGeneralScreen> {
  final AuthService _authService = AuthService();

  Future<_AdminGeneralData>? _dataFuture;
  String _teamFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  Future<_AdminGeneralData> _loadData() async {
    final List<dynamic> rawTeams = await _safeGetList('/api/equipes');
    final List<dynamic> rawTasks = await _safeGetList('/api/tarefas');
    final List<_TaskAnalyticsItem> analytics = <_TaskAnalyticsItem>[];

    for (final dynamic item in rawTasks) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final dynamic equipeRaw = item['equipe'];
      String name = 'Sem equipe';
      if (equipeRaw is Map<String, dynamic>) {
        final String resolved = (equipeRaw['nome'] ?? '').toString().trim();
        if (resolved.isNotEmpty) {
          name = resolved;
        }
      }
      final String status = (item['status'] ?? '').toString().trim();
      analytics.add(_TaskAnalyticsItem(teamName: name, status: status));
    }

    final Map<String, int> counts = <String, int>{};
    for (final _TaskAnalyticsItem item in analytics) {
      counts[item.teamName] = (counts[item.teamName] ?? 0) + 1;
    }

    final List<_TeamTaskMetric> teamTaskMetrics =
        counts.entries
            .map(
              (MapEntry<String, int> entry) =>
                  _TeamTaskMetric(teamName: entry.key, totalTasks: entry.value),
            )
            .toList()
          ..sort((a, b) => b.totalTasks.compareTo(a.totalTasks));

    return _AdminGeneralData(
      teamCount: rawTeams.whereType<Map<String, dynamic>>().length,
      teamTaskMetrics: teamTaskMetrics,
      analyticsItems: analytics,
    );
  }

  Future<List<dynamic>> _safeGetList(String endpoint) async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(endpoint);
      return response.data ?? <dynamic>[];
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 304) {
        return <dynamic>[];
      }
      throw ApiClient.mapError(error);
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
        currentRoute: '/admin/geral',
        onLogout: _logout,
      ),
      appBar: AppBar(title: const Text('Admin Geral')),
      body: FutureBuilder<_AdminGeneralData>(
        future: _dataFuture,
        builder:
            (BuildContext context, AsyncSnapshot<_AdminGeneralData> snapshot) {
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
                          'Erro ao carregar painel geral: ${snapshot.error}',
                        ),
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

              final _AdminGeneralData data =
                  snapshot.data ?? const _AdminGeneralData();
              final List<_TaskAnalyticsItem> filtered = data.analyticsItems
                  .where((item) {
                    final bool teamOk =
                        _teamFilter == 'all' || item.teamName == _teamFilter;
                    final bool statusOk =
                        _statusFilter == 'all' || item.status == _statusFilter;
                    return teamOk && statusOk;
                  })
                  .toList();

              final int pendentes = filtered
                  .where((item) => item.status == 'pendente')
                  .length;
              final int andamento = filtered
                  .where((item) => item.status == 'em_andamento')
                  .length;
              final int concluidas = filtered
                  .where((item) => item.status == 'concluido')
                  .length;

              final Map<String, int> filteredByTeam = <String, int>{};
              for (final _TaskAnalyticsItem item in filtered) {
                filteredByTeam[item.teamName] =
                    (filteredByTeam[item.teamName] ?? 0) + 1;
              }
              final List<_TeamTaskMetric> filteredTeamMetrics =
                  filteredByTeam.entries
                      .map(
                        (entry) => _TeamTaskMetric(
                          teamName: entry.key,
                          totalTasks: entry.value,
                        ),
                      )
                      .toList()
                    ..sort((a, b) => b.totalTasks.compareTo(a.totalTasks));
              final List<String> teamNames =
                  data.analyticsItems
                      .map((item) => item.teamName)
                      .toSet()
                      .toList()
                    ..sort();

              final bool compact = MediaQuery.of(context).size.width < 390;

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF0B1F4D), Color(0xFF1E4FA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Painel Geral',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Resumo rápido de equipes e tarefas no sistema.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatCard(
                      title: 'Equipes',
                      value: data.teamCount.toString(),
                      icon: Icons.groups_outlined,
                      accent: const Color(0xFF1E4FA8),
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Tarefas',
                      value: filtered.length.toString(),
                      icon: Icons.task_alt_outlined,
                      accent: const Color(0xFF0D9C6E),
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Pendentes',
                      value: pendentes.toString(),
                      icon: Icons.schedule_outlined,
                      accent: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Em andamento',
                      value: andamento.toString(),
                      icon: Icons.timelapse_outlined,
                      accent: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Concluídas',
                      value: concluidas.toString(),
                      icon: Icons.check_circle_outline,
                      accent: const Color(0xFF0D9C6E),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Filtros',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            if (compact) ...<Widget>[
                              DropdownButtonFormField<String>(
                                initialValue: _teamFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Equipe',
                                ),
                                items: <DropdownMenuItem<String>>[
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text(
                                      'Todas as equipes',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ...teamNames.map(
                                    (name) => DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _teamFilter = value ?? 'all',
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: _statusFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                ),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text(
                                      'Todos os status',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pendente',
                                    child: Text(
                                      'Pendente',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'em_andamento',
                                    child: Text(
                                      'Em andamento',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'concluido',
                                    child: Text(
                                      'Concluído',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _statusFilter = value ?? 'all',
                                ),
                              ),
                            ] else ...<Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _teamFilter,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Equipe',
                                      ),
                                      items: <DropdownMenuItem<String>>[
                                        const DropdownMenuItem(
                                          value: 'all',
                                          child: Text(
                                            'Todas as equipes',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...teamNames.map(
                                          (name) => DropdownMenuItem<String>(
                                            value: name,
                                            child: Text(
                                              name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) => setState(
                                        () => _teamFilter = value ?? 'all',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _statusFilter,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                      ),
                                      items: const <DropdownMenuItem<String>>[
                                        DropdownMenuItem(
                                          value: 'all',
                                          child: Text(
                                            'Todos os status',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'pendente',
                                          child: Text(
                                            'Pendente',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'em_andamento',
                                          child: Text(
                                            'Em andamento',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'concluido',
                                          child: Text(
                                            'Concluído',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) => setState(
                                        () => _statusFilter = value ?? 'all',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _ActionButton(
                          label: 'Ir para equipes',
                          icon: Icons.groups_outlined,
                          onPressed: () => context.go('/admin/equipes'),
                        ),
                        _ActionButton(
                          label: 'Ir para tarefas',
                          icon: Icons.task_outlined,
                          onPressed: () => context.go('/admin/tarefas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Distribuição de tarefas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: compact
                            ? Column(
                                children: <Widget>[
                                  SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: _DonutChart(
                                      segments: <_DonutSegment>[
                                        _DonutSegment(
                                          label: 'Pendentes',
                                          value: pendentes.toDouble(),
                                          color: Colors.orange,
                                        ),
                                        _DonutSegment(
                                          label: 'Em andamento',
                                          value: andamento.toDouble(),
                                          color: Colors.blue,
                                        ),
                                        _DonutSegment(
                                          label: 'Concluídas',
                                          value: concluidas.toDouble(),
                                          color: const Color(0xFF0D9C6E),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _LegendItem(
                                    color: Colors.orange,
                                    label: 'Pendentes',
                                    value: pendentes,
                                  ),
                                  const SizedBox(height: 8),
                                  _LegendItem(
                                    color: Colors.blue,
                                    label: 'Em andamento',
                                    value: andamento,
                                  ),
                                  const SizedBox(height: 8),
                                  _LegendItem(
                                    color: const Color(0xFF0D9C6E),
                                    label: 'Concluídas',
                                    value: concluidas,
                                  ),
                                ],
                              )
                            : Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: _DonutChart(
                                      segments: <_DonutSegment>[
                                        _DonutSegment(
                                          label: 'Pendentes',
                                          value: pendentes.toDouble(),
                                          color: Colors.orange,
                                        ),
                                        _DonutSegment(
                                          label: 'Em andamento',
                                          value: andamento.toDouble(),
                                          color: Colors.blue,
                                        ),
                                        _DonutSegment(
                                          label: 'Concluídas',
                                          value: concluidas.toDouble(),
                                          color: const Color(0xFF0D9C6E),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _LegendItem(
                                          color: Colors.orange,
                                          label: 'Pendentes',
                                          value: pendentes,
                                        ),
                                        const SizedBox(height: 10),
                                        _LegendItem(
                                          color: Colors.blue,
                                          label: 'Em andamento',
                                          value: andamento,
                                        ),
                                        const SizedBox(height: 10),
                                        _LegendItem(
                                          color: const Color(0xFF0D9C6E),
                                          label: 'Concluídas',
                                          value: concluidas,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tarefas por equipe',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filteredTeamMetrics.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Sem tarefas vinculadas a equipes no momento.',
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: SizedBox(
                            height: 240,
                            child: _TeamBarChart(
                              metrics: filteredTeamMetrics.take(6).toList(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _StatusBar(
                      label: 'Pendentes',
                      value: pendentes,
                      total: filtered.isEmpty ? 1 : filtered.length,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _StatusBar(
                      label: 'Em andamento',
                      value: andamento,
                      total: filtered.isEmpty ? 1 : filtered.length,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _StatusBar(
                      label: 'Concluídas',
                      value: concluidas,
                      total: filtered.isEmpty ? 1 : filtered.length,
                      color: const Color(0xFF0D9C6E),
                    ),
                  ],
                ),
              );
            },
      ),
    );
  }
}

class _AdminGeneralData {
  const _AdminGeneralData({
    this.teamCount = 0,
    this.teamTaskMetrics = const <_TeamTaskMetric>[],
    this.analyticsItems = const <_TaskAnalyticsItem>[],
  });

  final int teamCount;
  final List<_TeamTaskMetric> teamTaskMetrics;
  final List<_TaskAnalyticsItem> analyticsItems;
}

class _TaskAnalyticsItem {
  const _TaskAnalyticsItem({required this.teamName, required this.status});

  final String teamName;
  final String status;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.12),
            foregroundColor: accent,
            child: Icon(icon),
          ),
          title: Text(title),
          trailing: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fraction = total == 0 ? 0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[Text(label), Text('$value')],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.segments});

  final List<_DonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    final double total = segments.fold<double>(
      0,
      (double sum, _DonutSegment item) => sum + item.value,
    );
    if (total <= 0) {
      return const Center(child: Text('Sem dados'));
    }

    return CustomPaint(
      painter: _DonutPainter(segments: segments, total: total),
      child: Center(
        child: Text(
          total.toInt().toString(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments, required this.total});

  final List<_DonutSegment> segments;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius - 8);

    final Paint background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..color = const Color(0xFFE9EDF5);
    canvas.drawArc(rect, 0, math.pi * 2, false, background);

    double startAngle = -math.pi / 2;
    for (final _DonutSegment segment in segments) {
      final double sweep = (segment.value / total) * math.pi * 2;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 20
        ..color = segment.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments != segments;
  }
}

class _TeamTaskMetric {
  const _TeamTaskMetric({required this.teamName, required this.totalTasks});

  final String teamName;
  final int totalTasks;
}

class _TeamBarChart extends StatelessWidget {
  const _TeamBarChart({required this.metrics});

  final List<_TeamTaskMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final int maxValue = metrics.fold<int>(
      0,
      (int max, item) => item.totalTasks > max ? item.totalTasks : max,
    );
    return CustomPaint(
      painter: _TeamBarPainter(
        metrics: metrics,
        maxValue: maxValue == 0 ? 1 : maxValue,
      ),
      child: Container(),
    );
  }
}

class _TeamBarPainter extends CustomPainter {
  const _TeamBarPainter({required this.metrics, required this.maxValue});

  final List<_TeamTaskMetric> metrics;
  final int maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    const double topPadding = 10;
    const double leftPadding = 12;
    const double barGap = 14;
    const double barHeight = 18;
    const double labelWidth = 92;
    final double chartWidth = size.width - leftPadding - labelWidth - 18;

    final Paint trackPaint = Paint()..color = const Color(0xFFEAF0FA);
    final Paint barPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF1E4FA8), Color(0xFF38D5E5)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, barHeight));

    for (int i = 0; i < metrics.length; i++) {
      final _TeamTaskMetric metric = metrics[i];
      final double y = topPadding + i * (barHeight + barGap);
      final double barWidth = (metric.totalTasks / maxValue) * chartWidth;
      final RRect track = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftPadding + labelWidth, y, chartWidth, barHeight),
        const Radius.circular(999),
      );
      final RRect bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftPadding + labelWidth, y, barWidth, barHeight),
        const Radius.circular(999),
      );

      canvas.drawRRect(track, trackPaint);
      canvas.drawRRect(bar, barPaint);

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: _truncate(metric.teamName),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: labelWidth - 8);
      labelPainter.paint(canvas, Offset(leftPadding, y + 1));

      final TextPainter valuePainter = TextPainter(
        text: TextSpan(
          text: metric.totalTasks.toString(),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(
        canvas,
        Offset(leftPadding + labelWidth + chartWidth + 6, y + 1),
      );
    }
  }

  String _truncate(String text) {
    if (text.length <= 14) {
      return text;
    }
    return '${text.substring(0, 14)}...';
  }

  @override
  bool shouldRepaint(covariant _TeamBarPainter oldDelegate) {
    return oldDelegate.maxValue != maxValue || oldDelegate.metrics != metrics;
  }
}
