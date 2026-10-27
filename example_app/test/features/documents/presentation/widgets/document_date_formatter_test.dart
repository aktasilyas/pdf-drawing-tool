import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final date = DateTime(2026, 10, 21);

  test('formats a medium date in Turkish', () {
    expect(DocumentDateFormatter.format(date, 'tr'), '21 Eki 2026');
  });

  test('formats a medium date in English', () {
    expect(DocumentDateFormatter.format(date, 'en'), 'Oct 21, 2026');
  });
}
