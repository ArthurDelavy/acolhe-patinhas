import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../services/pet_service.dart';

class RegisterPetsScreen extends StatefulWidget {
  final String userToken; // Recebe o token JWT do usuário logado

  const RegisterPetsScreen({super.key, this.userToken = ''});

  @override
  State<RegisterPetsScreen> createState() => _RegisterPetsScreenState();
}

class _RegisterPetsScreenState extends State<RegisterPetsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  int? _selectedBreedId;
  int? _selectedColorId;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _toAdoption = false;

  List<Map<String, dynamic>> _breedsList = [];
  List<Map<String, dynamic>> _colorsList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    print("Token recebido na tela: ${widget.userToken}");
    _fetchLookupData();
  }

  Future<void> _fetchLookupData() async {
    try {
      final breeds = await PetService.fetchBreeds(widget.userToken);
      final colors = await PetService.fetchColors(widget.userToken);

      setState(() {
        _breedsList = breeds;
        _colorsList = colors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados do banco: $e'),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final String? formattedBirthDate = _selectedBirthDate != null
          ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
          : null;

      // Payload mapeado para a NewAnimalRequest.java
      final Map<String, dynamic> petPayload = {
        "name": _nameController.text.trim(),
        "microchipNumber": _microchipController.text.trim().isEmpty
            ? null
            : _microchipController.text.trim(),
        "breedId": _selectedBreedId,
        "colorId": _selectedColorId,
        "gender": _selectedGender,
        "birthDate": formattedBirthDate,
        "intakeDate": DateTime.now().toUtc().toIso8601String(),
        "toAdoption": _toAdoption,
      };

      try {
        final success = await PetService.registerAnimal(
          petPayload,
          widget.userToken,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar pet: $e'),
              backgroundColor: Colors.red,
            ),
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
                    // --- ÁREA DE FOTO ---
                    Center(
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
                        child: const Column(
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- NOME ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Pet *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do pet';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- MICROCHIP (OPCIONAL) ---
                    TextFormField(
                      controller: _microchipController,
                      decoration: const InputDecoration(
                        labelText: 'Número do Microchip (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- RAÇA E COR (DO BANCO) ---
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedBreedId,
                            decoration: const InputDecoration(
                              labelText: 'Raça *',
                              border: OutlineInputBorder(),
                            ),
                            items: _breedsList.map((breed) {
                              return DropdownMenuItem<int>(
                                value: breed['id'],
                                child: Text(
                                  breed['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedBreedId = value),
                            validator: (value) =>
                                value == null ? 'Selecione' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                child: Text(color['name']),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedColorId = value),
                            validator: (value) =>
                                value == null ? 'Selecione' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- GÊNERO E DATA DE NASCIMENTO ---
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
                                value: 'MALE',
                                child: Text('Macho'),
                              ),
                              DropdownMenuItem(
                                value: 'FEMALE',
                                child: Text('Fêmea'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedGender = value),
                            validator: (value) =>
                                value == null ? 'Selecione' : null,
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

                    // --- DISPONÍVEL PARA ADOÇÃO ---
                    SwitchListTile(
                      title: const Text('Disponível para adoção?'),
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

                    // --- BOTÃO DE SUBMIT ---
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
