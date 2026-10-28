import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

void main() {
  const legacy = '/data/user/0/old.pkg/app_flutter/elyanotes_images/a.png';
  const relative = 'elyanotes_images/a.png';

  ImageElement make(String path) => ImageElement(
        id: 'i1',
        filePath: path,
        x: 1,
        y: 2,
        width: 10,
        height: 20,
      );

  for (final path in [legacy, relative]) {
    test('JSON round-trips filePath unchanged: $path', () {
      final json = make(path).toJson();
      expect(json['filePath'], path);
      expect(ImageElement.fromJson(json).filePath, path);
    });
  }

  test('resolver maps legacy and relative paths to the new root', () {
    const resolver = PdfPathResolver('/new/root');
    expect(resolver.resolve(legacy), '/new/root/elyanotes_images/a.png');
    expect(resolver.resolve(relative), '/new/root/elyanotes_images/a.png');
  });
}
