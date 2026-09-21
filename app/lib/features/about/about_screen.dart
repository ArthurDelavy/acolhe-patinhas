import 'package:flutter/material.dart';
import '../../components/navbar.dart'; // Mantenha o caminho original da sua NavbarComponent

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Paleta de cores solicitada
  static const Color primaryColor = Color(0xFFFFA94D);
  static const Color secondaryColor = Color(0xFFFF8C42);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho com ClipPath e Logo
            SizedBox(
              height:
                  320, // Altura total do cabeçalho incluindo a logo que "vaza"
              child: Stack(
                clipBehavior:
                    Clip.none, // Permite que a logo fique sobreposta à borda
                alignment: Alignment.topCenter,
                children: [
                  // Fundo curvo (ClipPath)
                  ClipPath(
                    clipper: HeaderCurveClipper(),
                    child: Container(
                      height: 260,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, secondaryColor],
                        ),
                      ),
                    ),
                  ),

                  // Título no topo
                  const Positioned(
                    top: 60,
                    child: Text(
                      'Associação Acolher',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // Logo circular centralizada
                  Positioned(
                    top: 170, // Posição calculada para ficar no meio da curva
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        // Caminho da sua imagem (gatinho e cachorrinho)
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtítulo (Cidade)
            const Center(
              child: Text(
                'Encantado, RS',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // Corpo da página
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção Sobre Mim
                  const Text(
                    'Sobre Nós',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'A Associação Acolher é um refúgio de esperança para animais em situação de abandono na cidade de Encantado, RS. Nossa missão é resgatar, cuidar e encontrar lares cheios de amor para cães e gatos que mais precisam.\n\nAcreditamos que cada vida importa e, com o apoio da nossa comunidade, transformamos dor e abandono em alegria, conforto e muito carinho. Venha fazer parte dessa corrente do bem!',
                    style: TextStyle(
                      fontSize: 16,
                      height:
                          1.6, // Espaçamento entre linhas para leitura confortável
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 35),

                  // Seção Contato
                  const Text(
                    'Contato',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Item de Telefone
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone, color: secondaryColor),
                    ),
                    title: const Text(
                      '(51) 9XXXX-XXXX',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Item de Instagram (Rede Social)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: secondaryColor,
                      ),
                    ),
                    title: const Text(
                      '@associacaoacolher',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ), // Espaço no final para não colar na Navbar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 7),
    );
  }
}

// CustomClipper para desenhar a curva arredondada no fundo do cabeçalho
class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Começa do topo esquerdo
    path.lineTo(0, size.height - 70);

    // Cria a curva suave até o lado direito
    path.quadraticBezierTo(
      size.width / 2,
      size.height +
          20, // Ponto de controle no centro (puxando a curva para baixo)
      size.width,
      size.height - 70,
    );

    // Vai até o topo direito e fecha o caminho
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
