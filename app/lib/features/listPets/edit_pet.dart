import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/navbar.dart';
import '../../services/pet_service.dart';
import '../../services/veterinary_service.dart';
import '../../utils/validators.dart';
import '../../features/register/register_modal.dart';

// Cache em memória de nível de sessão para listas estáticas
List<Map<String, dynamic>>? _globalSpeciesCache;
List<Map<String, dynamic>>? _globalBreedsCache;
List<Map<String, dynamic>>? _globalColorsCache;
List<Map<String, dynamic>>? _globalDischargeReasonsCache;

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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _dischargeDateController =
      TextEditingController();

  int? _selectedSpeciesId;
  int? _selectedBreedId;
  int? _selectedColorId;
  int? _selectedDischargeReasonId;
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
  List<Map<String, dynamic>> _dischargeReasonsList = [];

  final List<_VetViewEntry> _veterinaryEntries = [];

  String _vetHeight = '';
  String _vetWeight = '';
  bool _vetNeutered = false;

  bool _isLoading = true;
  bool _isLoadingVet = true;
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
    _descriptionController.dispose();
    _birthDateController.dispose();
    _dischargeDateController.dispose();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    try {
      final id = widget.petData['id'];

      // 1. Usa dados em cache se já existirem, caso contrário busca em paralelo
      final speciesFuture = _globalSpeciesCache != null
          ? Future.value(_globalSpeciesCache)
          : PetService.fetchSpecies();
      final breedsFuture = _globalBreedsCache != null
          ? Future.value(_globalBreedsCache)
          : PetService.fetchBreeds();
      final colorsFuture = _globalColorsCache != null
          ? Future.value(_globalColorsCache)
          : PetService.fetchColors();
      final reasonsFuture = _globalDischargeReasonsCache != null
          ? Future.value(_globalDischargeReasonsCache)
          : PetService.fetchDischargeReasons();

      final results = await Future.wait([
        PetService.fetchAnimalDetail(id),
        speciesFuture,
        breedsFuture,
        colorsFuture,
        reasonsFuture,
      ]);

      final detail = results[0] as Map<String, dynamic>;
      _globalSpeciesCache = results[1] as List<Map<String, dynamic>>;
      _globalBreedsCache = results[2] as List<Map<String, dynamic>>;
      _globalColorsCache = results[3] as List<Map<String, dynamic>>;
      _globalDischargeReasonsCache = results[4] as List<Map<String, dynamic>>;

      final species = _globalSpeciesCache!;
      final breeds = _globalBreedsCache!;
      final colors = _globalColorsCache!;
      final reasons = _globalDischargeReasonsCache!;

      if (!mounted) return;

      _nameController.text = detail['name']?.toString() ?? '';
      _microchipController.text = detail['microchipNumber']?.toString() ?? '';
      _selectedGender = detail['gender']?.toString();
      _toAdoption = detail['toAdoption'] ?? false;
      _existingImageUrl = detail['imageUrl']?.toString();
      _originalIntakeDate = detail['intakeDate']?.toString();
      _descriptionController.text = detail['description']?.toString() ?? '';

      Map<String, dynamic>? vetRecord;
      final rawVetRecord = detail['veterinaryRecord'];
      if (rawVetRecord is Map) {
        vetRecord = Map<String, dynamic>.from(rawVetRecord);
      }

      _vetHeight = vetRecord?['size']?.toString() ?? '';
      _vetWeight = vetRecord?['weight']?.toString() ?? '';
      _vetNeutered = vetRecord?['neutered'] == true;

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

      // EXIBE A TELA IMEDIATAMENTE (NÃO BLOQUEIA ESPERANDO HISTÓRICO VETERINÁRIO)
      setState(() {
        _speciesList = species;
        _allBreedsList = breeds;
        _colorsList = colors;
        _dischargeReasonsList = reasons;
        _isLoading = false;
      });

      // 2. Carrega o histórico veterinário paralelizado em segundo plano
      _loadVeterinaryRecordsParallel(id as int);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Erro ao carregar dados do pet: $e';
      });
    }
  }

  Future<void> _loadVeterinaryRecordsParallel(int animalId) async {
    setState(() => _isLoadingVet = true);

    Future<List<_VetViewEntry>> fetchGroupEntries({
      required String type,
      required Future<List<Map<String, dynamic>>> Function(int) listCall,
      required Future<Map<String, dynamic>> Function(int) detailCall,
      required bool canDelete,
      required Future<void> Function(int) deleteCallFactory,
    }) async {
      try {
        final summaries = await listCall(animalId);
        if (summaries.isEmpty) return [];

        // Paraleliza os detalhes de todos os itens do grupo
        final entryFutures = summaries.map((summary) async {
          final id = _extractRecordId(summary, type);
          Map<String, dynamic> data = Map<String, dynamic>.from(summary);
          if (id != null) {
            try {
              data = await detailCall(id);
            } catch (_) {}
            data['_recordId'] = id;
          }
          return _VetViewEntry(
            type: type,
            data: data,
            canDelete: canDelete && id != null,
            deleteAction: id == null ? null : () => deleteCallFactory(id),
          );
        });

        return await Future.wait(entryFutures);
      } catch (_) {
        return [];
      }
    }

    // Dispara as 6 categorias veterinárias ao mesmo tempo em paralelo
    final results = await Future.wait([
      fetchGroupEntries(
        type: 'Vacinação',
        listCall: VeterinaryService.fetchAnimalVaccinations,
        detailCall: VeterinaryService.fetchVaccination,
        canDelete: true,
        deleteCallFactory: VeterinaryService.deleteVaccination,
      ),
      fetchGroupEntries(
        type: 'Cirurgia',
        listCall: VeterinaryService.fetchAnimalSurgeries,
        detailCall: VeterinaryService.fetchSurgery,
        canDelete: true,
        deleteCallFactory: VeterinaryService.deleteSurgery,
      ),
      fetchGroupEntries(
        type: 'Preventivo',
        listCall: VeterinaryService.fetchAnimalPreventives,
        detailCall: VeterinaryService.fetchPreventive,
        canDelete: false,
        deleteCallFactory: (_) async {},
      ),
      fetchGroupEntries(
        type: 'Exame laboratorial',
        listCall: VeterinaryService.fetchAnimalLabTests,
        detailCall: VeterinaryService.fetchLabTest,
        canDelete: true,
        deleteCallFactory: VeterinaryService.deleteLabTest,
      ),
      fetchGroupEntries(
        type: 'Diagnóstico',
        listCall: VeterinaryService.fetchAnimalDiagnoses,
        detailCall: VeterinaryService.fetchDiagnosis,
        canDelete: true,
        deleteCallFactory: VeterinaryService.deleteDiagnosis,
      ),
      fetchGroupEntries(
        type: 'Tratamento',
        listCall: VeterinaryService.fetchAnimalTreatments,
        detailCall: VeterinaryService.fetchTreatment,
        canDelete: true,
        deleteCallFactory: VeterinaryService.deleteTreatment,
      ),
    ]);

    if (!mounted) return;

    final allEntries = results.expand((entries) => entries).toList();

    setState(() {
      _veterinaryEntries
        ..clear()
        ..addAll(allEntries);
      _isLoadingVet = false;
    });
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
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
      _globalSpeciesCache?.add(newSpecies);
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
      _globalBreedsCache?.add(newBreed);
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
      _globalColorsCache?.add(newColor);
      _selectedColorId = newColor['id'];
    });
  }

  Future<void> _openRegisterDischargeReasonDialog() async {
    final newReason = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const RegisterDischargeReason(),
    );

    if (newReason == null || !mounted) return;

    setState(() {
      _dischargeReasonsList.add(newReason);
      _globalDischargeReasonsCache?.add(newReason);
      _selectedDischargeReasonId = newReason['id'];
    });
  }

  Future<void> _pickPetImage() async {
    if (!widget.isAdmin) return;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
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
    if (value == null || value.trim().isEmpty) return null;
    if (!Validators.isValidMicrochip(value)) {
      return 'Microchip deve ter até 15 caracteres';
    }
    if (value.trim().length != 15) {
      return 'Microchip deve ter 15 caracteres';
    }
    return null;
  }

  int? _extractRecordId(Map<String, dynamic> data, String type) {
    final keys = <String>['id'];
    switch (type) {
      case 'Vacinação':
        keys.add('vaccinationId');
        break;
      case 'Cirurgia':
        keys.add('surgeryId');
        break;
      case 'Preventivo':
        keys.add('preventiveId');
        break;
      case 'Exame laboratorial':
        keys.addAll(['labTestResultId', 'laboratoryTestResultId', 'labTestId']);
        break;
      case 'Diagnóstico':
        keys.add('diagnosisId');
        break;
      case 'Tratamento':
        keys.add('treatmentId');
        break;
    }
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  Future<void> _deleteVeterinaryEntry(_VetViewEntry entry) async {
    if (!entry.canDelete || entry.deleteAction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir ${entry.type.toLowerCase()}?'),
        content: const Text(
          'Essa ação remove o registro veterinário do pet. O cadastro do animal não será excluído.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await entry.deleteAction!();
      if (!mounted) return;
      setState(() => _veterinaryEntries.remove(entry));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.type} excluído com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir ${entry.type.toLowerCase()}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    String safeIntakeDate;
    if (_originalIntakeDate != null && _originalIntakeDate!.isNotEmpty) {
      safeIntakeDate = _originalIntakeDate!;
    } else {
      final safeNow = DateTime.now().toUtc().subtract(
        const Duration(minutes: 10),
      );
      safeIntakeDate =
          "${safeNow.year}-${safeNow.month.toString().padLeft(2, '0')}-${safeNow.day.toString().padLeft(2, '0')}"
          "T${safeNow.hour.toString().padLeft(2, '0')}:${safeNow.minute.toString().padLeft(2, '0')}:${safeNow.second.toString().padLeft(2, '0')}.000Z";
    }

    final String? formattedBirthDate = _selectedBirthDate != null
        ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
        : null;

    final String rawMicrochip = _microchipController.text.trim();

    final Map<String, dynamic> petPayload = {
      "name": _nameController.text.trim(),
      "gender": _selectedGender,
      "toAdoption": _toAdoption,
      "active": true,
      "intakeDate": safeIntakeDate,
      if (_selectedSpeciesId != null) "specieId": _selectedSpeciesId,
      if (_selectedSpeciesId != null) "specie": {"id": _selectedSpeciesId},
      if (_selectedBreedId != null) "breedId": _selectedBreedId,
      if (_selectedBreedId != null) "breed": {"id": _selectedBreedId},
      if (_selectedColorId != null) "colorId": _selectedColorId,
      if (_selectedColorId != null) "color": {"id": _selectedColorId},
      if (rawMicrochip.isNotEmpty) "microchipNumber": rawMicrochip,
      if (formattedBirthDate != null) "birthDate": formattedBirthDate,
      "description": _descriptionController.text.trim(),
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
    if (_selectedDischargeReasonId == null || _selectedDischargeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a Data da Baixa e o Motivo da Baixa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reasonName = _dischargeReasonsList.firstWhere(
      (r) => r['id'] == _selectedDischargeReasonId,
      orElse: () => {'name': '—'},
    )['name'];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar baixa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta ação inativa o cadastro e arquiva o pet no histórico.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
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
              'Motivo: $reasonName',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'CONFIRMAR BAIXA',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final DateTime baseDate = _selectedDischargeDate!;
      final String formattedDate =
          "${baseDate.year}-${baseDate.month.toString().padLeft(2, '0')}-${baseDate.day.toString().padLeft(2, '0')}T12:00:00.000Z";

      await PetService.dischargeAnimal(
        id: widget.petData['id'],
        dischargeReasonId: _selectedDischargeReasonId!,
        dischargeDate: formattedDate,
        breedId: _selectedBreedId!,
        colorId: _selectedColorId!,
        existingPetData: widget.petData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baixa do pet registrada com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar baixa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: primaryColor)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
    );
  }

  Widget _pair(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    const double size = 120;

    return Center(
      child: GestureDetector(
        onTap: widget.isAdmin ? _pickPetImage : null,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImage != null
                  ? (kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            fit: BoxFit.cover,
                            width: size,
                            height: size,
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                            width: size,
                            height: size,
                          ))
                  : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                        ? Image.network(
                            _existingImageUrl!,
                            fit: BoxFit.cover,
                            width: size,
                            height: size,
                            errorBuilder: (_, __, ___) => const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets_rounded,
                                  size: 38,
                                  color: primaryColor,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Foto do Pet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                size: 38,
                                color: primaryColor,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Foto do Pet',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )),
            ),
            if (widget.isAdmin)
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin ? 'Editar Pet' : 'Detalhes do Pet',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPhotoPicker(),
                        const SizedBox(height: 20),

                        _pair(
                          TextFormField(
                            controller: _nameController,
                            enabled: widget.isAdmin,
                            maxLength: 45,
                            decoration: _inputDecoration(
                              'Nome do Pet *',
                              icon: Icons.pets,
                            ),
                            validator: (value) =>
                                value == null ||
                                    !Validators.isValidPetName(value)
                                ? 'Informe um nome válido'
                                : null,
                          ),
                          TextFormField(
                            controller: _microchipController,
                            enabled: widget.isAdmin,
                            maxLength: 15,
                            decoration: _inputDecoration(
                              'Microchip (opcional)',
                              icon: Icons.qr_code,
                            ),
                            validator: _validateMicrochip,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _pair(
                          DropdownButtonFormField<int>(
                            value: _selectedSpeciesId,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              'Espécie *',
                              suffixIcon: widget.isAdmin
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: primaryColor,
                                      ),
                                      onPressed: _openRegisterSpeciesDialog,
                                    )
                                  : null,
                            ),
                            items: _speciesList.map((species) {
                              return DropdownMenuItem<int>(
                                value: species['id'],
                                child: Text(
                                  species['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                          DropdownButtonFormField<int>(
                            value: _selectedBreedId,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              'Raça *',
                              suffixIcon: widget.isAdmin
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: primaryColor,
                                      ),
                                      onPressed: _openRegisterBreedDialog,
                                    )
                                  : null,
                            ),
                            hint: Text(
                              _selectedSpeciesId == null
                                  ? 'Escolha a espécie'
                                  : 'Selecione',
                              overflow: TextOverflow.ellipsis,
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

                        const SizedBox(height: 12),

                        _pair(
                          DropdownButtonFormField<int>(
                            value: _selectedColorId,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              'Cor *',
                              suffixIcon: widget.isAdmin
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: primaryColor,
                                      ),
                                      onPressed: _openRegisterColorDialog,
                                    )
                                  : null,
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
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            decoration: _inputDecoration('Gênero *'),
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

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _birthDateController,
                          enabled: widget.isAdmin,
                          readOnly: true,
                          onTap: () => _selectBirthDate(context),
                          decoration: _inputDecoration(
                            'Data de nascimento (opcional)',
                            icon: Icons.calendar_today_rounded,
                            suffixIcon:
                                (_selectedBirthDate != null && widget.isAdmin)
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
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

                        const SizedBox(height: 8),

                        Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: SwitchListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            title: const Text(
                              'Disponível para adoção? *',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            subtitle: const Text(
                              'Marque se o pet estiver buscando um lar',
                            ),
                            value: _toAdoption,
                            activeColor: Colors.white,
                            activeTrackColor: primaryColor,
                            onChanged: widget.isAdmin
                                ? (bool value) =>
                                      setState(() => _toAdoption = value)
                                : null,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _descriptionController,
                          enabled: widget.isAdmin,
                          readOnly: !widget.isAdmin,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 1000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                            'Descrição (opcional)',
                            hint: 'Temperamento, cuidados, história do pet...',
                          ),
                        ),

                        _VeterinaryReadOnlySection(
                          entries: _veterinaryEntries,
                          isLoadingVet: _isLoadingVet,
                          onDelete: _deleteVeterinaryEntry,
                          height: _vetHeight,
                          weight: _vetWeight,
                          neutered: _vetNeutered,
                        ),

                        if (widget.isAdmin) ...[
                          const SizedBox(height: 20),

                          SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              border: Border.all(color: Colors.amber.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber.shade900,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Registro de Baixa: esta ação inativa o cadastro e arquiva o pet no histórico.',
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _pair(
                            TextFormField(
                              controller: _dischargeDateController,
                              readOnly: true,
                              onTap: () => _selectDischargeDate(context),
                              decoration: _inputDecoration(
                                'Data da Baixa',
                                icon: Icons.event_busy,
                                suffixIcon: _selectedDischargeDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() {
                                          _selectedDischargeDate = null;
                                          _dischargeDateController.clear();
                                        }),
                                      )
                                    : null,
                              ),
                            ),
                            DropdownButtonFormField<int>(
                              value: _selectedDischargeReasonId,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                'Motivo da Baixa',
                                icon: Icons.report_problem_outlined,
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: primaryColor,
                                  ),
                                  onPressed: _openRegisterDischargeReasonDialog,
                                ),
                              ),
                              items: _dischargeReasonsList.map((r) {
                                return DropdownMenuItem<int>(
                                  value: r['id'],
                                  child: Text(
                                    r['name'],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(
                                () => _selectedDischargeReasonId = val,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : _submitDischarge,
                              icon: const Icon(Icons.archive_outlined),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              label: const Text(
                                'REGISTRAR BAIXA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 3),
    );
  }
}

class _VetViewEntry {
  final String type;
  final Map<String, dynamic> data;
  final bool canDelete;
  final Future<void> Function()? deleteAction;

  _VetViewEntry({
    required this.type,
    required this.data,
    required this.canDelete,
    required this.deleteAction,
  });
}

class _VeterinaryReadOnlySection extends StatelessWidget {
  final List<_VetViewEntry> entries;
  final bool isLoadingVet;
  final Future<void> Function(_VetViewEntry) onDelete;
  final String height;
  final String weight;
  final bool neutered;

  const _VeterinaryReadOnlySection({
    required this.entries,
    required this.isLoadingVet,
    required this.onDelete,
    required this.height,
    required this.weight,
    required this.neutered,
  });

  static const Color orange = Color(0xFFE27B1D);

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: orange) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: orange, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<_VetViewEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.type, () => []).add(entry);
    }

    final groups = <String, _VetGroupInfo>{
      'Vacinação': _VetGroupInfo('Vacinas', Icons.vaccines_outlined),
      'Cirurgia': _VetGroupInfo('Cirurgias', Icons.healing_outlined),
      'Preventivo': _VetGroupInfo('Preventivos', Icons.shield_outlined),
      'Exame laboratorial': _VetGroupInfo(
        'Exames laboratoriais',
        Icons.biotech_outlined,
      ),
      'Diagnóstico': _VetGroupInfo(
        'Diagnósticos',
        Icons.medical_information_outlined,
      ),
      'Tratamento': _VetGroupInfo(
        'Tratamentos',
        Icons.medical_services_outlined,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 36),
        const Row(
          children: [
            Icon(Icons.medical_services_outlined, color: orange, size: 22),
            SizedBox(width: 8),
            Text(
              'Dados veterinários',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Opcional. Preencha apenas o que já existir no histórico do pet.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                initialValue: height,
                readOnly: true,
                maxLength: 3,
                decoration: _inputDecoration('Altura (cm)', icon: Icons.height),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: weight,
                readOnly: true,
                maxLength: 6,
                decoration: _inputDecoration(
                  'Peso (kg)',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
            ),
          ],
        ),

        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            title: const Text(
              'Castrado(a)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: neutered,
            activeColor: orange,
            onChanged: null,
          ),
        ),

        const SizedBox(height: 10),

        if (isLoadingVet)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: orange,
                ),
              ),
            ),
          )
        else if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Nenhum registro veterinário encontrado.'),
          )
        else
          for (final type in groups.keys)
            if ((grouped[type] ?? []).isNotEmpty)
              _ReadOnlyVetGroup(
                title: groups[type]!.title,
                icon: groups[type]!.icon,
                entries: grouped[type]!,
                onDelete: onDelete,
              ),
      ],
    );
  }
}

class _VetGroupInfo {
  final String title;
  final IconData icon;

  const _VetGroupInfo(this.title, this.icon);
}

class _ReadOnlyVetGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_VetViewEntry> entries;
  final Future<void> Function(_VetViewEntry) onDelete;

  const _ReadOnlyVetGroup({
    required this.title,
    required this.icon,
    required this.entries,
    required this.onDelete,
  });

  static const Color orange = Color(0xFFE27B1D);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title (${entries.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          for (final entry in entries)
            _VetReadOnlyCard(entry: entry, onDelete: () => onDelete(entry)),
        ],
      ),
    );
  }
}

