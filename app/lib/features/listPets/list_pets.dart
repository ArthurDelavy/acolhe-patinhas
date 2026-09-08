import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../services/pet_service.dart';
import '../../utils/token_storage.dart';
import '../register/register_pets.dart';
import '../listPets/edit_pet.dart';

class ListPetsScreen extends StatefulWidget {
  const ListPetsScreen({super.key});

  @override
  State<ListPetsScreen> createState() => _ListPetsScreenState();
}

class _ListPetsScreenState extends State<ListPetsScreen> {
  static const Color primaryColor = Color(0xFFE27B1D);

  bool _isAdmin = false;
  bool _isLoadingPermission = true;

  List<Map<String, dynamic>> _pets = [];
  bool _isLoadingPets = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadPets();
  }

  Future<void> _checkPermission() async {
    final isAdmin = await TokenStorage.hasPermission('animal:create');

    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
      _isLoadingPermission = false;
    });
  }

  Future<void> _loadPets() async {
    setState(() => _isLoadingPets = true);

    try {
      final petsList = await PetService.fetchAnimals();
      if (!mounted) return;

      setState(() {
        _pets = petsList;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets Cadastrados'),
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
                    'Nenhum pet cadastrado ainda.',
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
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return _buildGridPetCard(pet);
                },
              ),
            ),
      floatingActionButton: !_isLoadingPermission
          ? FloatingActionButton.extended(
              onPressed: _isAdmin
                  ? _openRegisterPets
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Apenas administradores podem cadastrar pets.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
              backgroundColor: _isAdmin ? primaryColor : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: _isAdmin ? 3 : 1,
              icon: Icon(_isAdmin ? Icons.add : Icons.lock_outline, size: 18),
              label: Text(
                'Cadastrar Pet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white.withOpacity(_isAdmin ? 1.0 : 0.8),
                ),
              ),
            )
          : null,
      bottomNavigationBar: const NavbarComponent(currentIndex: 3),
    );
  }

  // <--- 2. CARD ENVOLVIDO COM INKWELL E NAVEGAÇÃO
  Widget _buildGridPetCard(Map<String, dynamic> pet) {
    final String name = pet['name']?.toString() ?? 'Sem Nome';
    final String imageUrl = _resolveImageUrl(pet) ?? '';
    final String genderChar = pet['gender']?.toString().toUpperCase() ?? 'M';
    final bool isMale = genderChar == 'M';
    final bool toAdoption = pet['toAdoption'] ?? false;
    final String breed = pet['breed']?.toString() ?? 'Não informada';
    final String color = pet['color']?.toString() ?? 'Não informada';
    final String ageText = _formatAge(pet['age']);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        // Redireciona para a tela de edição
        final bool? updatedOrDischarged = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditPetScreen(petData: pet, isAdmin: _isAdmin),
          ),
        );

        // Se alterou ou deu baixa, recarrega a lista
        if (updatedOrDischarged == true) {
          _loadPets();
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner da Foto
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
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

            // Informações do Pet
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nome + Gênero
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

                  const SizedBox(height: 3),
                  // Raça e Cor
                  Text(
                    '$breed • Cor: $color',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),
                  // Idade
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
