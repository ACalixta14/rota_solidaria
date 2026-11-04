import 'package:flutter/material.dart';

import '../../models/assisted_person.dart';
import '../../repositories/assisted_person_repository.dart';
import 'person_detail_screen.dart';


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
  String _searchQuery = '';

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

//filtro para pesquisa em ordem alfabetica
          final people = List<AssistedPerson>.from(
            snapshot.data ?? <AssistedPerson>[],
          );

          people.sort((a, b) {
            final nameA = (a.name ?? '').trim().toLowerCase();
            final nameB = (b.name ?? '').trim().toLowerCase();

            return nameA.compareTo(nameB);
          });

          if (people.isEmpty) {
            return const Center(
              child: Text('Não há pessoas inativas.'),
            );
          }


final filteredPeople = people.where((person) {
  final query = _searchQuery.trim().toLowerCase();
  final name = (person.name ?? '').toLowerCase();
  final nickname = (person.nickname ?? '').toLowerCase();

  return name.contains(query) || nickname.contains(query);
}).toList();

return Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Pesquisar por nome ou alcunha',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    ),
    Expanded(
      child: filteredPeople.isEmpty
          ? const Center(
              child: Text('Nenhuma pessoa encontrada.'),
            )
          : ListView.builder(
              itemCount: filteredPeople.length,
              itemBuilder: (context, index) {
                final person = filteredPeople[index];

              return ListTile(
  leading: const Icon(Icons.person_off),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          person: person,
          readOnly: true,
        ),
      ),
    );
  },
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
            ),
    ),
  ],
);
        },
      ),
    );
  }
}
