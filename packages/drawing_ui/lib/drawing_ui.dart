/// Flutter UI components for the StarNote drawing library.
///
/// This package provides ready-to-use widgets for building drawing applications:
/// - [DrawingScreen] - The main drawing screen widget
/// - [TopNavigationBar] - Row 1: Navigation and document actions
/// - [ToolBar] - Row 2: Drawing tools and quick access
/// - Tool settings panels for various tools
library drawing_ui;

// Models
export 'src/models/tool_type.dart';

// Theme
export 'src/theme/drawing_theme.dart';
export 'src/theme/drawing_colors.dart';

// Screens
export 'src/screens/drawing_screen.dart';

// Canvas
export 'src/canvas/mock_canvas.dart';
export 'src/canvas/drawing_canvas.dart';
export 'src/canvas/stroke_painter.dart';

// Rendering
export 'src/rendering/flutter_stroke_renderer.dart';

// Toolbar (Two-row layout)
export 'src/toolbar/top_navigation_bar.dart';
export 'src/toolbar/tool_bar.dart';
export 'src/toolbar/tool_button.dart';
export 'src/toolbar/quick_access_row.dart';

// Note: drawing_toolbar.dart and right_action_buttons.dart deprecated
// Actions moved to TopNavigationBar

// Note: PenBox sidebar removed - pen presets managed via panel "Add to Pen Box" button
// Keeping pen_box files for potential future use, but not exported in public API

// Panels
export 'src/panels/tool_panel.dart';
export 'src/panels/pen_settings_panel.dart';
export 'src/panels/highlighter_settings_panel.dart';
export 'src/panels/eraser_settings_panel.dart';
export 'src/panels/shapes_settings_panel.dart';
export 'src/panels/sticker_panel.dart';
export 'src/panels/image_panel.dart';
export 'src/panels/ai_assistant_panel.dart';
export 'src/panels/toolbar_editor_panel.dart';
export 'src/panels/toolbar_settings_panel.dart';
export 'src/panels/lasso_selection_panel.dart';
export 'src/panels/laser_pointer_panel.dart';

// Common Widgets
export 'src/widgets/anchored_panel.dart';
export 'src/widgets/color_chip.dart';
export 'src/widgets/color_chips_grid.dart';
export 'src/widgets/thickness_slider.dart';
export 'src/widgets/panel_overlay.dart';
export 'src/widgets/panel_arrow.dart';
export 'src/widgets/unified_color_picker.dart';
export 'src/widgets/floating_pen_box.dart';
export 'src/widgets/pen_icon_widget.dart';
export 'src/widgets/reorderable_tool_list.dart';

// Utils
export 'src/utils/pen_type_mapper.dart';
export 'src/utils/anchor_position_calculator.dart';

// Re-export flutter_pen_toolbar for convenience
export 'package:flutter_pen_toolbar/flutter_pen_toolbar.dart';

// State Management
export 'src/providers/drawing_providers.dart';
export 'src/providers/document_provider.dart';
export 'src/providers/history_provider.dart';
export 'src/providers/tool_style_provider.dart';
export 'src/providers/toolbar_config_provider.dart';
export 'src/providers/canvas_transform_provider.dart';
