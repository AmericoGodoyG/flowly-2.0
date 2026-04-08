import 'package:flutter/material.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/widgets/animated_widgets.dart';

class TeamCard extends StatelessWidget {
  const TeamCard({
    required this.team,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Team team;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      borderRadius: 12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0x1AFFFFFF), const Color(0x12FFFFFF)],
          ),
          border: Border.all(color: flowlyBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[flowlyPrimary, flowlySecondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    team.nome[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      team.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: flowlyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.descricao,
                      style: const TextStyle(
                        fontSize: 12,
                        color: flowlyMutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${team.membros.length} membros • Código: ${team.code}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: flowlyMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              if (onEdit != null || onDelete != null)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      PopupMenuItem(
                        onTap: onEdit,
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        onTap: onDelete,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
