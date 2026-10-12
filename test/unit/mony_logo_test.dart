import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mony/shared/widgets/mony_logo.dart';

void main() {
  group('MonyLogo Brand Identity Tests', () {
    test('MonyLogo initializes with configurable sizes and background modes', () {
      const logoDefault = MonyLogo();
      expect(logoDefault.size, equals(36));
      expect(logoDefault.hasSquircleBackground, isTrue);
      expect(logoDefault.showText, isFalse);

      const logoHeader = MonyLogo(
        size: 28,
        showText: true,
        fontSize: 20,
      );
      expect(logoHeader.size, equals(28));
      expect(logoHeader.showText, isTrue);
      expect(logoHeader.fontSize, equals(20));

      const logoAuth = MonyLogo(
        size: 72,
        hasSquircleBackground: true,
      );
      expect(logoAuth.size, equals(72));
      expect(logoAuth.hasSquircleBackground, isTrue);
    });

    test('Vector SVG logo asset exists and contains valid gradients and paths', () {
      final svgFile = File('assets/images/logo.svg');
      expect(svgFile.existsSync(), isTrue);

      final content = svgFile.readAsStringSync();
      expect(content, contains('<svg'));
      expect(content, contains('viewBox="0 0 512 512"'));
      expect(content, contains('grad-left'));
      expect(content, contains('grad-center'));
      expect(content, contains('grad-right'));
      expect(content, contains('mony-mark'));
    });

    test('Web preview SVG assets exist and are accessible', () {
      final webLogo = File('web_preview/logo.svg');
      expect(webLogo.existsSync(), isTrue);

      final webFavicon = File('web_preview/favicon.svg');
      expect(webFavicon.existsSync(), isTrue);
    });
  });
}
