# P1.6 — Feed Principal

## STATUS
P1.6 CONCLUÍDA

## ESCOPO OFICIAL
O escopo oficial do checkpoint foi definido no roadmap social em [docs/p1_social_mvp_architecture.md](./p1_social_mvp_architecture.md):
- `### P1.6`
- `Feed principal`

Este checkpoint é restrito ao feed principal da rede social, sem ampliar para comentários, reações, seguidores, notificações, chat, stories, grupos ou qualquer funcionalidade P2.

O objetivo foi manter a base mínima e reutilizável para:
- lista cronológica de posts;
- refresh;
- paginação;
- carregamento inicial;
- estado vazio;
- estado de erro;
- retry;
- integração com `SocialProvider` e `SocialPostRepository`.

## AUDITORIA
Foi verificado:
- o perfil social já existe e está integrado à identidade autenticada;
- a infraestrutura de posts e mídia foi estabelecida no P1.5;
- a próxima etapa oficial do roadmap é o feed principal;
- o feed não deve assumir comentários, likes ou notificações como requisitos do checkpoint.

O código foi auditado para evitar:
- UI social além do necessário;
- segunda identidade de usuário;
- regras de acesso que permitissem escrita cruzada;
- duplicação de repository/provider;
- expansão artificial para funcionalidades futuras.

## PROBLEMAS ENCONTRADOS
### CRITICAL
- nenhum. O feed foi implementado como infraestrutura mínima e não como produto social completo.

### HIGH
- a apresentação visual do feed depende de conteúdo real em Firestore e do feed real do usuário; o checkpoint não cria um sistema completo de ranking ou recomendação.

### MEDIUM
- o feed atual é um módulo de base, e não uma experiência social completa; isso é intencional e alinhado ao roadmap.

## IMPLEMENTAÇÕES
- criação de `SocialFeedPage` com estados de carregamento, erro, vazio e retry;
- integração com `SocialProvider` para carregamento inicial e paginação;
- suporte a refresh e infinite scroll controlado;
- paginação mínima com cursor; 
- continuidade clara entre listagem e carregamento incremental;
- documentação do checkpoint em `docs/p1_6_main_feed.md`.

## ARQUIVOS ALTERADOS
- [lib/features/social/social_provider.dart](../lib/features/social/social_provider.dart)
- [lib/features/social/social_feed_page.dart](../lib/features/social/social_feed_page.dart)
- [lib/main.dart](../lib/main.dart)
- [docs/p1_6_main_feed.md](./p1_6_main_feed.md)

## TESTES
Executados com sucesso:
- `dart format .`
- `flutter analyze`
- `flutter test`
- `node --test tests/social_firestore_rules.test.js`
- `git diff --check`

## TESTES BLOQUEADOS
Nenhum.

## RISCOS RESIDUAIS
- o feed ainda não implementa feed algorítmico, ranking, comentários em linha, busca social avançada ou recomendações;
- a experiência visual pode ser refinada em etapas futuras, mas isso fica fora do escopo do P1.6;
- qualquer item relacionado a comportamento de produção real depende do ambiente Firebase/Firestore real.

## FORA DO ESCOPO
- comentários UI;
- likes UI;
- seguidores UI;
- notificações UI;
- chat;
- stories;
- grupos;
- busca social avançada;
- recomendação ou ranking;
- P2 e etapas futuras.

## PRÓXIMA ETAPA
A próxima etapa formal do roadmap permanece fora desta execução. Este checkpoint não deve ser expandido para funcionalidade adicional sem nova definição explícita de escopo.
