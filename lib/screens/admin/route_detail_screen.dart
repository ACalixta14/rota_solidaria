import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/assisted_person.dart';
import '../../models/route.dart' as app_route;
import '../../models/route_stop.dart';
import '../../repositories/assisted_person_repository.dart';
import '../../repositories/route_repository.dart';
import '../../repositories/route_stop_repository.dart';
import '../../repositories/visit_record_repository.dart';
import '../../services/session_service.dart';
import 'visit_form_screen.dart';
import 'person_detail_screen.dart';


class RouteDetailScreen extends StatefulWidget {
  final app_route.Route route;

  const RouteDetailScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteDetailScreen> createState() =>
      _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final RouteStopRepository _stopRepository =
      RouteStopRepository();

  final AssistedPersonRepository _personRepository =
      AssistedPersonRepository();

  final RouteRepository _routeRepository =
      RouteRepository();

  final VisitRecordRepository _visitRepository =
      VisitRecordRepository();

  final SessionService _session = SessionService.instance;

  late Future<List<RouteStop>> _stopsFuture;
  late Future<Set<String>> _visitedStopIdsFuture;
  late app_route.Route _route;


  @override
  void initState() {
    super.initState();
    _route = widget.route;
    _loadData();
  }

  void _loadData() {
    _stopsFuture =
        _stopRepository.getByRoute(widget.route.id);

    _visitedStopIdsFuture =
        _visitRepository.getVisitedRouteStopIds(
      widget.route.id,
    );
  }

  void _reload() {
    setState(() {
      _loadData();
    });
  }

  Future<void> _addPeople() async {
    final people = await _personRepository.getAll();

    final currentStops =
        await _stopRepository.getByRoute(
      widget.route.id,
    );

    if (!mounted) return;

    final existingIds = currentStops
        .map((stop) => stop.assistedPersonId)
        .toSet();

    final availablePeople = people
        .where(
          (person) => !existingIds.contains(person.id),
        )
        .toList();

    if (availablePeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não existem outras pessoas disponíveis.',
          ),
        ),
      );

      return;
    }

    final selectedIds = <String>{};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adicionar pessoas'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePeople.length,
                  itemBuilder: (context, index) {
                    final person =
                        availablePeople[index];

                    return CheckboxListTile(
                      value:
                          selectedIds.contains(person.id),
                      title: Text(
                        person.name ?? 'Sem nome',
                      ),
                      subtitle:
                          person.mainAddress == null
                              ? null
                              : Text(
                                  person.mainAddress!,
                                ),
                      onChanged: (selected) {
                        setDialogState(() {
                          if (selected == true) {
                            selectedIds.add(person.id);
                          } else {
                            selectedIds.remove(
                              person.id,
                            );
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(true);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true ||
        selectedIds.isEmpty) {
      return;
    }

    var nextOrder = currentStops.length + 1;

    for (final personId in selectedIds) {
      await _stopRepository.addPerson(
        routeId: widget.route.id,
        assistedPersonId: personId,
        stopOrder: nextOrder,
      );

      nextOrder++;
    }

    if (!mounted) return;

    _reload();
  }

  Future<void> _startRoute() async {
    final controller = TextEditingController();

    final startMileage = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Iniciar rota'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quilometragem inicial',
              suffixText: 'km',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final mileage = int.tryParse(
                  controller.text.trim(),
                );

                if (mileage == null ||
                    mileage < 0) {
                  return;
                }

                Navigator.of(dialogContext)
                    .pop(mileage);
              },
              child: const Text('Iniciar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (startMileage == null) return;

    try {
      await _routeRepository.startRoute(
        routeId: widget.route.id,
        startMileage: startMileage,
      );

      if (!mounted) return;

   final updatedRoute =
    await _routeRepository.getById(_route.id);

          if (!mounted) return;

          setState(() {
            _route = updatedRoute;
            _loadData();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Rota iniciada com sucesso.',
              ),
            ),
          );

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao iniciar rota: $error',
          ),
        ),
      );
    }
  }
  Future<String> _buildRouteSummary({
  required int endMileage,
}) async {
  final stops = await _stopRepository.getByRoute(
    widget.route.id,
  );

  final visits = await _visitRepository.getByRoute(
    widget.route.id,
  );

  final visitByPersonId = {
    for (final visit in visits)
      visit.assistedPersonId: visit,
  };

  final foundCount =
      visits.where((visit) => visit.wasFound).length;

  final notFoundCount =
      visits.where((visit) => !visit.wasFound).length;

  final startMileage = widget.route.startMileage;

  final distance = startMileage == null
      ? null
      : endMileage - startMileage;

  final buffer = StringBuffer();

  buffer.writeln(
    'ROTA SOLIDÁRIA — ${_formatDate(widget.route.routeDate)}',
  );
  buffer.writeln();

  if (startMileage != null) {
    buffer.writeln(
      'Quilometragem inicial: $startMileage km',
    );
  }

  buffer.writeln(
    'Quilometragem final: $endMileage km',
  );

  if (distance != null) {
    buffer.writeln(
      'Total percorrido: $distance km',
    );
  }

  buffer.writeln();
  buffer.writeln('Pessoas acompanhadas:');

  for (final stop in stops) {
    final visit =
        visitByPersonId[stop.assistedPersonId];

    final status = visit == null
        ? 'Sem registo'
        : visit.wasFound
            ? 'Encontrado'
            : 'Não encontrado';

    buffer.writeln(
      '${stop.stopOrder}. '
      '${stop.personName ?? 'Sem nome'} — $status',
    );
  }

  buffer.writeln();
  buffer.writeln('Resumo:');
  buffer.writeln('Encontrados: $foundCount');
  buffer.writeln(
    'Não encontrados: $notFoundCount',
  );
  buffer.writeln(
    'Total da rota: ${stops.length}',
  );

  return buffer.toString().trim();
}
Future<void> _completeRoute() async {
  final controller = TextEditingController();

  final endMileage = await showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Finalizar rota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.route.startMileage != null)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Text(
                  'Quilometragem inicial: '
                  '${widget.route.startMileage} km',
                ),
              ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quilometragem final',
                suffixText: 'km',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final mileage = int.tryParse(
                controller.text.trim(),
              );

              if (mileage == null || mileage < 0) {
                return;
              }

              Navigator.of(dialogContext).pop(
                mileage,
              );
            },
            child: const Text('Finalizar'),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (endMileage == null) return;

  try {
    await _routeRepository.completeRoute(
      routeId: widget.route.id,
      endMileage: endMileage,
    );

    if (!mounted) return;

    final startMileage =
        widget.route.startMileage;

    final distance = startMileage == null
        ? null
        : endMileage - startMileage;
    final summary = await _buildRouteSummary(
     endMileage: endMileage,
        );

if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rota finalizada'),
          content: SingleChildScrollView(
            child: Text(summary),
          ),
          actions: [
  TextButton.icon(
    onPressed: () async {
      await Clipboard.setData(
        ClipboardData(
          text: summary,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Resumo copiado.',
          ),
        ),
      );
    },
    icon: const Icon(Icons.copy_outlined),
    label: const Text('Copiar'),
  ),
  TextButton.icon(
    onPressed: () {
      SharePlus.instance.share(
        ShareParams(
          text: summary,
        ),
      );
    },
    icon: const Icon(Icons.share_outlined),
    label: const Text('Partilhar'),
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

    if (!mounted) return;

    Navigator.of(context).pop(true);
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erro ao finalizar rota: $error',
        ),
      ),
    );
  }
}
  Future<void> _registerVisit(
    RouteStop stop,
  ) async {
    final created =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitFormScreen(
          assistedPersonId:
              stop.assistedPersonId,
          routeId: widget.route.id,
          routeStopId: stop.id,
        ),
      ),
    );

    if (created == true && mounted) {
      _reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Visita registada com sucesso.',
          ),
        ),
      );
    }
  }
