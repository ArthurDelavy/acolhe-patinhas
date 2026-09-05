import 'package:flutter/material.dart';
import '../../services/pet_service.dart';

class RegisterBreedColor extends StatefulWidget {
  final int? speciesId;
  final String userToken;
  final bool isBreed;

  const RegisterBreedColor({
    super.key,
    this.speciesId,
    required this.userToken,
    required this.isBreed,
  });

  @override
  State<RegisterBreedColor> createState() => _RegisterBreedColorState();
}

class _RegisterBreedColorState extends State<RegisterBreedColor> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBreed
                ? 'Informe o nome da raça.'
                : 'Informe o nome da cor.',
          ),
        ),
      );
      return;
    }

    if (widget.isBreed && widget.speciesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma espécie primeiro.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> result = widget.isBreed
          ? await PetService.registerBreed(
              token: widget.userToken,
              name: name,
              specieId: widget.speciesId!,
            )
          : await PetService.registerColor(token: widget.userToken, name: name);

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível adicionar ${widget.isBreed ? "a raça" : "a cor"}: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBreed ? 'Adicionar raça' : 'Adicionar cor';
    final label = widget.isBreed ? 'Nome da raça' : 'Nome da cor';

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          if (!_isSaving) _save();
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}
