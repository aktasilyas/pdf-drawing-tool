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

class _PDFExportDialogState extends State<PDFExportDialog> {
  bool _exportAll = true;
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
          RadioListTile<bool>(
            title: const Text('Tüm Sayfalar'),
            value: true,
            groupValue: _exportAll,
            onChanged: (value) {
              setState(() {
                _exportAll = value!;
              });
            },
          ),
          RadioListTile<bool>(
            title: const Text('Sayfa Aralığı'),
            value: false,
            groupValue: _exportAll,
            onChanged: (value) {
              setState(() {
                _exportAll = value!;
              });
            },
          ),
          if (!_exportAll) ...[
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
