import 'package:flutter/material.dart';

class PDFExportDialog extends StatefulWidget {
  final int totalPages;

  const PDFExportDialog({
    super.key,
    required this.totalPages,
  });

  @override
  State<PDFExportDialog> createState() => _PDFExportDialogState();
}

enum ExportMode { all, range }

class _PDFExportDialogState extends State<PDFExportDialog> {
  ExportMode _exportMode = ExportMode.all;
  int _startPage = 1;
  int _endPage = 1;

  @override
  void initState() {
    super.initState();
    _endPage = widget.totalPages;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PDF Olarak Dışa Aktar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<ExportMode>(
            segments: const [
              ButtonSegment(
                value: ExportMode.all,
                label: Text('Tüm Sayfalar'),
              ),
              ButtonSegment(
                value: ExportMode.range,
                label: Text('Sayfa Aralığı'),
              ),
            ],
            selected: {_exportMode},
            onSelectionChanged: (Set<ExportMode> selection) {
              setState(() {
                _exportMode = selection.first;
              });
            },
          ),
          if (_exportMode == ExportMode.range) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _startPage.toString()),
                    onChanged: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 1 && page <= widget.totalPages) {
                        setState(() {
                          _startPage = page;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Bitiş',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _endPage.toString()),
                    onChanged: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 1 && page <= widget.totalPages) {
                        setState(() {
                          _endPage = page;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement PDF export with drawing_ui
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF dışa aktarma yakında eklenecek')),
            );
          },
          child: const Text('Dışa Aktar'),
        ),
      ],
    );
  }
}
