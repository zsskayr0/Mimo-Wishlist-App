/// How the Feed/Pasta grids render on a phone-width screen. Grid modes
/// are a fixed column count (not the auto-columns-by-width masonry
/// desktop uses) since a phone's width is comparatively fixed per
/// device — a column count that just fits the device makes more sense
/// there than an auto-fit rule.
enum MobileMimoView { list, detailedList, grid2, grid3, grid4 }

/// How they render on desktop width. `dynamicGrid` is the one grid
/// option here (unlike mobile's fixed column counts) — the masonry grid
/// already auto-adds columns as the window widens, and covers keep
/// their own real aspect ratio instead of being forced 1:1.
enum DesktopMimoView { list, detailedList, table, dynamicGrid }

extension MobileMimoViewLabel on MobileMimoView {
  String get label => switch (this) {
        MobileMimoView.list => 'Lista',
        MobileMimoView.detailedList => 'Lista detalhada',
        MobileMimoView.grid2 => 'Grid 2 colunas',
        MobileMimoView.grid3 => 'Grid 3 colunas',
        MobileMimoView.grid4 => 'Grid 4 colunas',
      };
}

extension DesktopMimoViewLabel on DesktopMimoView {
  String get label => switch (this) {
        DesktopMimoView.list => 'Lista',
        DesktopMimoView.detailedList => 'Lista detalhada',
        DesktopMimoView.table => 'Tabela',
        DesktopMimoView.dynamicGrid => 'Grid dinâmico',
      };
}
