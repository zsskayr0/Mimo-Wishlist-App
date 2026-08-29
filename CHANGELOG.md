# Changelog

Todas as mudanças notáveis deste projeto são documentadas aqui.

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [0.0.12-alpha] - 2026-08-29

### Fixed
- Salvar um mimo falhava por completo quando o upload da capa dava erro
  (ex.: a migration 006 ainda não tinha sido rodada) — agora um upload
  malsucedido só deixa o mimo sem capa, o resto salva normalmente.
- Card do Feed com proporção errada: a correção anterior do overflow
  (`Expanded` no lugar do `AspectRatio`) resolveu o estouro mas abriu mão
  do 1:1. Voltou a ser `AspectRatio(1)` de verdade, com o
  `childAspectRatio` do grid recalibrado (0.52) pra realmente caber
  imagem quadrada + texto na faixa de largura que o grid produz.
- Título/Preço da Captura Rápida apareciam centralizados — a `Column` que
  os envolve não tinha `crossAxisAlignment: CrossAxisAlignment.start`
  (o padrão do Flutter é centralizado). Corrigido, com `textAlign.left`
  explícito nos dois campos por garantia.
- Diálogo de "Nova tag" usava o `AlertDialog` genérico do Material, fora
  do padrão do resto do app — refeito como bottom sheet (handle, título,
  botão com gradiente) igual às outras telas de criação.

### Changed
- Removida a opção "Abrir link" do menu "···" do Detalhe do Mimo —
  redundante com o botão "Abrir na loja" que já fica fixo embaixo.

## [0.0.11-alpha] - 2026-08-29

### Fixed
- Bug real de estado: criar pasta/excluir mimo só refletia na lista depois
  de sair da tela e voltar. A causa não era o refetch em si — era só
  demorar um round-trip a mais que o usuário esperava ver. Resolvido com
  atualização otimista (o item aparece/some na hora, localmente) em
  `FeedScreen`, `FolderDetailScreen` e `FoldersScreen`.
- Botões "gradiente" (Salvar no Feed, Abrir na loja, Criar pasta, Convidar)
  eram na verdade cor sólida — `FilledButton.styleFrom` não pinta
  `Gradient`. Criado `GradientButton` (usa `Ink` de verdade) e aplicado
  nos quatro.

### Added
- Busca automática de dados do link: colar uma URL agora busca Open Graph
  e JSON-LD da própria página (sem servidor) e preenche título, preço e
  capa quando esses campos ainda estão vazios
  (`lib/data/services/link_metadata_service.dart`).
- Captura de imagem real: escolher da galeria/câmera, recorte 1:1 numa
  tela própria (`crop_your_image`, funciona no Windows — os pacotes
  nativos de crop não funcionam lá), badge circular preto no canto da
  capa (vira "+" sem imagem, "recortar" com imagem; com imagem, oferece
  recortar de novo ou trocar). Upload pro Storage do Supabase
  (`006_cover_storage.sql` — mais uma migration pra rodar).
- Editar mimo: o menu "···" do Detalhe agora abre a Captura Rápida
  pré-preenchida; salvar atualiza a linha em vez de criar outra.
- Criar tag nova direto da Captura Rápida (botão "+" ao lado das tags).
- Botão de opções do Detalhe do Mimo redesenhado (quadrado branco
  arredondado com sombra, igual ao resto do app) e com "Abrir link"
  adicionado ao menu.
- Campos Título/Preço/Link da Captura Rápida em rótulo próprio de 10px
  (não mais o label flutuante do Material, que encolhia sozinho) e a capa
  em 80×80.

## [0.0.10-alpha] - 2026-08-29

### Fixed
- `MimoCard` estourava a altura da célula do grid em certas larguras
  ("BOTTOM OVERFLOWED BY N PIXELS"): a imagem crescia com a largura do
  card via `AspectRatio`, mas o bloco de texto abaixo tinha altura fixa —
  em cards estreitos a soma passava da altura calculada pelo
  `childAspectRatio`. Trocado para `Expanded` na imagem, que absorve o
  espaço que sobra depois do texto em vez de brigar por ele.

### Added
- Tela de Detalhe do Mimo (`lib/features/mimo_detail/`) — tocar num card
  do Feed ou de uma pasta agora abre a tela real: capa, preço/loja com
  link pra abrir de verdade, pasta/tags, Prioridade e Status de compra
  editáveis ali mesmo, Notas, Duplicar em outra pasta e Excluir.
- Tags reais: `TagRepository` + seletor de múltipla escolha na Captura
  Rápida, usando as tags de sistema já semeadas.
- `FolderPickerSheet` compartilhado entre a Captura Rápida e o duplicar
  do Detalhe do Mimo.
- Captura Rápida reconstruída para seguir o wireframe: campos de
  título/preço no estilo rótulo-acima-do-valor ao lado da capa, link com
  domínio detectado ao vivo, seletor de prioridade, pasta como botão
  (abre o picker) em vez de chips sempre visíveis, e o seletor de tags.

## [0.0.9-alpha] - 2026-08-29

### Added
- Compartilhamento de pasta: convidar por `@usuário` com papel de editor ou
  visualizador (`lib/features/folders/invite_member_sheet.dart`), lista de
  membros na tela da pasta, botão de convidar visível só pro dono.
- `supabase/migrations/005_folder_members_visibility.sql`: qualquer membro
  de uma pasta compartilhada agora vê a lista completa de quem mais está
  nela (antes, só via a própria linha).

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
