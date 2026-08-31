# P1 — Produto Social e Experiência Principal

Status: in_progress

## Objetivo
A etapa P1 deve transformar a base técnica já estabilizada em uma experiência social principal coerente. A auditoria obrigatória mostrou que o código atual ainda não implementa o produto social real. Portanto, esta documentação registra o estado real e não declara conclusão do estágio.

## Inventário do produto

### EXISTENTE
- app de evento/landing page com identidade visual da marca;
- cadastro de cliente com validação e persistência local;
- painel administrativo para gestão de clientes e eventos;
- serviços de autenticação, observabilidade e armazenamento por plataforma;
- backend Node/Express com rotas públicas e privadas para evento, conteúdo e mídia.

### PARCIAL
- integração Firebase/Google Sign-In foi estabilizada em bootstrap, mas não representa social product;
- `EventConfigProvider` e a UI de evento existem e respondem a dados configuráveis;
- a base para perfil de usuário e autenticação existe parcialmente, mas não há fluxo de rede social real.

### AUSENTE
- feed social com posts, autor, avatar, reação, comentários, paginação e refresh;
- criação, edição e exclusão de posts
- comentários e respostas;
- perfil social completo com username, bio, seguidores, seguindo e posts;
- relações sociais (seguir, bloquear, privacidade);
- notificações sociais;
- chat em tempo real;
- stories;
- grupos;
- busca e exploração social;
- experiência de navegação social principal com feed, explorar, criar, notificações, chat e perfil.

### QUEBRADO
- nenhum módulo social coerente foi identificado no código;
- a documentação e os relatórios anteriores não refletem esse fato e não devem ser tratados como conclusão do estágio.

### FORA DE ESCOPO
- criação de funcionalidades sociais inventadas sem a arquitetura real do produto;
- remodelagem completa do aplicativo para um produto social inexistente;
- qualquer mudança destrutiva em P0.9 ou infraestrutura de produção.

## Auditoria e evidência técnica
O códigobase atual é predominantemente um app de evento/carnaval, e não uma plataforma social.

Arquivos e estruturas constatadas:
- `lib/views/landing_page.dart` — página principal de evento/landing page;
- `lib/views/client_registration_page.dart` — cadastro de cliente do evento;
- `lib/views/admin/*` — administração de clientes e dashboard;
- `lib/providers/client_provider.dart` — persistência local de clientes e compras;
- `lib/providers/event_config_provider.dart` — configuração do evento e dados públicos;
- `lib/services/auth_service.dart` — autenticação e persisting de sessão;
- `lib/services/api_service.dart` — integração de backend para evento/conteúdo;
- `lib/models/client.dart` — modelo de cliente e compras.

Não foram localizados módulos de:
- feed
- posts
- comentários
- likes/reactions
- perfil social
- seguidores
- chat
- stories
- grupos
- notificações sociais.

O que existe em código, portanto, é a base de um produto de evento e admissão, não um feed social principal.

## Correções realizadas e preservadas
- correções técnicas de bootstrap e compatibilidade de armazenamento foram mantidas;
- não foram inseridas abstrações sociais artificiais;
- a base de estabilidade do P0.9 foi preservada sem reescrever mecanismo de resiliência.

## Status do P1
Resultado real do estágio: parcial.

O estágio P1 ainda não pode ser declarado concluído porque a auditoria do produto social principal não foi executada com implementação correspondente. O repositório em estado atual não contém a funcionalidade social mínima exigida no escopo do P1.

## Testes executados
- `flutter analyze` — resultado: sem issues
- `flutter test test/widget_test.dart` — resultado: `All tests passed`

Esses testes validam a estabilidade técnica e o boot do app, mas não validam a experiência social principal, que ainda não existe.

## Próximos passos reais
1. confirmar o produto social desejado em arquitetura e dados;
2. definir a estrutura mínima de feed, post, perfil e relação;
3. implementar apenas o conjunto social que realmente cabe no projeto;
4. manter as garantias de P0.9 durante a evolução.

## Observações finais
- não foi iniciada a fase P2;
- não foi declarada conclusão falsa de P1;
- os dados reais, produção e infraestrutura externa não foram alterados.
