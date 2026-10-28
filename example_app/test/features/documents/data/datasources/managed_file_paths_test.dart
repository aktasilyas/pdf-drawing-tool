import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/data/datasources/managed_file_paths.dart';

void main() {
  test('collects the PDF path of a PDF page', () {
    final page = {
      'background': {'type': 'pdf', 'pdfFilePath': 'elyanotes_pdfs/a.pdf'},
    };
    expect(managedFilePathsOfPage(page), {'elyanotes_pdfs/a.pdf'});
  });

  test('collects the image path of an image page', () {
    final page = {
      'background': {'type': 'pdf', 'imageFilePath': 'elyanotes_images/1.png'},
    };
    expect(managedFilePathsOfPage(page), {'elyanotes_images/1.png'});
  });

  test('collects image element paths across layers', () {
    final page = {
      'background': {'type': 'blank'},
      'layers': [
        {
          'images': [
            {'id': 'a', 'filePath': 'elyanotes_images/a.png'},
            {'id': 'b', 'filePath': 'elyanotes_images/b.png'},
          ],
        },
        {
          'images': [
            {'id': 'c', 'filePath': 'elyanotes_images/a.png'},
          ],
        },
      ],
    };
    expect(managedFilePathsOfPage(page), {
      'elyanotes_images/a.png',
      'elyanotes_images/b.png',
    });
  });

  test('combines background and element paths', () {
    final page = {
      'background': {'imageFilePath': 'elyanotes_images/bg.png'},
      'layers': [
        {
          'images': [
            {'filePath': 'elyanotes_images/el.png'},
          ],
        },
      ],
    };
    expect(managedFilePathsOfPage(page), {
      'elyanotes_images/bg.png',
      'elyanotes_images/el.png',
    });
  });

  test('malformed or empty maps give an empty set', () {
    expect(managedFilePathsOfPage({}), isEmpty);
    expect(managedFilePathsOfPage({'background': 'x', 'layers': 3}), isEmpty);
    expect(
      managedFilePathsOfPage({
        'background': {'pdfFilePath': 5, 'imageFilePath': ''},
        'layers': [
          'x',
          {'images': 'y'},
          {
            'images': [
              'z',
              {'filePath': 7},
            ],
          },
        ],
      }),
      isEmpty,
    );
  });

  test('image paths outside elyanotes_images are never collected', () {
    final page = {
      'background': {'imageFilePath': '/storage/emulated/0/DCIM/bg.jpg'},
      'layers': [
        {
          'images': [
            {'filePath': '/storage/emulated/0/Download/photo.png'},
            {'filePath': 'elyanotes_images/../secret.png'},
            {'filePath': '/data/app/elyanotes_images/kept.png'},
          ],
        },
      ],
    };
    expect(
      managedFilePathsOfPage(page),
      {'/data/app/elyanotes_images/kept.png'},
    );
  });

  test('isManagedImagePath accepts only files directly in the images dir', () {
    expect(isManagedImagePath('elyanotes_images/a.png'), isTrue);
    expect(isManagedImagePath(r'C:\x\elyanotes_images\a.png'), isTrue);
    expect(isManagedImagePath('elyanotes_images/'), isFalse);
    expect(isManagedImagePath('a.png'), isFalse);
    expect(isManagedImagePath('/home/u/Pictures/a.png'), isFalse);
  });
}
