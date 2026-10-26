import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/fake_incoming_pdf_source.dart';

void main() {
  late FakeIncomingPdfSource source;
  late Directory tmp;
  late List<String> imported;
  Completer<void>? gate;
  late bool quotaAllowed;
  late bool importThrows;

  setUp(() {
    source = FakeIncomingPdfSource();
    tmp = Directory.systemTemp.createTempSync('incoming_pdf_test');
    imported = [];
    gate = null;
    quotaAllowed = true;
    importThrows = false;
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  IncomingPdf makePdf(String name) {
    final file = File('${tmp.path}/$name')..writeAsBytesSync([1, 2, 3]);
    return IncomingPdf(path: file.path, name: name, size: 3);
  }

  Future<void> fakeImporter(
    BuildContext context, {
    required String path,
    required String name,
    required int size,
  }) async {
    imported.add(name);
    await gate?.future;
    if (importThrows) throw StateError('import failed');
  }

  Future<bool> fakeQuota(BuildContext context) async => quotaAllowed;

  Future<void> pumpListener(
    WidgetTester tester, {
    EditorLeave? leave,
    bool Function()? ready,
    Listenable? routeChanges,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incomingPdfSourceProvider.overrideWithValue(source),
          activeEditorLeaveProvider.overrideWith((ref) => leave),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => IncomingPdfListener(
            navigatorKey: navigatorKey,
            routeChanges: routeChanges,
            isRouterReady: ready ?? () => true,
            importFile: fakeImporter,
            ensureQuota: fakeQuota,
            child: child!,
          ),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('cold start: a PDF waiting before mount is imported',
      (tester) async {
    final pdf = makePdf('cold.pdf');
    source.emit(pdf);
    await pumpListener(tester);
    expect(imported, ['cold.pdf']);
    expect(File(pdf.path).existsSync(), isFalse);
  });

  testWidgets('warm start: a PDF arriving while mounted is imported',
      (tester) async {
    await pumpListener(tester);
    expect(imported, isEmpty);
    source.emit(makePdf('warm.pdf'));
    await settle(tester);
    expect(imported, ['warm.pdf']);
  });

  testWidgets('PDFs are imported one at a time, in order', (tester) async {
    gate = Completer<void>();
    await pumpListener(tester);
    source.emit(makePdf('one.pdf'));
    source.emit(makePdf('two.pdf'));
    await settle(tester);
    expect(imported, ['one.pdf']);
    gate!.complete();
    await settle(tester);
    expect(imported, ['one.pdf', 'two.pdf']);
  });

  testWidgets('quota blocked: nothing is imported, copy is deleted',
      (tester) async {
    quotaAllowed = false;
    final pdf = makePdf('blocked.pdf');
    await pumpListener(tester);
    source.emit(pdf);
    await settle(tester);
    expect(imported, isEmpty);
    expect(File(pdf.path).existsSync(), isFalse);
  });

  testWidgets('copy is deleted after a successful import', (tester) async {
    final pdf = makePdf('ok.pdf');
    await pumpListener(tester);
    source.emit(pdf);
    await settle(tester);
    expect(imported, ['ok.pdf']);
    expect(File(pdf.path).existsSync(), isFalse);
  });

  testWidgets('active editor is left exactly once before the import',
      (tester) async {
    final events = <String>[];
    await pumpListener(tester, leave: () async {
      events.add('leave');
      return true;
    });
    final pdf = makePdf('editor.pdf');
    source.emit(pdf);
    await settle(tester);
    expect(imported, ['editor.pdf']);
    expect(events, ['leave']);
  });

  testWidgets('leave failed: no import, copy is kept while queued',
      (tester) async {
    var leaveCalls = 0;
    await pumpListener(tester, leave: () async {
      leaveCalls++;
      return false;
    });
    final pdf = makePdf('kept.pdf');
    source.emit(pdf);
    await settle(tester);
    expect(leaveCalls, 1);
    expect(imported, isEmpty);
    expect(File(pdf.path).existsSync(), isTrue);
  });

  testWidgets('router not ready (splash): waits, imports once ready',
      (tester) async {
    var isReady = false;
    final routes = ChangeNotifier();
    await pumpListener(tester, ready: () => isReady, routeChanges: routes);
    final pdf = makePdf('splash.pdf');
    source.emit(pdf);
    await settle(tester);
    expect(imported, isEmpty);
    expect(File(pdf.path).existsSync(), isTrue);
    isReady = true;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    routes.notifyListeners();
    await settle(tester);
    expect(imported, ['splash.pdf']);
  });

  testWidgets('leave throws: no import, copy kept', (tester) async {
    await pumpListener(tester, leave: () async => throw StateError('boom'));
    final pdf = makePdf('boom.pdf');
    source.emit(pdf);
    await settle(tester);
    expect(imported, isEmpty);
    expect(File(pdf.path).existsSync(), isTrue);
  });

  testWidgets('no active editor: imports directly', (tester) async {
    await pumpListener(tester);
    source.emit(makePdf('direct.pdf'));
    await settle(tester);
    expect(imported, ['direct.pdf']);
  });

  testWidgets('copy is deleted and the queue continues after a failure',
      (tester) async {
    importThrows = true;
    final first = makePdf('bad.pdf');
    await pumpListener(tester);
    source.emit(first);
    source.emit(makePdf('next.pdf'));
    await settle(tester);
    expect(imported, ['bad.pdf', 'next.pdf']);
    expect(File(first.path).existsSync(), isFalse);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}
