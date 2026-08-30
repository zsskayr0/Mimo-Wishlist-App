# Changelog

Todas as mudanças notáveis deste projeto são documentadas aqui.

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [0.0.36-alpha] - 2026-08-30

### Added
- Assinatura de release de verdade pro Android — `android/key.properties`
  (gitignored) + keystore próprio; sem esse arquivo o build release cai
  pra assinatura de debug sozinho, então nunca quebra. Confirmado:
  `flutter build apk --release` e `flutter build windows --release`
  funcionam.
- CI no GitHub Actions (`.github/workflows/ci.yml`): analyze + test em
  todo push/PR pra `main`, mais um build release de Android e de Windows
  pra pegar regressão de build cedo.
- Primeiros testes automatizados de verdade além do smoke test: lógica
  de filtro/ordenação (`MimoFilters`) e parsing de JSON dos modelos
  (`Mimo`, `Folder`, `FolderMember`, `UserProfile`) — cobrindo os embeds
  do Postgrest que já causaram bug real nessa sessão.
- README atualizado pra refletir o app de verdade (busca/filtros, pastas
  compartilhadas, share intent, modos de visualização) e documentar a
  numeração das migrations até a 008 e como gerar um build assinado.

## [0.0.35-alpha] - 2026-08-30

### Fixed
- Card de pasta compartilhada ainda com "barriga" — o selo de avatares
  sobreposto na capa continuava mudando a altura efetiva do card e
  ficava estranho por cima da foto. Movido de volta pro rodapé, mas
  agora na mesma linha da contagem de mimos (não numa linha própria) —
  sem variar altura entre cards e sem ficar em cima da imagem.

## [0.0.34-alpha] - 2026-08-30

### Fixed
- Card de pasta compartilhada com "barriga" (vão em branco embaixo) —
  o selo de avatares empurrava o rodapé pra baixo só nos cards
  compartilhados, obrigando a proporção do grid a reservar espaço extra
  em todo mundo. Selo movido pra cima da própria capa (sobreposto),
  então todo card tem exatamente a mesma altura e a proporção do grid
  ficou bem mais justa.
- "Editar pasta", "Convidar pra pasta" e "Opções da pasta" agora abrem
  como card flutuante centralizado no desktop, igual aos outros menus
  do app — antes eram sempre um bottom sheet, mesmo em tela larga.

## [0.0.33-alpha] - 2026-08-30

### Fixed
- Grid de cards de pasta desalinhado: era masonry (empacota pela coluna
  mais curta), o que não faz sentido pra cards de altura quase uniforme
  e bagunçava a ordem de leitura esquerda-pra-direita. Trocado por um
  grid de verdade nas três variantes (desktop, grid 2 e grid 3 mobile).

## [0.0.32-alpha] - 2026-08-30

### Added
- Cards de pasta (visão agrupada do Feed) seguem o modo de visualização
  escolhido: Grid 2/3 colunas → card no mesmo tamanho dos mimos; Lista →
  disposição igual à antiga tela de Pastas; Lista detalhada → mini
  ícones comprimidos das fotos dos itens da pasta. No desktop, pastas
  ficam sempre em card dinâmico de largura fixa, mesmo quando o modo dos
  mimos é Tabela — aí os mimos desorganizados abaixo é que seguem o modo
  escolhido de verdade (inclusive tabela).
- A pilha de avatares de quem tem acesso (antes só na tela de Pastas)
  agora aparece em todas as formas de card de pasta, em toda visão.
- "Opções da pasta" direto do card/linha, sem precisar entrar na pasta:
  botão "•••" no desktop, toque longo no mobile.

## [0.0.31-alpha] - 2026-08-30

### Changed
- Visão agrupada por pasta (toggle "Pastas" no Feed) trocada: em vez de
  expandir os mimos de cada pasta ali mesmo, agora é um card por pasta
  (foto de capa se tiver uma, ou um ícone colorido), com o total de
  mimos. Toca no card pra abrir a pasta de verdade. Desorganizados
  continuam como cards individuais, numa seção no final.

## [0.0.30-alpha] - 2026-08-30

