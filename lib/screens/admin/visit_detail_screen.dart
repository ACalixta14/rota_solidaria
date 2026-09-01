import 'package:flutter/material.dart';

import '../../models/visit_record.dart';

class VisitDetailScreen extends StatelessWidget {
  final VisitRecord visit;

  const VisitDetailScreen({
    super.key,
    required this.visit,
  });

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _foodStatusLabel(String value) {
    switch (value) {
      case 'delivered':
        return 'Entregue';
      case 'refused':
        return 'Recusada';
      case 'not_applicable':
        return 'Não aplicável';
      default:
        return value;
    }
  }

  String _emotionalStateLabel(String value) {
    switch (value) {
      case 'well_disposed':
        return 'Bem-disposto';
      case 'calm':
        return 'Tranquilo';
      case 'neutral':
        return 'Neutro';
      case 'worried':
        return 'Preocupado';
      case 'very_down':
        return 'Muito abatido';
      case 'irritated':
        return 'Irritado';
      case 'very_tired':
        return 'Muito cansado';
      case 'other':
        return 'Outro';
      default:
        return value;
    }
  }

  String _physicalConditionLabel(String value) {
    switch (value) {
      case 'no_apparent_change':
        return 'Sem alteração aparente';
      case 'tired_or_weak':
        return 'Cansado / debilitado';
      default:
        return value;
    }
  }

  Widget _detail({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da visita'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            visit.wasFound
                ? 'Pessoa encontrada'
                : 'Pessoa não encontrada',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 20),

          _detail(
            label: 'Data e hora',
            value: _formatDateTime(visit.createdAt),
          ),

          if (visit.wasFound &&
              visit.foodStatus != null) ...[
            _detail(
              label: 'Alimentação',
              value: _foodStatusLabel(
                visit.foodStatus!,
              ),
            ),
          ],

          if (!visit.wasFound &&
              visit.notFoundReason != null) ...[
            _detail(
              label: 'Motivo de não encontrada',
              value: visit.notFoundReason!,
            ),
          ],

          if (visit.emotionalState != null) ...[
            _detail(
              label: 'Estado emocional percebido',
              value: _emotionalStateLabel(
                visit.emotionalState!,
              ),
            ),
          ],

          if (visit.physicalCondition != null) ...[
            _detail(
              label: 'Condição física observada',
              value: _physicalConditionLabel(
                visit.physicalCondition!,
              ),
            ),
          ],

          if (visit.observation != null &&
              visit.observation!.isNotEmpty) ...[
            _detail(
              label: 'Observações',
              value: visit.observation!,
            ),
          ],

          if (visit.requestedItems != null &&
              visit.requestedItems!.isNotEmpty) ...[
            _detail(
              label: 'Pedidos registados',
              value: visit.requestedItems!,
            ),
          ],
        ],
      ),
    );
  }
}