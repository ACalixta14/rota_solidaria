
import 'package:flutter/material.dart';

import '../../models/route_inventory_item.dart';
import '../../repositories/route_inventory_repository.dart';

class RouteInventoryPanel extends StatefulWidget {
  final String routeId;
  final bool canEdit;

  const RouteInventoryPanel({
    super.key,
    required this.routeId,
    required this.canEdit,
  });

  @override
  State<RouteInventoryPanel> createState() =>
      _RouteInventoryPanelState();
}

class _RouteInventoryPanelState
    extends State<RouteInventoryPanel> {
  final RouteInventoryRepository _repository =
      RouteInventoryRepository();

  late Future<List<RouteInventoryItem>> _itemsFuture;

  bool _expanded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _itemsFuture = _repository.getByRoute(widget.routeId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _itemsFuture;
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro no contador: $error')),
    );
  }

  Future<void> _adjust(
    RouteInventoryItem item,
    int delta,
  ) async {
    if (_busy || !widget.canEdit) return;

    setState(() => _busy = true);

    try {
      await _repository.adjustItem(
        itemId: item.id,
        delta: delta,
      );

      if (!mounted) return;
      await _refresh();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addItem() async {
    if (_busy || !widget.canEdit) return;

    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adicionar item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do item',
                hintText: 'Ex.: Refeições quentes',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade inicial',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final quantity = int.tryParse(
                quantityController.text.trim(),
              );

              if (name.isEmpty ||
                  quantity == null ||
                  quantity < 0) {
                return;
              }

              Navigator.of(dialogContext).pop({
                'name': name,
                'quantity': quantity,
              });
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    // Os valores já foram recolhidos antes de
    // libertar os controladores.
    nameController.dispose();
    quantityController.dispose();

    if (result == null || !mounted) return;

    setState(() => _busy = true);

    try {
      await _repository.addItem(
        routeId: widget.routeId,
        itemName: result['name'] as String,
        quantity: result['quantity'] as int,
      );

      if (!mounted) return;
      await _refresh();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant_outlined),
            title: const Text('Contador de alimentos'),
            trailing: Icon(
              _expanded
                  ? Icons.expand_less
                  : Icons.expand_more,
            ),
            onTap: () {
              setState(() => _expanded = !_expanded);
            },
          ),
          if (_expanded)
            FutureBuilder<List<RouteInventoryItem>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Erro ao carregar: ${snapshot.error}',
                    ),
                  );
                }

                final items =
                    snapshot.data ?? <RouteInventoryItem>[];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in items)
                      ListTile(
                        title: Text(item.itemName),
                        subtitle: Text(
                          'Inicial: ${item.initialQuantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Descontar uma unidade',
                              onPressed: widget.canEdit &&
                                      !_busy &&
                                      item.remainingQuantity > 0
                                  ? () => _adjust(item, -1)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text(
                              '${item.remainingQuantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Acrescentar uma unidade',
                              onPressed: widget.canEdit && !_busy
                                  ? () => _adjust(item, 1)
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Ainda não existem itens nesta rota.',
                        ),
                      ),
                    if (widget.canEdit)
                      TextButton.icon(
                        onPressed: _busy ? null : _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar novo item'),
                      ),
                    TextButton.icon(
                      onPressed: _busy ? null : () {
                        _refresh().catchError(_showError);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar'),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
