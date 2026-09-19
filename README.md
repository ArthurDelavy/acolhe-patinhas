# 🐾 Acolhe Patinhas

> *Conectando animais em situação de vulnerabilidade a novos lares, apoio e conscientização sobre o bem-estar animal.*

---

## 📌 Sobre o Projeto

O **Acolhe Patinhas** é uma solução mobile desenvolvida para simplificar e fortalecer a ponte entre a Associação Acolher (Encantado/RS), protetores independentes e pessoas interessadas em adoção ou apoio animal.

O projeto une um aplicativo mobile moderno e acolhedor construído em **Flutter** a uma API REST robusta e segura em **Java / Spring Boot**, integrada ao **Supabase (PostgreSQL)** para persistência e armazenamento de arquivos.

---

## 🎯 Objetivos

* **Facilitar a busca:** Tornar a busca por pets para adoção rápida, intuitiva e acessível.
* **Dar visibilidade:** Divulgar animais em processo de recuperação e cuidados especiais.
* **Gestão simplificada:** Permitir que a organização e administradores cadastrem e atualizem informações de maneira centralizada.
* **Incentivar a adoção responsável:** Promover a conscientização sobre posse responsável e bem-estar animal.
* **Reporte de Animais:** Permite a denúncia de animais abandonados ou perdidos.

---

## ✨ Funcionalidades Principais

### 🔒 1. Autenticação e Segurança

* Cadastro de novos usuários e login com e-mail e senha.
* Validação de dados de entrada e verificação de e-mail.
* Recuperação de senha segura e controle de sessão via *Refresh Tokens*.
* Controle de acesso baseado em perfis e permissões (RBAC).

### 🐕 2. Feed e Visualização de Animais

* Listagem interativa com cards visuais contendo foto, nome, espécie, idade e status do pet.
* Navegação fluida para a tela de detalhes completos do animal.
* Visualização rápida de atributos essenciais para facilitar a tomada de decisão do adotante.

### 📋 3. Cadastro e Gestão de Animais

* Registro completo de pets: espécie, raça, cor, sexo, idade e traços comportamentais.
* Acompanhamento do status do animal (disponível, adotado, em tratamento).
* Gestão do histórico de saúde e prontuários.
* Padronização de referências no sistema (tabelas de espécies, raças, cores e motivos de alta).

### 👤 4. Perfil do Usuário

* Painel centralizado para gestão de dados da conta.
* Identificação clara do usuário autenticado.
* Estrutura preparada para histórico de adoções e ações de apoio futuro.

---

## 🛠️ Tech Stack

| Camada | Tecnologia | Descrição |
| --- | --- | --- |
| **Front-end Mobile** | Flutter / Dart | Interface nativa multiplataforma com Material Design |
| **Back-end API** | Java / Spring Boot | Framework robusto para regras de negócio e endpoints REST |
| **Segurança** | Spring Security / JWT | Autenticação stateless, criptografia e proteção de rotas |
| **Persistência** | Spring Data JPA / Hibernate | ORM para comunicação eficiente com o banco de dados |
| **Banco de Dados** | PostgreSQL | Banco relacional hospedado na nuvem via Supabase |
| **Armazenamento** | Supabase Storage | Bucket externo seguro para armazenamento de imagens dos pets |
| **Documentação** | OpenAPI / Swagger | Mapeamento e documentação interativa dos endpoints da API |
| **Comunicação** | JavaMail / SMTP | Serviço automatizado de envio de e-mails de validação e recuperação |

---

## 🎨 Design e Experiência do Usuário (UX)

A identidade visual foi projetada para transmitir **acolhimento, confiança e calor humano**:

* **Paleta Quente:** Uso de tons de laranja e amarelo suave para reforçar afeto e proximidade.
* **Hierarquia Limpa:** Tipografia legível, bom contraste e interface despoluída.
* **Destaque Visual:** Imagens de alta qualidade nos cards para criar conexão emocional imediata.
* **Navegação Intuitiva:** Telas organizadas em blocos de informação simples de escanear em dispositivos móveis.

---

## 🏗️ Arquitetura e Estrutura

O sistema adota uma **arquitetura desacoplada em duas camadas**, facilitando a manutenção e a escalabilidade independente de cada módulo:

```text
projeto/
├── app/                  # Aplicativo mobile em Flutter
│   ├── assets/           # Recursos estáticos (imagens, ícones, fontes)
│   ├── lib/              # Código-fonte (features, widgets, controllers, services)
│   └── pubspec.yaml      # Dependências e configurações do Flutter
│
├── api/                  # Back-end API REST em Spring Boot
│   ├── src/              # Controladores, serviços, repositórios e entidades
│   └── pom.xml           # Gerenciamento de dependências Maven
│
├── .gitignore
└── README.md

```

---

## 👤 Casos de Uso

1. **Criação e Acesso de Conta:** Usuários se cadastram e realizam login com segurança.
2. **Exploração de Pets:** Visitantes navegam pelo feed e examinam detalhes do animal de interesse.
3. **Gerenciamento por Admins:** Admins e usuários verificados cadastram animais, atualizam status de saúde e gerenciam fotos.
4. **Recuperação de Acesso:** Usuários redefinem senhas via e-mail em caso de esquecimento.

---

## 🚀 Benefícios Esperados

* **Maior Alcance:** Amplia a visibilidade de animais resgatados ou em situação vulnerável.
* **Aproximação Comunitária:** Reduz barreiras de comunicação entre a comunidade e as entidades protetoras.
* **Engajamento Social:** Cria um canal direto de informação, conscientização e apoio.
* **Eficiência Operacional:** Agiliza o controle de registros e o histórico dos pets abrigados.

---

## 📈 Status do Projeto

O projeto encontra-se em **desenvolvimento ativo**, com a infraestrutura principal de backend, modelo de dados, autenticação e telas base já consolidadas. As próximas etapas incluem o refinamento dos filtros de busca, inclusão do módulo de apadrinhamento/doações, reportes, feed social e notificações push.

---

## 🤝 Contribuição

O projeto é vetado de contribuições externas.

---

## 📄 Licença

Este projeto foi desenvolvido com fins acadêmicos e extensionistas. Para informações sobre reutilização de código ou distribuição, consulte a documentação e as diretrizes do repositório.