### Changed
- "Pastas" no Feed não abre mais uma tela separada — agora agrupa os
  mimos direto ali: cada pasta com seus itens, desorganizados numa
  seção no fim. É um grid fixo de 2 colunas por seção (não segue o modo
  de visualização escolhido em Configurações). Gerenciar pastas (criar,
  renomear, cor, capa) continua acessível por um link no topo dessa
  visão agrupada.

## [0.0.29-alpha] - 2026-08-30

### Added
- **Requer a migration `008_folder_cover_and_ownership.sql`** — adiciona
  `folders.cover_image_url` e a função `transfer_folder_ownership`.
  Enquanto ela não roda, editar pasta (nome/cor) e transferir dono dão
  erro; o resto desta versão funciona normalmente.
- Botão "Convidar" da pasta virou "Opções da pasta" (mesmo visual do
  botão de opções do Detalhe do mimo) e agora é o menu completo de quem
  tem acesso: dono (com a tag "Dono"), editores e visualizadores, cada
  um com avatar. Dono pode tornar outro membro o novo dono da pasta,
  remover membros, editar a pasta (nome, cor, foto de capa) e excluir a
  pasta inteira.
- Dono da pasta agora também aparece nos filtros por pessoa (antes só
  editores/visualizadores apareciam).
- Mimos de outra pessoa numa pasta compartilhada mostram um selo com o
  avatar de quem adicionou (nos modos lista e grid; tabela ainda não).

### Fixed
- Foto de perfil dos amigos nunca aparecia em lugar nenhum (busca,
  solicitações, lista de amigos) — sempre mostrava o ícone genérico
  mesmo com avatar_url preenchido.

## [0.0.28-alpha] - 2026-08-30

### Added
- Lista de Pastas mostra os avatares de quem tem acesso, empilhados ao
  lado do selo "Compartilhada" (conforme wireframe).
- Convidar pra pasta virou busca ao vivo (igual Amigos), com sugestões
  de @usuário e avatar — em vez de digitar um @exato e torcer.

### Fixed
- Aba Amigos: aceitar/recusar solicitação agora atualiza a tela na hora
  (não espera mais recarregar as 3 listas do zero pra sumir o pedido),
  os botões ficam desabilitados enquanto processa (sem risco de tocar
  2x), e erros de rede mostram aviso em vez de falhar silenciosamente.
  Adicionado "puxar pra atualizar" na lista (não tinha nenhum jeito
  manual de sincronizar antes).
- Botão "Adicionar" da busca de amigos agora vira "Pendente" depois de
  enviar a solicitação, em vez de continuar clicável como se nada
  tivesse acontecido.

## [0.0.27-alpha] - 2026-08-30

### Fixed
- Busca de amigos não encontrava ninguém: a própria dica do campo
  ("Buscar @usuário") convida a digitar o @, mas a busca nunca tirava
  esse caractere antes de comparar — e username é sempre salvo sem @, aí
  "@fulana" nunca batia com "fulana" no banco.
- `_isSearching` nunca voltava a `false` depois da busca terminar: com
  zero resultados, a tela ficava girando o spinner pra sempre em vez de
  mostrar "Ninguém encontrado." (o que parecia a busca travada/quebrada).

## [0.0.26-alpha] - 2026-08-30

### Changed
- Ícone do app menor e verificadamente centralizado (0.8x ainda ficava
  grande demais na tela real — foi pra 0.62x; conferido escaneando os
  pixels da marca em vez de só olhar a miniatura).

## [0.0.25-alpha] - 2026-08-30

### Added
- Captura por share intent: Mimo aparece no menu de compartilhar do
  Android pra links (texto/URL) e fotos. Compartilhar um produto de
  outro app/navegador abre a captura rápida já preenchida (o link puxa
  os metadados automaticamente, igual colar manualmente); compartilhar
  uma foto pré-carrega ela como capa. Funciona com o app fechado ou já
  aberto.

### Changed
- Ícone do app com mais respiro em volta da marca (menos "zoom" que a
  versão anterior, que seguia o SVG oficial cortado rente à borda).

