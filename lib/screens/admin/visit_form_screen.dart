import 'package:flutter/material.dart';

import '../../repositories/request_repository.dart';
import '../../repositories/visit_record_repository.dart';

class VisitFormScreen extends StatefulWidget {
  final String assistedPersonId;
  final String routeId;
  final String routeStopId;

  const VisitFormScreen({
    super.key,
    required this.assistedPersonId,
    required this.routeId,
    required this.routeStopId,
  });

  @override
  State<VisitFormScreen> createState() =>
      _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final VisitRecordRepository _visitRepository =
      VisitRecordRepository();

  final RequestRepository _requestRepository =
      RequestRepository();

  final _observationController = TextEditingController();

  bool _wasFound = true;
  bool _isSaving = false;

  String? _foodStatus;
  String? _notFoundReason;
  String? _emotionalState;
  String? _physicalCondition;

  Future<void> _save() async {
    if (_wasFound && _foodStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indique o resultado da entrega da alimentação.',
          ),
        ),
      );
      return;
    }

    if (!_wasFound && _notFoundReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indique o motivo pelo qual a pessoa não foi encontrada.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final visit = await _visitRepository.create(
        assistedPersonId: widget.assistedPersonId,
        routeId: widget.routeId,
        routeStopId: widget.routeStopId,
        wasFound: _wasFound,
        foodStatus: _wasFound ? _foodStatus : null,
        notFoundReason:
            _wasFound ? null : _notFoundReason,
        emotionalState:
            _wasFound ? _emotionalState : null,
        physicalCondition:
            _wasFound ? _physicalCondition : null,
        observation:
            _observationController.text.trim().isEmpty
                ? null
                : _observationController.text.trim(),
      );

      if (!mounted) return;

      if (_wasFound) {
        final hasRequest = await _askIfThereWasRequest();

        if (!mounted) return;

        if (hasRequest == true) {
          final description =
              await _askRequestDescription();

          if (!mounted) return;

          if (description != null &&
              description.trim().isNotEmpty) {
            await _requestRepository.createRequest(
              assistedPersonId:
                  widget.assistedPersonId,
              visitRecordId: visit.id,
              description: description,
            );
          }
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao registar visita: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool?> _askIfThereWasRequest() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pedido'),
          content: const Text(
            'A pessoa fez algum pedido?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askRequestDescription() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Novo pedido'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descrição do pedido',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Criar pedido'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registar visita'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pessoa encontrada'),
            value: _wasFound,
            onChanged: (value) {
              setState(() {
                _wasFound = value;

                if (_wasFound) {
                  _notFoundReason = null;
                } else {
                  _foodStatus = null;
                  _emotionalState = null;
                  _physicalCondition = null;
                }
              });
            },
          ),

          const SizedBox(height: 16),

          if (_wasFound) ...[
            DropdownButtonFormField<String>(
              value: _foodStatus,
              decoration: const InputDecoration(
                labelText: 'Alimentação',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'delivered',
                  child: Text('Entregue'),
                ),
                DropdownMenuItem(
                  value: 'refused',
                  child: Text('Recusada'),
                ),
                DropdownMenuItem(
                  value: 'not_applicable',
                  child: Text('Não aplicável'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _foodStatus = value;
                });
              },
            ),
//OPÇÕES QUE FOCAVAM EM UMA AVALIAÇÃO RÁPIDA FÍSICA E DE HUMOR DOS ASSISTIDOS
/*
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _emotionalState,
              decoration: const InputDecoration(
                labelText:
                    'Estado emocional percebido (opcional)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'well_disposed',
                  child: Text('Bem-disposto'),
                ),
                DropdownMenuItem(
                  value: 'calm',
                  child: Text('Tranquilo'),
                ),
                DropdownMenuItem(
                  value: 'neutral',
                  child: Text('Neutro'),
                ),
                DropdownMenuItem(
                  value: 'worried',
                  child: Text('Preocupado'),
                ),
                DropdownMenuItem(
                  value: 'very_down',
                  child: Text('Muito abatido'),
                ),
                DropdownMenuItem(
                  value: 'irritated',
                  child: Text('Irritado'),
                ),
                DropdownMenuItem(
                  value: 'very_tired',
                  child: Text('Muito cansado'),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Outro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _emotionalState = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _physicalCondition,
              decoration: const InputDecoration(
                labelText:
                    'Condição física observada (opcional)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'no_apparent_change',
                  child: Text(
                    'Sem alteração aparente',
                  ),
                ),
                DropdownMenuItem(
                  value: 'tired_or_weak',
                  child: Text(
                    'Cansado / debilitado',
                  ),
                ),
                DropdownMenuItem(
                  value: 'mobility_difficulty',
                  child: Text(
                    'Dificuldade de mobilidade',
                  ),
                ),
                DropdownMenuItem(
                  value: 'pain_or_discomfort',
                  child: Text(
                    'Sinais de dor / desconforto',
                  ),
                ),
                DropdownMenuItem(
                  value: 'visible_injury',
                  child: Text(
                    'Ferimento visível',
                  ),
                ),
                DropdownMenuItem(
                  value: 'appears_unwell',
                  child: Text(
                    'Aparência de doença',
                  ),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Outro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _physicalCondition = value;
                });
              },
            ),
    */
          ] else ...[
            DropdownButtonFormField<String>(
              value: _notFoundReason,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'not_at_location',
                  child: Text(
                    'Não estava no local',
                  ),
                ),
                DropdownMenuItem(
                  value: 'phone_not_answered',
                  child: Text(
                    'Telefone não atendido',
                  ),
                ),
                DropdownMenuItem(
                  value: 'location_empty',
                  child: Text(
                    'Local vazio / sem vestígios',
                  ),
                ),
                DropdownMenuItem(
                  value: 'location_changed',
                  child: Text(
                    'Localização alterada',
                  ),
                ),
                DropdownMenuItem(
                  value: 'access_impossible',
                  child: Text(
                    'Acesso impossível',
                  ),
                ),
                DropdownMenuItem(
                  value: 'not_visited_by_instruction',
                  child: Text(
                    'Visita não realizada por instrução',
                  ),
                ),
                DropdownMenuItem(
                  value: 'contact_refused',
                  child: Text(
                    'Recusa de contacto',
                  ),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Outro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _notFoundReason = value;
                });
              },
            ),
          ],

          const SizedBox(height: 16),

          TextField(
            controller: _observationController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving
                  ? 'A guardar...'
                  : 'Registar visita',
            ),
          ),
        ],
      ),
    );
  }
}