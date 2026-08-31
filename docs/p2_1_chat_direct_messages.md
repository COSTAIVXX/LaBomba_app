# P2.1 — Chat e Mensagens Diretas (DMs)

## STATUS
P2.1 — em implementação

## OBJETIVO
Adicionar suporte seguro e limitado a conversas diretas entre usuários autenticados do LaBomba, preservando a identidade canônica do Firebase Auth, as regras de bloqueio e a integridade social já consolidadas nos checkpoints anteriores.

## ARQUITETURA DE CONVERSAS E MENSAGENS
A implementação foi mantida na arquitetura social atual do projeto:
- Flutter client: `SocialProvider` centraliza as operações de DMs;
- modelos de domínio: `SocialConversation` e `SocialMessage` encapsulam conversas e mensagens;
- repositórios: `SocialConversationRepository` e `SocialMessageRepository` foram adicionados para suporte em memória e em Firestore;
- storage e regras de negócio: a visibilidade e a propriedade continuam sendo garantidas por `FirebaseAuth.currentUser.uid` e por regras do Firestore.

Para evitar duplicidade de thread, o identificador da conversa foi definido deterministically como:
- `dm:<uidMenor>:<uidMaior>`

Esse padrão evita que o mesmo par de usuários gere duas conversas distintas e mantém a expansão do escopo limitada a mensagens diretas de texto.

## SEGURANÇA E VALIDAÇÃO DE BLOQUEIOS
As regras de segurança seguem a política do projeto:
- apenas participantes da conversa podem ler mensagens;
- o `senderId` da mensagem deve ser exatamente o `request.auth.uid`;
- conversas só podem ser criadas quando os participantes forem distintos;
- bloqueios ativos impedem a criação de conversa e o envio de mensagem;
- a criação de mensagem exige texto obrigatório, sem vazios, com limite de 2000 caracteres.

A regra também mantém a identidade canônica da autenticação como única fonte de verdade, sem introduzir uma segunda identidade de usuário ou bypass de ownership.

## OBSERVABILIDADE
Com o padrão do P1.11, o envio de mensagens gera logs estruturados com `correlationId` e métricas de operação, sem registrar tokens, secrets, senhas ou dados pessoais desnecessários.

## LIMITAÇÕES E RISCOS RESIDUAIS
- a etapa foca em mensagens de texto e não cobre mídia pesada no chat;
- o mecanismo de leitura/escuta em tempo real foi implementado com streams de Firestore e deve ser validado em volume real;
- o sistema de moderação automática e IA permanece fora do escopo;
- conversas em grupo, stories, voz e vídeo continuam fora do escopo de P2.1.

## TESTES E VALIDAÇÃO
Os testes reforçam:
- criação segura de conversa;
- leitura restrita a participantes;
- bloqueio de criação de mensagem quando há `block` ativo;
- proteção de regras do Firestore para DMs.

## FORA DO ESCOPO
Ficou fora do escopo desta etapa:
- P2.2 (Stories);
- P2.3 (Grupos);
- chamadas de voz/vídeo;
- envio de arquivos pesados;
- IA, moderação automatizada e recomendação avançada.
