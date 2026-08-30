import 'package:flutter_test/flutter_test.dart';
import 'package:mimo/data/models/mimo.dart';

void main() {
  group('Mimo.fromJson', () {
    test('parses a bare row with no embeds', () {
      final mimo = Mimo.fromJson({
        'id': 'm1',
        'owner_id': 'u1',
        'title': 'Fone Bluetooth',
        'priority': 'alta',
        'purchase_status': 'desejado',
        'created_at': '2026-01-15T12:00:00Z',
        'folder_id': null,
        'notes': null,
        'cover_image_url': null,
        'original_url': null,
        'store_domain': null,
        'price': null,
      });

      expect(mimo.id, 'm1');
      expect(mimo.ownerId, 'u1');
      expect(mimo.title, 'Fone Bluetooth');
      expect(mimo.priority, 'alta');
      expect(mimo.purchaseStatus, 'desejado');
      expect(mimo.folderId, isNull);
      expect(mimo.folderName, isNull);
      expect(mimo.isUnorganized, isTrue);
      expect(mimo.tags, isEmpty);
    });

    test('reads folder name/color from the embedded folders(...) select', () {
      final mimo = Mimo.fromJson({
        'id': 'm1',
        'owner_id': 'u1',
        'title': 'Cadeira',
        'priority': 'media',
        'purchase_status': 'desejado',
        'created_at': '2026-01-15T12:00:00Z',
        'folder_id': 'f1',
        'folders': {'name': 'Setup', 'color': '#A6791F'},
      });

      expect(mimo.isUnorganized, isFalse);
      expect(mimo.folderName, 'Setup');
      expect(mimo.folderColor, '#A6791F');
    });

    test('unwraps mimo_tags(tags(...)) into flat MimoTag list', () {
      final mimo = Mimo.fromJson({
        'id': 'm1',
        'owner_id': 'u1',
        'title': 'Item',
        'priority': 'media',
        'purchase_status': 'desejado',
        'created_at': '2026-01-15T12:00:00Z',
        'mimo_tags': [
          {
            'tags': {
              'id': 't1',
              'name': 'Casa',
              'color': '#000000',
              'is_system': true,
            },
          },
          {
            'tags': {
              'id': 't2',
              'name': 'Presente',
              'color': '#ffffff',
              'is_system': false,
            },
          },
        ],
      });

      expect(mimo.tags, hasLength(2));
      expect(mimo.tags.map((t) => t.name), ['Casa', 'Presente']);
    });

    test('price parses from either an int or a double in the JSON', () {
      final asInt = Mimo.fromJson({
        'id': 'm1',
        'owner_id': 'u1',
        'title': 'Item',
        'priority': 'media',
        'purchase_status': 'desejado',
        'created_at': '2026-01-15T12:00:00Z',
        'price': 100,
      });
      expect(asInt.price, 100.0);
    });

    test('defaults priority/purchaseStatus when the column is missing', () {
      final mimo = Mimo.fromJson({
        'id': 'm1',
        'owner_id': 'u1',
        'title': 'Item',
        'created_at': '2026-01-15T12:00:00Z',
      });
      expect(mimo.priority, 'media');
      expect(mimo.purchaseStatus, 'desejado');
    });
  });

  group('Mimo.copyWith', () {
    final base = Mimo(
      id: 'm1',
      ownerId: 'u1',
      title: 'Item',
      priority: 'baixa',
      purchaseStatus: 'desejado',
      createdAt: DateTime(2026, 1, 1),
      notes: 'nota original',
    );

    test('updates priority/purchaseStatus independently', () {
      final updated = base.copyWith(priority: 'alta');
      expect(updated.priority, 'alta');
      expect(updated.purchaseStatus, 'desejado');
    });

    test('the nullable-clearing-function pattern distinguishes "leave" from "clear" for notes', () {
      final untouched = base.copyWith();
      expect(untouched.notes, 'nota original');

      final cleared = base.copyWith(notes: () => null);
      expect(cleared.notes, isNull);

      final replaced = base.copyWith(notes: () => 'nova nota');
      expect(replaced.notes, 'nova nota');
    });
  });
}
