import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../services/pet_service.dart';
import '../../services/veterinary_service.dart';
import '../register/register_pets.dart';
import '../listPets/edit_pet.dart';

const Color _kOrange = Color(0xFFE27B1D);

String? _resolveImageUrl(Map<String, dynamic> pet) {
  final rawUrl = pet['imageUrl'] ?? pet['image_url'] ?? pet['photoUrl'];
  if (rawUrl == null || rawUrl.toString().isEmpty) return null;

  final String urlStr = rawUrl.toString();
  if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
    return urlStr;
  }

  return '${PetService.baseUrl}$urlStr';
}

String _formatAge(dynamic ageRaw) {
  if (ageRaw == null) return 'Idade não informada';

  if (ageRaw is num) {
    final years = ageRaw.toInt();
    if (years <= 0) return 'Menos de 1 ano';
    return '$years ${years == 1 ? 'ano' : 'anos'}';
  }
  return '$ageRaw anos';
}

Map<String, dynamic>? _vetRecordOf(Map<String, dynamic> pet) {
  final r = pet['veterinaryRecord'];
  return r is Map<String, dynamic> ? r : null;
}

String? _formatWeight(dynamic w) {
  if (w == null) return null;
  final n = (w is num) ? w.toDouble() : double.tryParse(w.toString());
  if (n == null) return null;
  final s = (n == n.roundToDouble())
      ? n.toStringAsFixed(0)
      : n.toStringAsFixed(1);
  return '$s kg';
}

String? _formatSize(dynamic s) {
  if (s == null) return null;
  return '$s cm';
}

String _fmtIso(dynamic iso) {
  if (iso == null) return '';
  final str = iso.toString();
  if (str.isEmpty) return '';
  try {
    final d = DateTime.parse(str).toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return str;
  }
}

const _diagnosisStatusLabels = {
  'ACTIVE': 'Ativa',
  'HEALED': 'Curada',
  'CHRONIC': 'Crônica',
};

const _treatmentStatusLabels = {
  'PENDING': 'Pendente',
  'STARTED': 'Em andamento',
  'FINISHED': 'Concluído',
  'CANCELED': 'Cancelado',
};

Future<List<Map<String, dynamic>>> _safeList(
  String label,
  Future<List<Map<String, dynamic>>> Function() loader,
  List<String> errors,
) async {
  try {
    return await loader();
  } catch (e) {
    debugPrint('[histórico veterinário] $label falhou: $e');
    errors.add(label);
    return [];
  }
}

class _PetDetailsResult {
  final String? description;
  final List<Map<String, dynamic>> vaccinations;
  final List<Map<String, dynamic>> surgeries;
  final List<Map<String, dynamic>> preventives;
  final List<Map<String, dynamic>> labTests;
  final List<Map<String, dynamic>> diagnoses;
  final List<Map<String, dynamic>> treatments;
  final List<String> errors;

  const _PetDetailsResult({
    required this.description,
    required this.vaccinations,
    required this.surgeries,
    required this.preventives,
    required this.labTests,
    required this.diagnoses,
    required this.treatments,
    required this.errors,
  });
}

class _PetDetailsCache {
  static final Map<int, _PetDetailsResult> _cache = {};

  static _PetDetailsResult? get(int animalId) => _cache[animalId];

  static void put(int animalId, _PetDetailsResult result) {
    _cache[animalId] = result;
  }

  static void clear() => _cache.clear();
}

class ListPetsScreen extends StatefulWidget {
  final bool isAdminMode;
  final int navIndex;

  const ListPetsScreen({
    super.key,
    this.isAdminMode = false,
    this.navIndex = 1,
  });

  @override
  State<ListPetsScreen> createState() => _ListPetsScreenState();
}

class _ListPetsScreenState extends State<ListPetsScreen> {
  static const Color primaryColor = _kOrange;

