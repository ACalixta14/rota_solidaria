import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import 'people_list_screen.dart';
import 'routes_screen.dart';
import 'requests_screen.dart';
import 'people_map_screen.dart';


class AdminHomeScreen extends StatelessWidget {
  final AppUser user;

  const AdminHomeScreen({
    super.key,
    required this.user,
  });

  Future<void> _signOut(BuildContext context) async {
    final authRepository = AuthRepository();

    try {
      await authRepository.signOut();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair: $error'),
        ),
      );
    }
  }

//aqui sinaliza qual tipo de perfil entrou 
  String get _roleLabel {
    if (user.isAdmin) {
      return UserRole.admin.label;
    }

    if (user.isCoordinator) {
      return UserRole.coordinator.label;
    }
    
    if (user.isVolunteer){
      return UserRole.volunteer.label;
    }

    return 'Utilizador';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Solidária'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(_roleLabel),
                    if (user.email != null) ...[
                      const SizedBox(height: 4),
                      Text(user.email!),
                    ],
                  ],
                ),
              ),
            ),
            
// botão pessoas acompanhadas
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.people_outline),
              label: const Text('Pessoas acompanhadas'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PeopleListScreen(),
                  ),
                );
              },
            ),

            // botão rotas
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.route_outlined),
              label: const Text('Rotas'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RoutesScreen(),
                  ),
                );
              },
            ),
              const SizedBox(height: 12),

ElevatedButton.icon(
  icon: const Icon(Icons.inventory_2_outlined),
  label: const Text('Pedidos em aberto'),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RequestsScreen(),
      ),
    );
  },
),

// botão mapa de pessoas
const SizedBox(height: 12),
ElevatedButton.icon(
  icon: const Icon(Icons.map_outlined),
  label: const Text('Mapa de pessoas'),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PeopleMapScreen(),
      ),
    );
  },
),

          ],
        ),
      ),
    );
  }
}