Future<void> _openPersonProfile(
  RouteStop stop,
) async {
  try {
    final person = await _personRepository.getById(
      stop.assistedPersonId,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          person: person,
        ),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erro ao abrir o perfil: $error',
        ),
      ),
    );
  }
}
  Future<void> _openMaps(
    String? mapsLink,
  ) async {
    if (mapsLink == null ||
        mapsLink.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta pessoa não tem localização registada.',
          ),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(
      mapsLink.trim(),
    );

    if (uri == null ||
        !await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        )) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir a localização.',
          ),
        ),
      );
    }
  }
Future<void> _callPhone(
  String? phone,
) async {
  if (phone == null || phone.trim().isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Esta pessoa não tem telefone registado.',
        ),
      ),
    );

    return;
  }

  final uri = Uri(
    scheme: 'tel',
    path: phone.trim(),
  );

  if (!await launchUrl(uri)) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível abrir o telefone.',
        ),
      ),
    );
  }
}
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPlanned =
        _route.status == 'planned';

    final isInProgress =
        _route.status == 'in_progress';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rota ${_formatDate(widget.route.routeDate)}',
        ),
      ),

      floatingActionButton:
          _session.canManage && isPlanned
              ? FloatingActionButton(
                  onPressed: _addPeople,
                  tooltip: 'Adicionar pessoas',
                  child: const Icon(
                    Icons.person_add,
                  ),
                )
              : null,

      body: Column(
        children: [
          if (isPlanned)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startRoute,
                  icon: const Icon(
                    Icons.play_arrow,
                  ),
                  label: const Text(
                    'Iniciar rota',
                  ),
                ),
              ),
            ),