  List<Map<String, dynamic>> _pets = [];
  bool _isLoadingPets = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingPets = true);
    _PetDetailsCache.clear();

    try {
      final petsList = await PetService.fetchAnimals();
      if (!mounted) return;

      setState(() {
        if (!widget.isAdminMode) {
          _pets = petsList.where((pet) {
            final isToAdoption = pet['toAdoption'] == true;
            final hasDischarge =
                pet['dischargeDate'] != null ||
                pet['dischargeReasonId'] != null;
            return isToAdoption && !hasDischarge;
          }).toList();
        } else {
          _pets = petsList;
        }

        _isLoadingPets = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingPets = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar lista de pets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openRegisterPets() async {
    final bool? created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPetsScreen()),
    );

    if (created == true) {
      _loadPets(silent: true);
    }
  }

  void _showPetDetailsModal(Map<String, dynamic> pet, String heroTag) {
    showDialog(
      context: context,
      builder: (context) => _PetDetailsDialog(pet: pet, heroTag: heroTag),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdminMode ? 'Gestão de Pets (Admin)' : 'Pets para Adoção',
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: (_isLoadingPets && _pets.isEmpty)
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _pets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    widget.isAdminMode
                        ? 'Nenhum pet cadastrado no sistema.'
                        : 'Nenhum pet disponível para adoção no momento.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPets,
              color: primaryColor,
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return _buildGridPetCard(pet, index);
                },
              ),
            ),
      floatingActionButton: widget.isAdminMode
          ? FloatingActionButton.extended(
              onPressed: _openRegisterPets,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Cadastrar Pet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      bottomNavigationBar: NavbarComponent(currentIndex: widget.navIndex),
    );
  }

  Widget _buildGridPetCard(Map<String, dynamic> pet, int index) {
    final String name = pet['name']?.toString() ?? 'Sem Nome';
    final String imageUrl = _resolveImageUrl(pet) ?? '';
    final String genderChar = pet['gender']?.toString().toUpperCase() ?? 'M';
    final bool isMale = genderChar == 'M';
    final bool toAdoption = pet['toAdoption'] ?? false;
    final String heroTag = 'pet-img-${pet['id'] ?? index}';

    final String breed = pet['breed'] is Map
        ? (pet['breed']['name'] ?? 'Não informada')
        : (pet['breed']?.toString() ?? 'Não informada');

    final String color = pet['color'] is Map
        ? (pet['color']['name'] ?? 'Não informada')
        : (pet['color']?.toString() ?? 'Não informada');

    final String ageText = _formatAge(pet['age']);

    final vetRecord = _vetRecordOf(pet);
    final String? weightText = _formatWeight(vetRecord?['weight']);
    final String? sizeText = _formatSize(vetRecord?['size']);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (widget.isAdminMode) {
          final bool? updatedOrDischarged = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPetScreen(petData: pet, isAdmin: true),
            ),
          );

          if (updatedOrDischarged == true) {
            _loadPets(silent: true);
          }
        } else {
          // Modal de Detalhes com Animação Hero
          _showPetDetailsModal(pet, heroTag);
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem com Hero Tag
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: heroTag,
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: toAdoption
                            ? Colors.green.shade700
                            : Colors.grey.shade800.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        toAdoption ? 'Para Adoção' : 'Indisponível',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isMale ? Icons.male : Icons.female,
                        color: isMale ? Colors.blue : Colors.pink,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$breed • Cor: $color',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        size: 12,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ageText,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (weightText != null || sizeText != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.monitor_weight_outlined,
                          size: 12,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (weightText != null) weightText,
                              if (sizeText != null) sizeText,
                            ].join('  •  '),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Icon(Icons.pets, size: 28, color: Colors.grey[400])),
    );
  }
}

class _PetDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String heroTag;

  const _PetDetailsDialog({required this.pet, required this.heroTag});

  @override
  State<_PetDetailsDialog> createState() => _PetDetailsDialogState();
}

class _PetDetailsDialogState extends State<_PetDetailsDialog> {
  bool _loadingExtra = true;
  String? _description;
  List<Map<String, dynamic>> _vaccinations = [];
  List<Map<String, dynamic>> _surgeries = [];
  List<Map<String, dynamic>> _preventives = [];
  List<Map<String, dynamic>> _labTests = [];
  List<Map<String, dynamic>> _diagnoses = [];
  List<Map<String, dynamic>> _treatments = [];
  final List<String> _sectionErrors = [];

