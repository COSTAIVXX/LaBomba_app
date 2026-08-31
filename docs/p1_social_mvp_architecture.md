# P1.2 — Definição do MVP Social e Arquitetura da LaBomba

## VISÃO DO PRODUTO
A LaBomba hoje é um produto de evento e experiência de marca, com aterrissagem em cadastro, administração e logística do evento. O passo seguinte do P1 não é transformar a app em uma rede social genérica. O objetivo é fazer a LaBomba evoluir para uma plataforma social leve, centrada na comunidade do evento e na relação entre pessoas que participam do ecossistema da marca.

A proposta de produto deve ser simples e coerente:
- o usuário tem identidade social clara;
- pode publicar conteúdo breve;
- pode interagir com o conteúdo de outras pessoas;
- pode descobrir pessoas e publicações relevantes;
- pode manter relação mínima de seguir e bloquear;
- recebe notificações essenciais;
- mantém uma experiência de app moderna e enxuta.

Essa visão respeita o que já existe no código: a LaBomba não é um hub de mídia genérica, mas uma plataforma social ligada ao evento, à comunidade e à marca.

## ESTADO ATUAL
O estado real do código confirma que o projeto continua sendo predominantemente um app de evento/carnaval:
- landing page e estrutura de marca;
- cadastro de clientes e gestão administrativa;
- configuração do evento e conteúdo institucional;
- autenticação e persistência local/segura;
- backend para evento/conteúdo e upload.

Não há, no código atual, implementação real de:
- feed social;
- posts;
- comentários e respostas;
- likes/reactions;
- perfil social completo;
- seguidores;
- chat;
- stories;
- grupos;
- notificações sociais;
- descoberta social coerente.

Portanto, a etapa P1.2 é de arquitetura e definição do MVP, e não de implementação funcional completa.

## MVP SOCIAL
O MVP deve conter apenas o conjunto capaz de sustentar uma experiência social real, sem inventar uma plataforma inteira.

### P0 — ESSENCIAL
1. Perfil do usuário
   - avatar
   - nome
   - username
   - bio
   - privacidade básica

2. Publicação de conteúdo
   - criar post
   - texto
   - imagem
   - visualização
   - exclusão
   - autoria

3. Feed principal
   - lista cronológica
   - refresh
   - paginação
   - loading
   - empty state
   - erro
   - retry

4. Interação mínima
   - reactions/likes
   - comentários simples
   - contadores consistentes

5. Relacionamentos mínimos
   - seguir
   - deixar de seguir
   - lista de seguidores e seguindo
   - bloqueio

6. Descoberta mínima
   - busca simples por usuários
   - busca simples por conteúdo

7. Notificações essenciais
   - like
   - comentário
   - novo seguidor

### P1 — IMPORTANTE
1. Comentários em múltiplos níveis
2. Respostas curtas
3. Melhorias na busca por hashtags, usuários e conteúdo
4. Melhorias de perfil e edição
5. Melhorias de privacy e visibilidade
6. Filtros no feed

### P2 — FUTURO
1. Chat em tempo real
2. Stories
3. Grupos
4. Mídia em vídeo sofisticada
5. Feed algorítmico avançado
6. DM em larga escala
7. Notificações complexas e noções de prioridade

## PRIORIDADE ESTRUTURAL
| Funcionalidade | Prioridade | Motivo | Dependências |
| --- | --- | --- | --- |
| Perfil | P0 | base da identidade social | auth + storage |
| Posts | P0 | conteúdo principal | profile + media |
| Feed | P0 | experiência principal | posts + pagination |
| Reactions | P0 | interação mínima | posts + notifications |
| Comentários | P0 | conversa básica | posts + reactions |
| Seguidores | P0 | relacionamento social mínimo | profile |
| Busca | P1 | descoberta | posts + users |
| Notificações | P1 | apoio ao engagement | posts + follows |
| Chat | P2 | não essencial para MVP | conversations/messages |
| Stories | P2 | não essencial para MVP | media + lifecycle |
| Grupos | P2 | não essencial para MVP | communities |

## MODELO DE DADOS
A arquitetura do domínio social deve ser simples e ter crescimento controlado.

### users
Finalidade: identidade do usuário.
Campos essenciais:
- uid
- displayName
- username
- avatarUrl
- bio
- createdAt
- updatedAt
- isPrivate
- isBlocked

Campos opcionais:
- coverUrl
- links externos
- location
- pronouns

Riscos:
- muitos campos redundantes
- duplicação de dados pessoais

Recomendação:
- guardar apenas dados mínimos necessários para a experiência social;
- manter a identidade ligada ao `uid` do Firebase/Auth.

