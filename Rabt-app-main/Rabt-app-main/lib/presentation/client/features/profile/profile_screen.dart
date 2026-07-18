import 'package:flutter/material.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../core/utils/formatters.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
      child: Column(
        children: [
          // الصورة الشخصية
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: RabtDesignConstants.spaceMd),
          Text(
            'اسم المستخدم',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: RabtDesignConstants.spaceXs),
          Text(
            '+9627XXXXXXXX',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: RabtDesignConstants.spaceLg),

          // الإحصائيات
          Row(
            children: [
              _StatItem(theme, '0', 'رحلات'),
              const SizedBox(width: RabtDesignConstants.spaceMd),
              _StatItem(theme, '--', 'التقييم'),
              const SizedBox(width: RabtDesignConstants.spaceMd),
              _StatItem(theme, '0', 'نقاط'),
            ],
          ),
          const SizedBox(height: RabtDesignConstants.spaceXl),

          // قائمة الإعدادات
          _ProfileMenuItem(
            icon: Icons.history,
            title: 'سجل الرحلات',
            onTap: () => Navigator.pushNamed(context, '/trip-history'),
          ),
          _ProfileMenuItem(
            icon: Icons.payment,
            title: 'طرق الدفع',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.card_giftcard,
            title: 'كوبونات الخصم',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.support_agent,
            title: 'الدعم الفني',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.settings,
            title: 'الإعدادات',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _ProfileMenuItem(
            icon: Icons.info_outline,
            title: 'حول التطبيق',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final ThemeData theme;
  final String value;
  final String label;

  const _StatItem(this.theme, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: RabtDesignConstants.spaceMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }
}