  int? get _animalId {
    final raw = widget.pet['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    final id = _animalId;
    if (id == null) {
      setState(() => _loadingExtra = false);
      return;
    }

    final cached = _PetDetailsCache.get(id);
    if (cached != null) {
      _applyResult(cached);
      return;
    }

    String? description;
    final errors = <String>[];
    final descriptionFuture = PetService.fetchAnimalDetail(
      id,
    ).then((detail) => description = detail['description']?.toString());

    final results = await Future.wait([
      _safeList(
        'Vacinação',
        () => VeterinaryService.fetchAnimalVaccinations(id),
        errors,
      ),
      _safeList(
        'Cirurgias',
        () => VeterinaryService.fetchAnimalSurgeries(id),
        errors,
      ),
      _safeList(
        'Cuidados preventivos',
        () => VeterinaryService.fetchAnimalPreventives(id),
        errors,
      ),
      _safeList(
        'Exames laboratoriais',
        () => VeterinaryService.fetchAnimalLabTests(id),
        errors,
      ),
      _safeList(
        'Diagnósticos',
        () => VeterinaryService.fetchAnimalDiagnoses(id),
        errors,
      ),
      _safeList(
        'Tratamentos',
        () => VeterinaryService.fetchAnimalTreatments(id),
        errors,
      ),
    ]);
    await descriptionFuture;

    if (!mounted) return;

    final result = _PetDetailsResult(
      description: description,
      vaccinations: results[0],
      surgeries: results[1],
      preventives: results[2],
      labTests: results[3],
      diagnoses: results[4],
      treatments: results[5],
      errors: errors,
    );

    _PetDetailsCache.put(id, result);
    _applyResult(result);
  }

  void _applyResult(_PetDetailsResult r) {
    setState(() {
      _description = r.description;
      _vaccinations = r.vaccinations;
      _surgeries = r.surgeries;
      _preventives = r.preventives;
      _labTests = r.labTests;
      _diagnoses = r.diagnoses;
      _treatments = r.treatments;
      _sectionErrors
        ..clear()
        ..addAll(r.errors);
      _loadingExtra = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final String name = pet['name']?.toString() ?? 'Sem Nome';
    final String imageUrl = _resolveImageUrl(pet) ?? '';
    final String genderChar = pet['gender']?.toString().toUpperCase() ?? 'M';
    final bool isMale = genderChar == 'M';
    final bool toAdoption = pet['toAdoption'] ?? false;

    final String breed = pet['breed'] is Map
        ? (pet['breed']['name'] ?? 'Não informada')
        : (pet['breed']?.toString() ?? 'Não informada');

    final String color = pet['color'] is Map
        ? (pet['color']['name'] ?? 'Não informada')
        : (pet['color']?.toString() ?? 'Não informada');

    final String ageText = _formatAge(pet['age']);

    final vetRecord = _vetRecordOf(pet);
    final String? weightText = _formatWeight(vetRecord?['weight']);
    final String? sizeText = _formatSize(vetRecord?['size']);
    final bool? neutered = vetRecord?['neutered'] as bool?;

    final String description =
        (_description != null && _description!.trim().isNotEmpty)
        ? _description!
        : 'Este pet está à procura de um lar amoroso! Entre em contato para saber mais detalhes sobre o processo de adoção.';

    final bool hasHistory =
        _vaccinations.isNotEmpty ||
        _surgeries.isNotEmpty ||
        _preventives.isNotEmpty ||
        _labTests.isNotEmpty ||
        _diagnoses.isNotEmpty ||
        _treatments.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: widget.heroTag,
                  child: SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),

            // Informações do Pet
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        isMale ? Icons.male : Icons.female,
                        color: isMale ? Colors.blue : Colors.pink,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(Icons.pets, breed),
                      _buildChip(Icons.palette_outlined, color),
                      _buildChip(Icons.cake_outlined, ageText),
                      if (weightText != null)
                        _buildChip(Icons.monitor_weight_outlined, weightText),
                      if (sizeText != null) _buildChip(Icons.height, sizeText),
                      if (neutered == true)
                        _buildChip(Icons.check_circle_outline, 'Castrado(a)'),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Sobre o pet:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Histórico veterinário:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_loadingExtra)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kOrange,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (_sectionErrors.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Não foi possível carregar: ${_sectionErrors.join(', ')}.',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (!hasHistory && _sectionErrors.isEmpty)
                      Text(
                        'Nenhum histórico veterinário registrado.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    _buildHistorySection(
                      'Vacinação',
                      Icons.vaccines_outlined,
                      _vaccinations.map((v) {
                        final dose = v['dose']?.toString() ?? '';
                        return _HistoryRow(
                          title:
                              '${v['vaccineName'] ?? '—'}${dose.isEmpty ? '' : '  ($dose)'}',
                          subtitle: [
                            if (v['vaccinationDate'] != null)
                              'Aplicada em ${_fmtIso(v['vaccinationDate'])}',
                            if (v['nextDoseDate'] != null)
                              'Próxima em ${_fmtIso(v['nextDoseDate'])}',
                          ].join('  •  '),
                        );
                      }).toList(),
                    ),
                    _buildHistorySection(
                      'Cirurgias',
                      Icons.healing_outlined,
                      _surgeries.map((s) {
                        final obs = s['observations']?.toString() ?? '';
                        return _HistoryRow(
                          title: s['surgicalProcedureName']?.toString() ?? '—',
                          subtitle: [
                            if (s['procedureDate'] != null)
                              _fmtIso(s['procedureDate']),
                            if (obs.isNotEmpty) obs,
                          ].join('  •  '),
                        );
                      }).toList(),
                    ),
                    _buildHistorySection(
                      'Cuidados preventivos',
                      Icons.shield_outlined,
                      _preventives.map((p) {
                        final med = p['medicineName']?.toString();
                        return _HistoryRow(
                          title: p['procedureName']?.toString() ?? '—',
                          subtitle: [
                            if (p['procedureDate'] != null)
                              _fmtIso(p['procedureDate']),
                            if (med != null && med.isNotEmpty) med,
                            if (p['nextProcedureDate'] != null)
                              'Próximo em ${_fmtIso(p['nextProcedureDate'])}',
                          ].join('  •  '),
                        );
                      }).toList(),
                    ),
                    _buildHistorySection(
                      'Exames laboratoriais',
                      Icons.biotech_outlined,
                      _labTests.map((t) {
                        return _HistoryRow(
                          title: t['labTestName']?.toString() ?? '—',
                          subtitle: t['testDate'] != null
                              ? _fmtIso(t['testDate'])
                              : '',
                        );
                      }).toList(),
                    ),
                    _buildHistorySection(
                      'Diagnósticos',
                      Icons.sick_outlined,
                      _diagnoses.map((d) {
                        final status =
                            _diagnosisStatusLabels[d['status']] ??
                            d['status']?.toString() ??
                            '';
                        return _HistoryRow(
                          title: d['diseaseName']?.toString() ?? '—',
                          subtitle: [
                            status,
                            if (d['diagnosedAt'] != null)
                              _fmtIso(d['diagnosedAt']),
                          ].join('  •  '),
                        );
                      }).toList(),
                    ),
                    _buildHistorySection(
                      'Tratamentos',
                      Icons.medication_outlined,
                      _treatments.map((t) {
                        final status =
                            _treatmentStatusLabels[t['status']] ??
                            t['status']?.toString() ??
                            '';
                        return _HistoryRow(
                          title: t['diseaseName']?.toString() ?? 'Tratamento',
                          subtitle: status,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  if (toAdoption)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Interesse registrado para $name!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.favorite),
                        label: const Text(
                          'Quero Adotar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    String title,
    IconData icon,
    List<_HistoryRow> rows,
  ) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _kOrange),
              const SizedBox(width: 6),
              Text(
                '$title (${rows.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.title, style: const TextStyle(fontSize: 13)),
                  if (row.subtitle.isNotEmpty)
                    Text(
                      row.subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _kOrange),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Icon(Icons.pets, size: 28, color: Colors.grey[400])),
    );
  }
}

class _HistoryRow {
  final String title;
  final String subtitle;
  const _HistoryRow({required this.title, this.subtitle = ''});
}
