# Changelog

Todas as mudanças notáveis deste projeto são documentadas aqui.

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [0.0.8-alpha] - 2026-08-29

### Fixed
- `supabase/migrations/004_fix_folder_rls_recursion.sql`: `folders` e
  `folder_members` se consultavam mutuamente dentro das próprias políticas
  de RLS, causando "infinite recursion detected in policy" (42P17) assim
  que uma pasta compartilhada entrava em jogo. Resolvido com funções
  `SECURITY DEFINER` que rompem o ciclo.

## [0.0.7-alpha] - 2026-08-29

### Fixed
- Cadastro não dava nenhum feedback quando o projeto Supabase exige
  confirmação de e-mail (padrão de fábrica): `signUp()` tem sucesso mas
  não retorna sessão, então o `AuthGate` nunca reagia. Agora mostra um
  aviso pedindo pra confirmar o e-mail nesse caso.

## [0.0.6-alpha] - 2026-08-29

### Added
- Modo claro/escuro em todo o app (exceto a tela de Login/Cadastro, que
  segue fixa na referência escura fornecida). Escuro usa preto AMOLED puro
  no fundo (`MimoColors.dark.bg`). Preferência persistida e trocável em
  Configurações → Aparência (Claro/Escuro/Sistema), via
  `lib/core/theme/theme_controller.dart`.
- Fonte trocada para Poppins em todo o app (`lib/core/theme/mimo_text.dart`),
  registrando explicitamente os pesos usados (thin/light, regular, medium,
  semibold, bold) para não cair em negrito sintético.
- Ícones reais de Google e Facebook no Login/Cadastro (arquivos do usuário,
  em `assets/images/`); Apple continua com o ícone vetorial.
- Campo de nome de usuário no Cadastro, com validação de formato e
  checagem de disponibilidade antes de criar a conta.

## [0.0.5-alpha] - 2026-08-29

### Fixed
- Configurações: os dois `ListTile` dentro de um `Container` decorado
  perdiam o splash/ink por falta de um `Material` ancestral — achado ao
  rodar o dev build (o framework acusa isso em runtime, `flutter analyze`
  não pega). Envolvidos em `Material` próprio.
- Versão exibida em Configurações agora vem de `package_info_plus` (lê o
  `pubspec.yaml` de verdade) em vez de um texto fixo que ficava
  desatualizado a cada bump.

## [0.0.4-alpha] - 2026-08-29

### Changed
- Login/Cadastro (`lib/features/auth/login_screen.dart`) refeitos pra bater
  com a referência visual fornecida: painel escuro dividido, imagem própria
  em `assets/images/auth_background.jpg` no lado largo, form-only em telas
  estreitas. Campos, checkbox "Lembrar de mim", "Esqueceu a senha?" (real,
  via `resetPasswordForEmail`) e botões sociais (visuais, sem OAuth
  configurado ainda) seguem o layout de referência.
- `HomeShell`: barra inferior e rail lateral agora flutuam (margem, cantos
  de 8px, blur) em vez de ficarem coladas na borda da tela.

## [0.0.3-alpha] - 2026-08-29

### Added
- Pastas (`lib/features/folders/`): listar, criar (nome + cor) e abrir uma
  pasta pra ver os mimos dentro dela. Alocar/duplicar entre pastas segue a
  regra de 1 pasta por mimo — sem tabela de junção, é uma coluna só.
- Seletor de pasta na Captura Rápida, ligado às pastas reais do usuário.
- Amigos (`lib/features/friends/`): busca por @usuário, solicitações
  (aceitar/recusar) e lista de amigos, tudo contra `friendships` real.
- Shell adaptável (`lib/features/shell/home_shell.dart`): barra inferior
  com botão central em telas estreitas, rail lateral com botão "Novo mimo"
  em telas largas (>=840px) — mesmo breakpoint usado no grid do Feed.

## [0.0.2-alpha] - 2026-08-29

### Added
- Autenticação por e-mail/senha (`lib/features/auth/`), ligada ao trigger
  `handle_new_user` já existente no banco.
- Feed real (`lib/features/feed/`): busca `mimos` do usuário logado no
  Supabase, com a tag "Desorganizado" vs. "Pasta: <nome>" mutuamente
  exclusiva, estados de carregamento/erro/vazio e pull-to-refresh.
- Captura rápida manual (`lib/features/capture/`): bottom sheet pra colar
  link, título e preço, gravando direto em `mimos` — ainda sem
  share-intent nem sugestão por IA (fica pra próxima etapa).
- Barra de navegação com as 4 abas (Feed, Amigos, Perfil, Configurações) e
  o botão central de captura (`lib/features/shell/home_shell.dart`),
  igual ao wireframe.
- Telas de Perfil (identidade + contagem real de mimos) e Configurações
  (com "Sair" funcional); Amigos ainda é placeholder.

## [0.0.1-alpha] - 2026-08-29

### Added
- Scaffold inicial do app em Flutter, alvos Android e Windows.
- Bootstrap do Supabase (`supabase_flutter` + `flutter_dotenv`), lendo
  configuração de `.env` local ou `--dart-define` em builds de CI/release.
- Migrations SQL iniciais (`supabase/migrations/000_schema.sql` até
  `003_seed_system_tags.sql`): schema relacional, trigger de perfil no
  signup, políticas de RLS e tags de sistema pré-definidas.
- Documento de fundação do produto (PRD, schema, stack, mapa de telas) e
  wireframes estáticos das telas-chave.
