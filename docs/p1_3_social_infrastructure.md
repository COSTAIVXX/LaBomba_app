# P1.3 — Modelagem e Infraestrutura Social da LaBomba

## STATUS
A fundação social foi implementada como infraestrutura mínima, reutilizável e segura para sustentar o MVP do produto sem criar UI ou feed completos. O que foi validado neste checkpoint foi a base de domínio, persistência em Firestore, regras de segurança, storage e testes em emulator.

## IMPLEMENTADO
- domínio social estável para perfil, post, comentário, reação, relação, notificação e metadados de mídia;
- repositories em memória e Firebase concretos para os contratos sociais;
- provider com injeção de dependências e integração mínima com autenticação atual;
- regras Firestore e Storage reais;
- índices mínimos para feeds, comentários, relações e notificações;
- testes de regra executados em emulator;
- documentação declarando os limites da etapa sem premissas de UI ou feed completos.

## ARQUITETURA E LIMITE DE ESCOPO
O que continua fora do escopo desta etapa:
- feed visual;
- perfil em tela;
- criação visual de posts;
- feed completo e UX social;
- stories, chat e grupos;
- fan-out avançado e notificações complexas.

A próxima etapa real é P1.4 — Perfil e Identidade, que deve integrar o usuário autenticado com `SocialProfile` sem duplicar identidade nem inventar uma segunda base de perfil.

## MODELS
Foram introduzidos modelos mínimos para sustentar o MVP:
- `SocialProfile`
- `SocialPost`
- `SocialComment`
- `SocialReaction`
- `SocialRelation`
- `SocialNotification`
- `SocialMediaMetadata`

Esses modelos foram desenhados para suportar:
- identidade social;
- conteúdo do usuário;
- relações de follow/block;
- comentários e interações;
- notificações essenciais;
- metadados de mídia.

Todos os modelos possuem serialização e desserialização estáveis, timestamps em ISO 8601 e compatibilidade com Firestore.

## COLEÇÕES
A estrutura foi implementada em domínio, repositórios e regras de segurança:
- `profiles/{uid}`
- `posts/{postId}`
- `posts/{postId}/comments/{commentId}`
- `posts/{postId}/reactions/{reactionId}`
- `users/{uid}/notifications/{notificationId}`
- `relations/{relationId}`
- `media/{mediaId}`

## RELACIONAMENTOS
A modelagem prioriza evitar arrays gigantes e estruturas sem controle.

- `follow` e `block` foram representados por relacionamento único e determinístico;
- `posts` mantêm contadores e dados de domínio essenciais;
- `notifications` foram separadas por destinatário para suportar leitura e paginação real;
- `SocialProvider` mantém a lógica reativa sem acoplar UI ao backend.

## IDS
Identificadores determinísticos foram padronizados para melhorar idempotência:
- `SocialReaction.buildReactionId(postId, userId)`
- `SocialRelation.buildRelationId(sourceId, targetId, kind)`
- `SocialNotification.buildNotificationId(recipientId, actorId, entityId, type)`

Essa estratégia reduz risco de duplicidade em ações sociais críticas.

## PAGINAÇÃO
A infraestrutura foi desenhada para respeitar a realidade do Firestore:
- feed e notificações com limite explícito;
- paginação por `createdAt` e documento final;
- listas vazias, início e fim de coleção contemplados pelo design do repositório;
- ordenação por recência e idempotência de consultas.

## CONTADORES
Os contadores mantidos em `SocialPost` (`reactionCount` e `commentCount`) foram preservados como estado derivado. O modelo permite modernização de contadores atômicos em transação futura, mas a camada atual continua sendo mínima e segura.

## IDEMPOTÊNCIA
A estrutura de reação, relação e notificação foi desenhada com suporte a deduplicação:
- `reactionId` determinístico por `postId + userId`;
- `relationId` determinístico por `sourceId + targetId + kind`;
- `notificationId` determinístico por `recipientId + actorId + entityId + type`.

