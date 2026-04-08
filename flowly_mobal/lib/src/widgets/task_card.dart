import 'package:flutter/material.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/widgets/animated_widgets.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({required this.task, required this.onTap, super.key});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      borderRadius: 10,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.nome,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: flowlyText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(task.status),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            if (task.descricao.isNotEmpty)
              Text(
                task.descricao,
                style: const TextStyle(fontSize: 12, color: flowlyMutedText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildDifficultyBadge(task.dificuldade),
                    const SizedBox(width: 8),
                    _buildPriorityBadge(task.prioridade),
                  ],
                ),
                if (task.prazo != null)
                  Text(
                    _formatData(task.prazo!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: flowlyMutedText,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    final colors = {
      TaskStatus.pendente: flowlyWarning,
      TaskStatus.emAndamento: flowlyAccent,
      TaskStatus.concluido: flowlySuccess,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors[status],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(TaskDifficulty difficulty) {
    final colors = {
      TaskDifficulty.facil: flowlySuccess,
      TaskDifficulty.media: flowlyWarning,
      TaskDifficulty.dificil: flowlySecondary,
      TaskDifficulty.definir: flowlyMutedText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[difficulty] ?? Colors.grey).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: colors[difficulty],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    final colors = {
      TaskPriority.alta: flowlySecondary,
      TaskPriority.media: flowlyWarning,
      TaskPriority.baixa: flowlyAccent,
      TaskPriority.definir: flowlyMutedText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[priority] ?? Colors.grey).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.label.substring(0, 1),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: colors[priority],
        ),
      ),
    );
  }

  String _formatData(DateTime data) {
    final hoje = DateTime.now();
    final diferenca = data.difference(hoje).inDays;

    if (diferenca == 0) {
      return 'Hoje';
    } else if (diferenca == 1) {
      return 'Amanhã';
    } else if (diferenca < 0) {
      return 'Vencido';
    } else {
      return '${data.day}/${data.month}';
    }
  }
}
