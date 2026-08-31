# P1.11 — Runbook de Resposta a Incidentes

## STATUS
P1.11 — runbook operacional documentado

## SEVERIDADE

### SEV-1
Impacto crítico / possível exposição de dados / indisponibilidade grave.

### SEV-2
Impacto significativo, mas limitado.

### SEV-3
Problema operacional controlado.

### SEV-4
Problema menor ou observação.

## PROCEDIMENTO
1. Detectar
   - confirmar evento, log, erro de Firebase/GCP ou falha funcional;
   - identificar correlação, operação e componente.

2. Confirmar
   - verificar se a falha é reproduzível;
   - confirmar impacto e alcance;
   - validar se há exposição de dados ou falha de autorização.

3. Classificar
   - atribuir severidade com base no impacto e no risco operacional;
   - decidir se o incidente depende de ação de produção externa.

4. Contém
   - bloquear acesso indevido se necessário;
   - proteger regras e dados sensíveis;
   - preservar evidência relevante sem apagar logs antes da investigação.

5. Investigar
   - confirmar correlação e contexto da operação;
   - verificar ownership, auth, block/privacy e regras de Firestore;
   - revisar payload sensível e confirmar redaction.

6. Mitigar
   - aplicar correção segura e mínima;
   - evitar rollback permissivo sem análise de risco;
   - priorizar contenção antes de expansão funcional.

7. Recuperar
   - restaurar serviço ou configuração ao estado seguro;
   - validar que os fluxos legítimos foram retomados sem quebra de segurança.

8. Validar
   - executar testes e regressões relevantes;
   - confirmar que logs e métricas continuam sanitizados.

9. Documentar
   - registrar causa, impacto, decisão, correlação e ação;
   - manter evidência para análise futura.

10. Postmortem
   - quando houver impacto significativo ou falha repetida;
   - registrar risco residual e ações corretivas.

## INCIDENTES DE SEGURANÇA
Incidentes que exigem resposta imediata:
- exposição indevida de Firestore;
- Storage público indevido;
- alteração indevida de ownership;
- bypass de regra;
- vazamento de conteúdo privado;
- comprometimento de credencial;
- comportamento anormal de autenticação;
- abuso de operações sociais.

Em incidente de segurança:
- primeiro conter;
- depois investigar;
- preservar evidência;
- não diminuir regras para restaurar funcionalidade sem análise de risco.

## ROLLBACK
Procedimento seguro para rollback:
- aplicação local: revert de commit ou patch com validação em ambiente de teste;
- Firestore Rules: aplicar rollback com revisão de impacto de autorização;
- Storage Rules: validar exposição e acesso antes de publicar;
- alertas: remover ou ajustar regras somente após confirmar o impacto real;
- infraestrutura: exigir autorização e documentação operacional externa.

Rollback de regras de segurança deve ser tratado como atividade crítica, e não como solução de conveniência para restaurar funcionalidade sem análise.

## RETENÇÃO E GOVERNANÇA
- logs e métricas devem manter apenas o mínimo necessário para diagnósticos e resposta a incidentes;
- dados privados, tokens, senhas, cookies e credenciais não devem entrar em logs operacionais;
- retenção e eliminação de evidência devem ser confirmadas pela governança do ambiente de produção;
- qualquer aplicação de retenção específica depende de processo operacional externo.

## IAM / LEAST PRIVILEGE
Checklist operacional:
- confirmar service accounts mínimos;
- verificar roles do Firebase e GCP;
- revisar CI/CD credentials e segredos;
- confirmar ausência de privilégios administrativos excessivos;
- manter as operações de produção fora do código do repositório.

## RESPOSTA A INCIDENTES POR DOMÍNIO
### Autenticação
- validar token, `FirebaseAuth.currentUser.uid` e claims;
- revisar se houve falha de auth ou abuso;
- confirmar correlação e logging do evento.

### Firestore / Regras
- verificar ownership, follower/public visibility e block/privacy;
- confirmar que a falha não expôs dados ou permitiu modificação indevida.

### Storage
- confirmar regras de acesso e arquivos públicos;
- identificar se houve upload indevido ou leitura sem autorização.

### Social / Operações críticas
- revisar posts, follows, blocks, reações, notificações e feed;
- confirmar que a operação não gerou duplicidade, vazamento ou falha em observabilidade.

## EVIDÊNCIAS DE VALIDAÇÃO
- `flutter analyze` passou;
- `flutter test` passou;
- `node --test tests/*.js` passou;
- `git diff --check` passou.

## DEPENDÊNCIAS EXTERNAS
- alertas e dashboards do Firebase/GCP;
- IAM e permissões de ambiente de produção;
- retenção e políticas de logs do ambiente para produção;
- ação manual de operação e governança em ambiente real.

## COMUNICAÇÃO
A comunicação de incidentes deve ser clara, com:
- resumo do impacto;
- correlação relevante;
- status de contenção;
- próximos passos;
- responsável pela ação;
- tempo esperado para recuperação.

## CONCLUSÃO
Este runbook define a resposta mínima segura para incidentes em produção, mantendo o princípio Zero Trust, o mínimo necessário de observabilidade e a proteção de privacidade sem inventar infraestrutura inexistente no repositório.
