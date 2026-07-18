import 'package:flutter/material.dart';
import '../../../../core/constants/design_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _smsNotifications = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات', style: theme.textTheme.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
        children: [
          // الإشعارات
          Text('الإشعارات', style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: RabtDesignConstants.spaceSm),
          SwitchListTile(
            title: const Text('إشعارات التطبيق'),
            subtitle: const Text('استلام إشعارات الرحلات'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          SwitchListTile(
            title: const Text('إشعارات SMS'),
            subtitle: const Text('استلام رسائل نصية'),
            value: _smsNotifications,
            onChanged: (v) => setState(() => _smsNotifications = v),
          ),

          const SizedBox(height: RabtDesignConstants.spaceLg),
          const Divider(),

          // المظهر
          Text('المظهر', style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: RabtDesignConstants.spaceSm),
          SwitchListTile(
            title: const Text('الوضع الليلي'),
            subtitle: const Text('تفعيل الألوان الداكنة'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),

          const SizedBox(height: RabtDesignConstants.spaceLg),
          const Divider(),

          // الأمان
          Text('الأمان', style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: RabtDesignConstants.spaceSm),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('تغيير كلمة المرور'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('بصمة الإصبع'),
            subtitle: const Text('فتح التطبيق ببصمة الإصبع'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),

          const SizedBox(height: RabtDesignConstants.spaceLg),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text(
                'تسجيل الخروج',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
