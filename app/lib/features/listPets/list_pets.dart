import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../services/pet_service.dart';
import '../register/register_pets.dart';
import '../listPets/edit_pet.dart';

class ListPetsScreen extends StatefulWidget {
  final bool isAdminMode;
  final int navIndex;

  const ListPetsScreen({
    super.key,
    this.isAdminMode = false,
    this.navIndex = 1, // Padrão: Ícone 2 da Navbar (Usuário)
  });

  @override
  State<ListPetsScreen> createState() => _ListPetsScreenState();
}

class _ListPetsScreenState extends State<ListPetsScreen> {
  static const Color primaryColor = Color(0xFFE27B1D);

  List<Map<String, dynamic>> _pets = [];
  bool _isLoadingPets = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoadingPets = true);

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
      _loadPets();
    }
  }

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

  // --- MODAL DE DETALHES DO PET (MODO USUÁRIO) ---
  void _showPetDetailsModal(Map<String, dynamic> pet, String heroTag) {
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
    final String description =
        pet['description']?.toString() ??
        pet['about']?.toString() ??
        'Este pet está à procura de um lar amoroso! Entre em contato para saber mais detalhes sobre o processo de adoção.';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem expandida com botão de fechar
                Stack(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
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
                        ],
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Sobre o pet:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                      const SizedBox(height: 24),
                      if (toAdoption)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Interesse registrado para $name!',
                                  ),
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
      },
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
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
      body: _isLoadingPets
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
                  childAspectRatio:
                      0.82, // Proporção ajustada para enriquecer a imagem
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
            _loadPets();
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

            // Informações Compactas no Card
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
