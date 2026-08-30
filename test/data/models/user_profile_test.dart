import 'package:flutter_test/flutter_test.dart';
import 'package:mimo/data/models/user_profile.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('reads every column, including the 50-char bio', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'username': 'thaty',
        'display_name': 'Thaty',
        'avatar_url': 'https://x/a.png',
        'bio': 'Uma frase curta sobre mim',
      });

      expect(profile.id, 'u1');
      expect(profile.username, 'thaty');
      expect(profile.displayName, 'Thaty');
      expect(profile.avatarUrl, 'https://x/a.png');
      expect(profile.bio, 'Uma frase curta sobre mim');
    });

    test('displayName/avatarUrl/bio are null-safe when absent', () {
      final profile = UserProfile.fromJson({'id': 'u1', 'username': 'thaty'});
      expect(profile.displayName, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.bio, isNull);
    });
  });
}
