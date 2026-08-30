import 'package:flutter_test/flutter_test.dart';
import 'package:mimo/data/models/folder.dart';

void main() {
  group('Folder.fromJson', () {
    test('reads mimoCount from the embedded mimos(count) aggregate', () {
      final folder = Folder.fromJson({
        'id': 'f1',
        'owner_id': 'u1',
        'name': 'Setup',
        'color': '#A6791F',
        'is_shared': false,
        'mimos': [
          {'count': 7},
        ],
      });
      expect(folder.mimoCount, 7);
    });

    test('mimoCount defaults to 0 with no mimos embed at all', () {
      final folder = Folder.fromJson({
        'id': 'f1',
        'owner_id': 'u1',
        'name': 'Setup',
        'color': '#A6791F',
        'is_shared': false,
      });
      expect(folder.mimoCount, 0);
    });

    test('reads the owner profile from the disambiguated users!folders_owner_id_fkey embed', () {
      final folder = Folder.fromJson({
        'id': 'f1',
        'owner_id': 'u1',
        'name': 'Natal',
        'color': '#C2517B',
        'is_shared': true,
        'users': {
          'username': 'thaty',
          'display_name': 'Thaty',
          'avatar_url': 'https://x/a.png',
        },
      });
      expect(folder.ownerUsername, 'thaty');
      expect(folder.ownerDisplayName, 'Thaty');
      expect(folder.ownerAvatarUrl, 'https://x/a.png');
    });

    test('unwraps folder_members(users(avatar_url)) into a flat nullable list, one per member', () {
      final folder = Folder.fromJson({
        'id': 'f1',
        'owner_id': 'u1',
        'name': 'Natal',
        'color': '#C2517B',
        'is_shared': true,
        'folder_members': [
          {
            'users': {'avatar_url': 'https://x/1.png'},
          },
          {
            'users': {'avatar_url': null},
          },
        ],
      });
      expect(folder.memberAvatarUrls, ['https://x/1.png', null]);
    });

    test(
      'cover_image_url is null-safe (column may not exist yet, pre-migration)',
      () {
        final folder = Folder.fromJson({
          'id': 'f1',
          'owner_id': 'u1',
          'name': 'Setup',
          'color': '#A6791F',
          'is_shared': false,
        });
        expect(folder.coverImageUrl, isNull);
      },
    );
  });

  group('Folder.copyWith', () {
    const base = Folder(
      id: 'f1',
      ownerId: 'u1',
      name: 'Setup',
      color: '#A6791F',
      isShared: false,
      coverImageUrl: 'https://x/cover.png',
    );

    test('updates name/color', () {
      final updated = base.copyWith(name: 'Setup Novo', color: '#000000');
      expect(updated.name, 'Setup Novo');
      expect(updated.color, '#000000');
      expect(updated.id, 'f1');
    });

    test('the nullable-clearing-function pattern distinguishes "leave" from "clear" for coverImageUrl', () {
      final untouched = base.copyWith();
      expect(untouched.coverImageUrl, 'https://x/cover.png');

      final cleared = base.copyWith(coverImageUrl: () => null);
      expect(cleared.coverImageUrl, isNull);
    });
  });
}
