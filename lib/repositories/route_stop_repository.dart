import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/route_stop.dart';
import '../services/session_service.dart';

class RouteStopRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final SessionService _session = SessionService.instance;

  AppUser get _currentUser {
    final user = _session.currentUser;

    if (user == null) {
      throw Exception(
        'Não existe um utilizador autenticado na sessão.',
      );
    }

    return user;
  }

  Future<List<RouteStop>> getByRoute(String routeId) async {
    final user = _currentUser;

    final response = await _client
        .from('route_stops')

//selecionanando relação existente já em route_stops.assisted_person_id
        .select('''
  *,
  assisted_people (
    name,
    main_address,
    maps_link,
    phone
  )
''')
        .eq('organization_id', user.organizationId)
.eq('route_id', routeId)
.order(
  'stop_order',
  ascending: true,
);

    return response
        .map<RouteStop>(
          (item) => RouteStop.fromMap(item),
        )
        .toList();
  }

  Future<void> addPerson({
    required String routeId,
    required String assistedPersonId,
    required int stopOrder,
  }) async {
    final user = _currentUser;

    if (!user.canManage) {
      throw Exception(
        'O utilizador não tem permissão para alterar rotas.',
      );
    }

    if (stopOrder <= 0) {
      throw Exception(
        'A ordem da paragem deve ser maior que zero.',
      );
    }

    await _client.from('route_stops').insert({
      'organization_id': user.organizationId,
      'route_id': routeId,
      'assisted_person_id': assistedPersonId,
      'stop_order': stopOrder,
      'created_by': user.id,
    });
  }
Future<void> remove({
  required String routeId,
  required String routeStopId,
}) async {
  final user = _currentUser;

  if (!user.canManage) {
    throw Exception(
      'O utilizador não tem permissão para alterar rotas.',
    );
  }

  await _client.rpc(
    'remove_route_stop',
    params: {
      'p_route_id': routeId,
      'p_route_stop_id': routeStopId,
    },
  );
}
  Future<void> reorder({
  required String routeId,
  required List<RouteStop> stops,
}) async {
  final user = _currentUser;

  if (!user.canManage) {
    throw Exception(
      'O utilizador não tem permissão para reorganizar rotas.',
    );
  }

  await _client.rpc(
    'reorder_route_stops',
    params: {
      'p_route_id': routeId,
      'p_stop_ids': stops.map((stop) => stop.id).toList(),
    },
  );
}

}