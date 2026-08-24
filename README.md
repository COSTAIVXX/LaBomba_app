# La Bomba App

Aplicativo Flutter para a experiência da marca La Bomba.

## Visão geral

Este projeto foi criado com Flutter e está pronto para ser executado em ambiente local com o SDK do Flutter instalado corretamente.

## Pré-requisitos

- Flutter SDK instalado e configurado no PATH
- Android Studio ou VS Code com suporte a Flutter
- Emulador Android ou dispositivo físico conectado
- Git para versionamento

## Instalação

1. Clone o projeto
2. Acesse a pasta do projeto
3. Execute:
   ```bash
   flutter pub get
   ```

## Execução

Para rodar o app em modo de desenvolvimento:

```bash
flutter run
```

Para verificar se o projeto está sem erros:

```bash
flutter analyze
```

Para gerar um build de release Android:

```bash
flutter build apk
```

## Estrutura principal

- `lib/` — código principal da aplicação
- `test/` — testes automatizados
- `android/` — configuração nativa Android
- `ios/` — configuração nativa iOS
- `pubspec.yaml` — dependências e metadados do projeto

## Dicas

- Mantenha o ambiente Flutter atualizado
- Use emulador em modo debug para desenvolvimento
- Sempre execute `flutter pub get` após alterar dependências

## Documentação oficial

- [Flutter](https://docs.flutter.dev/)
- [Cookbook Flutter](https://docs.flutter.dev/cookbook)
- [Documentação de widgets](https://docs.flutter.dev/development/ui/widgets)

## Observações de execução

- Confirme que o Flutter SDK está instalado e atualizado antes de rodar o app.
- Execute `flutter pub get` sempre que houver alteração em dependências.
- Para validar o projeto sem executar a aplicação, use `flutter analyze`.
- Caso a estrutura de `lib/` ainda não tenha sido criada, siga a convenção padrão do Flutter para organizar widgets, páginas e serviços.
