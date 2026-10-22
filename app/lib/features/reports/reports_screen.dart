import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../components/navbar.dart';
import '../../services/foster_service.dart';
import '../../services/reports_service.dart';
import '../../utils/validators.dart';

const Color _orange = Color(0xFFE27B1D);
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

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ReportService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  ReportType _selectedType = ReportType.LOST;
  LatLng? _selectedLocation;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickPetImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
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

  Future<void> _openMapPicker() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapLocationPicker(selected: _selectedLocation),
      ),
    );

    if (point == null) return;

    final rounded = LatLng(
      double.parse(point.latitude.toStringAsFixed(6)),
      double.parse(point.longitude.toStringAsFixed(6)),
    );

    setState(() {
      _selectedLocation = rounded;
      _latitudeController.text = rounded.latitude.toStringAsFixed(6);
      _longitudeController.text = rounded.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma foto do animal.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha o local no mapa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        imageFile: File(_selectedImage!.path),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte publicado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/feed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: _orange) : null,
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
                shape: BoxShape.rectangle,
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
                          'Foto do Pet *',
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

  Widget _buildMapPreview() {
    final center = _selectedLocation ?? _defaultCenter;

    return GestureDetector(
      onTap: _openMapPicker,
      child: Container(
        height: 290,
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            IgnorePointer(
              child: FlutterMap(
                key: ValueKey(center),
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _selectedLocation == null ? 13 : 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: _mapLayers(_selectedLocation),
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
                      _selectedLocation == null
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

  Widget _buildTypeCard({
    required ReportType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? Function(String?) rule(
      bool Function(String?) isValid,
      String msg,
    ) =>
        (value) => isValid(value) ? null : msg;

    const pickMsg = 'Escolha o local no mapa';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reportar Animal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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

                  // Seleção do Tipo de Reporte
                  Row(
                    children: [
                      _buildTypeCard(
                        type: ReportType.LOST,
                        label: 'Perdido',
                        icon: Icons.search_rounded,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeCard(
                        type: ReportType.FOUND,
                        label: 'Encontrado',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeCard(
                        type: ReportType.ABANDONED,
                        label: 'Em Risco',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _titleController,
                    maxLength: 120,
                    decoration: _inputDecoration(
                      'Título do reporte *',
                      icon: Icons.title,
                      hint: 'Ex: Cachorro vira-lata amarelo com coleira',
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.length < 3)
                        return 'Informe um título com pelo menos 3 caracteres';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 5000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      'Descrição detalhada *',
                      hint:
                          'Características do animal, comportamento, ponto de referência...',
                    ),
                    validator: (v) {
                      final d = (v ?? '').trim();
                      if (d.length < 3)
                        return 'A descrição deve ter pelo menos 3 caracteres';
                      return null;
                    },
                  ),

                  const Divider(height: 32),

                  // SEÇÃO DE LOCALIZAÇÃO (Como último item antes do botão)
                  const Text(
                    'Localização *',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  _buildMapPreview(),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          readOnly: true,
                          decoration: _inputDecoration(
                            'Latitude',
                            icon: Icons.location_on_outlined,
                          ),
                          validator: rule(
                            (v) => Validators.isValidCoordinate(v, 90),
                            pickMsg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          readOnly: true,
                          decoration: _inputDecoration(
                            'Longitude',
                            icon: Icons.map_outlined,
                          ),
                          validator: rule(
                            (v) => Validators.isValidCoordinate(v, 180),
                            pickMsg,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isLoading ? 'PUBLICANDO...' : 'PUBLICAR REPORTE',
                        style: const TextStyle(
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
      bottomNavigationBar: const NavbarComponent(currentIndex: 1),
    );
  }
}

class _MapLocationPicker extends StatefulWidget {
  final LatLng? selected;

  const _MapLocationPicker({this.selected});

  @override
  State<_MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<_MapLocationPicker> {
  final _mapController = MapController();
  bool _isLocating = false;

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await FosterService().getCurrentPosition();
      if (!mounted) return;
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
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
  Widget build(BuildContext context) {
    final initial = widget.selected ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Arraste o mapa até o local',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initial,
              initialZoom: widget.selected == null ? 13 : 16,
              onTap: (_, point) =>
                  _mapController.move(point, _mapController.camera.zoom),
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
              backgroundColor: Colors.white,
              foregroundColor: _orange,
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
                      Navigator.pop(context, _mapController.camera.center),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
