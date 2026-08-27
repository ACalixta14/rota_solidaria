import 'package:flutter/material.dart';

import '../../models/assisted_person.dart';
import '../../repositories/assisted_person_repository.dart';

class InactivePeopleScreen extends StatefulWidget {
  const InactivePeopleScreen({super.key});

  @override
  State<InactivePeopleScreen> createState() =>
      _InactivePeopleScreenState();
}

class _InactivePeopleScreenState
    extends State<InactivePeopleScreen> {
  final AssistedPersonRepository _repository =
      AssistedPersonRepository();

  late Future<List<AssistedPerson>> _peopleFuture;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  void _loadPeople() {
    _peopleFuture = _repository.getInactive();
  }

  void _reload() {
    setState(() {
      _loadPeople();
    });
  }

  Future<void> _reactivatePerson(
    AssistedPerson person,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reativar pessoa'),
          content: Text(
            'Deseja reativar ${person.name ?? 'esta pessoa'}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Reativar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _repository.reactivate(person.id);

    if (!mounted) return;

    _reload();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pessoa reativada com sucesso.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pessoas inativas'),
      ),
      body: FutureBuilder<List<AssistedPerson>>(
        future: _peopleFuture,
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
                'Erro ao carregar pessoas inativas: '
                '${snapshot.error}',
              ),
            );
          }

          final people = snapshot.data ?? [];

          if (people.isEmpty) {
            return const Center(
              child: Text('Não há pessoas inativas.'),
            );
          }

          return ListView.builder(
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];

              return ListTile(
                leading: const Icon(Icons.person_off),
                title: Text(
                  person.name ?? 'Sem nome',
                ),
                subtitle: Text(
                  person.deactivationReason ??
                      'Motivo não registado',
                ),
                trailing: IconButton(
                  tooltip: 'Reativar',
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    _reactivatePerson(person);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}