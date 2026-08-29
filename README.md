# Mimo

> Uma wishlist sem bagunça de abas abertas.

Mimo transforma o ato de salvar e organizar desejos de compra numa
experiência rápida e organizada. Cada item salvo é um **mimo**: foto, preço,
pasta e prioridade, pronto pra ser encontrado de novo — sem depender de
prints perdidos na galeria ou links mandados pro próprio WhatsApp.

Projeto open source, mantido por uma pessoa só, com foco em **Android** e
**Windows**.

## Stack

- **App** — Flutter (Dart), Android + Windows a partir de um único codebase.
- **Backend** — [Supabase](https://supabase.com) (Postgres + Auth + Storage +
  Realtime), camada gratuita.
- **IA de visão** — Google Gemini API: sugestão de categoria, pasta, tags e
  recorte 1:1 a partir de um print.

## Rodando localmente

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install)
   (canal stable) — versão usada neste repo: 3.47.1.
2. `flutter pub get`
3. Copie `.env.example` para `.env` e preencha com a URL e a `anon key` do
   seu projeto Supabase (*Project Settings → API* no painel).
4. Rode as migrations de `supabase/migrations/` no seu projeto, na ordem
   numérica — cole no SQL Editor do painel, ou use `supabase db push` se
   estiver com a CLI configurada.
5. `flutter run -d windows` ou `flutter run -d <dispositivo-android>`

## Migrations

| Arquivo | O que faz |
|---|---|
| `000_schema.sql` | Tipos, tabelas e índices principais |
| `001_auth_trigger.sql` | Cria o perfil em `public.users` no signup |
| `002_rls_policies.sql` | Row Level Security de cada tabela |
| `003_seed_system_tags.sql` | Tags pré-definidas (Casa, Tech, Roupas...) |

Novas migrations seguem a mesma numeração sequencial, sempre subindo
(`004_...`, `005_...`, ...).

## Versionamento

Este projeto segue [Semantic Versioning 2.0.0](https://semver.org/). Versão
atual: **0.0.1-alpha** — fase inicial, schema e API ainda podem mudar sem
aviso prévio. Mudanças ficam registradas em [CHANGELOG.md](CHANGELOG.md).

## Licença

[MIT](LICENSE)
