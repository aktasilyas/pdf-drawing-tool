/// Centralized icon definitions for StarNote.
///
/// All icons use Phosphor Light style for thin, elegant appearance.
/// Active/selected states use Phosphor Regular for slightly bolder look.
///
/// Never use PhosphorIcons directly in widgets — always use StarNoteIcons.
library;

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/tool_type.dart';

abstract final class StarNoteIcons {
  // ═══════════════════════════════════════════
  // Navigation Bar Icons (Row 1)
  // ═══════════════════════════════════════════

  static const home = PhosphorIconsLight.house;
  static const sidebar = PhosphorIconsLight.sidebar;
  static const sidebarActive = PhosphorIconsRegular.sidebar;
  static const search = PhosphorIconsLight.magnifyingGlass;
  static const readerMode = PhosphorIconsLight.bookOpen;
  static const readerModeActive = PhosphorIconsRegular.bookOpen;
  static const layers = PhosphorIconsLight.stack;
  static const gridOn = PhosphorIconsLight.gridFour;
  static const gridOff = PhosphorIconsLight.squareSplitHorizontal;
  static const share = PhosphorIconsLight.shareFat;
  static const exportIcon = PhosphorIconsLight.export;
  static const more = PhosphorIconsLight.dotsThree;
  static const moreVert = PhosphorIconsLight.dotsThreeVertical;
  static const caretDown = PhosphorIconsLight.caretDown;
  static const caretUp = PhosphorIconsLight.caretUp;
  static const settings = PhosphorIconsLight.gearSix;

  // ═══════════════════════════════════════════
  // Tool Bar Icons (Row 2) — Drawing Tools
  // ═══════════════════════════════════════════

  // Pen tools
  static const penNib = PhosphorIconsLight.penNib;
  static const penNibActive = PhosphorIconsRegular.penNib;
  static const pencil = PhosphorIconsLight.pencilSimple;
  static const pencilActive = PhosphorIconsRegular.pencilSimple;
  static const pen = PhosphorIconsLight.pen;
  static const penActive = PhosphorIconsRegular.pen;
  static const markerCircle = PhosphorIconsLight.markerCircle;
  static const markerCircleActive = PhosphorIconsRegular.markerCircle;
  static const dashedPen = PhosphorIconsLight.penNibStraight;
  static const dashedPenActive = PhosphorIconsRegular.penNibStraight;
  static const paintBrush = PhosphorIconsLight.paintBrush;
  static const paintBrushActive = PhosphorIconsRegular.paintBrush;
  static const ruler = PhosphorIconsLight.ruler;
  static const rulerActive = PhosphorIconsRegular.ruler;

  // Highlighter
  static const highlighter = PhosphorIconsLight.highlighterCircle;
  static const highlighterActive = PhosphorIconsRegular.highlighterCircle;

  // Eraser
  static const eraser = PhosphorIconsLight.eraser;
  static const eraserActive = PhosphorIconsRegular.eraser;

  // Shape tools
  static const shapes = PhosphorIconsLight.shapes;
  static const shapesActive = PhosphorIconsRegular.shapes;

  // Text
  static const textT = PhosphorIconsLight.textT;
  static const textTActive = PhosphorIconsRegular.textT;

  // Image
  static const image = PhosphorIconsLight.imageSquare;
  static const imageActive = PhosphorIconsRegular.imageSquare;

  // Sticker
  static const sticker = PhosphorIconsLight.smiley;
  static const stickerActive = PhosphorIconsRegular.smiley;

  // Sticky note
  static const stickyNote = PhosphorIconsLight.noteBlank;
  static const stickyNoteActive = PhosphorIconsRegular.noteBlank;

  // Laser pointer
  static const laser = PhosphorIconsLight.cursorClick;
  static const laserActive = PhosphorIconsRegular.cursorClick;

  // Selection / Lasso
  static const selection = PhosphorIconsLight.selection;
  static const selectionActive = PhosphorIconsRegular.selection;

  // Pan/Zoom
  static const hand = PhosphorIconsLight.hand;
  static const handActive = PhosphorIconsRegular.hand;

  // ═══════════════════════════════════════════
  // Action Icons
  // ═══════════════════════════════════════════

