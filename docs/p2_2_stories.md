# P2.2 — Stories

Status: P2.2 — em implementação

## Arquitetura

O módulo de Stories reutiliza a mesma arquitetura do restante do social LaBomba:

- `lib/features/social/social_domain.dart`: modelos de domínio e validações.
- `lib/features/social/social_repositories.dart`: contratos e implementações de repositório.
- `lib/features/social/social_provider.dart`: orquestração da lógica de negócios, visibilidade e observabilidade.
- `lib/features/social/social_story_page.dart`: superfície mínima da UI para publicar e visualizar stories.
- `firestore.rules`: camada final de segurança e autorização.

A identidade canônica permanece `FirebaseAuth.currentUser.uid`.

## Modelo de dados

`SocialStory` inclui:

- `storyId`
- `ownerId`
- `contentType` (`text`, `image`, `video`)
- `createdAt`
- `expiresAt`
- `text` ou `mediaUrl`
- `visibility` (`public`, `followersOnly`, `private`)
- `status` (`created`, `active`, `expired`, `deleted`)

O identificador do story é determinístico para o proprietário e timestamp, e a expiração é tratada como regra de negócio lógica e não apenas como remoção física.

## Lifecycle

- `created`: story recém-criado.
- `active`: story visível quando ainda válido.
- `expired`: expiração explícita para preservação de auditoria.
- `deleted`: exclusão do proprietário.

O sistema considera `expiresAt` como critério de expiração e esconde histórias expiradas dos fluxos ativos.

## Política de acesso

- proprietário pode ler e excluir seu próprio story;
- stories públicos são visíveis para usuários autenticados;
- stories `followersOnly` exigem relacionamento de follow do visualizador para o dono;
- stories `private` são restritos ao dono;
- bloqueios de usuários continuam sendo respeitados;
- a leitura e a gravação não dependem de dados enviados do cliente como fonte de verdade.

## Regras do Firestore

O `stories/{storyId}` foi adicionando com controles de:

- autenticação obrigatória;
- ownership do story;
- validação de campos críticos;
- restrição de campos mutáveis;
- bloqueios e privacidade;
- expiração e lifecycle.

## Regras de Storage

Como a implementação atual evita um sistema novo de upload paralelo, os stories usam conteúdo textual simples e URLs do fluxo já existente; assim, não foi necessário introduzir um novo storage path de stories. Se houver evolução para mídia pesada, a política deve ser construída sobre o path padronizado de usuários e exigir ownership e validação de MIME/size.

## Threat model

- IDOR: mitigado pela regra de leitura do Firestore e pelo controle de owner.
- impersonation: evitado com `request.auth.uid` como principal de escrita.
- unauthorized write: bloqueado por `ownerId == request.auth.uid`.
- expiration bypass: tratado por `isExpired` e `status` não apenas por remissão de documento.
- payload abuse: validado por texto e limites de tamanho.

## Estratégia de performance

- listagem limitada por `limit` no provider/repository;
- stories expirados não são exibidos;
- filtros de visibilidade e bloqueio são aplicados antes de renderizar; 
- sem listeners globais ou consultas ilimitadas.

## Estratégia de testes

- testes de serialização e expiração em `test/social_infrastructure_test.dart`;
- validação de regras em `tests/social_firestore_rules.test.js`.

## Limitações conhecidas

- Stories são um primeiro subsistema leve, sem upload nativo de mídia pesada;
- sem fila de limpeza assíncrona nem jobs de expiração automática;
- visibilidade é coerente com o modelo social atual, mas não introduz uma nova rede de dependências complexas.

## Riscos residuais

- necessidade de definir política operacional de retenção mais rígida para mídia;
- crescimento do volume de stories exigirá indexação e limites por usuário;
- se stories com mídia forem adicionados em escala, será necessário reavaliar custo de Storage e Firestore.

## Evoluções futuras possíveis

- upload de mídia com validade/thumbnail;
- marcação de story visualizado por usuário;
- stories com segmentação por grupo de seguidores ou seleções;
- limpeza automática em agentes de backend quando a infraestrutura existir.
