import 'package:flutter/material.dart';
import '../../models/user_quota.dart';
import '../../utils/app_theme.dart';

class QuotaBadgeWidget extends StatelessWidget {
  final UserQuota quota;
  final bool compact;

  const QuotaBadgeWidget({
    super.key,
    required this.quota,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final percent = quota.isUnlimited ? 0.0 : (quota.percentUsed / 100.0).clamp(0.0, 1.0);
    final isDanger = !quota.isUnlimited && quota.percentUsed >= 90.0;
    final isWarning = !quota.isUnlimited && quota.percentUsed >= 75.0 && !isDanger;

    final barColor = isDanger
        ? AppTheme.roseDanger
        : (isWarning ? AppTheme.amberWarning : AppTheme.cyberCyan);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardSub,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_outlined, size: 14, color: barColor),
            const SizedBox(width: 6),
            Text(
              quota.isUnlimited ? 'Ilimitado' : '${quota.percentUsed.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDanger ? AppTheme.roseDanger.withOpacity(0.6) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.cloud_done_rounded, color: barColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Espacio Personal en el NAS',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        quota.partitionName,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                quota.isUnlimited ? 'Ilimitado' : '${quota.percentUsed.toStringAsFixed(1)}% Usado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: quota.isUnlimited ? 0.05 : percent,
              minHeight: 7,
              backgroundColor: AppTheme.cardSub,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${quota.usedHuman} de ${quota.maxHuman}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              Text(
                'Libre: ${quota.freeHuman}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          if (isDanger) ...[
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.roseDanger),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Partición casi llena. Elimina archivos o contacta al administrador.',
                    style: TextStyle(fontSize: 10, color: AppTheme.roseDanger),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
