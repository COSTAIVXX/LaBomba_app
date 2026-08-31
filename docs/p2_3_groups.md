# P2.3 — Grupos, comunidades e conversas em grupo

Status: P2.3 — validado

Gate: PASS

## Visão geral

Este checkpoint introduz a primeira camada segura de grupos e comunidades para o LaBomba, mantendo a arquitetura social já consolidada e evitando duplicação de sistemas de usuários ou autenticação. O escopo é deliberadamente pequeno: grupos com ownership explícito, papéis mínimos, banimento, membros e mensagens do grupo no mesmo padrão de observabilidade e proteção de identidade já usado no restante do app.

## Arquitetura

- `lib/features/social/social_domain.dart`
  - modelos de `SocialGroup`, `SocialGroupMember` e `SocialGroupMessage`;
  - papéis `owner`, `admin`, `moderator`, `member` e `banned`;
  - validação básica de nome e texto de mensagem.
- `lib/features/social/social_repositories.dart`
  - repositórios de grupo, membership e mensagens em memória e Firestore;
  - persistência em coleções separadas para grupos e subcoleções por grupo.
- `lib/features/social/social_provider.dart`
  - operações de criação, entrada, saída, banimento, envio de mensagens e listagem;
  - verificações de ownership e autorização;
  - integração com observabilidade e correlation IDs.
- `firestore.rules`
  - regras de acesso por coleta com `deny by default` e validações de pertencimento, banimento e ownership.

## Modelo de dados

### groups/{groupId}

- `id`
- `ownerId`
- `name`
- `description`
- `createdAt`
- `updatedAt`
- `isPrivate`
- `memberRoles` (mapa `userId -> role`)
- `bannedUserIds`

### groups/{groupId}/members/{userId}

- `groupId`
- `userId`
- `role`
- `joinedAt`
- `isBanned`

### groups/{groupId}/messages/{messageId}

- `id`
- `groupId`
- `senderId`
- `text`
- `createdAt`
- `updatedAt`
- `isDeleted`

## Ownership, papéis e autorização

A identidade canônica continua sendo `FirebaseAuth.currentUser.uid`. O cliente nunca é confiável para afirmar ownership ou role. A autorização é validada no provider e reforçada no `firestore.rules`.

- `owner`: pode criar, alterar propriedades do grupo, expulsar e banir membros e enviar mensagens.
- `admin` / `moderator`: podem gerir membros e moderar conversas.
- `member`: pode ler mensagens e enviar texto quando estiver ativo e não banido.
- `banned`: não pode participar nem ler a conversa do grupo.

Os dados são tratados como sensíveis e só acessíveis a membros autorizados do grupo, além do owner.

## Regras de segurança implementadas

- identificação do usuário autenticado como única origem de verdade;
- criação do grupo vinculada ao `ownerId` autenticado;
- entrada em grupos públicos apenas quando não banido e não duplicado;
- entrada em grupos privados bloqueada por regra de negócio para evitar ampliação indevida de acesso;
- banimento remove a associação de membership e registra o usuário como proibido;
- mensagens só podem ser publicadas por membros ativos e não banidos;
- `firestore.rules` reforçam a leitura e escrita por `memberRoles` e `bannedUserIds`.

## Limitações e riscos residuais

- sem convites e aprovação assíncrona para grupos privados, a criação de grupos privados permanece controlada por regras e por gestão manual;
- a implementação do P2.3 foca em grupos mínimos e observáveis, sem módulos avançados de moderação, mídia ou notificações de grupo;
- o sistema de mensagens do grupo reutiliza o mesmo padrão do chat direto, mas não introduz um segundo stack de mensagens;
- a escalabilidade pode ser aumentada em iterações futuras com paginação mais fina, índices extras e dashboards de uso.

## Testes e validação

A validação inclui:

- testes de serialização e regras para grupos e mensagens;
- verificação de criação permissiva do grupo pelo owner;
- verificação de negação para usuário não membro;
- checagem de sentinela para entradas duplicadas, banimentos e ações de moderation.

## Fora do escopo

- chat em tempo real multi-canal além do modelo de mensagens em grupo;
- stories, comunidade ampla, marketplace, IA ou recomendação;
- upload de mídia pesada em grupos;
- exclusão de grupos por qualquer membro sem owner;
- convites em larga escala sem necessidade para o MVP do P2.3.
