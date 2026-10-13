import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/veterinary_form_data.dart';
import '../../services/pet_service.dart';
import '../../services/veterinary_service.dart';

const Color _kOrange = Color(0xFFE27B1D);

ShapeBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

InputDecoration compactInput(
  String label, {
  IconData? icon,
  String? hint,
  Widget? suffixIcon,
  bool showCounter = false,
  bool multiline = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: Colors.grey.withOpacity(0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kOrange, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 20, color: Colors.grey.shade700),
    suffixIcon: suffixIcon,
    counterText: showCounter ? null : '',
    alignLabelWithHint: multiline,
  );
}

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

Future<DateTime?> _pickDate(
  BuildContext context, {
  DateTime? current,
  required DateTime first,
  required DateTime last,
}) {
  var initial = current ?? _today();
  if (initial.isAfter(last)) initial = last;
  if (initial.isBefore(first)) initial = first;

  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _kOrange),
        ),
        child: child!,
      );
    },
  );
}

class _DateTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateTextField({
    required this.controller,
    required this.label,
    required this.onTap,
    required this.onClear,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: compactInput(
        label,
        icon: Icons.calendar_today_outlined,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              ),
      ),
      validator: (v) =>
          required && (v == null || v.isEmpty) ? 'Informe a data' : null,
    );
  }
}

