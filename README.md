# Mimo

> Uma wishlist sem bagunça de abas abertas.

Mimo transforma o ato de salvar e organizar desejos de compra numa
experiência rápida e organizada. Cada item salvo é um **mimo**: foto, preço,
pasta, prioridade e status de compra, pronto pra ser encontrado de novo —
sem depender de prints perdidos na galeria ou links mandados pro próprio
WhatsApp.

Projeto open source, mantido por uma pessoa só, com foco em **Android** e
**Windows**.

## O que já tem

- **Feed** com busca, filtros (pasta, tag, dono, prioridade, status de
  compra, loja) e ordenação; agrupamento por pasta direto no feed.
- **Captura rápida** — cola um link e o título/preço/foto vêm sozinhos
  (Open Graph), ou tira foto/escolhe da galeria.
- **Compartilhar direto de outro app** (Android) — manda um link ou foto pro
  Mimo pelo menu de compartilhar do sistema.
- **Pastas** — cor, foto de capa, compartilhar com editor/visualizador,
  transferir o dono, ver quem tem acesso.
- **Amigos** — busca por @usuário, solicitações, pastas compartilhadas com
  você.
- **Modos de visualização** por dispositivo (lista, lista detalhada, grid,
  tabela no desktop; lista, lista detalhada, grid 2/3 colunas no mobile),
  configuráveis com preview animado.
- Tema claro/escuro, escuro com fundo verdadeiro preto pra telas AMOLED.

## Stack

- **App** — Flutter (Dart), Android + Windows a partir de um único codebase.
- **Backend** — [Supabase](https://supabase.com) (Postgres + Auth + Storage),
  camada gratuita.

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
| `004_fix_folder_rls_recursion.sql` | Corrige recursão nas policies de pasta |
| `005_folder_members_visibility.sql` | Qualquer membro vê o resto do elenco da pasta compartilhada |
| `006_cover_storage.sql` | Bucket de capa dos mimos |
| `007_avatar_storage.sql` | Bucket de foto de perfil |
| `008_folder_cover_and_ownership.sql` | Capa de pasta e transferência de dono |

Novas migrations seguem a mesma numeração sequencial, sempre subindo
(`009_...`, `010_...`, ...).

## Builds

Builds de teste (Android e Windows, debug e release) saem como
[Releases](../../releases) deste repo.

Pra gerar um APK assinado localmente, copie `android/key.properties.example`
para `android/key.properties` e preencha com o keystore de release (nunca
commitado — o `.gitignore` já cobre `key.properties` e `*.jks`). Sem esse
arquivo, `flutter build apk --release` cai pra assinatura de debug
automaticamente, então o build sempre funciona — só não fica instalável por
cima de uma versão assinada de verdade.

## Licença

[MIT](LICENSE)
