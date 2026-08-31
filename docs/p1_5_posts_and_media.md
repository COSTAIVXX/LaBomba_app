# P1.5 — Posts e Mídia

## STATUS
P1.5 PARCIAL

## ESCOPO OFICIAL
O escopo oficial do checkpoint foi definido na documentação do roadmap social, em [docs/p1_social_mvp_architecture.md](./p1_social_mvp_architecture.md):
- `### P1.5`
- `Posts e mídia`

Portanto, este checkpoint deve cobrir apenas:
- criação de posts do usuário autenticado;
- metadados de mídia vinculados ao dono correto;
- persistência mínima em Firestore;
- ownership e segurança do usuário autenticado;
- estrutura reutilizável para futuras etapas do feed, comentários e interações.

Qualquer desenvolvimento fora desse escopo é extrapolação e foi evitado.

## AUDITORIA
Foi verificado:
- a arquitetura social já define `SocialPost` e `SocialMediaMetadata`;
- a base do P1.3 já incluía repositories, provider e Firestore rules para posts e mídia;
- `SocialProvider` já tinha operações de criação de post, mas sem reforço de ownership explícito no cliente;
- a coleção `media` ainda não tinha regra específica de segurança em Firestore;
- não havia documentação oficial específica para P1.5 antes desta execução;
- não existe UI de feed ou posting em tela neste checkpoint.

## PROBLEMAS ENCONTRADOS
### CRITICAL
- ausência de regra Firestore para `media/{mediaId}` com ownership explícito;
- criação de post com `authorId` arbitrário podia contornar a identidade autenticada no provider.

### HIGH
- sem documentação específica do checkpoint P1.5;
- sem testes de segurança para metadados de mídia.

### MEDIUM
- criação de post sem reforço de identidade no cliente em alguns caminhos de uso;
- risco de duplicação de escopo se o checkpoint fosse ampliado para feed ou comentários.

## IMPLEMENTAÇÕES
- reforço de ownership no `SocialProvider.createPost`;
- criação de `createCurrentPost` para operação segura com `FirebaseAuth.currentUser.uid`;
- criação de `createMediaMetadata` para persistir metadados de mídia do usuário autenticado;
- regra Firestore `match /media/{mediaId}` com ownership e `id == mediaId`;
- testes unitários de regra para criação de media e proteção de dono;
- documentação do checkpoint em `docs/p1_5_posts_and_media.md`.

## ARQUIVOS ALTERADOS
- [lib/features/social/social_provider.dart](../lib/features/social/social_provider.dart)
- [firestore.rules](../firestore.rules)
- [tests/social_firestore_rules.test.js](../tests/social_firestore_rules.test.js)
- [docs/p1_5_posts_and_media.md](./p1_5_posts_and_media.md)

## TESTES
Executados:
- `dart format .`
- `flutter analyze`
- `flutter test`
- `node --test tests/social_firestore_rules.test.js`
- `git diff --check`

## TESTES BLOQUEADOS
Nenhum.

## RISCOS RESIDUAIS
- o feed visual e as interações sociais avançadas continuam fora do escopo oficial do checkpoint;
- a UI de criação de posts ainda não foi implementada;
- regras de Firestore em produção exigem revisão em ambiente real do Firebase.

## FORA DO ESCOPO
- feed visual;
- comentários UI;
- likes UI;
- seguidores UI;
- notificações UI;
- chat;
- stories;
- grupos;
- busca social avançada;
- P2 e etapas futuras.

## PRÓXIMA ETAPA
A próxima etapa formal definida no roadmap é `P1.6` — Feed principal. Este checkpoint não a iniciou.
