import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, pen group button opens PenTypePicker instead of PenSettingsPanel.
final penPickerModeProvider = StateProvider<bool>((ref) => false);
