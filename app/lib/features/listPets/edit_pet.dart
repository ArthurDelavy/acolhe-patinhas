import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/navbar.dart';
import '../../services/pet_service.dart';
import '../../utils/validators.dart';
import '../../features/register/register_modal.dart';

class EditPetScreen extends StatefulWidget {
  final Map<String, dynamic> petData;
  final bool isAdmin;

  const EditPetScreen({super.key, required this.petData, this.isAdmin = true});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  static const Color primaryColor = Color(0xFFE27B1D);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  final TextEditingController _dischargeDateController =
      TextEditingController();
  final TextEditingController _dischargeReasonController =
      TextEditingController();

  int? _selectedSpeciesId;
  int? _selectedBreedId;
  int? _selectedColorId;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  DateTime? _selectedDischargeDate;
  bool _toAdoption = false;

  String? _existingImageUrl;
  String? _originalIntakeDate;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _speciesList = [];
  List<Map<String, dynamic>> _allBreedsList = [];
  List<Map<String, dynamic>> _filteredBreedsList = [];
  List<Map<String, dynamic>> _colorsList = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _microchipController.dispose();
    _birthDateController.dispose();
    _dischargeDateController.dispose();
    _dischargeReasonController.dispose();
    super.dispose();
  }

  /// Busca os detalhes completos do pet (GET /animal/{id}) e as listas
  /// de referência, depois preenche o formulário. Isso é necessário
  /// porque o card da listagem só traz nomes (ex: "Labrador"), não os
  /// IDs de raça/cor/espécie que o formulário precisa para os dropdowns.
  Future<void> _loadEverything() async {
    try {
      final id = widget.petData['id'];

      final results = await Future.wait([
        PetService.fetchAnimalDetail(id),
        PetService.fetchSpecies(),
        PetService.fetchBreeds(),
        PetService.fetchColors(),
      ]);

      final detail = results[0] as Map<String, dynamic>;
      final species = results[1] as List<Map<String, dynamic>>;
      final breeds = results[2] as List<Map<String, dynamic>>;
      final colors = results[3] as List<Map<String, dynamic>>;

      if (!mounted) return;

      _nameController.text = detail['name']?.toString() ?? '';
      _microchipController.text = detail['microchipNumber']?.toString() ?? '';
      _selectedGender = detail['gender']?.toString();
      _toAdoption = detail['toAdoption'] ?? false;
      _existingImageUrl = detail['imageUrl']?.toString();
      _originalIntakeDate = detail['intakeDate']?.toString();

      // Casa os NOMES retornados pelo backend com os IDs das listas
      // de referência (o GET /animal/{id} só devolve nomes, não IDs).
      final String? specieName = detail['specie']?.toString();
      final String? breedName = detail['breed']?.toString();
      final String? colorName = detail['color']?.toString();

      _selectedSpeciesId = _findIdByName(species, specieName);
      _selectedColorId = _findIdByName(colors, colorName);

      if (_selectedSpeciesId != null) {
        _filteredBreedsList = breeds
            .where((b) => b['specieId'] == _selectedSpeciesId)
            .toList();
      } else {
        _filteredBreedsList = [];
      }
      _selectedBreedId = _findIdByName(breeds, breedName);

      if (detail['birthDate'] != null) {
        try {
          _selectedBirthDate = DateTime.parse(detail['birthDate'].toString());
          final age = _calculateAge(_selectedBirthDate!);
          final formattedDate =
              "${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}";
          _birthDateController.text =
              "$formattedDate ($age ${age == 1 ? 'ano' : 'anos'})";
        } catch (_) {}
      }

      setState(() {
        _speciesList = species;
        _allBreedsList = breeds;
        _colorsList = colors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Erro ao carregar dados do pet: $e';
      });
    }
  }

  int? _findIdByName(List<Map<String, dynamic>> list, String? name) {
    if (name == null) return null;
    for (final item in list) {
      if (item['name']?.toString().trim().toLowerCase() ==
          name.trim().toLowerCase()) {
        return item['id'] as int?;
      }
    }
    return null;
  }

  int _calculateAge(DateTime birthDate) {
    final hoje = DateTime.now();
    int idade = hoje.year - birthDate.year;
    if (hoje.month < birthDate.month ||
        (hoje.month == birthDate.month && hoje.day < birthDate.day)) {
      idade--;
    }
    return idade < 0 ? 0 : idade;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    if (!widget.isAdmin) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        final formattedDate =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        final age = _calculateAge(picked);
        _birthDateController.text =
            "$formattedDate ($age ${age == 1 ? 'ano' : 'anos'})";
      });
    }
  }

  Future<void> _selectDischargeDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDischargeDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDischargeDate = picked;
        _dischargeDateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _onSpeciesChanged(int? speciesId) {
    setState(() {
      _selectedSpeciesId = speciesId;
      _selectedBreedId = null;

      if (speciesId == null) {
        _filteredBreedsList = [];
        return;
      }

      _filteredBreedsList = _allBreedsList
          .where((breed) => breed['specieId'] == speciesId)
          .toList();
    });
  }

  Future<void> _openRegisterSpeciesDialog() async {
    if (!widget.isAdmin) return;
    final newSpecies = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const RegisterSpecies(),
    );

    if (newSpecies == null || !mounted) return;

    setState(() {
      _speciesList.add(newSpecies);
      _selectedSpeciesId = newSpecies['id'];
      _selectedBreedId = null;
      _filteredBreedsList = _allBreedsList
          .where((breed) => breed['specieId'] == newSpecies['id'])
          .toList();
    });
  }

  Future<void> _openRegisterBreedDialog() async {
    if (!widget.isAdmin) return;
    if (_selectedSpeciesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma espécie primeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newBreed = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          RegisterBreedColor(isBreed: true, speciesId: _selectedSpeciesId!),
    );

    if (newBreed == null || !mounted) return;

    setState(() {
      _allBreedsList.add(newBreed);
      _filteredBreedsList.add(newBreed);
      _selectedBreedId = newBreed['id'];
    });
  }

  Future<void> _openRegisterColorDialog() async {
    if (!widget.isAdmin) return;
    final newColor = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => RegisterBreedColor(
        isBreed: false,
        speciesId: _selectedSpeciesId ?? 0,
      ),
    );

    if (newColor == null || !mounted) return;

    setState(() {
      _colorsList.add(newColor);
      _selectedColorId = newColor['id'];
    });
  }

  Future<void> _pickPetImage() async {
    if (!widget.isAdmin) return;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar a foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validateMicrochip(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    if (value.trim().length != 15) {
      return 'Microchip deve ter exatamente 15 caracteres';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final String? formattedBirthDate = _selectedBirthDate != null
        ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
        : null;

    final String rawMicrochip = _microchipController.text.trim();

    final Map<String, dynamic> petPayload = {
      "name": _nameController.text.trim(),
      "gender": _selectedGender,
      "toAdoption": _toAdoption,
      "breedId": _selectedBreedId,
      "colorId": _selectedColorId,
      // Preserva a data de entrada original: o backend sobrescreve
      // esse campo com o que vier aqui, então precisamos reenviar o
      // valor de antes para não perdê-lo.
      if (_originalIntakeDate != null) "intakeDate": _originalIntakeDate,
      if (rawMicrochip.isNotEmpty) "microchipNumber": rawMicrochip,
      if (formattedBirthDate != null) "birthDate": formattedBirthDate,
    };

    try {
      final success = await PetService.updateAnimalWithImage(
        id: widget.petData['id'],
        payload: petPayload,
        imageFile: _selectedImage,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar edições: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitDischarge() async {
    if (_dischargeReasonController.text.trim().isEmpty ||
        _selectedDischargeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a Data da Baixa e o Motivo da Baixa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta ação é irreversível. O registro será excluído permanentemente do banco de dados.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tem certeza que deseja dar baixa no pet "${_nameController.text}"?',
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${_dischargeReasonController.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Data: ${_dischargeDateController.text}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      await PetService.deleteAnimal(widget.petData['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet excluído com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir pet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Editar Pet' : 'Detalhes do Pet'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: widget.isAdmin ? _pickPetImage : null,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedImage != null
                              ? Image.network(
                                  _selectedImage!.path,
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                )
                              : (_existingImageUrl != null &&
                                    _existingImageUrl!.isNotEmpty)
                              ? Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.pets,
                                    size: 40,
                                    color: primaryColor,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: primaryColor,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Foto do Pet',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      enabled: widget.isAdmin,
                      maxLength: 45,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Pet *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) {
                        if (value == null ||
                            !Validators.isValidPetName(value)) {
                          return 'Informe um nome válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _microchipController,
                      enabled: widget.isAdmin,
                      maxLength: 15,
                      decoration: const InputDecoration(
                        labelText: 'Número do Microchip (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: _validateMicrochip,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedSpeciesId,
                            decoration: const InputDecoration(
                              labelText: 'Espécie *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _speciesList.map((species) {
                              return DropdownMenuItem<int>(
                                value: species['id'],
                                child: Text(species['name']),
                              );
                            }).toList(),
                            onChanged: widget.isAdmin
                                ? _onSpeciesChanged
                                : null,
                            validator: (value) =>
                                Validators.isValidSpecies(value)
                                ? null
                                : 'Selecione a espécie',
                          ),
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            tooltip: 'Cadastrar espécie',
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: primaryColor,
                            ),
                            onPressed: _openRegisterSpeciesDialog,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedBreedId,
                            decoration: InputDecoration(
                              labelText: 'Raça *',
                              border: const OutlineInputBorder(),
                              helperText: _selectedSpeciesId == null
                                  ? 'Selecione a espécie primeiro'
                                  : null,
                            ),
                            items: _filteredBreedsList.map((breed) {
                              return DropdownMenuItem<int>(
                                value: breed['id'],
                                child: Text(
                                  breed['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged:
                                (_selectedSpeciesId == null || !widget.isAdmin)
                                ? null
                                : (value) =>
                                      setState(() => _selectedBreedId = value),
                            validator: (value) => Validators.isValidBreed(value)
                                ? null
                                : 'Selecione a raça',
                          ),
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            tooltip: 'Cadastrar raça',
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: primaryColor,
                            ),
                            onPressed: _openRegisterBreedDialog,
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedColorId,
                            decoration: const InputDecoration(
                              labelText: 'Cor *',
                              border: OutlineInputBorder(),
                            ),
                            items: _colorsList.map((color) {
                              return DropdownMenuItem<int>(
                                value: color['id'],
                                child: Text(
                                  color['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: widget.isAdmin
                                ? (value) =>
                                      setState(() => _selectedColorId = value)
                                : null,
                            validator: (value) => Validators.isValidColor(value)
                                ? null
                                : 'Selecione a cor',
                          ),
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            tooltip: 'Cadastrar cor',
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: primaryColor,
                            ),
                            onPressed: _openRegisterColorDialog,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gênero *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'M',
                                child: Text('Macho'),
                              ),
                              DropdownMenuItem(
                                value: 'F',
                                child: Text('Fêmea'),
                              ),
                            ],
                            onChanged: widget.isAdmin
                                ? (value) =>
                                      setState(() => _selectedGender = value)
                                : null,
                            validator: (value) =>
                                Validators.isValidGender(value)
                                ? null
                                : 'Selecione o gênero',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            enabled: widget.isAdmin,
                            onTap: () => _selectBirthDate(context),
                            decoration: InputDecoration(
                              labelText: 'Data Nasc. (Opcional)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon:
                                  (_selectedBirthDate != null && widget.isAdmin)
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _selectedBirthDate = null;
                                          _birthDateController.clear();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Disponível para adoção? *'),
                      subtitle: const Text(
                        'Marque se o pet estiver buscando um lar',
                      ),
                      value: _toAdoption,
                      activeColor: primaryColor,
                      onChanged: widget.isAdmin
                          ? (bool value) => setState(() => _toAdoption = value)
                          : null,
                    ),

                    if (widget.isAdmin) ...[
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'SALVAR ALTERAÇÕES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Zona de exclusão: dar baixa remove o pet permanentemente do banco de dados.',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _dischargeDateController,
                        readOnly: true,
                        onTap: () => _selectDischargeDate(context),
                        decoration: InputDecoration(
                          labelText: 'Data da Baixa',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.event_busy),
                          suffixIcon: _selectedDischargeDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDischargeDate = null;
                                      _dischargeDateController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _dischargeReasonController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Motivo da Baixa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.report_problem_outlined),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitDischarge,
                        icon: const Icon(Icons.delete_forever),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          'DAR BAIXA E EXCLUIR PET',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 3),
    );
  }
}
