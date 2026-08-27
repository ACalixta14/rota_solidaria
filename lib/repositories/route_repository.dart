import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/route.dart';
import '../services/session_service.dart';


class RouteRepository {
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

  Future<List<Route>> getAll() async {
    final user = _currentUser;

    final response = await _client
        .from('routes')
        .select()
        .eq('organization_id', user.organizationId)
        .order('route_date', ascending: false);

    return response
        .map<Route>(
          (item) => Route.fromMap(item),
        )
        .toList();
  }
Future<Route> getById(String routeId) async {
  final user = _currentUser;

  final response = await _client
      .from('routes')
      .select()
      .eq('id', routeId)
      .eq('organization_id', user.organizationId)
      .single();

  return Route.fromMap(response);
}

  Future<void> create({
    required DateTime routeDate,
  }) async {
    final user = _currentUser;

    if (!user.canManage) {
      throw Exception(
        'O utilizador não tem permissão para criar rotas.',
      );
    }

    await _client.from('routes').insert({
      'organization_id': user.organizationId,
      'route_date':
          routeDate.toIso8601String().split('T').first,
      'status': 'planned',
      'created_by': user.id,
    });
  }
Future<void> startRoute({
  required String routeId,
  required int startMileage,
}) async {
  _currentUser;

  if (startMileage < 0) {
    throw Exception(
      'A quilometragem inicial não pode ser negativa.',
    );
  }

  await _client.rpc(
    'start_route',
    params: {
      'p_route_id': routeId,
      'p_start_mileage': startMileage,
    },
  );
}
Future<void> completeRoute({
  required String routeId,
  required int endMileage,
}) async {
  _currentUser;

  if (endMileage < 0) {
    throw Exception(
      'A quilometragem final não pode ser negativa.',
    );
  }

  await _client.rpc(
    'complete_route',
    params: {
      'p_route_id': routeId,
      'p_end_mileage': endMileage,
    },
  );
}
}