import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/session_service.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Faz login com e-mail e senha.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Cria uma nova conta no Supabase Auth.
  //
  // O Flutter envia apenas os dados pessoais necessários.
  // A organização e a função "volunteer" são definidas
  // automaticamente pelo banco através de handle_new_user().
  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

  // Encerra a sessão atual.
  Future<void> signOut() async {
    await _client.auth.signOut();

    // Também limpa o utilizador guardado em memória.
    SessionService.instance.clear();
  }

  // Utilizador autenticado no Supabase Auth.
  User? get currentAuthUser {
    return _client.auth.currentUser;
  }

  // Sessão atual.
  Session? get currentSession {
    return _client.auth.currentSession;
  }

  // Avisa quando acontece login, logout
  // ou outra alteração na autenticação.
  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  // Busca o perfil e as funções do utilizador autenticado.
  Future<AppUser?> getCurrentProfile() async {
    final authUser = currentAuthUser;

    // Não existe utilizador autenticado.
    if (authUser == null) {
      SessionService.instance.clear();
      return null;
    }

    // Primeiro buscamos o perfil.
    final profileData = await _client
        .from('profiles')
        .select(
          'id, organization_id, full_name, email, is_active',
        )
        .eq('id', authUser.id)
        .maybeSingle();

    // Existe uma conta autenticada, mas nenhum perfil correspondente.
    if (profileData == null) {
      SessionService.instance.clear();
      return null;
    }

    final organizationId = profileData['organization_id'];

    // Garante que o perfil possui uma organização válida.
    if (organizationId is! String || organizationId.isEmpty) {
      throw const FormatException(
        'O perfil não possui uma organização válida.',
      );
    }

    // Depois buscamos todas as funções desse utilizador
    // dentro da sua organização.
    final rolesResponse = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', authUser.id)
        .eq('organization_id', organizationId);

    final rolesData = List<Map<String, dynamic>>.from(
      rolesResponse,
    );

    // Só podemos criar o AppUser depois de obter
    // profileData e rolesData.
    final user = AppUser.fromMap(
      profileMap: Map<String, dynamic>.from(profileData),
      rolesMaps: rolesData,
    );

    // Guarda o utilizador em memória.
    SessionService.instance.setUser(user);

    return user;
  }
}