### Fixed
- `receive_sharing_intent` vendorizado em `third_party/` e fixado na
  1.8.1 em vez da 1.9.0: a 1.9.0 exige `compileSdk 37`, e essa versão do
  Android SDK só está instalada aqui como `android-37.0` (esquema de
  nomeação novo), que o Gradle não resolve pra um `compileSdk 37` cru. A
  1.8.1 também precisou de um ajuste pontual (compileOptions/kotlinOptions
  faltando no módulo do plugin causava incompatibilidade Java 11 vs
  Kotlin 17). Detalhes em `third_party/PATCHES.md`.

## [0.0.24-alpha] - 2026-08-30

### Added
- Marca da Mimo (`MimoMark`, desenhada com `Canvas`/`Path`, sem depender
  de asset/SVG em runtime) substitui o coração antigo nos 4 lugares que
  ainda usavam `Icons.favorite`: tela de login, cabeçalho do Feed, barra
  lateral do desktop e tela de configuração ausente do Supabase.
- Botão de adicionar mimo embutido na barra inferior, centralizado
  verticalmente junto das abas — não é mais um círculo flutuante acima
  da barra.
- Swipe horizontal entre Feed/Amigos/Perfil/Config no celular, ao estilo
  Instagram (`PageView`), preservando o estado de cada aba ao trocar
  (nada recarrega ou perde a posição do scroll ao voltar pra ela).

### Fixed
- Botão de adicionar mimo só respondia ao toque bem no ícone do "+": a
  versão flutuante furava a área de toque do próprio `Stack` que a
  continha (metade do círculo ficava fora dos limites de layout,
  mesmo pintando por cima via `clipBehavior: Clip.none` — pintura e
  hit-test não são a mesma coisa). Resolvido embutindo o botão na barra
  em vez de fazê-lo flutuar por cima.
- Overflow (`RenderFlex`) no título da tela de pasta com nomes longos —
  o `Text` não estava dentro de um `Expanded`, então não encolhia.

## [0.0.23-alpha] - 2026-08-30

### Added
- Logo definitiva aplicada como ícone do app: tag branca com furo, sobre
  o gradiente diagonal blush→rosé→violeta, gerada a partir dos SVGs
  oficiais em ambas as plataformas (Android com ícone adaptativo —
  fundo e primeiro plano separados — e legado; Windows `.ico`).
  `tool/generate_icons.dart` (roda via `flutter test`, não faz parte da
  suíte normal) desenha a marca direto com `dart:ui`/`Canvas` a partir
  do path SVG e exporta os PNGs fonte em `assets/icon/`; o
  `flutter_launcher_icons` aplica o resultado pras duas plataformas.

### Fixed
- Build Android travando com "Could not close incremental caches" no
  Kotlin (provável antivírus prendendo os arquivos `.tab` bem na hora
  em que o compilador ia fechá-los) — desativado
  `kotlin.incremental=false` no `gradle.properties` do módulo Android;
  incremental não faz falta pra builds do zero.

## [0.0.22-alpha] - 2026-08-30

### Fixed
- Achada a causa raiz do bug das tags no desktop: `Container(alignment:
  Alignment.center)` sem `width` explícito se expande pra preencher
  qualquer largura *limitada* que o pai dê — mesmo uma "até N" solta,
  como um `Wrap` — em vez de abraçar o conteúdo. Funcionava na
  `ListView` horizontal (largura ilimitada ali), mas quebrava dentro de
  `Wrap`, virando aquelas barras esticadas cheias de espaço vazio. Tirado
  o `alignment` de onde não fazia falta (`_FilterChip` no Feed, `_Choice`
  no `MimoFilterSheet` — esse último provavelmente já estava com o
  mesmo problema sem ter sido notado, já que também vive dentro de
  `Wrap`), preservando o preenchimento onde era intencional (as duas
  opções de "Ordenar por", dentro de `Expanded`) via um `width:
  double.infinity` explícito em vez do `alignment` ambíguo.

### Changed
- Barra de tags do Feed no desktop simplificada de volta pra rolagem
  horizontal, igual ao celular — a versão de "quebra em até 2 linhas"
  não valia a complexidade extra frente ao bug acima.

## [0.0.21-alpha] - 2026-08-30