class _VetReadOnlyCard extends StatelessWidget {
  final _VetViewEntry entry;
  final VoidCallback onDelete;

  const _VetReadOnlyCard({required this.entry, required this.onDelete});

  static const Color orange = Color(0xFFE27B1D);

  String? _firstValue(List<String> keys) {
    for (final key in keys) {
      final value = entry.data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _displayStatus(String value) {
    switch (value.toLowerCase()) {
      case 'active':
      case 'ativo':
        return 'Ativo';
      case 'inactive':
      case 'inativo':
        return 'Inativo';
      case 'resolved':
      case 'resolvido':
        return 'Resolvido';
      default:
        return value;
    }
  }

  String _recordName() {
    switch (entry.type) {
      case 'Vacinação':
        return _firstValue([
              'vaccineName',
              'vaccine',
              'name',
              'vaccine_name',
            ]) ??
            'Vacinação';
      case 'Cirurgia':
        return _firstValue([
              'surgeryName',
              'procedureName',
              'surgeryType',
              'name',
              'procedure',
            ]) ??
            'Cirurgia';
      case 'Preventivo':
        return _firstValue([
              'preventiveName',
              'procedureName',
              'name',
              'preventive',
            ]) ??
            'Preventivo';
      case 'Exame laboratorial':
        return _firstValue(['testName', 'labTestName', 'name', 'test']) ??
            'Exame laboratorial';
      case 'Diagnóstico':
        return _firstValue([
              'diseaseName',
              'diagnosisName',
              'name',
              'disease',
              'diagnosis',
            ]) ??
            'Diagnóstico';
      case 'Tratamento':
        return _firstValue(['treatmentName', 'name', 'description', 'title']) ??
            'Tratamento';
      default:
        return entry.type;
    }
  }

  String? _date() {
    switch (entry.type) {
      case 'Vacinação':
        return _firstValue([
          'vaccinationDate',
          'date',
          'appliedAt',
          'applicationDate',
          'dateApplied',
        ]);
      case 'Cirurgia':
        return _firstValue([
          'procedureDate',
          'surgeryDate',
          'date',
          'performedAt',
        ]);
      case 'Preventivo':
        return _firstValue([
          'procedureDate',
          'preventiveDate',
          'date',
          'performedAt',
          'applicationDate',
        ]);
      case 'Exame laboratorial':
        return _firstValue(['testDate', 'date', 'performedAt', 'resultDate']);
      case 'Diagnóstico':
        return _firstValue(['diagnosedAt', 'diagnosisDate', 'date']);
      case 'Tratamento':
        return _firstValue(['startDate', 'startedAt', 'beginDate']);
      default:
        return null;
    }
  }

  String? _dose() {
    if (entry.type == 'Vacinação' || entry.type == 'Preventivo') {
      return _firstValue(['dose', 'doseAmount', 'dosage']);
    }
    return null;
  }

  String? _subtitle() {
    final date = _date();
    final dose = _dose();

    final parts = <String>[];
    if (date != null) parts.add('Aplicado em ${_formatDate(date)}');
    if (dose != null) parts.add('Dose: $dose');

    if (entry.type == 'Exame laboratorial') {
      final result = _firstValue([
        'results',
        'result',
        'resultValue',
        'resultDescription',
      ]);
      if (result != null) parts.add('Resultado: $result');
    }

    if (entry.type == 'Tratamento') {
      final end = _firstValue(['endDate', 'endedAt', 'finishDate']);
      if (end != null) parts.add('Até ${_formatDate(end)}');
    }

    if (entry.type == 'Diagnóstico') {
      final status = _firstValue(['status']);
      if (status != null) parts.add(_displayStatus(status));
    }

    return parts.isEmpty ? null : parts.join('  •  ');
  }

  IconData _icon() {
    switch (entry.type) {
      case 'Vacinação':
        return Icons.vaccines_outlined;
      case 'Cirurgia':
        return Icons.healing_outlined;
      case 'Preventivo':
        return Icons.shield_outlined;
      case 'Exame laboratorial':
        return Icons.biotech_outlined;
      case 'Diagnóstico':
        return Icons.medical_information_outlined;
      case 'Tratamento':
        return Icons.medical_services_outlined;
      default:
        return Icons.pets;
    }
  }

  Future<void> _showDetails(BuildContext context) async {
    final fields = <MapEntry<String, String>>[];

    void add(String label, String? value, {bool date = false}) {
      if (value == null || value.trim().isEmpty) return;
      fields.add(MapEntry(label, date ? _formatDate(value) : value));
    }

    switch (entry.type) {
      case 'Vacinação':
        add('Vacina', _recordName());
        add('Data', _date(), date: true);
        add('Dose', _dose());
        add('Fabricante', _firstValue(['manufacturer']));
        add('Lote', _firstValue(['batchNumber', 'batchNumer']));
        add('Próxima dose', _firstValue(['nextDoseDate']), date: true);
        break;
      case 'Cirurgia':
        add('Procedimento', _recordName());
        add('Data', _date(), date: true);
        add('Observações', _firstValue(['observations', 'observation']));
        break;
      case 'Preventivo':
        add('Procedimento', _recordName());
        add('Data', _date(), date: true);
        add('Dose', _dose());
        add(
          'Próximo procedimento',
          _firstValue(['nextProcedureDate']),
          date: true,
        );
        add('Observações', _firstValue(['observations', 'observation']));
        break;
      case 'Exame laboratorial':
        add('Exame', _recordName());
        add('Data', _date(), date: true);
        add(
          'Resultado',
          _firstValue([
            'results',
            'result',
            'resultValue',
            'resultDescription',
          ]),
        );
        add('Observações', _firstValue(['observations', 'observation']));
        break;
      case 'Diagnóstico':
        add('Diagnóstico', _recordName());
        add('Data', _date(), date: true);
        final status = _firstValue(['status']);
        add('Situação', status == null ? null : _displayStatus(status));
        break;
      case 'Tratamento':
        add('Tratamento', _recordName());
        add('Início', _date(), date: true);
        add(
          'Fim',
          _firstValue(['endDate', 'endedAt', 'finishDate']),
          date: true,
        );
        add('Situação', _firstValue(['status']));
        add('Observações', _firstValue(['observations', 'observation']));
        break;
    }

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(entry.type),
        content: fields.isEmpty
            ? const Text('Não há mais informações disponíveis.')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: '${field.key}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: field.value),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(right: 4),
      leading: Icon(_icon(), size: 20, color: orange),
      title: Text(_recordName(), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Ver dados completos',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.visibility_outlined, size: 20),
            onPressed: () => _showDetails(context),
          ),
          if (entry.canDelete)
            IconButton(
              tooltip: 'Remover',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.redAccent,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
