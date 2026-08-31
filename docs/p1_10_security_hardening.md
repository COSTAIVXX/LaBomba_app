# P1.10 — Security Hardening

## STATUS
P1.10 — validado

## OBJETIVO
Fortalecer a camada de autorização do LaBomba sob o princípio Zero Trust, com privilégio mínimo, controle de ownership e proteção de campos sensíveis em Firestore, sem abrir brechas de acesso ou criar sistemas paralelos de identidade.

## RT-001 — CONTROLE DE ACESSO BASEADO EM OWNERSHIP E VISIBILIDADE
A camada de regras foi reforçada para:
- negar por padrão (
  deny by default
);
- exigir ownership explícito para recursos privados;
- preservar visibilidade pública somente quando a política de produto e os dados estruturados permitirem;
- aplicar política de seguimento e visibilidade conforme os documentos sociais válidos;
- bloquear leitura por usuários bloqueados em qualquer direção quando a regra aplicável exigir isolamento.

Os principais fluxos cobertos foram:
- perfis (`profiles/{uid}`);
- posts (`posts/{postId}`);
- reações/interações (`reactions/{reactionId}`);
- stories (`stories/{storyId}`);
- grupos (`groups/{groupId}`) e mensagens (`groups/{groupId}/messages/{messageId}`);
- relações de bloqueio (`blocks/{docId}` e equivalentes usados pelo modelo social).

## RT-002 — PROTEÇÃO DE CAMPOS SENSÍVEIS
A regra de atualização foi ajustada para impedir mutações em campos protegidos do modelo, incluindo atributos de identificação e papel, sem bloquear mudanças legítimas em campos editáveis.

Campos protegidos validados no modelo existente:
- `ownerId`
- `authorId`
- `creatorId`
- `userId`
- `role`
- `permissions`
- `admin`
- `moderator`
- `senderId`
- `createdAt`

A implementação usa a autoridade do documento e do contexto autenticado em vez de confiar em valores enviados pelo cliente.

## RT-003 — ISOLAMENTO BIDIRECIONAL DE BLOQUEIO
A política de bloqueio foi consolidada em nível de regra para garantir isolamento bidirecional:
- um usuário bloqueado não pode acessar o perfil ou conteúdo do bloqueador em fluxos que requeiram privacidade;
- o isolamento foi aplicado em coleções relevantes sem ampliar o escopo funcional do produto;
- as regras foram validadas contra cenários de bypass por IDOR, spoofing de ownership e manipulação de documentos.

## FASE 2 — REGRESSION INVESTIGATION
Original result: 19/20

Failing test:
- `group message creation`

Root cause:
- A falha não era uma regressão permissiva de segurança do modelo de regras social.
- O problema real estava na validação de atualização protegida: `hasProtectedUpdate` executava `request.resource.data.diff(resource.data)` mesmo em operações de criação, quando `resource` é `null`, gerando erro de `Null value` e false negative no fluxo de mensagem de grupo.
- Também houve risco de contaminação de estado entre execuções do Firestore emulator porque o projeto em teste reaproveitava um ID constante em diferentes ambientes.

Pre-existing or regression:
- Regression do processo de validação e do helper de proteção de campos, e não uma falha de regra de autorização permissiva.
- O modelo de segurança zero-trust foi preservado; a correção foi para robustez do guard e isolamento do ambiente de teste.

Security impact:
- Nenhuma autorização permissiva foi introduzida ou mantida.
- O impacto principal foi bloqueio acidental de fluxo legítimo e falha de teste, não uma vulnerabilidade funcional de produção.

Fix:
- corrigir o helper de campos protegidos para tratar criação e atualização separadamente;
- isolar o ID do projeto do emulator por teste para evitar leakage de estado;
- revalidar que owner e membro autorizados continuam permitidos e não-membros continuam negados.

Tests added:
- validação de owner e membro autorizados criando mensagem de grupo;
- validação de não-membro negando escrita;
- validação de campos protegidos em updates;
- validação de bloqueio bidirecional para leitura de perfil e conteúdo.

Final result:
- `node --test tests/*.js` passed;
- `flutter test` passed;
- `flutter analyze` passed;
- `dart format .` passed;
- `git diff --check` passed.

Residual risk:
- A política de produção real exige revisão de IAM e Firebase Console em ambiente de implantação, mas não foi alterada neste trabalho.
- Qualquer expansão de modelo de grupos/roles ou promoção de privilégios deve continuar a ser validada por regras e testes específicos.

## ARQUITÉTICA E IMPLEMENTAÇÃO
A correção foi mantida na arquitetura existente do projeto:
- Flutter: `SocialProvider`, `SocialRepository`, camada social e regras de negócio em cliente para consistência operacional;
- Firestore: regras de segurança como boundary final da autorização;
- Firebase Auth: `FirebaseAuth.currentUser.uid` como identidade canônica, sem paralelo de usuários ou autenticação alternativa;
- testes: suite de regressão em JavaScript para Firestore rules e execução de validação em Flutter.

## TESTES E VALIDAÇÃO EXECUTADOS
- `node --test tests/*.js`
- `flutter test`
- `flutter analyze`
- `dart format .`
- `git diff --check`

## RISCOS RESIDUAIS
- O projeto continua dependente de manutenção correta de índices e regras em Firestore quando a base social crescer;
- qualquer futuro aumento de permissões ou papel de grupo deve ser revisado com Zero Trust;
- a produção real exige auditoria de IAM e ambiente, fora do escopo desta etapa.

## CONCLUSÃO
O hardening de P1.10 foi concluído com regras de segurança reforçadas, validação de regressão positiva e ausência de autorização permissiva. O sistema legítimo continua funcional, e os fluxos críticos de ownership, bloqueio e mutação de campos protegidos permaneceram protegidos.