### Added
- Tabela: coluna LINK (domínio da loja, largura fixa, abre o link ao
  tocar) à direita do título; linha em branco no fim pra criar um mimo
  digitando o título ali mesmo, sem abrir o sheet de captura.
- Preview do modo de visualização: corrigido overflow real (5px) no
  mockup da Tabela — margens internas apertadas demais pra caber na
  caixinha do preview.

### Changed
- Tabela: só a foto do item abre o Detalhe agora — o resto da linha
  (título, link, preço, pasta, tags) não faz mais nada ao tocar, e
  prioridade/status continuam editáveis ali mesmo. Também perdeu a
  moldura de card (borda + cantos arredondados + clip) que dava a
  impressão de ser uma caixa separada da página; agora é só a lista de
  linhas rolando na própria página, sem cortar a última linha.
- Barra de tags do Feed no desktop: reescrita pra realmente fazer o que
  foi pedido — flui até a borda da tela, quebra pra uma segunda linha se
  precisar, e qualquer tag que ainda sobre depois dessas duas linhas
  simplesmente não aparece ali (continua alcançável via busca ou
  Filtros). A versão anterior (Wrap com scroll) não tinha esse
  comportamento e renderizava estranho.

## [0.0.20-alpha] - 2026-08-30

### Fixed
- Achado no log do dev build da v0.0.19: `FolderRepository.fetchSharedWithMe`
  quebrava com `PGRST201` (embed ambíguo) assim que a aba Amigos abria —
  `folders` tem dois caminhos até `users` (o FK direto `owner_id` e o
  many-to-many via `folder_members`), então `users(username)` sozinho não
  bastava pro Postgrest escolher; agora usa `users!folders_owner_id_fkey`.
- Overflow real no Feed no desktop: a barra de tags virando `Wrap` (fix
  da v0.0.19) podia crescer sem limite com muitas tags e estourar a
  altura disponível pro grid abaixo. Agora tem um teto de altura (~2
  linhas) com rolagem própria, então nunca mais estoura o layout
  independente de quantas tags existirem.

## [0.0.19-alpha] - 2026-08-30

### Added
- Configurações → Visualização agora abre em duas páginas dedicadas
  (celular e desktop, cada uma com sua própria seleção persistida), não
  mais um `Wrap` de chips na própria tela de Configurações — cada opção
  mostra um preview animado (fade + escala com leve atraso entre os
  blocos) do que aquele modo faz.
- Tabela (desktop): prioridade e status de compra agora são editáveis
  direto na linha (menu de seleção rápido), sem precisar abrir o mimo;
  colunas ganharam mais espaço entre si.
- Avatar de perfil e bio (até 50 caracteres, aparece abaixo do
  @usuário) — `EditProfileSheet` ganhou um seletor de foto (recorte 1:1
  circular) e o campo de bio; novo bucket `avatars` no Storage
  (`007_avatar_storage.sql`).
- Fundo verdadeiramente preto (AMOLED) na tela de autenticação — as
  cores `authBg`/`authPanel`/`authInputBg`/`authBorder` tinham um viés
  arroxeado (B > R > G) mesmo depois do ajuste anterior pro tema escuro
  geral; agora são neutras.
- Rolagem com o botão esquerdo do mouse habilitada em todo o app
  (`ScrollBehavior` global) — as linhas horizontais de chip (tags no
  Feed) só respondiam a toque, não a arrastar com o mouse no desktop.

### Changed
- Corrigida uma falha de planejamento: o recorte 1x1 deixou de ser
  aplicado (destrutivamente) no momento da captura — a imagem agora é
  guardada na proporção original, e o recorte quadrado é só uma escolha
  de exibição (`MimoCard.dynamicCover`, o modo "Grid quadrado"). Antes,
  toda capa já chegava cortada quadrada no Storage, então o "Grid
  dinâmico" ficava idêntico ao quadrado — não tinha mais nada "dinâmico"
  pra mostrar.
- Seletor de pasta (`FolderPickerSheet`) ganhou busca (a partir de 5
  pastas) e "Criar nova pasta" direto no fluxo, sem precisar sair da
  captura/edição pra criar a pasta antes.
- Removido o modo "Grid 4 colunas" no celular — ficava pequeno demais
  pra ser útil.
