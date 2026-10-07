import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/navbar.dart';
import '../../utils/veterinary_form_data.dart';
import '../../services/pet_service.dart';
import '../../services/veterinary_service.dart';
import '../../utils/validators.dart';
import '../../features/register/register_modal.dart';

class RegisterPetsScreen extends StatefulWidget {
  const RegisterPetsScreen({super.key});

  @override
  State<RegisterPetsScreen> createState() => _RegisterPetsScreenState();
}

class _RegisterPetsScreenState extends State<RegisterPetsScreen> {
  static const Color _orange = Color(0xFFE27B1D);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final VeterinaryFormData _vetData = VeterinaryFormData();

  int? _createdAnimalId;
  bool _imageUploaded = false;

  int? _selectedSpeciesId;
  int? _selectedBreedId;
  int? _selectedColorId;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _toAdoption = false;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _speciesList = [];
  List<Map<String, dynamic>> _allBreedsList = [];
  List<Map<String, dynamic>> _filteredBreedsList = [];
  List<Map<String, dynamic>> _colorsList = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLookupData();
  }

  Future<void> _fetchLookupData() async {
    try {
      final species = await PetService.fetchSpecies();
      final breeds = await PetService.fetchBreeds();
      final colors = await PetService.fetchColors();

      if (!mounted) return;

      setState(() {
        _speciesList = species;
        _allBreedsList = breeds;
        _colorsList = colors;
        _isLoading = false;
      });

      if (_selectedSpeciesId != null) {
        _onSpeciesChanged(_selectedSpeciesId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _microchipController.dispose();
    _birthDateController.dispose();
    _descriptionController.dispose();
    _vetData.dispose();
    super.dispose();
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _orange,
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

  void _onSpeciesChanged(int? speciesId) {
    setState(() {
      _selectedSpeciesId = speciesId;
      _selectedBreedId = null;

      if (speciesId == null) {
        _filteredBreedsList = [];
        return;
      }

      _filteredBreedsList = _allBreedsList.where((breed) {
        return breed['specieId'] == speciesId;
      }).toList();
    });
  }

  Future<void> _openRegisterSpeciesDialog() async {
    final newSpecies = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const RegisterSpecies(),
    );

    if (newSpecies == null || !mounted) return;
    final int? newSpeciesId = newSpecies['id'];

    setState(() {
      _speciesList.add(newSpecies);
      _selectedSpeciesId = newSpeciesId;
      _selectedBreedId = null;

      if (newSpeciesId == null) {
        _filteredBreedsList = [];
        return;
      }

      _filteredBreedsList = _allBreedsList.where((breed) {
        final specieObj = breed['specie'] ?? breed['species'];
        int? speciesIdFromObject;

        if (specieObj is Map) {
          speciesIdFromObject = specieObj['id'];
        }

        final int? speciesIdDirect =
            breed['speciesId'] ??
            breed['specie_id'] ??
            breed['species_id'] ??
            breed['idSpecie'];

        final int? breedSpeciesId = speciesIdFromObject ?? speciesIdDirect;
        return breedSpeciesId == newSpeciesId;
      }).toList();
    });
  }

  Future<void> _openRegisterBreedDialog() async {
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
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final String rawMicrochip = _microchipController.text.trim();
      final String description = _descriptionController.text.trim();

      final now = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      final String intakeFormatted =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}"
          "T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.000Z";

      final String? formattedBirthDate = _selectedBirthDate != null
          ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
          : null;

      final Map<String, dynamic> petPayload = {
        "name": _nameController.text.trim(),
        "gender": _selectedGender,
        "toAdoption": _toAdoption,
        "intakeDate": intakeFormatted,
        if (_selectedBreedId != null) "breed": {"id": _selectedBreedId},
        if (_selectedBreedId != null) "breedId": _selectedBreedId,
        if (_selectedColorId != null) "color": {"id": _selectedColorId},
        if (_selectedColorId != null) "colorId": _selectedColorId,
        if (rawMicrochip.isNotEmpty) "microchipNumber": rawMicrochip,
        if (formattedBirthDate != null) "birthDate": formattedBirthDate,
        if (description.isNotEmpty) "description": description,
        ..._vetData.recordPayload(),
      };

      try {
        bool success;

        if (_createdAnimalId == null && !_vetData.hasItems) {
          success = await PetService.registerAnimalWithImage(
            payload: petPayload,
            imageFile: _selectedImage,
          );
        } else {
          _createdAnimalId ??= await PetService.registerAnimalAndGetId(
            payload: petPayload,
          );

          if (_selectedImage != null && !_imageUploaded) {
            await PetService.uploadAnimalImage(
              animalId: _createdAnimalId.toString(),
              imageFile: _selectedImage!,
            );
            _imageUploaded = true;
          }

          if (_vetData.hasItems) {
            await VeterinaryService.saveAll(_createdAnimalId!, _vetData);
          }

          success = true;
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Erro ao salvar pet: $e';

          if (_createdAnimalId != null) {
            errorMessage =
                'O pet já foi salvo, mas houve um erro: $e\n'
                'Toque em cadastrar novamente para reenviar apenas o que faltou.';
          } else if (e.toString().contains('409')) {
            errorMessage =
                'Conflito (409): Um registro idêntico ou microchip informado já existe no sistema.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
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
      prefixIcon: icon != null ? Icon(icon, size: 20, color: _orange) : null,
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
        borderSide: const BorderSide(color: _orange, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
    );
  }

  Widget _buildPhotoPicker() {
    const double size = 120;

    return Center(
      child: GestureDetector(
        onTap: _pickPetImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.rectangle, // Borda Quadrada
                borderRadius: BorderRadius.zero,
                border: Border.all(color: _orange, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets_rounded, size: 38, color: _orange),
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
                    )
                  : (kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            width: size,
                            height: size,
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            width: size,
                            height: size,
                          )),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: _orange,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastrar Pet',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
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
                            maxLength: 45,
                            decoration: _inputDecoration(
                              'Nome do Pet *',
                              icon: Icons.pets,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !Validators.isValidPetName(value)) {
                                return 'Informe um nome válido';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _microchipController,
                            maxLength: 15,
                            decoration: _inputDecoration(
                              'Microchip (opcional)',
                              icon: Icons.qr_code,
                            ),
                            validator: (value) {
                              if (!Validators.isValidMicrochip(value)) {
                                return 'Microchip deve ter até 15 caracteres';
                              }
                              final v = (value ?? '').trim();
                              if (v.isNotEmpty && v.length != 15) {
                                return 'Microchip deve ter 15 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        _pair(
                          DropdownButtonFormField<int>(
                            value: _selectedSpeciesId,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              'Espécie *',
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: _orange,
                                ),
                                onPressed: _openRegisterSpeciesDialog,
                              ),
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
                            onChanged: _onSpeciesChanged,
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
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: _orange,
                                ),
                                onPressed: _openRegisterBreedDialog,
                              ),
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
                            onChanged: _selectedSpeciesId == null
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
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: _orange,
                                ),
                                onPressed: _openRegisterColorDialog,
                              ),
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
                            onChanged: (value) =>
                                setState(() => _selectedColorId = value),
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
                            onChanged: (value) =>
                                setState(() => _selectedGender = value),
                            validator: (value) =>
                                Validators.isValidGender(value)
                                ? null
                                : 'Selecione o gênero',
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: () => _selectBirthDate(context),
                          decoration: _inputDecoration(
                            'Data de nascimento (opcional)',
                            icon: Icons.calendar_today_rounded,
                            suffixIcon: _selectedBirthDate != null
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
                                color: _orange,
                              ),
                            ),
                            subtitle: const Text(
                              'Marque se o pet estiver buscando um lar',
                            ),
                            value: _toAdoption,
                            activeColor: Colors.white,
                            activeTrackColor: _orange,
                            onChanged: (bool value) {
                              setState(() => _toAdoption = value);
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        // DESCRIÇÃO (Campo expandido e maior)
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 3, // Aumentado
                          maxLines: 5, // Aumentado
                          maxLength: 1000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                            'Descrição (opcional)',
                            hint: 'Temperamento, cuidados, história do pet...',
                          ),
                        ),

                        // DADOS VETERINÁRIOS
                        VeterinarySection(data: _vetData),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _orange,
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
                                    'CADASTRAR PET',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
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

const Color _kOrange = Color(0xFFE27B1D);

class _VetGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<VetEntry> entries;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _VetGroup({
    required this.title,
    required this.icon,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

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
              Icon(icon, size: 20, color: _kOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entries.isEmpty ? title : '$title (${entries.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  foregroundColor: _kOrange,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          for (int i = 0; i < entries.length; i++)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 4),
              title: Text(
                entries[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: entries[i].subtitle.isEmpty
                  ? null
                  : Text(
                      entries[i].subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: IconButton(
                tooltip: 'Remover',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                onPressed: () => onRemove(i),
              ),
            ),
        ],
      ),
    );
  }
}

class VeterinarySection extends StatefulWidget {
  final VeterinaryFormData data;

  const VeterinarySection({super.key, required this.data});

  @override
  State<VeterinarySection> createState() => _VeterinarySectionState();
}

class _VeterinarySectionState extends State<VeterinarySection> {
  List<Map<String, dynamic>> _vaccines = [];
  List<Map<String, dynamic>> _surgicalProcedures = [];
  List<Map<String, dynamic>> _preventiveProcedures = [];
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _diseases = [];
  List<Map<String, dynamic>> _labTests = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: _kOrange) : null,
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
        borderSide: const BorderSide(color: _kOrange, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
    );
  }

  Future<List<Map<String, dynamic>>> _safeLoad(
    String label,
    Future<List<Map<String, dynamic>>> Function() loader,
    List<String> errors,
  ) async {
    try {
      return await loader();
    } catch (e) {
      errors.add('$label: ${e.toString().replaceFirst('Exception: ', '')}');
      return [];
    }
  }

  Future<void> _loadCatalogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final errors = <String>[];

    final results = await Future.wait([
      _safeLoad('Vacinas', VeterinaryService.fetchVaccines, errors),
      _safeLoad('Cirurgias', VeterinaryService.fetchSurgicalProcedures, errors),
      _safeLoad(
        'Preventivos',
        VeterinaryService.fetchPreventiveProcedures,
        errors,
      ),
      _safeLoad('Medicamentos', VeterinaryService.fetchMedicines, errors),
      _safeLoad('Doenças', VeterinaryService.fetchDiseases, errors),
      _safeLoad('Exames', VeterinaryService.fetchLabTests, errors),
    ]);

    if (!mounted) return;
    setState(() {
      _vaccines = results[0];
      _surgicalProcedures = results[1];
      _preventiveProcedures = results[2];
      _medicines = results[3];
      _diseases = results[4];
      _labTests = results[5];
      _error = errors.isEmpty ? null : errors.join('\n');
      _loading = false;
    });
  }

  Future<void> _addVaccination() async {
    final entry = await showDialog<VetEntry>(
      context: context,
      builder: (_) => VaccinationDialog(vaccines: _vaccines),
    );
    if (entry == null || !mounted) return;
    setState(() => widget.data.vaccinations.add(entry));
  }

  Future<void> _addSurgery() async {
    final entry = await showDialog<VetEntry>(
      context: context,
      builder: (_) => SurgeryDialog(procedures: _surgicalProcedures),
    );
    if (entry == null || !mounted) return;
    setState(() => widget.data.surgeries.add(entry));
  }

  Future<void> _addPreventive() async {
    final entry = await showDialog<VetEntry>(
      context: context,
      builder: (_) => PreventiveDialog(
        procedures: _preventiveProcedures,
        medicines: _medicines,
      ),
    );
    if (entry == null || !mounted) return;
    setState(() => widget.data.preventives.add(entry));
  }

  Future<void> _addLabTest() async {
    final entry = await showDialog<VetEntry>(
      context: context,
      builder: (_) => LabTestDialog(labTests: _labTests),
    );
    if (entry == null || !mounted) return;
    setState(() => widget.data.labTests.add(entry));
  }

  Future<void> _addDiagnosis() async {
    final entry = await showDialog<VetEntry>(
      context: context,
      builder: (_) => DiagnosisDialog(
        diseases: _diseases,
        localId: widget.data.newLocalId(),
      ),
    );
    if (entry == null || !mounted) return;
    setState(() => widget.data.diagnoses.add(entry));
  }

  Future<void> _addTreatment() async {
    final entry = await showDialog<VetEntry>(
      context: context,
      builder: (_) => TreatmentDialog(
        medicines: _medicines,
        diagnoses: widget.data.diagnoses,
      ),
    );
    if (entry == null || !mounted) return;
    setState(() => widget.data.treatments.add(entry));
  }

  void _removeDiagnosis(int index) {
    final d = widget.data;
    final localId = d.diagnoses[index].meta['localId'];
    final used = d.treatments.any((t) => t.meta['diagnosisLocalId'] == localId);

    if (used) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Remova primeiro o tratamento ligado a este diagnóstico.',
          ),
        ),
      );
      return;
    }

    setState(() => d.diagnoses.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 36),
        const Row(
          children: [
            Icon(Icons.medical_services_outlined, color: _kOrange, size: 22),
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
                controller: d.sizeController,
                keyboardType: TextInputType.number,
                maxLength: 3,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration('Altura (cm)', icon: Icons.height),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return null;
                  final n = int.tryParse(value);
                  return (n == null || n <= 0)
                      ? 'Use um valor maior que 0'
                      : null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: d.weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: _inputDecoration(
                  'Peso (kg)',
                  icon: Icons.monitor_weight_outlined,
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return null;
                  return RegExp(r'^\d{1,3}([.,]\d{1,2})?$').hasMatch(value)
                      ? null
                      : 'Ex.: 12,5';
                },
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
            value: d.neutered,
            activeColor: _kOrange,
            onChanged: (v) => setState(() => d.neutered = v),
          ),
        ),

        const SizedBox(height: 10),

        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(color: _kOrange),
          )
        else ...[
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Não foi possível carregar:\n$_error',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadCatalogs,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
          _VetGroup(
            title: 'Vacinas',
            icon: Icons.vaccines_outlined,
            entries: d.vaccinations,
            onAdd: _addVaccination,
            onRemove: (i) => setState(() => d.vaccinations.removeAt(i)),
          ),
          _VetGroup(
            title: 'Cirurgias',
            icon: Icons.healing_outlined,
            entries: d.surgeries,
            onAdd: _addSurgery,
            onRemove: (i) => setState(() => d.surgeries.removeAt(i)),
          ),
          _VetGroup(
            title: 'Cuidados preventivos',
            icon: Icons.shield_outlined,
            entries: d.preventives,
            onAdd: _addPreventive,
            onRemove: (i) => setState(() => d.preventives.removeAt(i)),
          ),
          _VetGroup(
            title: 'Exames laboratoriais',
            icon: Icons.biotech_outlined,
            entries: d.labTests,
            onAdd: _addLabTest,
            onRemove: (i) => setState(() => d.labTests.removeAt(i)),
          ),
          _VetGroup(
            title: 'Diagnósticos',
            icon: Icons.sick_outlined,
            entries: d.diagnoses,
            onAdd: _addDiagnosis,
            onRemove: _removeDiagnosis,
          ),
          _VetGroup(
            title: 'Tratamentos',
            icon: Icons.medication_outlined,
            entries: d.treatments,
            onAdd: _addTreatment,
            onRemove: (i) => setState(() => d.treatments.removeAt(i)),
          ),
        ],
      ],
    );
  }
}
