# P1.12 — Descoberta, Busca e Maturidade de Relações

## STATUS
P1.12 — validado

## OBJETIVO
Aprimorar a descoberta de perfis, a organização do feed e a maturidade das relações sociais do LaBomba sem ampliar o escopo para P2 ou criar sistemas paralelos de identidade, recomendação ou comunicação em tempo real.

## ARQUITETURA DE BUSCA E ÍNDICES
A solução foi mantida na arquitetura atual do projeto:
- Flutter client: `SocialProvider` e `SocialProfileRepository`/`SocialPostRepository` como camada de domínio e aplicação;
- Firestore: consultas de perfil e listagem de posts com ordenação por `createdAt` e filtros seguros no cliente;
- restrições de visibilidade e bloqueio mantidas na lógica da aplicação e no conjunto de regras do Firestore;
- sem criação de backend social novo ou de serviço de recomendação.

Para evitar custo excessivo de leitura:
- a busca de usuários foi limitada por `limit` e filtrada no repositório antes de exibir resultados;
- perfis bloqueados e privados são descartados antes de serem retornados ao cliente;
- o feed permanece paginado com cursor por última postagem e filtros aplicados localmente sobre o lote retornado.

## REGRA DE VISIBILIDADE E PRIVACIDADE
As regras implementadas respeitam o princípio da identidade canônica:
- `FirebaseAuth.currentUser.uid` continua sendo a única identidade de usuário;
- perfis bloqueados não aparecem em resultados de busca;
- perfis privados não são exibidos em descoberta para outros usuários que não sejam o dono do perfil;
- blocked users são excluídos de feeds de conteúdo e de resultados de busca quando o usuário autenticado estiver afetado pela relação;
- as ações de follow/block continuam restritas ao usuário autenticado e sem bypass de ownership.

## FILTROS DE FEED
O feed foi refinado com suporte a filtros de visão:
- `recent`: posts recentes em ordem cronológica decrescente;
- `following`: exibe o conteúdo dos usuários que o usuário autenticado segue;
- `mine`: exibe apenas os posts do usuário autenticado.

Componentes impactados:
- `lib/features/social/social_provider.dart`
- `lib/features/social/social_repositories.dart`

## RELAÇÕES E MATURIDADE
A maturidade de relações foi reforçada com:
- `followUser` verificando bloqueios existentes antes de criar a relação;
- `unfollowUser` removendo o vínculo de segmentação social;
- `blockUser` removendo follow mútuo e invalidando a visibilidade de relacionamento;
- `unblockUser` reativando a possibilidade de interação quando permitido pela política de uso;
- contadores de seguidores e seguindo atualizados no perfil quando a relação muda.

## RISCOS RESIDUAIS
- a descoberta ainda é restrita ao escopo de busca por perfil e feed, sem algoritmos de recomendação;
- a visibilidade de conteúdo privado em cenários de “seguindo” exige validação legal e de produto conforme a adoção real do app;
- o Firestore continua dependente de índices e regras bem mantidos para escalabilidade em produção;
- o requisito de recomendação e descoberta avançada permanece fora do escopo de P1.12.

## TESTES E VALIDAÇÃO
Os testes adicionados cobrem:
- busca segura de perfis sem bloqueados ou privados;
- filtros de feed em visão recente, mine e following;
- gestão de relações e contadores de perfil;
- prevenção de self-follow/self-block.

## LIMITE DE ESCOPO
Ficou fora do escopo desta etapa:
- P2;
- chat em tempo real;
- stories;
- grupos/comunidades;
- marketplace;
- IA, recomendação inteligente ou ranking avançado;
- redesign de UX global ou novo design system.