- Barra de tags do Feed: no desktop, quebra em várias linhas até a borda
  da tela em vez de rolar horizontalmente; no celular continua rolando.
- Desktop (Feed e Pasta) usa a largura total da tela agora, com só um
  padding lateral — antes ficava travado numa coluna central de 1100px,
  sobrando bastante espaço vazio dos dois lados numa tela larga.

### Fixed
- Flicker ao voltar de qualquer tela (Detalhe, editar perfil, aceitar
  amizade...): o Feed, a Pasta, Perfil, Configurações, Amigos e Pastas
  usavam `FutureBuilder` puro, que reseta pro estado de carregamento
  assim que o Future é trocado — a lista inteira sumia e reaparecia por
  uma fração de segundo. Trocado por um padrão de estado em cache que só
  troca os dados quando os novos já estão prontos, nunca limpa antes.

## [0.0.18-alpha] - 2026-08-30

### Fixed
- Regressão séria da v0.0.16-alpha: trocar o `Dialog` do Flutter pelo
  `showFloatingDialog` (fix do "fecha ao tocar fora") removeu, sem
  querer, o ancestral `Material` que o `Dialog` fornecia de graça —
  qualquer `InkWell`/`Ink` dentro (botões, chips, o `GradientButton`)
  quebrava com "No Material widget found" assim que renderizava.
  `MimoDetailScreen` já tinha o próprio `Material`; `QuickCaptureSheet` e
  `MimoFilterSheet` agora também têm.

## [0.0.17-alpha] - 2026-08-30

### Added
- Criar pasta nova on-the-go direto do seletor de pasta ("Criar nova
  pasta" abre o sheet de criação sem sair do fluxo de captura/edição; ao
  salvar, já volta selecionada).
- Busca ao escolher pasta (`FolderPickerSheet`), quando há mais de 4
  pastas.
- Configurações → Visualização: escolha independente pra celular (Lista,
  Lista detalhada, Grid 2/3/4 colunas) e desktop (Lista, Lista detalhada,
  Tabela, Grid dinâmico), persistida (`ViewModeController`,
  mesmo padrão do `ThemeController`). Aplicada no Feed e na tela de
  Pasta via o novo `MimoCollectionView`.
- Tabela (desktop): colunas de capa, título, preço, pasta, tags,
  prioridade e status de compra, com cabeçalho e divisórias finas —
  substitui o grid quando esse modo é escolhido.

### Changed
- O toggle avulso "Dinâmico" saiu do Feed/Pasta — a mesma ideia (capas
  com a proporção real da imagem) agora é o modo "Grid dinâmico" nas
  Configurações, junto dos outros modos de visualização, em vez de um
  controle solto de sessão.

## [0.0.16-alpha] - 2026-08-29

### Added
- Perfil real, conforme wireframe: avatar, nome/@usuário, "Editar perfil",
  cards de mimos/pastas/amigos, Resumo (desorganizados) e Histórico
  (comprados/arquivados) — todos tocáveis, abrindo a lista filtrada
  correspondente.
- Configurações real, conforme wireframe: card de conta (abre "Editar
  perfil"), Notificações (Push, "em breve"), Privacidade (dois seletores
  visuais — "Todos" fixo por enquanto, nada aplicado no backend ainda,
  então tocar mostra "Em breve" em vez de fingir que salvou algo),
  Aparência (tema, já existia), Sobre o Mimo, Código aberto no GitHub
  (abre o repo de verdade) e Sair.
- Amigos: seção nova "Pastas compartilhadas com você" (pastas de outras
  pessoas das quais você é membro); "Seus amigos" ganhou a contagem;
  linhas de amigo agora mostram nome + @usuário e abrem um menu com
  "Remover amizade"; botão de busca no cabeçalho; "Recusar" virou botão
  com borda (antes era só texto).
- `EditProfileSheet` compartilhado entre Perfil e Configurações (edita
  nome e @usuário, com a mesma validação/checagem de disponibilidade do
  Cadastro).

