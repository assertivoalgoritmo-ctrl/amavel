import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/family_providers.dart';
import '../models/alert.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);
    final seniorId = ref.watch(linkedSeniorIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    selected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pendentes',
                    selected: _selectedFilter == 'unresolved',
                    onTap: () => setState(() => _selectedFilter = 'unresolved'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Críticos',
                    selected: _selectedFilter == 'critical',
                    onTap: () => setState(() => _selectedFilter = 'critical'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Resolvidos',
                    selected: _selectedFilter == 'resolved',
                    onTap: () => setState(() => _selectedFilter = 'resolved'),
                  ),
                ],
              ),
            ),
          ),
          // Alerts List
          Expanded(
            child: alerts.when(
              data: (alertList) {
                final filtered = _filterAlerts(alertList);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final alert = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: _AlertListItem(
                        alert: alert,
                        onResolve: () => _showResolveDialog(
                          context,
                          ref,
                          seniorId.value ?? '',
                          alert,
                        ),
                        onAcknowledge: () => _acknowledgeAlert(
                          context,
                          ref,
                          seniorId.value ?? '',
                          alert,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Erro: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Alert> _filterAlerts(List<Alert> alerts) {
    switch (_selectedFilter) {
      case 'unresolved':
        return alerts.where((a) => !a.resolved).toList();
      case 'critical':
        return alerts
            .where((a) => a.severity == AlertSeverity.critical && !a.resolved)
            .toList();
      case 'resolved':
        return alerts.where((a) => a.resolved).toList();
      default:
        return alerts;
    }
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'unresolved':
        return 'Nenhum alerta pendente';
      case 'critical':
        return 'Nenhum alerta crítico';
      case 'resolved':
        return 'Nenhum alerta resolvido';
      default:
        return 'Nenhum alerta';
    }
  }

  void _acknowledgeAlert(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
    Alert alert,
  ) async {
    try {
      await ref.read(
        acknowledgeAlertProvider((seniorId, alert.id)).future,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta confirmado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _showResolveDialog(
    BuildContext context,
    WidgetRef ref,
    String seniorId,
    Alert alert,
  ) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolver Alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(alert.title),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notas da resolução',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Descreva como foi resolvido...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(
                  resolveAlertProvider(
                    (seniorId, alert.id, notesController.text),
                  ).future,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alerta resolvido')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? const Color(0xFF6366F1) : Colors.grey[300]!,
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF6366F1) : Colors.grey,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _AlertListItem extends StatelessWidget {
  final Alert alert;
  final VoidCallback onResolve;
  final VoidCallback onAcknowledge;

  const _AlertListItem({
    required this.alert,
    required this.onResolve,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    String severityLabel;

    switch (alert.severity) {
      case AlertSeverity.critical:
        severityColor = Colors.red;
        severityLabel = 'Crítico';
        break;
      case AlertSeverity.high:
        severityColor = Colors.orange;
        severityLabel = 'Alto';
        break;
      case AlertSeverity.medium:
        severityColor = Colors.amber;
        severityLabel = 'Médio';
        break;
      case AlertSeverity.low:
        severityColor = Colors.blue;
        severityLabel = 'Baixo';
        break;
    }

    return Card(
      elevation: alert.resolved ? 0 : 2,
      color: alert.resolved ? Colors.grey[50] : Colors.white,
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                severityLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(alert.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (alert.acknowledged)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else
              Icon(Icons.circle, color: Colors.grey[300], size: 20),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.description,
                  style: const TextStyle(fontSize: 14),
                ),
                if (alert.resolved && alert.resolvedNotes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notas da resolução:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.resolvedNotes!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!alert.resolved)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!alert.acknowledged)
                          ElevatedButton(
                            onPressed: onAcknowledge,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Confirmar'),
                          )
                        else
                          const SizedBox(),
                        if (!alert.acknowledged) const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: onResolve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Resolver'),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Resolvido em ${DateFormat('dd/MM HH:mm').format(alert.resolvedAt!)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
