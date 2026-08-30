import 'package:flutter/material.dart';

import '../../../core/theme/mimo_colors.dart';
import '../../../core/widgets/options_glyph.dart';
import '../../../data/models/folder.dart';

Color _folderColor(Folder folder) =>
    Color(int.parse('FF${folder.color.replaceFirst('#', '')}', radix: 16));

/// Small overlapping avatar stack for a shared folder's members — shared
/// across every place a folder gets shown (Pastas list, Feed's
/// grouped-by-folder view in every layout).
class FolderAvatarStack extends StatelessWidget {
  const FolderAvatarStack({super.key, required this.urls});

  final List<String?> urls;

  static const _max = 3;
  static const _size = 18.0;
  static const _overlap = 6.0;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final shown = urls.take(_max).toList();
    return SizedBox(
      width: _size + (shown.length - 1) * (_size - _overlap),
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.placeholder,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: shown[i] == null
                    ? null
                    : Image.network(shown[i]!, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}

class _SharedBadge extends StatelessWidget {
  const _SharedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: MimoColors.gradientA.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Compartilhada',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: MimoColors.gradientA,
        ),
      ),
    );
  }
}

/// Row style — icon-square (or cover) + name + count (+ avatar stack/
/// shared badge) + chevron. Used by FoldersScreen ("Gerenciar pastas")
/// and, mode "Lista", the Feed's grouped-by-folder view.
///
/// [onOptions] is "opções da pasta on the go": a small "•••" button on
/// desktop (no room to spare for it on mobile's tighter rows), a
/// long-press on mobile instead.
class FolderListTile extends StatelessWidget {
  const FolderListTile({
    super.key,
    required this.folder,
    required this.count,
    required this.onTap,
    required this.isDesktop,
    this.onOptions,
  });

  final Folder folder;
  final int count;
  final VoidCallback onTap;
  final bool isDesktop;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final color = _folderColor(folder);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: !isDesktop ? onOptions : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: folder.coverImageUrl == null
                      ? Container(
                          color: color.withValues(alpha: 0.16),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.folder_outlined,
                            color: color,
                            size: 20,
                          ),
                        )
                      : Image.network(folder.coverImageUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '$count ${count == 1 ? 'mimo' : 'mimos'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.inkFaint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (folder.isShared) ...[
                          const SizedBox(width: 8),
                          if (folder.memberAvatarUrls.isNotEmpty) ...[
                            FolderAvatarStack(urls: folder.memberAvatarUrls),
                            const SizedBox(width: 6),
                          ],
                          const _SharedBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isDesktop && onOptions != null) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: onOptions,
                  child: const OptionsGlyph(),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bigger row with a strip of compressed mini cover thumbnails from the
/// folder's own items instead of just one icon. Feed's grouped view,
/// mode "Lista detalhada". See FolderListTile for [onOptions].
class FolderDetailedTile extends StatelessWidget {
  const FolderDetailedTile({
    super.key,
    required this.folder,
    required this.count,
    required this.coverUrls,
    required this.onTap,
    required this.isDesktop,
    this.onOptions,
  });

  final Folder folder;
  final int count;
  final List<String> coverUrls;
  final VoidCallback onTap;
  final bool isDesktop;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final color = _folderColor(folder);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: !isDesktop ? onOptions : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: coverUrls.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.folder_outlined,
                          color: color,
                          size: 26,
                        ),
                      )
                    : _MiniCoverGrid(urls: coverUrls),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$count ${count == 1 ? 'mimo' : 'mimos'}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.inkFaint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (folder.isShared) ...[
                          const SizedBox(width: 8),
                          if (folder.memberAvatarUrls.isNotEmpty) ...[
                            FolderAvatarStack(urls: folder.memberAvatarUrls),
                            const SizedBox(width: 6),
                          ],
                          const _SharedBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isDesktop && onOptions != null) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: onOptions,
                  child: const OptionsGlyph(),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCoverGrid extends StatelessWidget {
  const _MiniCoverGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final shown = urls.take(4).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: shown.length == 1
          ? Image.network(shown.first, fit: BoxFit.cover)
          : GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 1.5,
              crossAxisSpacing: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final url in shown) Image.network(url, fit: BoxFit.cover),
              ],
            ),
    );
  }
}

/// Dynamic-card style — cover/icon + name + count (+ avatar stack/shared
/// badge). Feed's grouped view, mode "Grid" (mobile, 2/3 columns) or
/// always on desktop (fixed width, regardless of the selected
/// DesktopMimoView — "as pastas continuam em card"). See FolderListTile
/// for [onOptions].
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    required this.count,
    required this.onTap,
    required this.isDesktop,
    this.onOptions,
  });

  final Folder folder;
  final int count;
  final VoidCallback onTap;
  final bool isDesktop;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final color = _folderColor(folder);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: !isDesktop ? onOptions : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: folder.coverImageUrl == null
                        ? Container(
                            color: color.withValues(alpha: 0.14),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.folder_rounded,
                              size: 42,
                              color: color,
                            ),
                          )
                        : Image.network(
                            folder.coverImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (isDesktop && onOptions != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: onOptions,
                        child: const OptionsGlyph(),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Same row as the count, not a row of its own below
                    // it — every card must stay exactly as tall as any
                    // other one (a real GridView, one fixed cell height
                    // per row, not Masonry), and an extra row here used
                    // to force every OTHER card's aspect ratio to reserve
                    // dead space for a badge most of them don't have.
                    Row(
                      children: [
                        Text(
                          '$count ${count == 1 ? 'mimo' : 'mimos'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.inkFaint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (folder.isShared &&
                            folder.memberAvatarUrls.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          FolderAvatarStack(urls: folder.memberAvatarUrls),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