if (isInProgress)
  Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _completeRoute,
        icon: const Icon(
          Icons.flag_outlined,
        ),
        label: const Text(
          'Finalizar rota',
        ),
      ),
    ),
  ),
          Expanded(
            child:
                FutureBuilder<List<RouteStop>>(
              future: _stopsFuture,
              builder:
                  (context, stopsSnapshot) {
                if (stopsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (stopsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar a rota: '
                      '${stopsSnapshot.error}',
                    ),
                  );
                }

                final stops =
                    stopsSnapshot.data ?? [];

                if (stops.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ainda não existem pessoas '
                      'nesta rota.',
                    ),
                  );
                }

                return FutureBuilder<Set<String>>(
                  future: _visitedStopIdsFuture,
                  builder:
                      (context, visitsSnapshot) {
                    if (visitsSnapshot
                            .connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (visitsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar o estado '
                          'das visitas: '
                          '${visitsSnapshot.error}',
                        ),
                      );
                    }

                    final visitedStopIds =
                        visitsSnapshot.data ??
                            <String>{};

                    Widget buildStopTile(
                      BuildContext context,
                      int index,
                    ) {
                      final stop = stops[index];

                      final visitRegistered =
                          visitedStopIds.contains(
                        stop.id,
                      );

                      return ListTile(
                        key: ValueKey(stop.id),

                        leading: Stack(
                          alignment:
                              Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              child: Text(
                                '${stop.stopOrder}',
                              ),
                            ),

                            if (visitRegistered)
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                              ),
                          ],
                        ),

                        title: Text(
                          stop.personName ??
                              'Sem nome',
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (stop.personAddress != null)
                              Text(
                                stop.personAddress!,
                              ),

                            if (visitRegistered)
                              const Text(
                                'Visita registada',
                              ),

                            if (isInProgress)
                              TextButton.icon(
                                onPressed: () {
                                  _openPersonProfile(
                                    stop,
                                  );
                                },
                                icon: const Icon(
                                  Icons.person_outline,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Ver perfil',
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize:
                                      const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize
                                          .shrinkWrap,
                                ),
                              ),
                          ],
                        ),

                        trailing:
                            isPlanned &&
                                    _session.canManage
                                ? const Icon(
                                    Icons.drag_handle,
                                  )
                                : isInProgress
                                    ? Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip:
                                                'Abrir localização',
                                            icon: const Icon(
                                              Icons
                                                  .navigation_outlined,
                                            ),
                                            onPressed:
                                                stop.personMapsLink ==
                                                        null
                                                    ? null
                                                    : () =>
                                                        _openMaps(
                                                          stop.personMapsLink,
                                                        ),
                                          ),
                                          IconButton(
                                            tooltip:
                                                'Telefonar',
                                            icon: const Icon(
                                              Icons
                                                  .phone_outlined,
                                            ),
                                            onPressed:
                                                stop.personPhone ==
                                                            null ||
                                                        stop
                                                            .personPhone!
                                                            .trim()
                                                            .isEmpty
                                                    ? null
                                                    : () =>
                                                        _callPhone(
                                                          stop.personPhone,
                                                        ),
                                          ),

                                          if (!visitRegistered)
                                            IconButton(
                                              tooltip:
                                                  'Registar visita',
                                              icon: const Icon(
                                                Icons
                                                    .assignment_turned_in_outlined,
                                              ),
                                              onPressed: () {
                                                _registerVisit(
                                                  stop,
                                                );
                                              },
                                            )
                                          else
                                            const Padding(
                                              padding:
                                                  EdgeInsets
                                                      .symmetric(
                                                horizontal: 12,
                                              ),
                                              child: Icon(
                                                Icons
                                                    .check_circle_outline,
                                              ),
                                            ),
                                        ],
                                      )
                                    : null,
                      );
                    }

                    if (isPlanned &&
                        _session.canManage) {
                      return ReorderableListView
                          .builder(
                        itemCount: stops.length,

                        onReorder:
                            (oldIndex,
                                newIndex) async {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          final reorderedStops =
                              List<RouteStop>.from(
                            stops,
                          );

                          final movedStop =
                              reorderedStops
                                  .removeAt(
                            oldIndex,
                          );

                          reorderedStops.insert(
                            newIndex,
                            movedStop,
                          );

                          setState(() {
                            _stopsFuture =
                                Future.value(
                              reorderedStops,
                            );
                          });

                          try {
                            await _stopRepository
                                .reorder(
                              routeId:
                                  widget.route.id,
                              stops:
                                  reorderedStops,
                            );

                            if (!mounted) return;

                            _reload();
                          } catch (error) {
                            if (!mounted) return;

                            _reload();

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao alterar '
                                  'a ordem: $error',
                                ),
                              ),
                            );
                          }
                        },

                        itemBuilder:
                            buildStopTile,
                      );
                    }

                    return ListView.builder(
                      itemCount: stops.length,
                      itemBuilder: buildStopTile,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}