### profiles
Finalidade: perfil público/privado do usuário.
Campos essenciais:
- uid
- username
- fullName
- avatarUrl
- bio
- followersCount
- followingCount
- postsCount
- isPrivate
- status

Estratégia:
- `profiles/{uid}` é o documento canônico;
- `users` pode ser usado para autenticação e dados sensíveis;
- `profiles` para leitura pública.

### posts
Finalidade: conteúdo social principal.
Campos essenciais:
- postId
- authorUid
- authorUsername
- authorAvatarUrl
- text
- mediaUrls
- createdAt
- updatedAt
- visibility
- deletedAt
- reactionSummary
- commentCount

Campos opcionais:
- location
- tags
- originalPostId

Estratégia:
- usar coleção `posts` com documentos por post;
- paginação por `createdAt` + `postId`;
- leitura por feed ordenado por recência.

### comments
Finalidade: conversa sobre posts.
Campos essenciais:
- commentId
- postId
- authorUid
- text
- createdAt
- updatedAt
- deletedAt

Estratégia:
- coleção `posts/{postId}/comments`;
- limitar comentários iniciais no feed e carregar sob demanda.

### reactions
Finalidade: interação curta e idempotente.
Campos essenciais:
- reactionId
- postId
- userUid
- type
- createdAt

Estratégia:
- usar documento único por par `(postId, userUid)` em subcoleção;
- manter contagem agregada em `posts` para evitar reads pesadas em feed.

### follows
Finalidade: relacionamento social.
Campos essenciais:
- followerUid
- followingUid
- createdAt
- status

Estratégia:
- documento único por par e um contador em perfil;
- evitar arrays de usuários gigantes; preferir conjuntos e contadores.

### blocks
Finalidade: isolamento de interações.
Campos essenciais:
- blockerUid
- blockedUid
- createdAt

Estratégia:
- documento por par;
- bloquear leitura e interações por regras de segurança e validação de backend.

### notifications
Finalidade: alertar sobre ações importantes.
Campos essenciais:
- notificationId
- receiverUid
- actorUid
- type
- entityId
- seen
- createdAt
- dedupeKey

Estratégia:
- manter deduplicação por `dedupeKey`;
- notificar somente eventos relevantes;
- limitar leitura por usuário e paginação por data.

## FIRESTORE
A arquitetura deve priorizar custo, ordem e escalabilidade.

### Padrões recomendados
- evitar arrays gigantes;
- evitar documentos com muitos campos de relacionamento;
- evitar contadores mutáveis sem controle de concorrência;
- usar subcoleções para comentários e mídia por entidade;
- usar paginação por limites e Cursor real.

### Coleções sugeridas
- `profiles`
- `posts`
- `posts/{postId}/comments`
- `posts/{postId}/reactions`
- `users/{uid}/notifications`
- `users/{uid}/follows`
- `users/{uid}/blocks`
- `media`

### Índices
- por `createdAt` em feed de posts;
- por `authorUid` em posts;
- por `postId` em comments;
- por `userUid` em reactions;
- por `receiverUid` e `seen` em notifications;
- por `followerUid` e `followingUid` em follows.

### Páginação
- use `createdAt` + `postId` como cursor;
- limite por página de 10–20 itens;
- cache local no cliente para melhoria de UX;
- respeitar as proteções do P0.9.

## BACKEND
As operações sociais devem ser tratadas com responsabilidade clara.

### Operações que devem ser realizadas no backend/Cloud Function
- likes/reactions com idempotência;
- follows e unfollows;
- bloqueios;
- criação e exclusão de posts; 
- contadores de likes, comentários e seguidores;
- notificações;
- deduplicação e mitigação de duplicidade;
- regras de visibilidade e privacidade.

### Operações que podem permanecer no cliente
- leitura de feed e perfil;
- renderização de UI;
- pré-visualização de mídia;
- preenchimento do formulário de post.

### Operações críticas para transação
- `follow`/`unfollow`
- `reaction toggle`
- `post delete`
- notificação deduplicada

### Idempotência
- usar `dedupeKey` para notificação;
- usar chave única no documento de reação;
- evitar múltiplas gravações para uma mesma ação por retrigger;
- preservar mecanismos de outbox e retry do P0.9.

## SEGURANÇA
A segurança deve ser parte da arquitetura, não um detalhe final.

### Regras de autorização por entidade
- posts: autor pode editar/excluir; usuário autenticado pode ler se público; usuários bloqueados não podem interagir;
- comments: autor pode editar/excluir; qualquer usuário autenticado pode comentar se não bloqueado;
- reactions: apenas o usuário autenticado pode alterar seu próprio reaction;
- follows: apenas o usuário autenticado pode seguir/deixar de seguir;
- blocks: apenas o usuário autenticado pode bloquear/desbloquear;
- notifications: o receptor deve ser o único que lê e marca como lida;

