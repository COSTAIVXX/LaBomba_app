# 🎭 LaBomba

### O carnaval do seu bloco, conectado.

Aplicativo mobile desenvolvido para criar uma experiência digital completa para comunidades de carnaval, conectando foliões, conteúdo, eventos e experiências do bloco em um único lugar.

**LaBomba é um produto da GDC Labs.**

---

## 🚀 Sobre o projeto

O **LaBomba** é uma aplicação mobile desenvolvida com **Flutter**, criada para oferecer uma experiência social voltada ao carnaval.

A proposta é aproximar o bloco de sua comunidade por meio de uma plataforma moderna, intuitiva e preparada para evoluir com novos recursos.

### Principais objetivos

* 🎭 Conectar foliões e comunidade
* 📸 Compartilhar conteúdos e momentos
* 🎉 Divulgar eventos e novidades
* ❤️ Criar interação entre usuários
* 📱 Oferecer uma experiência mobile moderna
* 🚀 Criar uma base tecnológica escalável para novos recursos

---

## 🏢 Ecossistema

**LaBomba** faz parte do ecossistema de produtos da:

### GDC Labs

> **Ideias que viram tecnologia.**

A GDC Labs é uma marca independente de tecnologia focada na criação de aplicações, sistemas e produtos digitais.

**Fundador:** Gustavo Dionisio Costa
**Área:** Desenvolvimento de Software & Produtos Digitais

---

## 🎨 Identidade

### Marca

**LaBomba**

### Slogan

> **O carnaval do seu bloco, conectado.**

### Assinatura

> **A product by GDC Labs**

A identidade visual do aplicativo utiliza uma linguagem vibrante e contemporânea, combinando elementos de carnaval, comunidade e tecnologia.

---

## 🛠️ Tecnologias

O projeto utiliza atualmente:

* **Flutter**
* **Dart**
* **Material Design**
* **Git / GitHub**

A arquitetura e as tecnologias podem evoluir conforme o produto crescer.

---

## 📋 Pré-requisitos

Antes de executar o projeto, certifique-se de possuir:

* Flutter SDK instalado
* Dart SDK configurado
* Android Studio ou VS Code
* Flutter/Dart extensions instaladas
* Android Emulator ou dispositivo físico
* Git instalado

Para verificar o ambiente:

```bash
flutter doctor
```

---

## 📥 Instalação

Clone o repositório:

```bash
git clone SEU_REPOSITORIO_AQUI
```

Entre na pasta:

```bash
cd labomba
```

Instale as dependências:

```bash
flutter pub get
```

---

## ▶️ Executando o projeto

Para executar em ambiente de desenvolvimento:

```bash
flutter run
```

Para verificar problemas de análise:

```bash
flutter analyze
```

Para executar os testes:

```bash
flutter test
```

---

## 📦 Build Android

Para gerar um APK de release:

```bash
flutter build apk --release
```

Para gerar um App Bundle para publicação na Google Play:

```bash
flutter build appbundle --release
```

---

## 🧱 Estrutura do projeto

A estrutura deve seguir uma organização simples e escalável:

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── feed/
│   ├── profile/
│   └── events/
│
├── services/
│
└── main.dart

assets/
├── images/
├── icons/
└── branding/

test/

android/

ios/

pubspec.yaml
```

A estrutura pode ser adaptada conforme novas funcionalidades forem implementadas.

---

## 🎨 Design System

O aplicativo deve seguir a identidade visual oficial do LaBomba.

### Direção

* Vibrante
* Jovem
* Social
* Festiva
* Simples
* Mobile-first
* Acessível

### Cores de referência

```text
Purple
Pink
Orange
Yellow
Teal
```

A paleta definitiva deve ser centralizada no tema do aplicativo para evitar cores espalhadas pelo código.

---

## 🧩 Princípios de desenvolvimento

O LaBomba deve priorizar:

### Simplicidade

Código fácil de entender e manter.

### Componentização

Widgets reutilizáveis sempre que fizer sentido.

### Organização

Separação clara entre interface, lógica e serviços.

### Escalabilidade

Estrutura preparada para novas funcionalidades.

### Segurança

Credenciais e informações sensíveis nunca devem ser armazenadas diretamente no código.

### Experiência

A tecnologia deve servir à experiência do usuário, e não o contrário.

---

## 🔐 Variáveis de ambiente

Informações sensíveis não devem ser versionadas no Git.

Exemplos:

```text
API_URL
API_KEY
DATABASE_URL
AUTH_SECRET
```

Utilize arquivos/configurações apropriados para o ambiente de desenvolvimento e produção.

**Nunca publique chaves privadas no GitHub.**

---

## 🌿 Git Workflow

Recomendação inicial:

```text
main
│
├── develop
│
└── feature/*
```

Exemplo:

```bash
git checkout -b feature/login
```

Após finalizar:

```bash
git add .
git commit -m "feat: implement login"
git push
```

### Convenção de commits

```text
feat: nova funcionalidade
fix: correção de problema
refactor: melhoria estrutural
style: alteração visual
docs: documentação
test: testes
chore: manutenção
```

---

## 🧪 Qualidade

Antes de considerar uma alteração pronta:

```bash
flutter analyze
```

```bash
flutter test
```

E, quando necessário:

```bash
flutter build apk --release
```

O objetivo é evitar que alterações simples quebrem funcionalidades existentes.

---

## 🗺️ Roadmap

### Fase 01 — Fundação

* [x] Configuração inicial do Flutter
* [ ] Design System
* [ ] Identidade visual
* [ ] Arquitetura inicial
* [ ] Navegação principal

### Fase 02 — Experiência

* [ ] Splash Screen
* [ ] Onboarding
* [ ] Login
* [ ] Cadastro
* [ ] Home
* [ ] Feed
* [ ] Perfil

### Fase 03 — Carnaval

* [ ] Eventos
* [ ] Programação
* [ ] Conteúdos do bloco
* [ ] Interações sociais
* [ ] Notificações

### Fase 04 — Produto

* [ ] Backend
* [ ] Autenticação
* [ ] Banco de dados
* [ ] Analytics
* [ ] Sistema de notificações
* [ ] Painel administrativo

### Fase 05 — Publicação

* [ ] Testes
* [ ] Preparação Android
* [ ] Google Play
* [ ] Preparação iOS
* [ ] App Store
* [ ] Monitoramento de produção

---

## 📱 Plataformas

| Plataforma | Status                |
| ---------- | --------------------- |
| Android    | 🚧 Em desenvolvimento |
| iOS        | 🚧 Em desenvolvimento |
| Web        | 🔮 Futuro             |
| Desktop    | 🔮 Futuro             |

---

## 📸 Screenshots

As capturas oficiais do aplicativo serão adicionadas conforme as telas forem finalizadas.

---

## 📚 Documentação

Documentação oficial do Flutter:

* https://docs.flutter.dev/
* https://docs.flutter.dev/cookbook/
* https://docs.flutter.dev/ui/

---

## 👨‍💻 Criador

### Gustavo Dionisio Costa

**Desenvolvedor de Software & Criador de Produtos Digitais**

Fundador da **GDC Labs**.

> Ideias que viram tecnologia.

---

## 🏢 GDC Labs

**LaBomba** é um produto desenvolvido pela **GDC Labs**.

**GDC Labs**
*Ideias que viram tecnologia.*

---

## 📄 Licença

Este projeto é propriedade de seus respectivos detentores de direitos.

A licença definitiva será definida conforme a estratégia de distribuição do produto.

---

### 🎭 LaBomba

**O carnaval do seu bloco, conectado.**

**A product by GDC Labs.**
