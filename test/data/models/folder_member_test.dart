import 'package:flutter_test/flutter_test.dart';
import 'package:mimo/data/models/folder_member.dart';

void main() {
  group('FolderMember.fromJson', () {
    test('reads role and the nested users(...) profile', () {
      final member = FolderMember.fromJson({
        'role': 'editor',
        'users': {
          'id': 'u1',
          'username': 'thaty',
          'display_name': 'Thaty',
          'avatar_url': 'https://x/a.png',
        },
      });

      expect(member.userId, 'u1');
      expect(member.username, 'thaty');
      expect(member.displayName, 'Thaty');
      expect(member.avatarUrl, 'https://x/a.png');
      expect(member.role, 'editor');
    });

    test('avatarUrl/displayName are null-safe when absent', () {
      final member = FolderMember.fromJson({
        'role': 'visualizador',
        'users': {'id': 'u1', 'username': 'thaty'},
      });
      expect(member.displayName, isNull);
      expect(member.avatarUrl, isNull);
    });
  });

  group('FolderMember.isOwner', () {
    test('true only for the synthetic "dono" role', () {
      const owner = FolderMember(userId: 'u1', username: 'dono', role: 'dono');
      const editor = FolderMember(
        userId: 'u2',
        username: 'editor',
        role: 'editor',
      );
      expect(owner.isOwner, isTrue);
      expect(editor.isOwner, isFalse);
    });
  });
}
