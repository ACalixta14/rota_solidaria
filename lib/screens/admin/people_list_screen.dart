import 'package:flutter/material.dart';

import '../../models/assisted_person.dart';
import '../../repositories/assisted_person_repository.dart';
import 'person_form_screen.dart';
import 'person_detail_screen.dart';
import '../../services/session_service.dart';
import 'inactive_people_screen.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final AssistedPersonRepository _repository =
    AssistedPersonRepository();

  final SessionService _session = SessionService.instance;

  late Future<List<AssistedPerson>> _peopleFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _peopleFuture = _repository.getAll();
  }

  Future<void> _reload() async {
    setState(() {
      _peopleFuture = _repository.getAll();
    });
  }

  @override
  //interface: criar novos cadastros if permissão
  Widget build(BuildContext context) {
    return Scaffold(
floatingActionButton: _session.canManage
    ? FloatingActionButton(
        onPressed: () async {
          final created =
              await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const PersonFormScreen(),
            ),
          );

          if (created == true) {
            _reload();
          }
        },
        child: const Icon(Icons.add),
      )
    : null,
      appBar: AppBar(
        title: const Text('Pessoas acompanhadas'),
         actions: [
    if (_session.canManage)
      IconButton(
        tooltip: 'Pessoas inativas',
        icon: const Icon(Icons.person_off),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const InactivePeopleScreen(),
            ),
          );

          _reload();
        },
      ),
  ],
      ),
      body: FutureBuilder<List<AssistedPerson>>(
        future: _peopleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar: ${snapshot.error}'),
            );
          }

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
              child: Text('Nenhuma pessoa cadastrada ainda.'),
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
      child: RefreshIndicator(
        onRefresh: _reload,
        child: filteredPeople.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text('Nenhuma pessoa encontrada.'),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: filteredPeople.length,
                itemBuilder: (context, index) {
                  final person = filteredPeople[index];

                  return ListTile(
                    title: Text(person.name ?? 'Sem nome'),
                    subtitle: Text(
                      person.mainAddress ?? 'Sem morada',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated =
                          await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => PersonDetailScreen(
                            person: person,
                          ),
                        ),
                      );

                      if (updated == true) {
                        _reload();
                      }
                    },
                  );
                },
              ),
      ),
    ),
  ],
);

        },
      ),
    );
  }
}