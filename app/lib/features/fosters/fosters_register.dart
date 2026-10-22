import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/foster_service.dart';
import '../../utils/validators.dart';

const Color _secondaryColor = Color(0xFFE27B1D);
const LatLng _defaultCenter = LatLng(-29.2361, -51.8697);

List<Widget> _mapLayers(LatLng? point) => [
  TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.ong.acolhepatinhas',
  ),
  if (point != null)
    MarkerLayer(
      markers: [
        Marker(
          point: point,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ],
    ),
];

class FosterRegister extends StatefulWidget {
  final FosterHome? foster;

  const FosterRegister({super.key, this.foster});

  @override
  State<FosterRegister> createState() => _FosterRegisterState();
}

class _FosterRegisterState extends State<FosterRegister> {
  final _formKey = GlobalKey<FormState>();
  final _service = FosterService();

  final _ownerEmailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _capacityController = TextEditingController();

  List<UserOption> _userOptions = [];
  UserOption? _selectedUser;
  bool _isLoadingUsers = false;

  LatLng? _selected;
  bool _isLoading = false;

  bool get _isEditing => widget.foster != null;

  @override
  void initState() {
    super.initState();

    final f = widget.foster;
    if (f != null) {
      _nameController.text = f.name;
      _ownerEmailController.text = f.ownerEmail ?? '';
      _phoneController.text = f.phoneNumber ?? '';
      _emailController.text = f.email ?? '';
      _capacityController.text = f.capacity?.toString() ?? '';

      if (f.hasLocation) {
        _selected = LatLng(f.latitude!, f.longitude!);
        _latitudeController.text = f.latitude!.toStringAsFixed(6);
        _longitudeController.text = f.longitude!.toStringAsFixed(6);
      }
    } else {
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _service.listUserOptions();
      if (mounted) {
        setState(() {
          _userOptions = users;
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _openMap() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => _MapPickerScreen(selected: _selected)),
    );

    if (point == null) return;
    final rounded = LatLng(
      double.parse(point.latitude.toStringAsFixed(6)),
      double.parse(point.longitude.toStringAsFixed(6)),
    );

    setState(() => _selected = rounded);
    _latitudeController.text = rounded.latitude.toStringAsFixed(6);
    _longitudeController.text = rounded.longitude.toStringAsFixed(6);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ownerEmailToSubmit = !_isEditing
          ? _ownerEmailController.text.trim()
          : (widget.foster?.email ?? _emailController.text.trim());

      await _service.saveFosterHome(
        id: widget.foster?.id,
        ownerEmail: ownerEmailToSubmit,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        email: _emailController.text.trim(),
        latitude: _selected!.latitude,
        longitude: _selected!.longitude,
        capacity: int.parse(_capacityController.text.trim()),
      );

      if (!mounted) return;

      _showMessage(
        _isEditing
            ? 'Lar atualizado com sucesso!'
            : 'Lar temporário cadastrado com sucesso!',
        Colors.green,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  String? Function(String?) _rule(bool Function(String?) isValid, String msg) =>
      (value) => isValid(value) ? null : msg;

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: Icon(icon, color: _secondaryColor, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _secondaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    final center = _selected ?? _defaultCenter;

    return GestureDetector(
      onTap: _openMap,
      child: Container(
        height: 260,
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Stack(
          children: [
            IgnorePointer(
              child: FlutterMap(
                key: ValueKey(center),
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _selected == null ? 13 : 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: _mapLayers(_selected),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_full,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selected == null
                          ? 'Toque para escolher o local'
                          : 'Toque para ampliar',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ownerEmailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailRule = _rule(
      (v) => Validators.isValidEmail((v ?? '').trim()),
      'Informe um e-mail válido',
    );

    const pickMsg = 'Escolha o local no mapa';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          _isEditing ? 'Editar lar' : 'Cadastrar lar',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: _secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing
                            ? 'Editar lar temporário'
                            : 'Cadastrar lar temporário',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Preencha os dados do lar e de seu responsável.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Nome do lar',
                        controller: _nameController,
                        icon: Icons.home_outlined,
                        validator: _rule(
                          (v) => Validators.isValidLength(v, 3, 50),
                          'Use entre 3 e 50 caracteres',
                        ),
                      ),

                      if (!_isEditing) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _isLoadingUsers
                              ? const LinearProgressIndicator(
                                  color: _secondaryColor,
                                )
                              : DropdownButtonFormField<UserOption>(
                                  value: _selectedUser,
                                  decoration: InputDecoration(
                                    labelText: 'Selecione o responsável *',
                                    isDense: true,
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: _secondaryColor,
                                      size: 20,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: _secondaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  items: _userOptions.map((user) {
                                    return DropdownMenuItem<UserOption>(
                                      value: user,
                                      child: Text(
                                        user.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (selected) {
                                    setState(() {
                                      _selectedUser = selected;
                                      if (selected != null) {
                                        _ownerEmailController.text =
                                            selected.email;
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null &&
                                        _ownerEmailController.text
                                            .trim()
                                            .isEmpty) {
                                      return 'Selecione o responsável pelo lar';
                                    }
                                    return null;
                                  },
                                ),
                        ),
                      ],

                      if (_isEditing && widget.foster?.ownerName != null) ...[
                        _buildField(
                          label: 'Responsável',
                          controller: TextEditingController(
                            text: widget.foster!.ownerName,
                          ),
                          icon: Icons.badge_outlined,
                          readOnly: true,
                          validator: (_) => null,
                        ),
                      ],

                      _buildField(
                        label: 'Telefone celular',
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _rule(
                          Validators.isValidCellPhone,
                          'Informe um celular com DDD e 11 dígitos',
                        ),
                      ),
                      _buildField(
                        label: 'E-mail de contato do lar',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: emailRule,
                      ),
                      _buildField(
                        label: 'Capacidade de animais',
                        controller: _capacityController,
                        icon: Icons.pets_outlined,
                        keyboardType: TextInputType.number,
                        validator: _rule(
                          Validators.isValidPositiveInt,
                          'Informe uma capacidade maior que zero',
                        ),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Localização',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMapPreview(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Latitude',
                              controller: _latitudeController,
                              icon: Icons.location_on_outlined,
                              readOnly: true,
                              validator: _rule(
                                (v) => Validators.isValidCoordinate(v, 90),
                                pickMsg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Longitude',
                              controller: _longitudeController,
                              icon: Icons.map_outlined,
                              readOnly: true,
                              validator: _rule(
                                (v) => Validators.isValidCoordinate(v, 180),
                                pickMsg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isLoading
                                ? 'Salvando...'
                                : _isEditing
                                ? 'Salvar alterações'
                                : 'Cadastrar lar temporário',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPickerScreen extends StatefulWidget {
  final LatLng? selected;

  const _MapPickerScreen({this.selected});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  final _controller = MapController();
  bool _isLocating = false;

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);

    try {
      final position = await FosterService().getCurrentPosition();
      if (!mounted) return;

      _controller.move(LatLng(position.latitude, position.longitude), 16);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.selected;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'Arraste o mapa até o local',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: _secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: initial ?? _defaultCenter,
              initialZoom: initial == null ? 13 : 16,
              onTap: (_, point) =>
                  _controller.move(point, _controller.camera.zoom),
            ),
            children: _mapLayers(null),
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'my-location',
              backgroundColor: Colors.white,
              foregroundColor: _secondaryColor,
              tooltip: 'Usar minha localização atual',
              onPressed: _isLocating ? null : _goToMyLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, _controller.camera.center),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar local'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
