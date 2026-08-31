# P1.4 — Perfil e Identidade

## IMPLEMENTADO
- integração do `SocialProvider` com a identidade autenticada via `FirebaseAuth.instance.currentUser`;
- carregamento do `SocialProfile` do usuário autenticado usando `profiles/{uid}`;
- bootstrap determinístico de perfil quando ele ainda não existe;
- atualização do próprio perfil sem criar um segundo sistema de usuário;
- preservação de `id`, `createdAt` e contadores durante updates do perfil social;
- regras Firestore validadas para criação e atualização de perfil do próprio usuário;
- testes em Dart e Node cobrindo enumeração de perfil, ownership e regras críticas.

## ARQUITETURAL
A estrutura preserva o contrato mínimo:

FirebaseAuth
↓
SocialProvider
↓
SocialProfileRepository
↓
Firestore

O UID do Firebase Auth continua sendo a source of truth e a chave do documento social.

- `profiles/{uid}` é o documento canônico para dados sociais;
- `id` do perfil deve coincidir com `FirebaseAuth.currentUser.uid`;
- `createdAt` fica imutável após criação;
- `updatedAt` é renovado em cada update legítimo;
- `username`, `displayName`, `bio`, `avatarUrl` e `isPrivate` são campos do perfil social e não duplicam a autenticação.

## PENDENTE
- UI social do perfil;
- edição visual do perfil no app;
- feed, posts, follows e notificações em interface;
- busca social e recomendações;
- regras de bloqueio e privacidade avançadas em UX;
- qualquer feature de P2 ou fan-out completo.

## LIMITES DE ESCOPO
Esta etapa não implementa rede social completa nem cria um perfil independente da autenticação. O objetivo é apenas garantir que o `SocialProfile` represente corretamente a identidade autenticada e que a fundação social possa continuar para as próximas etapas sem duplicação de autoria.
