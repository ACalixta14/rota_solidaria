
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_inventory_item.dart';
import '../services/session_service.dart';

class RouteInventoryRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final SessionService _session = SessionService.instance;

  String get _organizationId {
    final user = _session.currentUser;

    if (user == null) {
      throw Exception(
        'Não existe um utilizador autenticado na sessão.',
      );
    }

    return user.organizationId;
  }

  // Consultar os itens de uma rota.
  Future<List<RouteInventoryItem>> getByRoute(
    String routeId,
  ) async {
    final organizationId = _organizationId;

    final response = await _client
        .from('route_inventory_items')
        .select()
        .eq('route_id', routeId)
        .eq('organization_id', organizationId)
        .order('created_at', ascending: true);

    return response
        .map<RouteInventoryItem>(
          (item) => RouteInventoryItem.fromMap(item),
        )
        .toList();
  }

  // Adicionar um novo item ao contador.
  Future<RouteInventoryItem> addItem({
    required String routeId,
    required String itemName,
    required int quantity,
  }) async {
    _organizationId;

    if (itemName.trim().isEmpty) {
      throw Exception('O nome do item é obrigatório.');
    }

    if (quantity < 0) {
      throw Exception(
        'A quantidade não pode ser negativa.',
      );
    }

    final response = await _client.rpc(
      'add_route_inventory_item',
      params: {
        'p_route_id': routeId,
        'p_item_name': itemName.trim(),
        'p_quantity': quantity,
      },
    );

    return RouteInventoryItem.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  // Aumentar ou diminuir uma unidade.
  Future<RouteInventoryItem> adjustItem({
    required String itemId,
    required int delta,
  }) async {
    _organizationId;

    if (delta != 1 && delta != -1) {
      throw Exception(
        'A alteração deve ser +1 ou -1.',
      );
    }

    final response = await _client.rpc(
      'adjust_route_inventory_item',
      params: {
        'p_item_id': itemId,
        'p_delta': delta,
      },
    );

    return RouteInventoryItem.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }
}
