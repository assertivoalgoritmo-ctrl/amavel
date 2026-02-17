import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/family_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final seniorProfile = ref.watch(seniorProfileProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SettingItem(
                        icon: Icons.person,
                        label: 'Nome',
                        value: currentUser?.displayName ?? 'Não configurado',
                      ),
                      const Divider(),
                      _SettingItem(
                        icon: Icons.email,
                        label: 'Email',
                        value: currentUser?.email ?? 'Não configurado',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Linked Senior Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: seniorProfile.when(
                    data: (senior) {
                      if (senior == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Idoso Vinculado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum idoso vinculado',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Idoso Vinculado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SettingItem(
                            icon: Icons.person,
                            label: 'Nome',
                            value: senior.name,
                          ),
                          const Divider(),
                          _SettingItem(
                            icon: Icons.phone,
                            label: 'Telefone',
                            value: senior.phone,
                          ),
                          const Divider(),
                          _SettingItem(
                            icon: Icons.email,
                            label: 'Email',
                            value: senior.email,
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Erro: $err'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notifications Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notificações',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: notificationSettings.values.any((v) => v),
                            onChanged: (value) {
                              ref
                                  .read(notificationSettingsProvider.notifier)
                                  .setAll(value);
                            },
                            activeColor: const Color(0xFF6366F1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _NotificationToggle(
                        severity: 'critical',
                        label: 'Alertas Críticos',
                        description: 'Emergências e situações críticas',
                        notificationSettings: notificationSettings,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleNotification('critical');
                        },
                      ),
                      const SizedBox(height: 12),
                      _NotificationToggle(
                        severity: 'high',
                        label: 'Alertas Altos',
                        description: 'Situações que requerem atenção imediata',
                        notificationSettings: notificationSettings,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleNotification('high');
                        },
                      ),
                      const SizedBox(height: 12),
                      _NotificationToggle(
                        severity: 'medium',
                        label: 'Alertas Médios',
                        description: 'Situações que requerem acompanhamento',
                        notificationSettings: notificationSettings,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleNotification('medium');
                        },
                      ),
                      const SizedBox(height: 12),
                      _NotificationToggle(
                        severity: 'low',
                        label: 'Alertas Baixos',
                        description: 'Informações e notificações gerais',
                        notificationSettings: notificationSettings,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleNotification('low');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sobre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SettingItem(
                        icon: Icons.info,
                        label: 'Versão',
                        value: '1.0.0',
                      ),
                      const Divider(),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AMAVEL Family Companion'),
                            ),
                          );
                        },
                        child: const _SettingItem(
                          icon: Icons.help,
                          label: 'Sobre o App',
                          value: 'AMAVEL Companion',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Sair da Conta'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authService = ref.read(authServiceProvider);
                await authService.logout();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final String severity;
  final String label;
  final String description;
  final Map<String, bool> notificationSettings;
  final Function(bool) onChanged;

  const _NotificationToggle({
    required this.severity,
    required this.label,
    required this.description,
    required this.notificationSettings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: notificationSettings[severity] ?? false,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