### Fixed
- Diálogos flutuantes no desktop (Novo/Editar mimo, Detalhe do mimo,
  Filtros) agora fecham ao tocar fora deles. O `Dialog` padrão do Flutter
  absorve toques em toda a própria área — inclusive na margem
  transparente ao redor do card — antes que cheguem à barreira que
  fecharia o diálogo; substituído por um `showFloatingDialog` próprio
  (`GestureDetector` cobrindo a tela, fecha ao tocar fora, absorve toque
  no próprio card).

## [0.0.15-alpha] - 2026-08-29

### Added
- Campo de Notas editável no Detalhe do mimo — antes só existia leitura
  condicional (só aparecia se já tivesse notas, sem jeito nenhum de
  criar); agora é sempre um campo de texto, salvando automaticamente
  (debounce de 600ms) via `MimoRepository.updateNotes`.
- Filtro de pasta ganhou a opção "Desorganizado", pra achar os mimos sem
  pasta nenhuma — antes só dava pra filtrar por uma pasta específica ou
  "Todas".

### Changed
- Detalhe do mimo em duas colunas no desktop: esquerda com imagem,
  título, valor e link (+ botão "Abrir na loja" logo abaixo); direita com
  pasta, tags, prioridade, status de compra e notas. O diálogo deixou de
  ter altura fixa nesse modo — agora se ajusta ao conteúdo (com um teto),
  já que o botão "Abrir na loja" não depende mais de ficar fixo no rodapé
  via `Positioned`. No mobile continua uma coluna só, sem mudança.

## [0.0.14-alpha] - 2026-08-29

### Added
- Toggle "Dinâmico" ao lado de "Filtros" (Feed e Pasta): ativado, cada
  card se ajusta à proporção real da própria imagem de capa; desativado
  (padrão), continua tudo 1:1 como antes.

### Changed
- `MimoFilterSheet` também abre como diálogo flutuante centralizado no
  desktop, igual ao `QuickCaptureSheet` — e nesse modo os filtros ficam
  em duas colunas (a busca de "Ordenar por" continua em linha única no
  topo).
- Grid do Feed e da Pasta trocado de `GridView` (childAspectRatio fixo)
  pra `MasonryGridView.extent` (`flutter_staggered_grid_view`): cada card
  agora tem exatamente a altura que precisa — corrige o espaço em branco
  sobrando embaixo da pill de pasta em cards com título curto ou sem
  preço.
- "Revisar mimo" (a tela de Detalhe) agora também abre como diálogo
  flutuante centralizado no desktop, em vez de página cheia — mesmo
  tratamento que já tinha sido dado ao "Novo/Editar mimo". No mobile
  continua página cheia, sem mudança.

## [0.0.13-alpha] - 2026-08-29

### Added
- Busca de verdade no Feed e na tela de Pasta: pesquisa por título ou por
  nome de tag, não só decorativa.
- Filtro/ordenação completo (`MimoFilters`, `MimoFilterSheet`): tag, pasta,
  owner (pra achar itens de alguém numa pasta compartilhada — os chips de
  membro na tela de Pasta agora também funcionam como esse filtro),
  prioridade, status de compra e loja (lista dinâmica, tirada do domínio
  de cada link salvo); ordena por data de inclusão ou valor, crescente ou
  decrescente.
- No modo desktop, "Novo mimo" e "Editar mimo" agora abrem como um diálogo
  flutuante centralizado (mesmo padrão visual), em vez do bottom sheet
  esticado que ficava com "zoom grande" numa janela larga.

### Fixed
- Exceção não tratada pego no log do dev build: em `FeedScreen`,
  `FoldersScreen` e `FolderDetailScreen`,
  `setState(() => _algumaFuture = future)` faz o closure retornar o
  próprio `Future` (atribuição é uma expressão que avalia pro valor
  atribuído) — o Flutter rejeita isso em runtime. Acontecia sempre que
  `_reload()`/`_reloadMimos()`/`_reloadMembers()` rodava, inclusive ao
  voltar da tela de Detalhe. Trocado por corpo de bloco
  (`setState(() { _algumaFuture = future; })`) nos quatro lugares onde
  acontecia.
- "Queixo" visual no shell desktop: a área de conteúdo não tinha a mesma
  margem de 16px que a sidebar flutuante já tinha, sobrando uma borda
  desalinhada acima dela.

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