class _CatalogDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<int?> onChanged;
  final VoidCallback? onAdd;
  final String? addTooltip;
  final bool allowNone;
  final String? Function(int?)? validator;

  const _CatalogDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.onAdd,
    this.addTooltip,
    this.allowNone = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bool empty = items.isEmpty;

    final dropdown = DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      decoration: compactInput(label),
      hint: Text(
        empty
            ? (onAdd != null
                  ? 'Nenhum cadastrado. Toque aqui'
                  : 'Nenhum cadastrado')
            : 'Selecione',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
      items: [
        if (allowNone)
          const DropdownMenuItem<int>(value: null, child: Text('Nenhum')),
        ...items.map(
          (i) => DropdownMenuItem<int>(
            value: i['id'] as int,
            child: Text(i['name'].toString(), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
      validator: validator,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: (empty && onAdd != null)
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAdd,
                  child: IgnorePointer(child: dropdown),
                )
              : dropdown,
        ),
        if (onAdd != null) ...[
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: addTooltip,
            style: IconButton.styleFrom(
              backgroundColor: _kOrange.withOpacity(0.12),
              foregroundColor: _kOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            onPressed: onAdd,
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// REGISTROS SIMPLES (RAÇA/COR, ESPÉCIE, MOTIVO BAIXA)
// ============================================================================

class RegisterBreedColor extends StatefulWidget {
  final int? speciesId;
  final bool isBreed;

  const RegisterBreedColor({super.key, this.speciesId, required this.isBreed});

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
              name: name,
              specieId: widget.speciesId!,
            )
          : await PetService.registerColor(name: name);

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
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: _nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isSaving) _save();
          },
          decoration: compactInput(label),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}

class RegisterSpecies extends StatefulWidget {
  const RegisterSpecies({super.key});

  @override
  State<RegisterSpecies> createState() => _RegisterSpeciesState();
}

class _RegisterSpeciesState extends State<RegisterSpecies> {
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
        const SnackBar(content: Text('Informe o nome da espécie.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await PetService.registerSpecies(name: name);

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível adicionar a espécie: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar espécie',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: _nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isSaving) _save();
          },
          decoration: compactInput('Nome da espécie'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}

class RegisterDischargeReason extends StatefulWidget {
  const RegisterDischargeReason({super.key});

  @override
  State<RegisterDischargeReason> createState() =>
      _RegisterDischargeReasonState();
}

class _RegisterDischargeReasonState extends State<RegisterDischargeReason> {
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
        const SnackBar(content: Text('Informe o nome do motivo.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await PetService.registerDischargeReason(name: name);

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível adicionar o motivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar motivo de baixa',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: _nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isSaving) _save();
          },
          decoration: compactInput('Nome do motivo'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ============================================================================
// CATALOG DIALOG
// ============================================================================

class VetCatalogDialog extends StatefulWidget {
  final String title;
  final String label;
  final int minLength;
  final int maxLength;
  final bool askFrequency;
  final Future<Map<String, dynamic>> Function(String name, int? frequencyDays)
  onSave;

  const VetCatalogDialog({
    super.key,
    required this.title,
    required this.label,
    required this.onSave,
    this.minLength = 1,
    this.maxLength = 50,
    this.askFrequency = false,
  });

  @override
  State<VetCatalogDialog> createState() => _VetCatalogDialogState();
}

class _VetCatalogDialogState extends State<VetCatalogDialog> {
  final _nameController = TextEditingController();
  final _frequencyController = TextEditingController();
  bool _isSaving = false;
  String? _nameError;
  String? _frequencyError;
  String? _saveError;

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final frequency = int.tryParse(_frequencyController.text.trim());

    String? nameError;
    String? frequencyError;

    if (name.isEmpty) {
      nameError = 'Informe o nome.';
    } else if (name.length < widget.minLength) {
      nameError = 'Use ao menos ${widget.minLength} caracteres.';
    }

    if (widget.askFrequency && (frequency == null || frequency <= 0)) {
      frequencyError = 'Informe a frequência em dias.';
    }

    if (nameError != null || frequencyError != null) {
      setState(() {
        _nameError = nameError;
        _frequencyError = frequencyError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _nameError = null;
      _frequencyError = null;
      _saveError = null;
    });

    try {
      final result = await widget.onSave(name, frequency);
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Não foi possível adicionar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: widget.maxLength,
              textInputAction: widget.askFrequency
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) {
                if (!widget.askFrequency && !_isSaving) _save();
              },
              decoration: compactInput(
                widget.label,
              ).copyWith(errorText: _nameError),
            ),
            if (widget.askFrequency) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _frequencyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 5,
                onSubmitted: (_) {
                  if (!_isSaving) _save();
                },
                decoration: compactInput(
                  'Repetir a cada (dias)',
                  hint: 'Ex.: 180',
                ).copyWith(errorText: _frequencyError),
              ),
            ],
            if (_saveError != null) ...[
              const SizedBox(height: 8),
              Text(
                _saveError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ============================================================================
// VACINA
// ============================================================================

class VaccinationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> vaccines;

  const VaccinationDialog({super.key, required this.vaccines});

  @override
  State<VaccinationDialog> createState() => _VaccinationDialogState();
}

class _VaccinationDialogState extends State<VaccinationDialog> {
  static const _doseSuggestions = [
    'Única',
    'Reforço',
    'Anual',
    '1ª',
    '2ª',
    '3ª',
  ];

  final _formKey = GlobalKey<FormState>();
  final _doseCtl = TextEditingController();
  final _manufacturerCtl = TextEditingController();
  final _batchCtl = TextEditingController();
  final _dateCtl = TextEditingController();
  final _nextCtl = TextEditingController();

  int? _vaccineId;
  DateTime? _date;
  DateTime? _next;

  @override
  void dispose() {
    _doseCtl.dispose();
    _manufacturerCtl.dispose();
    _batchCtl.dispose();
    _dateCtl.dispose();
    _nextCtl.dispose();
    super.dispose();
  }

  Future<void> _createVaccine() async {
    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => VetCatalogDialog(
        title: 'Adicionar vacina',
        label: 'Nome da vacina',
        minLength: 3,
        maxLength: 30,
        onSave: (name, _) => VeterinaryService.registerVaccine(name),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      widget.vaccines.add(created);
      _vaccineId = created['id'] as int;
    });
  }

  Future<void> _pickDoseDate() async {
    final p = await _pickDate(
      context,
      current: _date,
      first: DateTime(2000),
      last: _today(),
    );
    if (p == null) return;
    setState(() {
      _date = p;
      _dateCtl.text = _fmt(p);
    });
  }

  Future<void> _pickNextDate() async {
    final p = await _pickDate(
      context,
      current: _next,
      first: _today().add(const Duration(days: 1)),
      last: DateTime(_today().year + 10),
    );
    if (p == null) return;
    setState(() {
      _next = p;
      _nextCtl.text = _fmt(p);
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final vaccineName = widget.vaccines
        .firstWhere((v) => v['id'] == _vaccineId)['name']
        .toString();
    final dose = _doseCtl.text.trim();
    final manufacturer = _manufacturerCtl.text.trim();
    final batch = _batchCtl.text.trim();

    final subtitle = [
      'Fab.: $manufacturer',
      'Lote: $batch',
      if (_date != null) 'Aplicada em ${_fmt(_date!)}',
      if (_next != null) 'Próxima em ${_fmt(_next!)}',
    ].join('  •  ');

    Navigator.pop(
      context,
      VetEntry(
        title: '$vaccineName  ($dose)',
        subtitle: subtitle,
        payload: {
          'vaccineId': _vaccineId,
          'dose': dose,
          'manufacturer': manufacturer,
          // ⚠️ "batchNumer" (sem o "b") é mantido do DTO do backend
          'batchNumer': batch,
          if (_date != null) 'vaccinationDate': _iso(_date!),
          if (_next != null) 'nextDoseDate': _iso(_next!),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar vacina',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _CatalogDropdown(
                  label: 'Vacina *',
                  value: _vaccineId,
                  items: widget.vaccines,
                  onChanged: (v) => setState(() => _vaccineId = v),
                  onAdd: _createVaccine,
                  addTooltip: 'Cadastrar vacina',
                  validator: (v) => v == null ? 'Selecione a vacina' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doseCtl,
                  maxLength: 10,
                  decoration: compactInput('Dose *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe a dose' : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final s in _doseSuggestions)
                        ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          onPressed: () => _doseCtl.text = s,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _manufacturerCtl,
                  maxLength: 50,
                  decoration: compactInput('Fabricante *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o fabricante'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _batchCtl,
                  maxLength: 50,
                  decoration: compactInput('Lote *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o lote' : null,
                ),
                const SizedBox(height: 12),
                _DateTextField(
                  controller: _dateCtl,
                  label: 'Data da aplicação',
                  onTap: _pickDoseDate,
                  onClear: () => setState(() {
                    _date = null;
                    _dateCtl.clear();
                  }),
                ),
                const SizedBox(height: 12),
                _DateTextField(
                  controller: _nextCtl,
                  label: 'Próxima dose',
                  onTap: _pickNextDate,
                  onClear: () => setState(() {
                    _next = null;
                    _nextCtl.clear();
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _confirm,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ============================================================================
// CIRURGIA
// ============================================================================

class SurgeryDialog extends StatefulWidget {
  final List<Map<String, dynamic>> procedures;

  const SurgeryDialog({super.key, required this.procedures});

  @override
  State<SurgeryDialog> createState() => _SurgeryDialogState();
}

class _SurgeryDialogState extends State<SurgeryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtl = TextEditingController();
  final _obsCtl = TextEditingController();

  int? _procedureId;
  DateTime? _date;

  @override
  void dispose() {
    _dateCtl.dispose();
    _obsCtl.dispose();
    super.dispose();
  }

  Future<void> _createProcedure() async {
    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => VetCatalogDialog(
        title: 'Adicionar procedimento cirúrgico',
        label: 'Nome do procedimento',
        maxLength: 50,
        onSave: (name, _) => VeterinaryService.registerSurgicalProcedure(name),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      widget.procedures.add(created);
      _procedureId = created['id'] as int;
    });
  }

  Future<void> _pickProcedureDate() async {
    final p = await _pickDate(
      context,
      current: _date,
      first: DateTime(2000),
      last: _today(),
    );
    if (p == null) return;
    setState(() {
      _date = p;
      _dateCtl.text = _fmt(p);
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final name = widget.procedures
        .firstWhere((p) => p['id'] == _procedureId)['name']
        .toString();
    final obs = _obsCtl.text.trim();

    Navigator.pop(
      context,
      VetEntry(
        title: name,
        subtitle: [_fmt(_date!), if (obs.isNotEmpty) obs].join('  •  '),
        payload: {
          'procedureId': _procedureId,
          'procedureDate': _iso(_date!),
          if (obs.isNotEmpty) 'observations': obs,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar cirurgia',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _CatalogDropdown(
                  label: 'Procedimento *',
                  value: _procedureId,
                  items: widget.procedures,
                  onChanged: (v) => setState(() => _procedureId = v),
                  onAdd: _createProcedure,
                  addTooltip: 'Cadastrar procedimento',
                  validator: (v) =>
                      v == null ? 'Selecione o procedimento' : null,
                ),
                const SizedBox(height: 12),
                _DateTextField(
                  controller: _dateCtl,
                  label: 'Data da cirurgia *',
                  required: true,
                  onTap: _pickProcedureDate,
                  onClear: () => setState(() {
                    _date = null;
                    _dateCtl.clear();
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _obsCtl,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 5000,
                  decoration: compactInput('Observações', multiline: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _confirm,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ============================================================================
// CUIDADO PREVENTIVO
// ============================================================================

class PreventiveDialog extends StatefulWidget {
  final List<Map<String, dynamic>> procedures;
  final List<Map<String, dynamic>> medicines;

  const PreventiveDialog({
    super.key,
    required this.procedures,
    required this.medicines,
  });

  @override
  State<PreventiveDialog> createState() => _PreventiveDialogState();
}

class _PreventiveDialogState extends State<PreventiveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtl = TextEditingController();
  final _nextCtl = TextEditingController();
  final _obsCtl = TextEditingController();

  int? _procedureId;
  int? _medicineId;
  DateTime? _date;
  DateTime? _next;
  bool _nextAuto = false;

  @override
  void dispose() {
    _dateCtl.dispose();
    _nextCtl.dispose();
    _obsCtl.dispose();
    super.dispose();
  }

  Future<void> _createProcedure() async {
    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => VetCatalogDialog(
        title: 'Adicionar procedimento preventivo',
        label: 'Nome do procedimento',
        maxLength: 50,
        askFrequency: true,
        onSave: (name, days) => VeterinaryService.registerPreventiveProcedure(
          name: name,
          defaultFrequencyDays: days!,
        ),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      widget.procedures.add(created);
      _procedureId = created['id'] as int;
    });
    _suggestNext();
  }

  Future<void> _createMedicine() async {
    final created = await _createMedicineDialog(context);
    if (created == null || !mounted) return;
    setState(() {
      widget.medicines.add(created);
      _medicineId = created['id'] as int;
    });
  }

  void _suggestNext() {
    if (_date == null || _procedureId == null) return;
    if (_next != null && !_nextAuto) return;

    final proc = widget.procedures.firstWhere(
      (p) => p['id'] == _procedureId,
      orElse: () => <String, dynamic>{},
    );
    final days = proc['defaultFrequencyDays'];
    if (days is! int || days <= 0) return;

    final suggested = _date!.add(Duration(days: days));
    if (suggested.isBefore(_today())) return;

    setState(() {
      _next = suggested;
      _nextAuto = true;
      _nextCtl.text = _fmt(suggested);
    });
  }

  Future<void> _pickProcedureDate() async {
    final p = await _pickDate(
      context,
      current: _date,
      first: DateTime(2000),
      last: _today(),
    );
    if (p == null) return;
    setState(() {
      _date = p;
      _dateCtl.text = _fmt(p);
    });
    _suggestNext();
  }

  Future<void> _pickNextDate() async {
    final p = await _pickDate(
      context,
      current: _next,
      first: _today(),
      last: DateTime(_today().year + 10),
    );
    if (p == null) return;
    setState(() {
      _next = p;
      _nextAuto = false;
      _nextCtl.text = _fmt(p);
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final procName = widget.procedures
        .firstWhere((p) => p['id'] == _procedureId)['name']
        .toString();
    final medName = _medicineId == null
        ? null
        : widget.medicines
              .firstWhere((m) => m['id'] == _medicineId)['name']
              .toString();
    final obs = _obsCtl.text.trim();

    Navigator.pop(
      context,
      VetEntry(
        title: procName,
        subtitle: [
          _fmt(_date!),
          if (medName != null) medName,
          if (_next != null) 'Próximo em ${_fmt(_next!)}',
        ].join('  •  '),
        payload: {
          'procedureId': _procedureId,
          if (_medicineId != null) 'medicineId': _medicineId,
          'procedureDate': _iso(_date!),
          if (_next != null) 'nextProcedureDate': _iso(_next!),
          if (obs.isNotEmpty) 'observations': obs,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar cuidado preventivo',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _CatalogDropdown(
                  label: 'Procedimento *',
                  value: _procedureId,
                  items: widget.procedures,
                  onChanged: (v) {
                    setState(() => _procedureId = v);
                    _suggestNext();
                  },
                  onAdd: _createProcedure,
                  addTooltip: 'Cadastrar procedimento',
                  validator: (v) =>
                      v == null ? 'Selecione o procedimento' : null,
                ),
                const SizedBox(height: 12),
                _CatalogDropdown(
                  label: 'Medicamento (opcional)',
                  value: _medicineId,
                  items: widget.medicines,
                  allowNone: true,
                  onChanged: (v) => setState(() => _medicineId = v),
                  onAdd: _createMedicine,
                  addTooltip: 'Cadastrar medicamento',
                ),
                const SizedBox(height: 12),
                _DateTextField(
                  controller: _dateCtl,
                  label: 'Data do procedimento *',
                  required: true,
                  onTap: _pickProcedureDate,
                  onClear: () => setState(() {
                    _date = null;
                    _dateCtl.clear();
                  }),
                ),
                const SizedBox(height: 12),
                _DateTextField(
                  controller: _nextCtl,
                  label: 'Próximo procedimento',
                  onTap: _pickNextDate,
                  onClear: () => setState(() {
                    _next = null;
                    _nextAuto = false;
                    _nextCtl.clear();
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _obsCtl,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 5000,
                  decoration: compactInput('Observações', multiline: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _confirm,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ============================================================================
// MEDICAMENTO (CADASTRO RÁPIDO) & EXAME
// ============================================================================

Future<Map<String, dynamic>?> _createMedicineDialog(BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => VetCatalogDialog(
      title: 'Adicionar medicamento',
      label: 'Nome do medicamento',
      maxLength: 50,
      onSave: (name, _) => VeterinaryService.registerMedicine(name),
    ),
  );
}

class LabTestDialog extends StatefulWidget {
  final List<Map<String, dynamic>> labTests;

  const LabTestDialog({super.key, required this.labTests});

  @override
  State<LabTestDialog> createState() => _LabTestDialogState();
}

class _LabTestDialogState extends State<LabTestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtl = TextEditingController();
  final _resultsCtl = TextEditingController();
  final _obsCtl = TextEditingController();

  int? _testId;
  DateTime? _date;

  @override
  void dispose() {
    _dateCtl.dispose();
    _resultsCtl.dispose();
    _obsCtl.dispose();
    super.dispose();
  }

  Future<void> _createTest() async {
    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => VetCatalogDialog(
        title: 'Adicionar tipo de exame',
        label: 'Nome do exame',
        maxLength: 50,
        onSave: (name, _) => VeterinaryService.registerLabTest(name),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      widget.labTests.add(created);
      _testId = created['id'] as int;
    });
  }

  Future<void> _pickTestDate() async {
    final p = await _pickDate(
      context,
      current: _date,
      first: DateTime(2000),
      last: _today(),
    );
    if (p == null) return;
    setState(() {
      _date = p;
      _dateCtl.text = _fmt(p);
    });
  }

  String _instantFor(DateTime d) {
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final local = isToday
        ? now.subtract(const Duration(minutes: 5))
        : DateTime(d.year, d.month, d.day, 12);
    return local.toUtc().toIso8601String();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final name = widget.labTests
        .firstWhere((t) => t['id'] == _testId)['name']
        .toString();
    final results = _resultsCtl.text.trim();
    final obs = _obsCtl.text.trim();

    Navigator.pop(
      context,
      VetEntry(
        title: name,
        subtitle: [_fmt(_date!), results].join('  •  '),
        payload: {
          'labTestId': _testId,
          'testDate': _instantFor(_date!),
          'results': results,
          if (obs.isNotEmpty) 'observations': obs,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar exame',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _CatalogDropdown(
                  label: 'Exame *',
                  value: _testId,
                  items: widget.labTests,
                  onChanged: (v) => setState(() => _testId = v),
                  onAdd: _createTest,
                  addTooltip: 'Cadastrar tipo de exame',
                  validator: (v) => v == null ? 'Selecione o exame' : null,
                ),
                const SizedBox(height: 12),
                _DateTextField(
                  controller: _dateCtl,
                  label: 'Data do exame *',
                  required: true,
                  onTap: _pickTestDate,
                  onClear: () => setState(() {
                    _date = null;
                    _dateCtl.clear();
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resultsCtl,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 10000,
                  decoration: compactInput('Resultado *', multiline: true),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o resultado'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _obsCtl,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 5000,
                  decoration: compactInput('Observações', multiline: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _confirm,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ============================================================================
// DIAGNÓSTICO
// ============================================================================

class DiagnosisDialog extends StatefulWidget {
  final List<Map<String, dynamic>> diseases;
  final int localId;

  const DiagnosisDialog({
    super.key,
    required this.diseases,
    required this.localId,
  });

  @override
  State<DiagnosisDialog> createState() => _DiagnosisDialogState();
}

class _DiagnosisDialogState extends State<DiagnosisDialog> {
  static const _statuses = {
    'ACTIVE': 'Ativa',
    'HEALED': 'Curada',
    'CHRONIC': 'Crônica',
  };

  final _formKey = GlobalKey<FormState>();
  final _dateCtl = TextEditingController();

  int? _diseaseId;
  DateTime? _date;
  String _status = 'ACTIVE';

  @override
  void dispose() {
    _dateCtl.dispose();
    super.dispose();
  }

  Future<void> _createDisease() async {
    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => VetCatalogDialog(
        title: 'Adicionar doença',
        label: 'Nome da doença',
        maxLength: 50,
        onSave: (name, _) => VeterinaryService.registerDisease(name),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      widget.diseases.add(created);
      _diseaseId = created['id'] as int;
    });
  }

  Future<void> _pickDiagnosisDate() async {
    final p = await _pickDate(
      context,
      current: _date,
      first: DateTime(2000),
      last: _today(),
    );
    if (p == null) return;
    setState(() {
      _date = p;
      _dateCtl.text = _fmt(p);
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final name = widget.diseases
        .firstWhere((d) => d['id'] == _diseaseId)['name']
        .toString();
    final iso = _date == null ? null : _iso(_date!);

    Navigator.pop(
      context,
      VetEntry(
        title: name,
        subtitle: [
          _statuses[_status]!,
          if (_date != null) _fmt(_date!),
        ].join('  •  '),
        payload: {
          'diseaseId': _diseaseId,
          'status': _status,
          if (iso != null) 'diagnosedAt': iso,
        },
        meta: {
          'localId': widget.localId,
          'diseaseName': name,
          'status': _status,
          'diagnosedAt': iso,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar diagnóstico',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _CatalogDropdown(
                  label: 'Doença *',
                  value: _diseaseId,
                  items: widget.diseases,
                  onChanged: (v) => setState(() => _diseaseId = v),
                  onAdd: _createDisease,
                  addTooltip: 'Cadastrar doença',
                  validator: (v) => v == null ? 'Selecione a doença' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  decoration: compactInput('Situação'),
                  items: _statuses.entries
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
                ),
                const SizedBox(height: 12),
                _DateTextField(
                  controller: _dateCtl,
                  label: 'Data do diagnóstico',
                  onTap: _pickDiagnosisDate,
                  onClear: () => setState(() {
                    _date = null;
                    _dateCtl.clear();
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _confirm,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

// ============================================================================
// POSOLOGIA & TRATAMENTO
// ============================================================================

class PosologyDialog extends StatefulWidget {
  final List<Map<String, dynamic>> medicines;
  final DateTime? defaultStart;

  const PosologyDialog({super.key, required this.medicines, this.defaultStart});

  @override
  State<PosologyDialog> createState() => _PosologyDialogState();
}

class _PosologyDialogState extends State<PosologyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dosageCtl = TextEditingController();
  final _frequencyCtl = TextEditingController();
  final _daysCtl = TextEditingController();
  final _dateCtl = TextEditingController();

  int? _medicineId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.defaultStart ?? _today();
    _dateCtl.text = _fmt(_date);
  }

  @override
  void dispose() {
    _dosageCtl.dispose();
    _frequencyCtl.dispose();
    _daysCtl.dispose();
    _dateCtl.dispose();
    super.dispose();
  }

  Future<void> _newMedicine() async {
    final created = await _createMedicineDialog(context);
    if (created == null || !mounted) return;
    setState(() {
      widget.medicines.add(created);
      _medicineId = created['id'] as int;
    });
  }

  Future<void> _pickStart() async {
    final p = await _pickDate(
      context,
      current: _date,
      first: DateTime(2000),
      last: _today(),
    );
    if (p == null) return;
    setState(() {
      _date = p;
      _dateCtl.text = _fmt(p);
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final name = widget.medicines
        .firstWhere((m) => m['id'] == _medicineId)['name']
        .toString();
    final dosage = _dosageCtl.text.trim();
    final frequency = _frequencyCtl.text.trim();
    final days = int.parse(_daysCtl.text.trim());

    Navigator.pop(
      context,
      VetEntry(
        title: name,
        subtitle:
            '$dosage  •  $frequency  •  $days ${days == 1 ? 'dia' : 'dias'}',
        payload: {
          'medicineId': _medicineId,
          'dosage': dosage,
          'frequency': frequency,
          'durationDays': days,
          // ⚠️ "starDate" (sem o "t") é mantido do NewPosologyRequest do backend
          'starDate': _iso(_date),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar medicamento',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _CatalogDropdown(
                  label: 'Medicamento *',
                  value: _medicineId,
                  items: widget.medicines,
                  onChanged: (v) => setState(() => _medicineId = v),
                  onAdd: _newMedicine,
                  addTooltip: 'Cadastrar medicamento',
                  validator: (v) =>
                      v == null ? 'Selecione o medicamento' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dosageCtl,
                  maxLength: 30,
                  decoration: compactInput('Dose *', hint: 'Ex.: 1 comprimido'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe a dose' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _frequencyCtl,
                  maxLength: 30,
                  decoration: compactInput(
                    'Frequência *',
                    hint: 'Ex.: a cada 12h',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a frequência'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _daysCtl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  decoration: compactInput('Duração (dias) *'),
                  validator: (v) => int.tryParse((v ?? '').trim()) == null
                      ? 'Informe os dias'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateCtl,
                  readOnly: true,
                  onTap: _pickStart,
                  decoration: compactInput(
                    'Início *',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _confirm,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class TreatmentDialog extends StatefulWidget {
  final List<Map<String, dynamic>> medicines;
  final List<VetEntry> diagnoses;

  const TreatmentDialog({
    super.key,
    required this.medicines,
    required this.diagnoses,
  });

  @override
  State<TreatmentDialog> createState() => _TreatmentDialogState();
}

class _TreatmentDialogState extends State<TreatmentDialog> {
  static const _statuses = {
    'PENDING': 'Pendente',
    'STARTED': 'Em andamento',
    'FINISHED': 'Concluído',
    'CANCELED': 'Cancelado',
  };

  final _startCtl = TextEditingController();
  final _endCtl = TextEditingController();
  final _obsCtl = TextEditingController();
  final List<VetEntry> _meds = [];

  String _status = 'PENDING';
  int? _diagnosisLocalId;
  DateTime? _start;
  DateTime? _end;
  String? _error;

  @override
  void dispose() {
    _startCtl.dispose();
    _endCtl.dispose();
    _obsCtl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final p = await _pickDate(
      context,
      current: _start,
      first: DateTime(2000),
      last: _today(),
    );
    if (p == null) return;
    setState(() {
      _start = p;
      _startCtl.text = _fmt(p);
    });
  }

  Future<void> _pickEndDate() async {
    final p = await _pickDate(
      context,
      current: _end,
      first: _start ?? DateTime(2000),
      last: DateTime(_today().year + 5),
    );
    if (p == null) return;
    setState(() {
      _end = p;
      _endCtl.text = _fmt(p);
    });
  }

  Future<void> _addMed() async {
    final e = await showDialog<VetEntry>(
      context: context,
      builder: (_) =>
          PosologyDialog(medicines: widget.medicines, defaultStart: _start),
    );
    if (e == null || !mounted) return;
    setState(() => _meds.add(e));
  }

  void _confirm() {
    if (_diagnosisLocalId == null) {
      setState(
        () => _error =
            'Selecione um diagnóstico (adicione um antes, se preciso).',
      );
      return;
    }

    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      setState(() => _error = 'A data final não pode ser antes da inicial.');
      return;
    }

    final diagnosisName = widget.diagnoses
        .firstWhere((d) => d.meta['localId'] == _diagnosisLocalId)
        .title;
    final obs = _obsCtl.text.trim();

    Navigator.pop(
      context,
      VetEntry(
        title: 'Tratamento (${_statuses[_status]})',
        subtitle: [
          'Diagnóstico: $diagnosisName',
          if (_start != null) 'Início ${_fmt(_start!)}',
          if (_end != null) 'Fim ${_fmt(_end!)}',
          if (_meds.isNotEmpty) '${_meds.length} medicamento(s)',
        ].join('  •  '),
        payload: {
          'status': _status,
          if (_start != null) 'startDate': _iso(_start!),
          if (_end != null) 'endDate': _iso(_end!),
          if (obs.isNotEmpty) 'observations': obs,
        },
        meta: {
          'diagnosisLocalId': _diagnosisLocalId,
          'createdId': null,
          'medicines': _meds.map((m) => m.payload).toList(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: _dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(16),
      title: const Text(
        'Adicionar tratamento',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(280, 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _diagnosisLocalId,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                decoration: compactInput('Diagnóstico *'),
                hint: Text(
                  widget.diagnoses.isEmpty
                      ? 'Adicione um diagnóstico antes'
                      : 'Selecione',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                items: widget.diagnoses
                    .map(
                      (d) => DropdownMenuItem<int>(
                        value: d.meta['localId'] as int,
                        child: Text(d.title, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _diagnosisLocalId = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                decoration: compactInput('Situação'),
                items: _statuses.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'PENDING'),
              ),
              const SizedBox(height: 12),
              _DateTextField(
                controller: _startCtl,
                label: 'Início',
                onTap: _pickStartDate,
                onClear: () => setState(() {
                  _start = null;
                  _startCtl.clear();
                }),
              ),
              const SizedBox(height: 12),
              _DateTextField(
                controller: _endCtl,
                label: 'Fim',
                onTap: _pickEndDate,
                onClear: () => setState(() {
                  _end = null;
                  _endCtl.clear();
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obsCtl,
                minLines: 2,
                maxLines: 3,
                maxLength: 5000,
                decoration: compactInput('Observações', multiline: true),
              ),
              if (VetRoutes.posologyEnabled) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Medicamentos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: _kOrange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onPressed: _addMed,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (int i = 0; i < _meds.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      title: Text(
                        _meds[i].title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _meds[i].subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => setState(() => _meds.removeAt(i)),
                      ),
                    ),
                  ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kOrange),
          onPressed: _confirm,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