## FIRESTORE RULES
As regras reais de Firebase foram adicionadas e validadas em emulator.

O que elas garantem:
- autenticação obrigatória para escrever;
- ownership em perfil, posts, comentários, reações e notificações;
- usuários não podem editar ou excluir conteúdo de terceiros;
- reações e follows são escritos no contexto do usuário autenticado;
- leitura de perfil e notifications respeita as regras de acesso e donos.

Essas regras foram validadas em `node --test tests/social_firestore_rules.test.js` com os emuladores ativos.

## ÍNDICES
Índices reais foram adicionados em `firestore.indexes.json` para suportar os acessos mínimos do MVP:
- feed por `createdAt`;
- comentários por `postId`;
- notificações por `recipientId`;
- relações por `sourceId` e `targetId`;
- busca e listagem de objetos do mesmo usuário.

## STORAGE
A infraestrutura de mídia foi mantida no nível de metadados e path de referência, sem armazenar binários no Firestore.

- `SocialMediaMetadata` guarda apenas metadados mínimos;
- Storage tem regras limitadas ao usuário autenticado;
- ownership e path são controlados pelo uid do usuário;
- não existe upload fictício de UI nem real persistência de mídia sem consumidor concreto.

## BACKEND
A arquitetura separa domínio e infraestrutura. As entidades foram colocadas em repositories e provider para permitir evolução sem acoplamento direto à UI:
- `ProfileRepository`
- `PostRepository`
- `CommentRepository`
- `ReactionRepository`
- `RelationRepository`
- `NotificationRepository`
- `MediaRepository`

## PROVIDERS
Foi criado `SocialProvider` como camada reativa e testável para:
- carregar feed;
- criar perfis;
- criar posts;
- adicionar comentários;
- alternar reactions;
- seguir e bloquear usuários;
- carregar e marcar notificações como lidas;
- integrar a autenticação atual ao perfil social sem criar nova identidade paralela.

## REPOSITORIES
As implementações em memória e Firebase deixam a base pronta para testes, desenvolvimento incremental e futura integração real no app.

## BLOQUEIO
O bloqueio foi modelado como relação de tipo `block`, com referência explícita ao usuário bloqueado. A arquitetura está preparada para aplicar a regra em feed, comentários, interações e notificações, sem implementá-la ainda em UI.

## PRIVACIDADE
A estrutura do `SocialProfile` inclui `isPrivate` e `isBlocked`, preservando o caminho para conteúdo privado e interação restrita sem congelar o modelo em uma configuração pública rígida.

## LGPD
A infraestrutura mantém coleta mínima e não introduz novos dados pessoais além do necessário para identidade e publicação social.

## OBSERVABILIDADE
A base foi preparada para logs de operações críticas sem expor tokens, secrets ou informação sensível.

## TESTES
Foram adicionados testes de infraestrutura de domínio e provider para validar:
- serialização de profile;
- desserialização de profile;
- geração de ids determinísticos;
- estabilidade de igualdade e estrutura;
- casos vazios e JSON parcial;
- provider com criação de post, comentário e relações.

Além disso, regras Firestore foram validadas em emulator com testes explícitos de allow/deny.

## RISCOS
- a app ainda não possui UX social completa;
- integração de perfil visual no app precisa ser feita em P1.4 sem duplicar identidade;
- contadores e fan-out avançado continuam sendo camada mínima e podem exigir transações reais no futuro;
- regras de produção precisam ser reaprovadas no ambiente Firebase real.

## DECISÕES
- a LaBomba é tratada como plataforma social leve e ligada à comunidade do evento;
- chat, stories e grupos ficam fora do MVP inicial;
- a infraestrutura prioriza segurança, idempotência e escalabilidade sobre quantidade de features;
- a estratégia local em memória foi usada apenas como base de infraestrutura e teste.

## O QUE NÃO FOI ALTERADO
- produção;
- Firebase Console;
- dados reais;
- secrets;
- deploy;
- migrações destrutivas.
