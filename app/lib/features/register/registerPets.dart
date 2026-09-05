import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/navbar.dart';
import '../../services/pet_service.dart';
import '../../utils/validators.dart';
import '../../features/register/register_modal.dart';

class RegisterPetsScreen extends StatefulWidget {
  final String userToken;

  const RegisterPetsScreen({super.key, this.userToken = ''});

  @override
  State<RegisterPetsScreen> createState() => _RegisterPetsScreenState();
}

class _RegisterPetsScreenState extends State<RegisterPetsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

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
      final species = await PetService.fetchSpecies(widget.userToken);
      final breeds = await PetService.fetchBreeds(widget.userToken);
      final colors = await PetService.fetchColors(widget.userToken);

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
        // 1. Tenta buscar ID dentro de objeto aninhado: breed['specie']['id'] ou breed['species']['id']
        final specieObj = breed['specie'] ?? breed['species'];
        int? idFromObj;
        if (specieObj is Map) {
          idFromObj = specieObj['id'];
        }

        // 2. Tenta buscar ID direto no mapa: breed['speciesId'], breed['specie_id'] ou breed['species_id']
        final int? directId =
            breed['speciesId'] ??
            breed['specie_id'] ??
            breed['species_id'] ??
            breed['idSpecie'];

        final int? finalSpeciesId = idFromObj ?? directId;

        // Se a raça no banco não tiver vinculo com espécie (null), exibe por garantia
        return finalSpeciesId == null || finalSpeciesId == speciesId;
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
      builder: (_) => RegisterBreedColor(
        isBreed: true,
        speciesId: _selectedSpeciesId!,
        userToken: widget.userToken,
      ),
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
        userToken: widget.userToken,
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
        imageQuality: 85,
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

      final String? formattedBirthDate = _selectedBirthDate != null
          ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
          : null;

      final String rawMicrochip = _microchipController.text.trim();
      final Map<String, dynamic> petPayload = {
        "name": _nameController.text.trim(),
        "gender": _selectedGender,
        "toAdoption": _toAdoption,
        "breed": _selectedBreedId != null ? {"id": _selectedBreedId} : null,
        "color": _selectedColorId != null ? {"id": _selectedColorId} : null,
        "breedId": _selectedBreedId,
        "colorId": _selectedColorId,
        if (rawMicrochip.isNotEmpty) "microchipNumber": rawMicrochip,
      };

      if (formattedBirthDate != null) {
        petPayload["birthDate"] = formattedBirthDate;
      }

      // 2. Trata o microchip: adiciona na requisição APENAS se tiver caracteres preenchidos
      final String microchipVal = _microchipController.text.trim();
      if (microchipVal.isNotEmpty) {
        petPayload["microchipNumber"] = microchipVal;
      }

      try {
        final success = await PetService.registerAnimalWithImage(
          payload: petPayload,
          imageFile: _selectedImage,
          token: widget.userToken,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Erro ao salvar pet: $e';

          if (e.toString().contains('409')) {
            errorMessage =
                'Conflito (409): Um registro idêntico ou microchip informado já existe no sistema.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Pet'),
        backgroundColor: const Color(0xFFE27B1D),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE27B1D)),
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
                        onTap: _pickPetImage,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE27B1D),
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedImage == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: Color(0xFFE27B1D),
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
                                )
                              : Image.network(
                                  _selectedImage!.path,
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
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
                      maxLength: 15,
                      decoration: const InputDecoration(
                        labelText: 'Número do Microchip (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (value) {
                        if (!Validators.isValidMicrochip(value)) {
                          return 'Microchip deve ter até 15 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<int>(
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
                      onChanged: _onSpeciesChanged,
                      validator: (value) => Validators.isValidSpecies(value)
                          ? null
                          : 'Selecione a espécie',
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
                            onChanged: _selectedSpeciesId == null
                                ? null
                                : (value) =>
                                      setState(() => _selectedBreedId = value),
                            validator: (value) => Validators.isValidBreed(value)
                                ? null
                                : 'Selecione a raça',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cadastrar raça',
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFE27B1D),
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
                            onChanged: (value) =>
                                setState(() => _selectedColorId = value),
                            validator: (value) => Validators.isValidColor(value)
                                ? null
                                : 'Selecione a cor',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cadastrar cor',
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFE27B1D),
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
                            onChanged: (value) =>
                                setState(() => _selectedGender = value),
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
                            onTap: () => _selectBirthDate(context),
                            decoration: InputDecoration(
                              labelText: 'Data Nasc. (Opcional)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: _selectedBirthDate != null
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
                      activeColor: const Color(0xFFE27B1D),
                      onChanged: (bool value) {
                        setState(() => _toAdoption = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE27B1D),
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
                              'CADASTRAR PET',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 3),
    );
  }
}
