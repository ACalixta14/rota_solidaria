import 'package:flutter/material.dart';

import '../../models/route.dart' as app_route;
import '../../repositories/route_repository.dart';
import '../../services/session_service.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final RouteRepository _repository = RouteRepository();
  final SessionService _session = SessionService.instance;

late Future<List<app_route.Route>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  void _loadRoutes() {
    _routesFuture = _repository.getAll();
  }

  void _reload() {
    setState(() {
      _loadRoutes();
    });
  }

  Future<void> _createRoute() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (selectedDate == null) return;

    try {
      await _repository.create(
        routeDate: selectedDate,
      );

      if (!mounted) return;

      _reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota criada com sucesso.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar rota: $error'),
        ),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'planned':
        return 'Planeada';
      case 'in_progress':
        return 'Em curso';
      case 'completed':
        return 'Concluída';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotas'),
      ),
      floatingActionButton: _session.canManage
          ? FloatingActionButton(
              onPressed: _createRoute,
              child: const Icon(Icons.add),
            )
          : null,
      body: FutureBuilder<List<app_route.Route>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar rotas: ${snapshot.error}',
              ),
            );
          }

          final routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return const Center(
              child: Text('Ainda não existem rotas.'),
            );
          }

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              return ListTile(
                leading: const Icon(Icons.route_outlined),
                title: Text(
                  'Rota de ${_formatDate(route.routeDate)}',
                ),
                subtitle: Text(
                  _statusLabel(route.status),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
          onTap: () async {
  final updated =
      await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => RouteDetailScreen(
        route: route,
      ),
    ),
  );

  if (updated == true && mounted) {
    _reload();
  }
},
              );
            },
          );
        },
      ),
    );
  }
}