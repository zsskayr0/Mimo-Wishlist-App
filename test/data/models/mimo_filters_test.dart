import 'package:flutter_test/flutter_test.dart';
import 'package:mimo/data/models/mimo.dart';
import 'package:mimo/data/models/mimo_filters.dart';
import 'package:mimo/data/models/tag.dart';

Mimo _mimo({
  required String id,
  String title = 'Mimo',
  String ownerId = 'owner-1',
  String? folderId,
  String priority = 'media',
  String purchaseStatus = 'desejado',
  String? storeDomain,
  double? price,
  DateTime? createdAt,
  List<MimoTag> tags = const [],
}) {
  return Mimo(
    id: id,
    ownerId: ownerId,
    title: title,
    priority: priority,
    purchaseStatus: purchaseStatus,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    folderId: folderId,
    storeDomain: storeDomain,
    price: price,
    tags: tags,
  );
}

void main() {
  group('MimoFilters.apply — search', () {
    test('matches the title, case-insensitively', () {
      final mimos = [
        _mimo(id: '1', title: 'Fone Bluetooth'),
        _mimo(id: '2', title: 'Cadeira Gamer'),
      ];
      final result = const MimoFilters(searchQuery: 'bluetooth').apply(mimos);
      expect(result.map((m) => m.id), ['1']);
    });

    test(
      'also matches a tag name — "a pesquisa consiga pesquisar tags também"',
      () {
        final mimos = [
          _mimo(id: '1', title: 'Sem tag relevante'),
          _mimo(
            id: '2',
            title: 'Outro item',
            tags: const [
              MimoTag(
                id: 't1',
                name: 'Tech',
                color: '#000000',
                isSystem: false,
              ),
            ],
          ),
        ];
        final result = const MimoFilters(searchQuery: 'tech').apply(mimos);
        expect(result.map((m) => m.id), ['2']);
      },
    );

    test('empty query keeps everything', () {
      final mimos = [_mimo(id: '1'), _mimo(id: '2')];
      expect(const MimoFilters().apply(mimos), hasLength(2));
    });
  });

  group('MimoFilters.apply — folder filters', () {
    final mimos = [
      _mimo(id: 'a', folderId: 'folder-1'),
      _mimo(id: 'b', folderId: 'folder-2'),
      _mimo(id: 'c', folderId: null),
    ];

    test('folderId keeps only that folder', () {
      final result = const MimoFilters(folderId: 'folder-1').apply(mimos);
      expect(result.map((m) => m.id), ['a']);
    });

    test('unorganizedOnly keeps only folderless mimos', () {
      final result = const MimoFilters(unorganizedOnly: true).apply(mimos);
      expect(result.map((m) => m.id), ['c']);
    });
  });

  test('MimoFilters.apply — tagIds keeps mimos with any matching tag', () {
    final mimos = [
      _mimo(
        id: '1',
        tags: const [
          MimoTag(id: 't1', name: 'Casa', color: '#000000', isSystem: false),
        ],
      ),
      _mimo(
        id: '2',
        tags: const [
          MimoTag(id: 't2', name: 'Tech', color: '#000000', isSystem: false),
        ],
      ),
      _mimo(id: '3', tags: const []),
    ];
    final result = const MimoFilters(tagIds: {'t1'}).apply(mimos);
    expect(result.map((m) => m.id), ['1']);
  });

  test('MimoFilters.apply — ownerId keeps only that owner\'s mimos', () {
    final mimos = [
      _mimo(id: '1', ownerId: 'alice'),
      _mimo(id: '2', ownerId: 'bob'),
    ];
    final result = const MimoFilters(ownerId: 'bob').apply(mimos);
    expect(result.map((m) => m.id), ['2']);
  });

  test(
    'MimoFilters.apply — priority and purchaseStatus filter independently',
    () {
      final mimos = [
        _mimo(id: '1', priority: 'alta', purchaseStatus: 'desejado'),
        _mimo(id: '2', priority: 'baixa', purchaseStatus: 'comprado'),
      ];
      expect(
        const MimoFilters(priority: 'alta').apply(mimos).map((m) => m.id),
        ['1'],
      );
      expect(
        const MimoFilters(purchaseStatus: 'comprado')
            .apply(mimos)
            .map((m) => m.id),
        ['2'],
      );
    },
  );

  test('MimoFilters.apply — storeDomain filters exactly', () {
    final mimos = [
      _mimo(id: '1', storeDomain: 'amazon.com.br'),
      _mimo(id: '2', storeDomain: 'shopee.com.br'),
    ];
    final result = const MimoFilters(storeDomain: 'amazon.com.br').apply(mimos);
    expect(result.map((m) => m.id), ['1']);
  });

  test('MimoFilters.apply — filters combine (AND, not OR)', () {
    final mimos = [
      _mimo(id: '1', folderId: 'f1', priority: 'alta'),
      _mimo(id: '2', folderId: 'f1', priority: 'baixa'),
      _mimo(id: '3', folderId: 'f2', priority: 'alta'),
    ];
    final result = const MimoFilters(
      folderId: 'f1',
      priority: 'alta',
    ).apply(mimos);
    expect(result.map((m) => m.id), ['1']);
  });

  group('MimoFilters.apply — sorting', () {
    test('dateAdded descending (default) — newest first', () {
      final mimos = [
        _mimo(id: 'old', createdAt: DateTime(2025, 1, 1)),
        _mimo(id: 'new', createdAt: DateTime(2026, 1, 1)),
      ];
      final result = const MimoFilters().apply(mimos);
      expect(result.map((m) => m.id), ['new', 'old']);
    });

    test('dateAdded ascending — oldest first', () {
      final mimos = [
        _mimo(id: 'old', createdAt: DateTime(2025, 1, 1)),
        _mimo(id: 'new', createdAt: DateTime(2026, 1, 1)),
      ];
      final result = const MimoFilters(sortDescending: false).apply(mimos);
      expect(result.map((m) => m.id), ['old', 'new']);
    });

    test('price sort treats a missing price as zero', () {
      final mimos = [
        _mimo(id: 'no-price'),
        _mimo(id: 'cheap', price: 10),
        _mimo(id: 'pricey', price: 999),
      ];
      final result = const MimoFilters(sortBy: MimoSortBy.price).apply(mimos);
      expect(result.map((m) => m.id), ['pricey', 'cheap', 'no-price']);
    });
  });

  group('MimoFilters.hasActiveFilters / activeCount', () {
    test('empty filters report nothing active', () {
      expect(const MimoFilters().hasActiveFilters, isFalse);
      expect(const MimoFilters().activeCount, 0);
    });

    test(
      'folderId and unorganizedOnly count as the same one "pasta" filter',
      () {
        expect(const MimoFilters(folderId: 'f1').activeCount, 1);
        expect(const MimoFilters(unorganizedOnly: true).activeCount, 1);
      },
    );

    test('activeCount adds up independent filter kinds', () {
      const filters = MimoFilters(
        tagIds: {'t1'},
        priority: 'alta',
        storeDomain: 'amazon.com.br',
      );
      expect(filters.hasActiveFilters, isTrue);
      expect(filters.activeCount, 3);
    });
  });

  group('MimoFilters.copyWith', () {
    test(
      'the nullable-clearing-function pattern can explicitly clear a field',
      () {
        const withFolder = MimoFilters(folderId: 'f1');
        final cleared = withFolder.copyWith(folderId: () => null);
        expect(cleared.folderId, isNull);
      },
    );

    test('omitting a param leaves that field untouched', () {
      const original = MimoFilters(folderId: 'f1', searchQuery: 'fone');
      final updated = original.copyWith(searchQuery: 'cadeira');
      expect(updated.folderId, 'f1');
      expect(updated.searchQuery, 'cadeira');
    });
  });
}
