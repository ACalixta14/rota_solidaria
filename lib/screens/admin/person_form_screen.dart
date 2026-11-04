import 'package:flutter/material.dart';

import '../../models/assisted_person.dart';
import '../../repositories/assisted_person_repository.dart';

class PersonFormScreen extends StatefulWidget {
  final AssistedPerson? person;

  const PersonFormScreen({
    super.key,
    this.person,
  });

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final AssistedPersonRepository _repository =
      AssistedPersonRepository();

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _addressController = TextEditingController();

  // localização no Google Maps
  final _mapsLinkController = TextEditingController();

  // coordenadas para o mapa
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // contacto telefónico
  final _phoneController = TextEditingController();

  final _publicNotesController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final person = widget.person;

    if (person != null) {
      _nameController.text = person.name ?? '';
      _nicknameController.text = person.nickname ?? '';
      _addressController.text = person.mainAddress ?? '';
      _mapsLinkController.text = person.mapsLink ?? '';
      _latitudeController.text =
          person.latitude != null ? person.latitude.toString() : '';
      _longitudeController.text =
          person.longitude != null ? person.longitude.toString() : '';
      _phoneController.text = person.phone ?? '';
      _publicNotesController.text = person.publicNotes ?? '';
    }
  }

  /// Converte o texto do controller para double, retornando null se vazio ou inválido.
  double? _parseCoordinate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _save() async {
    // Validar coordenadas antes de salvar
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();

    if (latText.isNotEmpty && double.tryParse(latText) == null) {
      _showError('Latitude inválida. Use um número decimal (ex.: 38.667154)');
      return;
    }

    if (lngText.isNotEmpty && double.tryParse(lngText) == null) {
      _showError('Longitude inválida. Use um número decimal (ex.: -9.163734)');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final latitude = _parseCoordinate(latText);
      final longitude = _parseCoordinate(lngText);

      if (widget.person == null) {
        await _repository.create(
          name: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          mainAddress: _addressController.text.trim(),
          mapsLink: _mapsLinkController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          phone: _phoneController.text.trim(),
          publicNotes: _publicNotesController.text.trim(),
        );
      } else {
        await _repository.update(
          id: widget.person!.id,
          name: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          mainAddress: _addressController.text.trim(),
          mapsLink: _mapsLinkController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          phone: _phoneController.text.trim(),
          publicNotes: _publicNotesController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      _showError('Erro ao salvar: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _addressController.dispose();
    _mapsLinkController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _publicNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.person != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar pessoa' : 'Cadastrar pessoa',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Apelido / identificação',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Morada ou ponto principal',
              hintText: 'Ex.: Rua, praça ou ponto de referência',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _mapsLinkController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link da localização no Google Maps',
              hintText: 'https://maps.google.com/...',
            ),
          ),
          const SizedBox(height: 16),

          // Seção de coordenadas para o mapa
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Coordenadas para o mapa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Preencha para que a pessoa apareça no Mapa de Pessoas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'Ex.: 38.667154',
                          prefixIcon: Icon(Icons.north, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'Ex.: -9.163734',
                          prefixIcon: Icon(Icons.east, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone / contacto',
              hintText: 'Ex.: +351 912 345 678',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _publicNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observações operacionais',
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving ? 'Salvando...' : 'Salvar',
            ),
          ),
        ],
      ),
    );
  }
}