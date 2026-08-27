import 'package:flutter/material.dart';

import '../../models/request.dart';
import '../../repositories/request_repository.dart';
import 'request_detail_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() =>
      _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final RequestRepository _repository =
      RequestRepository();

  late Future<List<Request>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture =
        _repository.getOpenRequests();
  }

  void _reload() {
    setState(() {
      _loadRequests();
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';

      case 'partially_fulfilled':
        return 'Parcialmente atendido';

      case 'fulfilled':
        return 'Atendido';

      case 'canceled':
        return 'Cancelado';

      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos em aberto'),
      ),
      body: FutureBuilder<List<Request>>(
        future: _requestsFuture,
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
                'Erro ao carregar pedidos: '
                '${snapshot.error}',
              ),
            );
          }

          final requests =
              snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'Não existem pedidos em aberto.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
            },
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request =
                    requests[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      request.personName ??
                          'Sem nome',
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.description,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _statusLabel(
                            request.status,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () async {
                      final updated =
                          await Navigator.of(
                        context,
                      ).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestDetailScreen(
                            request: request,
                          ),
                        ),
                      );

                      if (updated == true) {
                        _reload();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}