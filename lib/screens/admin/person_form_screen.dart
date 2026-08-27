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
      _phoneController.text = person.phone ?? '';
      _publicNotesController.text = person.publicNotes ?? '';
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.person == null) {
        await _repository.create(
          name: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          mainAddress: _addressController.text.trim(),
          mapsLink: _mapsLinkController.text.trim(),
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
          phone: _phoneController.text.trim(),
          publicNotes: _publicNotesController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _addressController.dispose();
    _mapsLinkController.dispose();
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
          const SizedBox(height: 12),

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