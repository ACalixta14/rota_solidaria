import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/visit_record.dart';
import '../services/session_service.dart';

class VisitRecordRepository {
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

Future<VisitRecord> create({
  required String assistedPersonId,
  required bool wasFound,
  required String routeId,
  required String routeStopId,
  String? foodStatus,
  String? notFoundReason,
  String? emotionalState,
  String? physicalCondition,
  String? observation,
}) async {
  final user = _currentUser;

  final response = await _client
      .from('visit_records')
      .insert({
        'organization_id': user.organizationId,
        'assisted_person_id': assistedPersonId,
        'route_id': routeId,
        'route_stop_id': routeStopId,
        'volunteer_id': user.id,
        'was_found': wasFound,
        'food_status': foodStatus,
        'not_found_reason': notFoundReason,
        'emotional_state': emotionalState,
        'physical_condition': physicalCondition,
        'observation': observation,
      })
      .select()
      .single();

  return VisitRecord.fromMap(response);
}

  Future<List<VisitRecord>> getByPerson(
    String assistedPersonId,
  ) async {
    final response = await _client
        .from('visit_records')
        .select()
        .eq('assisted_person_id', assistedPersonId)
        .order('created_at', ascending: false);

    return response
        .map<VisitRecord>(
          (item) => VisitRecord.fromMap(item),
        )
        .toList();
  }
  
  Future<Set<String>> getVisitedRouteStopIds(
  String routeId,
) async {
  final user = _currentUser;

  final response = await _client
      .from('visit_records')
      .select('route_stop_id')
      .eq('organization_id', user.organizationId)
      .eq('route_id', routeId)
      .not('route_stop_id', 'is', null);

  return response
      .map<String?>(
        (item) => item['route_stop_id'] as String?,
      )
      .whereType<String>()
      .toSet();
}
Future<List<VisitRecord>> getByRoute(
  String routeId,
) async {
  final user = _currentUser;

  final response = await _client
      .from('visit_records')
      .select()
      .eq('organization_id', user.organizationId)
      .eq('route_id', routeId)
      .order('created_at');

  return response
      .map<VisitRecord>(
        (item) => VisitRecord.fromMap(item),
      )
      .toList();
}
}