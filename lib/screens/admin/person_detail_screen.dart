import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/assisted_person.dart';
import '../../models/visit_record.dart';
import '../../repositories/request_repository.dart';
import '../../repositories/assisted_person_repository.dart';
import '../../repositories/visit_record_repository.dart';
import '../../services/session_service.dart';
import 'person_form_screen.dart';
import 'visit_form_screen.dart';
import 'visit_detail_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final AssistedPerson person;

  const PersonDetailScreen({
    super.key,
    required this.person,
  });

  @override
  State<PersonDetailScreen> createState() =>
      _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final VisitRecordRepository _visitRepository =
      VisitRecordRepository();

  final AssistedPersonRepository _personRepository =
      AssistedPersonRepository();

  final RequestRepository _requestRepository =
    RequestRepository();

  final SessionService _session = SessionService.instance;

  late Future<List<VisitRecord>> _visitsFuture;

  late Future<int> _openRequestsCountFuture;


@override
void initState() {
  super.initState();

  _visitsFuture =
      _visitRepository.getByPerson(widget.person.id);

  _openRequestsCountFuture =
      _loadOpenRequestsCount();
}
Future<void> _createRequest() async {
  final controller = TextEditingController();

  final description = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Novo pedido'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Descrição do pedido',
            border: OutlineInputBorder(),
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
              final value = controller.text.trim();

              if (value.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Criar pedido'),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (description == null || description.trim().isEmpty) {
    return;
  }

  try {
    await _requestRepository.createRequest(
      assistedPersonId: widget.person.id,
      description: description,
    );

    if (!mounted) return;

    setState(() {
      _openRequestsCountFuture =
          _loadOpenRequestsCount();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido criado com sucesso.'),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erro ao criar pedido: $error',
        ),
      ),
    );
  }
}

Future<int> _loadOpenRequestsCount() async {
  final requests =
      await _requestRepository.getOpenByPerson(widget.person.id);

  return requests.length;
}

  void _reloadVisits() {
    setState(() {
      _visitsFuture =
          _visitRepository.getByPerson(widget.person.id);
    });
  }
Future<void> _openMaps(String mapsLink) async {
  final uri = Uri.tryParse(mapsLink);

  if (uri == null || !await launchUrl(uri)) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir a localização.'),
      ),
    );
  }
}

Future<void> _callPhone(String phone) async {
  final uri = Uri(
    scheme: 'tel',
    path: phone,
  );

  if (!await launchUrl(uri)) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir o telefone.'),
      ),
    );
  }
}

  Future<void> _deactivatePerson() async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Desativar pessoa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esta pessoa será removida da lista principal, '
                'mas o histórico continuará guardado.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo da inativação',
                  hintText: 'Indique o motivo',
                  border: OutlineInputBorder(),
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
                final value = reasonController.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Desativar'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    await _personRepository.deactivate(
      id: widget.person.id,
      reason: reason,
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name ?? 'Detalhes'),
        actions: [
          if (_session.canManage) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated =
                    await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PersonFormScreen(
                      person: person,
                    ),
                  ),
                );

                if (updated == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_off),
              onPressed: _deactivatePerson,
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            person.name ?? 'Sem nome',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
      Text('Apelido: ${person.nickname ?? '-'}'),
const SizedBox(height: 8),

Text('Morada: ${person.mainAddress ?? '-'}'),
const SizedBox(height: 8),

if (person.mapsLink != null && person.mapsLink!.isNotEmpty) ...[
  ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.location_on_outlined),
    title: const Text('Abrir localização no Google Maps'),
    onTap: () => _openMaps(person.mapsLink!),
  ),
],

if (person.phone != null && person.phone!.isNotEmpty) ...[
  ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.phone_outlined),
    title: Text(person.phone!),
    subtitle: const Text('Telefonar'),
    onTap: () => _callPhone(person.phone!),
  ),
],

const SizedBox(height: 8),
Text('Observações: ${person.publicNotes ?? '-'}'),

const SizedBox(height: 16),

FutureBuilder<int>(
  future: _openRequestsCountFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text('A carregar pedidos em aberto...');
    }

    if (snapshot.hasError) {
      return const Text(
        'Não foi possível carregar os pedidos em aberto.',
      );
    }

    final count = snapshot.data ?? 0;

    return Text(
      count == 1
          ? '🟠 1 pedido em aberto'
          : '🟠 $count pedidos em aberto',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    );
  },
),

const SizedBox(height: 12),

ElevatedButton.icon(
  onPressed: _createRequest,
  icon: const Icon(Icons.add),
  label: const Text('Novo pedido'),
),
const SizedBox(height: 24),

//BOTÃO REGISTRAR VISITAS DENTRO DO PERFIL DO ASSISTIDO
//COMENTADO POIS HOJE NÃO FAZEMOS VISITAS FORA DA VOLTA, PARA ATIVAR, BASTA DESCOMENTAR
//POSSÍVEL UTILIZAÇÃO NO FUTURO 
         /* ElevatedButton.icon(
            onPressed: () async {
              final created =
                  await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => VisitFormScreen(
                    assistedPersonId: person.id,
                  ),
                ),
              );

              if (created == true) {
                _reloadVisits();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar visita'),
          ),*/

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          const Text(
            'Histórico de visitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          FutureBuilder<List<VisitRecord>>(
            future: _visitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Erro ao carregar histórico: '
                  '${snapshot.error}',
                );
              }

              final visits = snapshot.data ?? [];

              if (visits.isEmpty) {
                return const Text(
                  'Ainda não há visitas registadas.',
                );
              }

              return Column(
                children: visits.map((visit) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        visit.wasFound
                            ? 'Encontrado'
                            : 'Não encontrado',
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${visit.createdAt.day.toString().padLeft(2, '0')}/'
                            '${visit.createdAt.month.toString().padLeft(2, '0')}/'
                            '${visit.createdAt.year}',
                          ),
                          if (visit.observation != null &&
                              visit.observation!.isNotEmpty)
                            Text(
                              'Obs: ${visit.observation}',
                            ),
                          if (visit.requestedItems != null &&
                              visit.requestedItems!.isNotEmpty)
                            Text(
                              'Pedidos: ${visit.requestedItems}',
                            ),
                        ],
                      ),
                      trailing: const Icon(
                       Icons.chevron_right,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VisitDetailScreen(
                                visit: visit,
                              ),
                            ),
                          );
                        },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}