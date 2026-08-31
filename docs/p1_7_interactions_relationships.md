# P1.7 — Interações e Relacionamentos

## STATUS
P1.7 PARCIAL

## ESCOPO OFICIAL
O escopo oficial do checkpoint foi definido no roadmap social em [docs/p1_social_mvp_architecture.md](./p1_social_mvp_architecture.md):
- `### P1.7`
- `Interações e relacionamentos`

Este checkpoint deve cobrir apenas:
- reações em posts;
- comentários em posts;
- relação de seguir;
- relação de bloquear;
- ownership e identidade autenticada;
- integridade mínima do relacionamento social;
- suporte de infraestrutura para notificações futuras sem abrir o escopo de P1.8.

Não inclui:
- feed visual completo;
- notificações UI;
- recomendação;
- chat;
- stories;
- grupos;
- features de P2.

## AUDITORIA
Foi verificado:
- o modelo social já contém `SocialComment`, `SocialReaction`, `SocialRelation` e `SocialNotification`;
- as operações de reação, comentário e relacionamento já existiam no `SocialProvider` como base de infraestrutura;
- faltava reforço explícito de identidade autenticada e documentação oficial do checkpoint;
- faltava validação mínima para ações inválidas, como auto-seguimento e auto-bloqueio;
- o roadmap oficial define P1.7 como a etapa de interações e relacionamentos, não como uma expansão para notificações ou UX sofisticada.

## PROBLEMAS ENCONTRADOS
### CRITICAL
- sem reforço claro de `FirebaseAuth.currentUser.uid` em operações de interação/relacionamento quando o usuário autenticado estava disponível;
- ausência de guardas mínimas para auto-relação.

### HIGH
- documentação específica do P1.7 inexistente;
- cobertura de testes insuficiente para ações inválidas de relacionamento.

### MEDIUM
- risco de expansão de escopo se o checkpoint fosse confundido com notificações ou feed avançado.

## IMPLEMENTAÇÕES
- reforço de identidade do usuário autenticado em `SocialProvider` para comentários, reações e relacionamentos;
- validação de campos vazios em comentários;
- bloqueio de auto-follow e auto-block;
- métodos auxiliares para a operação do usuário atual (`addCurrentComment`, `toggleCurrentReaction`, `followCurrentUser`, `blockCurrentUser`);
- testes mínimos para a regra de auto-relacionamento;
- documentação do checkpoint em `docs/p1_7_interactions_relationships.md`.

## ARQUIVOS ALTERADOS
- [lib/features/social/social_provider.dart](../lib/features/social/social_provider.dart)
- [test/social_infrastructure_test.dart](../test/social_infrastructure_test.dart)
- [docs/p1_7_interactions_relationships.md](./p1_7_interactions_relationships.md)

## SEGURANÇA
Controles aplicados:
- `FirebaseAuth.currentUser.uid` é usado como fonte de verdade quando o usuário está autenticado;
- ações com UID divergente geram `ArgumentError`;
- comentários vazios são rejeitados;
- auto-follow e auto-block são rejeitados;
- qualquer operação que dependa de auth continua restrita ao usuário autenticado na camada de provider.

Riscos residuais:
- a validação de regras de Firestore e Storage continua sendo a fronteira final no backend em ambiente Firebase real;
- material de UX e notificações continuam fora do escopo do checkpoint.

## TESTES
Executados:
- `dart format .`
- `flutter analyze`
- `flutter test`
- `git diff --check`

## BLOQUEIOS
Nenhum bloqueio operacional foi identificado para a execução local.

## RISCOS RESIDUAIS
- P1.8 continua sendo a próxima etapa oficial para notificações;
- qualquer refinamento de UX ou acessibilidade deve esperar o P1.9;
- o sistema de relacionamento não foi ampliado para regras complexas de privacidade ou recomendação.

## FORA DO ESCOPO
- notificações UI;
- feed algorítmico;
- chat;
- stories;
- grupos;
- marketplace;
- busca social avançada;
- recomendação;
- P2.

## PRÓXIMA ETAPA
A próxima etapa formal definida no roadmap continua sendo `P1.8` — Notificações, e não foi iniciada nesta execução.
