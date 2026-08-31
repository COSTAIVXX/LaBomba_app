# P1.8 — Notificações

## STATUS
P1.8 — CONCLUÍDA

## CHECKPOINT
O checkpoint oficial definido no roadmap em [docs/p1_social_mvp_architecture.md](./p1_social_mvp_architecture.md) é `P1.8 — Notificações`.

Este checkpoint cobre apenas:
- notificação de evento social essencial;
- ownership do destinatário;
- leitura/unread;
- idempotência mínima por chave determinística;
- suporte a `SocialNotification` no provider e no repository;
- regras de Firestore para leitura e atualização do próprio canal.

Fora do escopo do P1.8:
- FCM/UI de notificações completa;
- chat;
- stories;
- grupos;
- marketplace;
- recomendações;
- P2.

## AUDITORIA
Foi verificado:
- a infraestrutura social já continha `SocialNotification` e um repository de notificações;
- o `SocialProvider` já criava notificações de follow em nível mínimo;
- faltava reforço de ownership explícito para leitura e marcação como lida;
- faltava documentação oficial do P1.8;
- faltava uma estratégia de deduplicação mais clara para eventos repetidos.

## IMPLEMENTAÇÃO
Implementações efetivas:
- criação de `dedupeKey` em `SocialNotification` para suportar eventos determinísticos e repetidos;
- ajuste de `SocialNotification.buildNotificationId` para gerar identificadores estáveis com ou sem dedupe;
- criação de `createNotification` e `createCurrentNotification` no `SocialProvider`;
- reforço de ownership em `markNotificationRead` para garantir que somente o destinatário autenticado possa marcar as próprias notificações;
- `loadCurrentNotifications` e `markCurrentNotificationRead` para uso de identidade autenticada;
- reforço das regras Firestore em `notifications` para limitar leitura/alteração ao próprio usuário e impedir campos arbitrários.

## ARQUIVOS ALTERADOS
- [lib/features/social/social_domain.dart](../lib/features/social/social_domain.dart)
- [lib/features/social/social_provider.dart](../lib/features/social/social_provider.dart)
- [firestore.rules](../firestore.rules)
- [test/social_infrastructure_test.dart](../test/social_infrastructure_test.dart)
- [docs/p1_8_notifications.md](./p1_8_notifications.md)

## SEGURANÇA
Controles implementados:
- leitura restrita ao destinatário da notificação;
- atualização de leitura restrita ao dono da notificação;
- `id` e `recipientId` protegidos em regras do Firestore;
- campos sensíveis do cliente não podem ser alterados arbitrariamente;
- eventos podem manter uma chave determinística para evitar duplicação.

Riscos residuais:
- FCM real/Push ainda exige ambiente e configurações externas do Firebase Console;
- UX visual de notificações permanece fora do escopo do P1.8 e se enquadra em etapas futuras.

## TESTES
Executados com sucesso:
- `dart format .`
- `flutter analyze`
- `flutter test`
- `node --test tests/social_firestore_rules.test.js`
- `git diff --check`

## BLOQUEIOS
Nenhum bloqueio operacional local foi identificado.

## RISCOS RESIDUAIS
- push em produção depende do ambiente real do Firebase e de configuração externa;
- nenhuma notificação de comentário/reação foi convertida em UI, apenas em infraestrutura mínima de domínio/segurança.

## O QUE NÃO FOI ALTERADO
- sem deploy;
- sem alteração de dados reais;
- sem alteração de produção;
- sem bypass de segurança;
- sem criação de sistema paralelo de usuários;
- sem P2;
- sem antecipação indevida de P1.9.

## PRÓXIMA ETAPA
A próxima etapa oficial do roadmap continua sendo `P1.9 — Polimento UX, acessibilidade e performance`, sem ser iniciada nesta execução.
