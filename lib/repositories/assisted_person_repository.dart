import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/assisted_person.dart';
import '../services/session_service.dart';

//Repositorio resposável pelas operações das pessoas assistidas (DADOS)
//Centraliza acesso Supabase para leitura, criação, atualização, (des)ativação 

class AssistedPersonRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final SessionService _session = SessionService.instance;

  AppUser get _currentUser {
    final user = _session.currentUser;

    if (user == null) {
//interrompe e gera um erro
      throw Exception(
        'Não existe um utilizador autenticado na sessão.',
      );
    }

    return user;
  }

//Busca pessoas ativas, consulta pelo supabase e recebe como Map
//é convertido em objetos AssistedPerson através do fromMap()

//*REVISÃO - Diferente dos outros este apenas consulta "is_active"
//outros pegam .eq('organization_id', user.organizationId)  
//*/

  Future<List<AssistedPerson>> getAll() async {
    final response = await _client
        .from('assisted_people')
        .select()
        .eq('is_active', true)
        .order('name');

    return response
        .map<AssistedPerson>(
          (item) => AssistedPerson.fromMap(item),
        )
        .toList();
  }
Future<AssistedPerson> getById(String id) async {
  final user = _currentUser;

  final response = await _client
      .from('assisted_people')
      .select()
      .eq('id', id)
      .eq('organization_id', user.organizationId)
      .single();

  return AssistedPerson.fromMap(response);
}
  //metodo assincrono que busca e devolve uma lista de pessoas inativas
  Future<List<AssistedPerson>> getInactive() async {
  final user = _currentUser;

  if (!user.canManage) {
    throw Exception(
      'O utilizador não tem permissão para consultar pessoas inativas.',
    );
  }

  final response = await _client
      .from('assisted_people')
      .select()
      .eq('organization_id', user.organizationId)
      .eq('is_active', false)
      .order('name');

  return response
      .map<AssistedPerson>(
        (item) => AssistedPerson.fromMap(item),
      )
      .toList();
}

Future<void> reactivate(String id) async {
  final user = _currentUser;

  if (!user.canManage) {
    throw Exception(
      'O utilizador não tem permissão para reativar pessoas.',
    );
  }

  await _client.rpc(
    'reactivate_assisted_person',
    params: {
      'p_person_id': id,
    },
  );
}


  Future<void> create({
  required String name,
  required String nickname,
  required String mainAddress,
  required String mapsLink,
  required String phone,
  required String publicNotes,
}) async {
  final user = _currentUser;

  await _client.from('assisted_people').insert({
    'organization_id': user.organizationId,
    'name': name.isEmpty ? null : name,
    'nickname': nickname.isEmpty ? null : nickname,
    'main_address': mainAddress.isEmpty ? null : mainAddress,
    'maps_link': mapsLink.isEmpty ? null : mapsLink,
    'phone': phone.isEmpty ? null : phone,
    'public_notes': publicNotes.isEmpty ? null : publicNotes,
    'is_active': true,
    'created_by': user.id,
    'updated_by': user.id,
  });
}

Future<void> update({
  required String id,
  required String name,
  required String nickname,
  required String mainAddress,
  required String mapsLink,
  required String phone,
  required String publicNotes,
}) async {
  final user = _currentUser;

  await _client
      .from('assisted_people')
      .update({
        'name': name.isEmpty ? null : name,
        'nickname': nickname.isEmpty ? null : nickname,
        'main_address': mainAddress.isEmpty ? null : mainAddress,
        'maps_link': mapsLink.isEmpty ? null : mapsLink,
        'phone': phone.isEmpty ? null : phone,
        'public_notes': publicNotes.isEmpty ? null : publicNotes,
        'updated_by': user.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', id)
      .eq('organization_id', user.organizationId);
}

Future<void> deactivate({
  required String id,
  required String reason,
}) async {
  final user = _currentUser;

  if (!user.canManage) {
    throw Exception(
      'O utilizador não tem permissão para inativar pessoas.',
    );
  }

  final trimmedReason = reason.trim();

  if (trimmedReason.isEmpty) {
    throw Exception(
      'O motivo da inativação é obrigatório.',
    );
  }

  await _client.rpc(
    'deactivate_assisted_person',
    params: {
      'p_person_id': id,
      'p_reason': trimmedReason,
    },
  );
}

}