### Privacidade
- perfil privado deve ocultar conteúdo para usuários não autorizados;
- bloqueio deve impedir interação e leitura de conteúdo do usuário bloqueado;
- dados pessoais devem permanecer mínimos.

### LGPD
- coleta mínima;
- exclusão de dados pessoais quando necessário;
- sem logs com dados sensíveis;
- consentimento explícito para qualquer dado externo ao essencial.

## FLUTTER
Organização recomendada:
- `models/` — entidades do domínio social;
- `repositories/` — acesso a dados e modelagem de persistência;
- `services/` — infra, upload, observabilidade, auth;
- `providers/` — estado reativo do app;
- `features/` — módulos sociais por domínio (feed, profile, post, follow, notification);
- `widgets/` — componentes reutilizáveis e cards;
- `views/` — páginas e fluxos de usuário.

### Arquitetura recomendada
Estruturar em modulos de domínio em vez de criar funções espalhadas:
- `feed`
- `posts`
- `profile`
- `relations`
- `notifications`

Evitar monólito excessivo. O objetivo é evoluir incrementalmente sem duplicar responsabilidades.

## NAVEGAÇÃO
A navegação do MVP deve ser simples, clara e compatível com o app atual.

Estrutura recomendada para o MVP:
- Feed
- Explorar
- Criar
- Notificações
- Perfil

A estrutura pode ser adaptada para a app existente, mas a navegação deve ser coerente e não profunda.

## DESIGN SYSTEM
A primeira camada do design system social deve usar o que já existe e consolidar padrões.

### Elementos essenciais
- cores
- tipografia
- spacing
- radius
- buttons
- inputs
- cards
- avatar
- loading
- skeleton
- empty state
- error state
- post card

### Regra
Não reescrever tudo; reutilizar componentes existentes e consolidar repetição real.

## UX
Fluxos principais do MVP:

### Novo usuário
entrada -> autenticação -> perfil -> descoberta -> feed

### Usuário recorrente
feed -> interação -> perfil -> notificações

### Criar conteúdo
criar -> mídia -> preview -> publicar -> confirmação

### Interagir
post -> reaction/comentário -> atualização visual -> notificação

### Relacionamento
perfil -> seguir -> estado atualizado

Estados críticos:
- loading
- success
- error
- retry
- empty
- offline
- timeout
- duplicated action

## PERFORMANCE
Regras de performance da arquitetura:
- manter feed paginado e com cache local;
- limitar leitura em listas;
- evitar listeners permanentes desnecessários;
- manter o uso de mídia controlado;
- usar upload e thumbnail otimizados;
- reduzir rebuilds em listas longas;
- evitar contador inconsistente em feed.

## TESTES
Estratégia de testes no MVP:
- unit: regras de validação de usuário/post/like
- widget: feed, perfil, criação de post, estados vazios
- integration: fluxo de autenticação + post + comentário
- backend: regras e idempotência de reactions/follows
- security rules: privacidade, bloqueio e visibilidade

## RISCOS
- a app atual não possui a identidade social definida em dados;
- sem produto definido, a implementação corre o risco de criar uma rede social genérica e inadequada;
- a modelagem social precisa ser simples para evitar custo exagerado e consultas frágeis;
- a privacidade e os bloqueios devem ser considerados no início.

## DECISÕES DE PRODUTO NECESSÁRIAS
1. A LaBomba é um produto social ligado ao evento e à comunidade, não uma rede social genérica.
2. O MVP incluirá posts, perfil, feed, reactions, comentários, seguidores e notificações essenciais.
3. Chat, stories e grupos ficam fora do MVP inicial.
4. A busca e exploração serão limitadas ao que for essencial.
5. O produto deve priorizar comunidade e engajamento real sobre escala massiva de conteúdo.

## ROADMAP P1
### P1.2
Definição do MVP e arquitetura.

### P1.3
Modelagem e infraestrutura social.

### P1.4
Perfil e identidade.

### P1.5
Posts e mídia.

### P1.6
Feed principal.

### P1.7
Interações e relacionamentos.

### P1.8
Notificações.

### P1.9
Polimento UX, acessibilidade e performance.

## VALIDAÇÃO
As validações executadas no contexto atual foram:
- `flutter analyze`
- `flutter test test/widget_test.dart`

Essas validações provam estabilidade técnica do código atual, mas não validam o MVP social, que ainda está em definição arquitetural e não em implementação funcional.

## O QUE NÃO FOI ALTERADO
- produção;
- Firebase Console;
- dados reais;
- secrets;
- deploy;
- migrações destrutivas.
