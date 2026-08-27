import 'package:flutter/material.dart';

import '../../models/request.dart';
import '../../models/request_fulfillment.dart';
import '../../repositories/request_repository.dart';


class RequestDetailScreen extends StatefulWidget {
  final Request request;

  const RequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState
    extends State<RequestDetailScreen> {
  final RequestRepository _repository =
      RequestRepository();

  late Future<List<RequestFulfillment>> _fulfillmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadFulfillments();
  }

  void _loadFulfillments() {
    _fulfillmentsFuture =
        _repository.getFulfillments(widget.request.id);
  }

  void _reload() {
    setState(() {
      _loadFulfillments();
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'partially_fulfilled':
        return 'Parcialmente atendido';
      case 'fulfilled':
        return 'Atendido';
      case 'canceled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Future<void> _fulfillRequest() async {
    final descriptionController =
        TextEditingController();

    bool completesRequest = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Registar atendimento',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        descriptionController,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'O que foi entregue / atendido',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    title: const Text(
                      'Este atendimento conclui o pedido',
                    ),
                    value: completesRequest,
                    onChanged: (value) {
                      setDialogState(() {
                        completesRequest =
                            value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(false);
                  },
                  child:
                      const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (descriptionController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(true);
                  },
                  child:
                      const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      descriptionController.dispose();
      return;
    }

    final description =
        descriptionController.text.trim();

    descriptionController.dispose();

    await _repository.fulfillRequest(
      requestId: widget.request.id,
      description: description,
      completesRequest: completesRequest,
    );

    if (!mounted) return;

    if (completesRequest) {
      Navigator.of(context).pop(true);
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Atendimento parcial registado.',
        ),
      ),
    );
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar pedido'),
          content: const Text(
            'Deseja cancelar este pedido?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text('Cancelar pedido'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _repository.cancelRequest(
      widget.request.id,
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do pedido'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            request.personName ?? 'Sem nome',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 12),
          Text(request.description),
          const SizedBox(height: 8),
          Text(
            'Estado: '
            '${_statusLabel(request.status)}',
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _fulfillRequest,
            icon: const Icon(
              Icons.inventory_2_outlined,
            ),
            label: const Text(
              'Registar atendimento',
            ),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _cancelRequest,
            icon: const Icon(
              Icons.cancel_outlined,
            ),
            label: const Text(
              'Cancelar pedido',
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          const Text(
            'Histórico de atendimentos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          FutureBuilder<
              List<RequestFulfillment>>(
            future: _fulfillmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Erro ao carregar histórico: '
                  '${snapshot.error}',
                );
              }

              final fulfillments =
                  snapshot.data ?? [];

              if (fulfillments.isEmpty) {
                return const Text(
                  'Ainda não existem atendimentos registados.',
                );
              }

              return Column(
                children:
                    fulfillments.map((item) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        item.description,
                      ),
                      subtitle: Text(
                        '${item.deliveredAt.day.toString().padLeft(2, '0')}/'
                        '${item.deliveredAt.month.toString().padLeft(2, '0')}/'
                        '${item.deliveredAt.year}',
                      ),
                      trailing:
                          item.completesRequest
                              ? const Icon(
                                  Icons
                                      .check_circle_outline,
                                )
                              : const Icon(
                                  Icons
                                      .pending_outlined,
                                ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}