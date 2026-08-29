# Changelog

Todas as mudanças notáveis deste projeto são documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e o versionamento segue [Semantic Versioning 2.0.0](https://semver.org/).

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
