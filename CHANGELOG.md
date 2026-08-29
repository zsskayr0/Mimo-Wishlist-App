# Changelog

Todas as mudanças notáveis deste projeto são documentadas aqui.

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

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
