import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/assisted_person.dart';
import '../../repositories/assisted_person_repository.dart';

class PeopleMapScreen extends StatefulWidget {
  const PeopleMapScreen({super.key});

  @override
  State<PeopleMapScreen> createState() => _PeopleMapScreenState();
}

class _PeopleMapScreenState extends State<PeopleMapScreen> {
  final AssistedPersonRepository _repository = AssistedPersonRepository();
  final MapController _mapController = MapController();

  // Coordenadas padrão: Almada, Portugal.
  static const double _defaultLatitude = 38.667154;
  static const double _defaultLongitude = -9.163734;

  List<AssistedPerson> _people = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final people = await _repository.getAll();
      setState(() {
        _people = people;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  // Filtra apenas as pessoas que possuem latitude e longitude preenchidos.
  List<AssistedPerson> get _peopleWithLocation {
    return _people
        .where((person) => person.latitude != null && person.longitude != null)
        .toList();
  }

  // Calcula o centro do mapa com base nos pontos existentes.
  // Se não houver pontos, usa Almada como padrão.
  LatLng get _mapCenter {
    final located = _peopleWithLocation;

    if (located.isEmpty) {
      return const LatLng(_defaultLatitude, _defaultLongitude);
    }

    double sumLat = 0;
    double sumLng = 0;

    for (final person in located) {
      sumLat += person.latitude!;
      sumLng += person.longitude!;
    }

    return LatLng(
      sumLat / located.length,
      sumLng / located.length,
    );
  }

  // Cria os marcadores (pins) no mapa.
  List<Marker> get _markers {
    return _peopleWithLocation.map((person) {
      return Marker(
        point: LatLng(person.latitude!, person.longitude!),
        width: 200,
        height: 80,
        child: GestureDetector(
          onTap: () => _showPersonInfo(person),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Balão com o nome
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  person.nickname ?? person.name ?? 'Sem nome',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Ícone do pin
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 36,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Exibe um BottomSheet com informações da pessoa ao tocar no marcador.
  void _showPersonInfo(AssistedPerson person) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra decorativa
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                person.name ?? 'Sem nome',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (person.nickname != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Apelido: ${person.nickname}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (person.mainAddress != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.place, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(person.mainAddress!)),
                  ],
                ),
              ],
              if (person.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(person.phone!),
                  ],
                ),
              ],
              if (person.publicNotes != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    person.publicNotes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Pessoas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPeople,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Estado de carregamento.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de erro.
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadPeople,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final located = _peopleWithLocation;

    // Mapa (mostra Almada mesmo sem pontos).
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: located.isEmpty ? 14.0 : 15.0,
          ),
          children: [
            // Camada dos tiles (fundo do mapa - OpenStreetMap).
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.rota_solidaria',
            ),
            // Camada dos marcadores.
            MarkerLayer(
              markers: _markers,
            ),
          ],
        ),
        // Indicador de quantas pessoas estão no mapa.
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 6),
                Text(
                  located.isEmpty
                      ? 'Nenhuma pessoa com coordenadas'
                      : '${located.length} pessoa(s) no mapa',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
