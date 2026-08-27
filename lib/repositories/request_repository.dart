import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/request.dart';
import '../models/request_fulfillment.dart';
import '../services/session_service.dart';

class RequestRepository {
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

  Future<void> createRequest({
    required String assistedPersonId,
    required String description,
    String? visitRecordId,
  }) async {
    final user = _currentUser;
    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception(
        'A descrição do pedido é obrigatória.',
      );
    }

    await _client.from('requests').insert({
      'organization_id': user.organizationId,
      'assisted_person_id': assistedPersonId,
      'visit_record_id': visitRecordId,
      'description': trimmedDescription,
      'status': 'pending',
      'created_by': user.id,
    });
  }

  Future<List<Request>> getOpenByPerson(
    String assistedPersonId,
  ) async {
    final user = _currentUser;

    final response = await _client
        .from('requests')
        .select()
        .eq('organization_id', user.organizationId)
        .eq('assisted_person_id', assistedPersonId)
        .inFilter(
          'status',
          [
            'pending',
            'partially_fulfilled',
          ],
        )
        .order('created_at', ascending: false);

    return response
        .map<Request>(
          (item) => Request.fromMap(item),
        )
        .toList();
  }

  Future<List<Request>> getOpenRequests() async {
    final user = _currentUser;

    final response = await _client
        .from('requests')
        .select('''
           *,
           assisted_people (
          name
           )
          ''')
        .eq('organization_id', user.organizationId)
        .inFilter(
          'status',
          [
            'pending',
            'partially_fulfilled',
          ],
        )
        .order('created_at', ascending: false);

    return response
        .map<Request>(
          (item) => Request.fromMap(item),
        )
        .toList();
  }

  Future<void> fulfillRequest({
    required String requestId,
    required String description,
    required bool completesRequest,
  }) async {
    _currentUser;

    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception(
        'A descrição do atendimento é obrigatória.',
      );
    }

    await _client.rpc(
      'fulfill_request',
      params: {
        'p_request_id': requestId,
        'p_description': trimmedDescription,
        'p_completes_request': completesRequest,
      },
    );
  }

  Future<void> cancelRequest(
    String requestId,
  ) async {
    final user = _currentUser;

    await _client
        .from('requests')
        .update({
          'status': 'canceled',
          'canceled_at':
              DateTime.now().toUtc().toIso8601String(),
          'updated_at':
              DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('organization_id', user.organizationId);
  }

  Future<List<RequestFulfillment>> getFulfillments(
    String requestId,
  ) async {
    final user = _currentUser;

    final response = await _client
        .from('request_fulfillments')
        .select()
        .eq('organization_id', user.organizationId)
        .eq('request_id', requestId)
        .order('delivered_at', ascending: false);

    return response
        .map<RequestFulfillment>(
          (item) => RequestFulfillment.fromMap(item),
        )
        .toList();
  }
}