import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/route.dart' as app_route;
import '../../repositories/route_repository.dart';
import '../../services/session_service.dart';
import 'route_detail_screen.dart';
import '../../repositories/route_stop_repository.dart';
import '../../repositories/visit_record_repository.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final RouteRepository _repository = RouteRepository();
  final SessionService _session = SessionService.instance;
//dados para exportar o relatório nas rotas  
  final RouteStopRepository _stopRepository = RouteStopRepository();
  final VisitRecordRepository _visitRepository = VisitRecordRepository(); 

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

  //relatorio
  Future<void> _copyFinalReport(app_route.Route route) async {
  final endMileage = route.endMileage;

  if (endMileage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Esta rota não tem quilometragem final registada.',
        ),
      ),
    );
    return;
  }

  try {
    final summary = await RouteDetailScreen.buildRouteSummary(
      route: route,
      endMileage: endMileage,
      stopRepository: _stopRepository,
      visitRepository: _visitRepository,
    );

    await Clipboard.setData(ClipboardData(text: summary));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Relatório copiado. Pode agora enviá-lo pelo WhatsApp.',
        ),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao recuperar relatório: $error'),
      ),
    );
  }
}

//restrição do relatorio mensal para o adm
Future<void> _selectMonthlyReport() async {
  if (!_session.canManage) {
    return;
  }

  final now = DateTime.now();

  final selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime(now.year, now.month, 1),
    firstDate: DateTime(now.year - 5, 1),
    lastDate: DateTime(now.year + 1, 12, 31),
    helpText: 'Selecionar mês do relatório',
  );

  if (selectedDate == null) return;

  try {
    final routes = await _repository.getAll();

    final completedRoutes = routes.where((route) {
      return route.status == 'completed' &&
          route.routeDate.year == selectedDate.year &&
          route.routeDate.month == selectedDate.month &&
          route.startMileage != null &&
          route.endMileage != null &&
          route.driverName != null &&
          route.driverName!.trim().isNotEmpty;
    }).toList();

    if (!mounted) return;

    if (completedRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não existem rotas concluídas com quilometragem neste mês.',
          ),
        ),
      );
      return;
    }

    completedRoutes.sort(
      (a, b) => a.routeDate.compareTo(b.routeDate),
    );

    int totalKm = 0;

    final Map<String, int> kmByDriver = {};
    final Map<String, int> routesByDriver = {};
    final Map<String, String> driverDisplayName = {};

    final buffer = StringBuffer();

    buffer.writeln(
      'RELATÓRIO DE ROTAS — '
      '${selectedDate.month.toString().padLeft(2, '0')}/'
      '${selectedDate.year}',
    );

    buffer.writeln();

    for (final route in completedRoutes) {
      final startMileage = route.startMileage!;
      final endMileage = route.endMileage!;
      final distance = endMileage - startMileage;

      final originalDriverName = route.driverName!.trim();

      // Permite considerar "Natalia", "natalia" e
      // " Natalia " como a mesma motorista.
      final driverKey = originalDriverName.toLowerCase();

      driverDisplayName.putIfAbsent(
        driverKey,
        () => originalDriverName,
      );

      totalKm += distance;

      kmByDriver[driverKey] =
          (kmByDriver[driverKey] ?? 0) + distance;

      routesByDriver[driverKey] =
          (routesByDriver[driverKey] ?? 0) + 1;

      buffer.writeln(
        '${_formatDate(route.routeDate)}'
        ' — $originalDriverName'
  ' — Inicial: $startMileage km'
  ' | Final: $endMileage km'
  ' | Percorridos: $distance km',
);
    }

    buffer.writeln();
    buffer.writeln('RESUMO DO MÊS');
    buffer.writeln(
      'Rotas concluídas: ${completedRoutes.length}',
    );
    buffer.writeln(
      'Total percorrido: $totalKm km',
    );

    buffer.writeln();
    buffer.writeln('POR MOTORISTA');

    final drivers = kmByDriver.keys.toList()
      ..sort((a, b) {
        return driverDisplayName[a]!
            .toLowerCase()
            .compareTo(
              driverDisplayName[b]!.toLowerCase(),
            );
      });

    for (final driverKey in drivers) {
      final name = driverDisplayName[driverKey]!;
      final km = kmByDriver[driverKey]!;
      final routeCount = routesByDriver[driverKey]!;

      buffer.writeln(
        '$name — '
        '$routeCount ${routeCount == 1 ? 'rota' : 'rotas'}'
        ' — $km km',
      );
    }

    final report = buffer.toString().trim();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Relatório '
            '${selectedDate.month.toString().padLeft(2, '0')}/'
            '${selectedDate.year}',
          ),
          content: SingleChildScrollView(
            child: SelectableText(report),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: report),
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Relatório mensal copiado.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erro ao gerar relatório mensal: $error',
        ),
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
  actions: [
    if(_session.canManage)
    IconButton(
      tooltip: 'Relatório mensal',
      icon: const Icon(Icons.bar_chart_outlined),
      onPressed: _selectMonthlyReport,
    ),
  ],
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
                trailing: _session.canManage
    ? PopupMenuButton<String>(
             onSelected: (value) async {
          if (value == 'copy_report') {
            await _copyFinalReport(route);
            return;
          }

          if (value != 'duplicate') return;

          final now = DateTime.now();

          final selectedDate = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(now.year - 1),
            lastDate: DateTime(now.year + 1),
          );

          if (selectedDate == null) return;

          try {
            await _repository.duplicateRoute(
              sourceRouteId: route.id,
              routeDate: selectedDate,
            );

            if (!mounted) return;

            _reload();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Rota duplicada com sucesso.',
                ),
              ),
            );
          } catch (error) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erro ao duplicar rota: $error',
                ),
              ),
            );
          }
        },
           itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_outlined),
                SizedBox(width: 12),
                Text('Duplicar rota'),
              ],
            ),
          ),
          if (route.status == 'completed' && route.endMileage != null)
            const PopupMenuItem<String>(
              value: 'copy_report',
              child: Row(
                children: [
                  Icon(Icons.description_outlined),
                  SizedBox(width: 12),
                  Text('Copiar relatório final'),
                ],
              ),
            ),
        ],
      )
    : const Icon(
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