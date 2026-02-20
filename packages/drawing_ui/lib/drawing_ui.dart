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
export 'src/theme/starnote_icons.dart';

// Re-export phosphor_flutter for PhosphorIcon widget
export 'package:phosphor_flutter/phosphor_flutter.dart';

// Screens
export 'src/screens/drawing_screen.dart';
export 'src/screens/drawing_screen_panels.dart';
export 'src/screens/drawing_screen_layout.dart';

// Canvas
export 'src/canvas/mock_canvas.dart';
export 'src/canvas/drawing_canvas.dart';
export 'src/canvas/stroke_painter.dart';
export 'src/canvas/infinite_background_painter.dart';
export 'src/canvas/canvas_color_scheme.dart';

// Painters
export 'src/painters/template_pattern_painter.dart';

// Rendering
export 'src/rendering/flutter_stroke_renderer.dart';

// Services
export 'src/services/services.dart';

// Models (PDF)
export 'src/models/models.dart';

// Widgets (Multi-page & PDF)
export 'src/widgets/widgets.dart';

// Template Picker
export 'src/widgets/template_picker/template_picker_widgets.dart';

// Toolbar (Two-row layout)
export 'src/toolbar/starnote_nav_button.dart';
export 'src/toolbar/top_navigation_bar.dart';
export 'src/toolbar/top_nav_menus.dart';
export 'src/toolbar/tool_bar.dart';
export 'src/toolbar/tool_button.dart';
export 'src/toolbar/quick_access_row.dart';
export 'src/toolbar/quick_thickness_chips.dart';
export 'src/toolbar/toolbar_widgets.dart';
export 'src/toolbar/toolbar_layout_mode.dart';
export 'src/toolbar/adaptive_toolbar.dart';
export 'src/toolbar/medium_toolbar.dart';
export 'src/toolbar/toolbar_overflow_menu.dart';
export 'src/toolbar/compact_bottom_bar.dart';
export 'src/toolbar/compact_tool_panel_sheet.dart';
export 'src/toolbar/tool_groups.dart';
export 'src/toolbar/toolbar_logic.dart';
export 'src/toolbar/toolbar_nav_sections.dart';

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
export 'src/widgets/compact_color_picker.dart';
export 'src/widgets/color_chip.dart';
export 'src/widgets/color_chips_grid.dart';
export 'src/widgets/color_picker_strip.dart';
export 'src/widgets/color_picker_widgets.dart';
export 'src/widgets/color_presets.dart';
export 'src/widgets/cover_preview_widget.dart';
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
export 'src/providers/providers.dart';
