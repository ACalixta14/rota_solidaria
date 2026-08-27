// Representa as funções permitidas atualmente no aplicativo.
enum UserRole {
  admin,
  coordinator,
  volunteer;

  // Converte o texto recebido do Supabase em um valor do enum.
  static UserRole? fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;

      case 'coordinator':
        return UserRole.coordinator;

      case 'volunteer':
        return UserRole.volunteer;

      default:
        return null;
    }
  }

  // Nome amigável para mostrar na interface.
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';

      case UserRole.coordinator:
        return 'Coordenador';

      case UserRole.volunteer:
        return 'Voluntário';
    }
  }
}

class AppUser {
  final String id;
  final String organizationId;
  final String fullName;
  final String? email;
  final bool isActive;

  // Set evita funções repetidas.
  final Set<UserRole> roles;

  const AppUser({
    required this.id,
    required this.organizationId,
    required this.fullName,
    required this.email,
    required this.isActive,
    required this.roles,
  });

  // Facilita as verificações em outras partes do aplicativo.
  bool get isAdmin {
    return roles.contains(UserRole.admin);
  }

  bool get isCoordinator {
    return roles.contains(UserRole.coordinator);
  }

  bool get isVolunteer {
    return roles.contains(UserRole.volunteer);
  }

  // Admin ou coordenador podem gerir pessoas acompanhadas.
  bool get canManage {
    return isAdmin || isCoordinator;
  }

  factory AppUser.fromMap({
    required Map<String, dynamic> profileMap,
    required List<Map<String, dynamic>> rolesMaps,
  }) {
    final parsedRoles = rolesMaps
        .map((roleMap) {
          final roleValue = roleMap['role'];

          if (roleValue is! String) {
            return null;
          }

          return UserRole.fromString(roleValue);
        })
        .whereType<UserRole>()
        .toSet();

    return AppUser(
      id: profileMap['id'] as String,
      organizationId: profileMap['organization_id'] as String,
      fullName:
          (profileMap['full_name'] as String?)?.trim().isNotEmpty == true
              ? profileMap['full_name'] as String
              : 'Utilizador',
      email: profileMap['email'] as String?,
      isActive: profileMap['is_active'] as bool? ?? false,
      roles: parsedRoles,
    );
  }
}