  static const undo = PhosphorIconsRegular.arrowBendUpLeft;
  static const redo = PhosphorIconsRegular.arrowBendUpRight;
  static const close = PhosphorIconsLight.x;
  static const check = PhosphorIconsLight.check;
  static const plus = PhosphorIconsLight.plus;
  static const minus = PhosphorIconsLight.minus;
  static const trash = PhosphorIconsLight.trash;
  static const copy = PhosphorIconsLight.copy;
  static const duplicate = PhosphorIconsLight.copySimple;
  static const bookmark = PhosphorIconsLight.bookmarkSimple;
  static const bookmarkFilled = PhosphorIconsFill.bookmarkSimple;
  static const rotate = PhosphorIconsLight.arrowsClockwise;
  static const rotateCW = PhosphorIconsLight.arrowClockwise;
  static const rotateCCW = PhosphorIconsLight.arrowCounterClockwise;
  static const rotateHalf = PhosphorIconsLight.arrowUDownLeft;
  static const template = PhosphorIconsLight.layout;
  static const goToPage = PhosphorIconsLight.arrowSquareRight;
  static const sliders = PhosphorIconsLight.slidersHorizontal;
  static const palette = PhosphorIconsLight.palette;
  static const eyedropper = PhosphorIconsLight.eyedropper;
  static const list = PhosphorIconsLight.list;
  static const lock = PhosphorIconsLight.lock;
  static const lockOpen = PhosphorIconsLight.lockOpen;
  static const lockFilled = PhosphorIconsFill.lock;
  static const star = PhosphorIconsLight.star;
  static const starFilled = PhosphorIconsFill.star;
  static const link = PhosphorIconsLight.link;
  static const tag = PhosphorIconsLight.tag;
  static const camera = PhosphorIconsLight.camera;
  static const images = PhosphorIconsLight.images;
  static const cloud = PhosphorIconsLight.cloudArrowUp;
  static const chartLine = PhosphorIconsLight.chartLine;
  static const circle = PhosphorIconsLight.circle;
  static const broom = PhosphorIconsLight.broom;
  static const sparkle = PhosphorIconsLight.sparkle;
  static const info = PhosphorIconsLight.info;
  static const checkCircle = PhosphorIconsLight.checkCircle;
  static const hourglass = PhosphorIconsLight.hourglassSimple;
  static const send = PhosphorIconsLight.paperPlaneRight;
  static const refresh = PhosphorIconsLight.arrowCounterClockwise;
  static const warningCircle = PhosphorIconsLight.warningCircle;
  static const touchApp = PhosphorIconsLight.handTap;
  static const addCircle = PhosphorIconsLight.plusCircle;
  static const crown = PhosphorIconsLight.crown;
  static const brokenImage = PhosphorIconsLight.imageBroken;
  static const uploadFile = PhosphorIconsLight.uploadSimple;
  static const colorize = PhosphorIconsLight.eyedropperSample;
  static const move = PhosphorIconsLight.arrowsOutCardinal;
  static const dragHandle = PhosphorIconsLight.dotsSixVertical;
  static const editPencil = PhosphorIconsLight.pencilSimpleLine;
  static const orientationPortrait = PhosphorIconsLight.deviceMobile;
  static const orientationLandscape = PhosphorIconsLight.deviceTabletSpeaker;
  static const comment = PhosphorIconsLight.chatCircleDots;
  static const scrollDirection = PhosphorIconsLight.arrowsHorizontal;
  static const scrollDirectionVertical = PhosphorIconsLight.arrowsDownUp;
  static const splitView = PhosphorIconsLight.squareSplitHorizontal;

  // ═══════════════════════════════════════════
  // Audio Icons
  // ═══════════════════════════════════════════

  static const microphone = PhosphorIconsLight.microphone;
  static const waveform = PhosphorIconsLight.waveform;
  static const play = PhosphorIconsLight.play;
  static const pause = PhosphorIconsLight.pause;
  static const recordCircle = PhosphorIconsLight.record;

  // ═══════════════════════════════════════════
  // Page & Document Icons
  // ═══════════════════════════════════════════

  static const page = PhosphorIconsLight.file;
  static const pageAdd = PhosphorIconsLight.filePlus;
  static const pageClear = PhosphorIconsLight.fileX;
  static const pdfFile = PhosphorIconsLight.filePdf;
  static const folder = PhosphorIconsLight.folder;
  static const folderOpen = PhosphorIconsLight.folderOpen;

  // ═══════════════════════════════════════════
  // Navigation Icons
  // ═══════════════════════════════════════════

  static const chevronLeft = PhosphorIconsLight.caretLeft;
  static const chevronRight = PhosphorIconsLight.caretRight;
  static const arrowLeft = PhosphorIconsLight.arrowLeft;

  // ═══════════════════════════════════════════
  // Size Constants
  // ═══════════════════════════════════════════

  /// Navigation bar icon size
  static const double navSize = 20.0;

  /// Tool bar icon size
  static const double toolSize = 22.0;

  /// Panel icon size
  static const double panelSize = 18.0;

  /// Action button icon size
  static const double actionSize = 20.0;

  // ═══════════════════════════════════════════
  // Helper: ToolType → Icon mapping
  // ═══════════════════════════════════════════

  /// Returns the appropriate icon for a given ToolType.
  static PhosphorIconData iconForTool(ToolType tool, {bool active = false}) {
    return switch (tool) {
      ToolType.pencil => active ? pencilActive : pencil,
      ToolType.hardPencil => active ? pencilActive : pencil,
      ToolType.ballpointPen => active ? penActive : pen,
      ToolType.gelPen => active ? markerCircleActive : markerCircle,
      ToolType.dashedPen => active ? dashedPenActive : dashedPen,
      ToolType.brushPen => active ? paintBrushActive : paintBrush,
      ToolType.rulerPen => active ? rulerActive : ruler,
      ToolType.highlighter ||
      ToolType.neonHighlighter =>
        active ? highlighterActive : highlighter,
      ToolType.pixelEraser ||
      ToolType.strokeEraser ||
      ToolType.lassoEraser =>
        active ? eraserActive : eraser,
      ToolType.shapes => active ? shapesActive : shapes,
      ToolType.text => active ? textTActive : textT,
      ToolType.image => active ? imageActive : image,
      ToolType.sticker => active ? stickerActive : sticker,
      ToolType.laserPointer => active ? laserActive : laser,
      ToolType.stickyNote => active ? stickyNoteActive : stickyNote,
      ToolType.selection => active ? selectionActive : selection,
      ToolType.panZoom => active ? handActive : hand,
      ToolType.toolbarSettings => active ? sliders : sliders,
    };
  }
}
