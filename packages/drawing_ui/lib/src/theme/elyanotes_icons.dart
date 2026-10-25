/// Centralized icon definitions for Elyanotes.
///
/// Follows docs/design/BRIEF.md and docs/specs/52-editor-chrome.md
/// (section 6): Phosphor Regular for idle chrome, Phosphor Fill for the
/// active/selected variant (`*Active`, `*Filled`, `library*Fill`).
///
/// Never use PhosphorIcons directly in widgets — always use ElyanotesIcons.
library;

import 'package:phosphor_icons/phosphor_icons.dart';

import '../models/tool_type.dart';

abstract final class ElyanotesIcons {
  // ═══════════════════════════════════════════
  // Navigation Bar Icons (Row 1)
  // ═══════════════════════════════════════════

  static const home = PhosphorIconsRegular.house;
  static const sidebar = PhosphorIconsRegular.sidebar;
  static const sidebarActive = PhosphorIconsFill.sidebar;
  static const search = PhosphorIconsRegular.magnifyingGlass;
  static const readerMode = PhosphorIconsRegular.bookOpen;
  static const readerModeActive = PhosphorIconsFill.bookOpen;
  static const layers = PhosphorIconsRegular.stack;
  static const gridOn = PhosphorIconsRegular.gridFour;
  static const gridOnActive = PhosphorIconsFill.gridFour;
  static const gridOff = PhosphorIconsRegular.squareSplitHorizontal;
  static const share = PhosphorIconsRegular.shareFat;
  static const exportIcon = PhosphorIconsRegular.export;
  static const more = PhosphorIconsRegular.dotsThree;
  static const moreVert = PhosphorIconsRegular.dotsThreeVertical;
  static const caretDown = PhosphorIconsRegular.caretDown;
  static const caretUp = PhosphorIconsRegular.caretUp;
  static const settings = PhosphorIconsRegular.gearSix;

  // ═══════════════════════════════════════════
  // Tool Bar Icons (Row 2) — Drawing Tools
  // ═══════════════════════════════════════════

  // Pen tools
  static const penNib = PhosphorIconsRegular.penNib;
  static const penNibActive = PhosphorIconsFill.penNib;
  static const pencil = PhosphorIconsRegular.pencilSimple;
  static const pencilActive = PhosphorIconsFill.pencilSimple;
  static const pen = PhosphorIconsRegular.pen;
  static const penActive = PhosphorIconsFill.pen;
  static const markerCircle = PhosphorIconsRegular.markerCircle;
  static const markerCircleActive = PhosphorIconsFill.markerCircle;
  static const dashedPen = PhosphorIconsRegular.penNibStraight;
  static const dashedPenActive = PhosphorIconsFill.penNibStraight;
  static const paintBrush = PhosphorIconsRegular.paintBrush;
  static const paintBrushActive = PhosphorIconsFill.paintBrush;
  static const ruler = PhosphorIconsRegular.ruler;
  static const rulerActive = PhosphorIconsFill.ruler;

  // Highlighter
  static const highlighter = PhosphorIconsRegular.highlighterCircle;
  static const highlighterActive = PhosphorIconsFill.highlighterCircle;

  // Eraser
  static const eraser = PhosphorIconsRegular.eraser;
  static const eraserActive = PhosphorIconsFill.eraser;

  // Shape tools
  static const shapes = PhosphorIconsRegular.shapes;
  static const shapesActive = PhosphorIconsFill.shapes;

  // Text
  static const textT = PhosphorIconsRegular.textT;
  static const textTActive = PhosphorIconsFill.textT;

  // Image
  static const image = PhosphorIconsRegular.imageSquare;
  static const imageActive = PhosphorIconsFill.imageSquare;

  // Sticker
  static const sticker = PhosphorIconsRegular.smiley;
  static const stickerActive = PhosphorIconsFill.smiley;

  // Sticky note
  static const stickyNote = PhosphorIconsRegular.noteBlank;
  static const stickyNoteActive = PhosphorIconsFill.noteBlank;

  // Laser pointer
  static const laser = PhosphorIconsRegular.cursorClick;
  static const laserActive = PhosphorIconsFill.cursorClick;

  // Selection / Lasso
  static const selection = PhosphorIconsRegular.selection;
  static const selectionActive = PhosphorIconsFill.selection;

  // Pan/Zoom
  static const hand = PhosphorIconsRegular.hand;
  static const handActive = PhosphorIconsFill.hand;

  // ═══════════════════════════════════════════
  // Action Icons
  // ═══════════════════════════════════════════

  static const undo = PhosphorIconsRegular.arrowBendUpLeft;
  static const redo = PhosphorIconsRegular.arrowBendUpRight;
  static const close = PhosphorIconsRegular.x;
  static const check = PhosphorIconsRegular.check;
  static const plus = PhosphorIconsRegular.plus;
  static const minus = PhosphorIconsRegular.minus;
  static const trash = PhosphorIconsRegular.trash;
  static const copy = PhosphorIconsRegular.copy;
  static const duplicate = PhosphorIconsRegular.copySimple;
  static const paste = PhosphorIconsRegular.clipboardText;
  static const scissors = PhosphorIconsRegular.scissors;
  static const bookmark = PhosphorIconsRegular.bookmarkSimple;
  static const bookmarkFilled = PhosphorIconsFill.bookmarkSimple;
  static const rotate = PhosphorIconsRegular.arrowsClockwise;
  static const rotateCW = PhosphorIconsRegular.arrowClockwise;
  static const rotateCCW = PhosphorIconsRegular.arrowCounterClockwise;
  static const rotateHalf = PhosphorIconsRegular.arrowUDownLeft;
  static const template = PhosphorIconsRegular.layout;
  static const goToPage = PhosphorIconsRegular.arrowSquareRight;
  static const sliders = PhosphorIconsRegular.slidersHorizontal;
  static const palette = PhosphorIconsRegular.palette;
  static const eyedropper = PhosphorIconsRegular.eyedropper;
  static const list = PhosphorIconsRegular.list;
  static const lock = PhosphorIconsRegular.lock;
  static const lockOpen = PhosphorIconsRegular.lockOpen;
  static const lockFilled = PhosphorIconsFill.lock;
  static const star = PhosphorIconsRegular.star;
  static const starFilled = PhosphorIconsFill.star;
  static const link = PhosphorIconsRegular.link;
  static const tag = PhosphorIconsRegular.tag;
  static const camera = PhosphorIconsRegular.camera;
  static const images = PhosphorIconsRegular.images;
  static const cloud = PhosphorIconsRegular.cloudArrowUp;
  static const chartLine = PhosphorIconsRegular.chartLine;
  static const circle = PhosphorIconsRegular.circle;
  static const broom = PhosphorIconsRegular.broom;
  static const sparkle = PhosphorIconsRegular.sparkle;
  static const info = PhosphorIconsRegular.info;
  static const checkCircle = PhosphorIconsRegular.checkCircle;
  static const hourglass = PhosphorIconsRegular.hourglassSimple;
  static const send = PhosphorIconsRegular.paperPlaneRight;
  static const refresh = PhosphorIconsRegular.arrowCounterClockwise;
  static const warningCircle = PhosphorIconsRegular.warningCircle;
  static const touchApp = PhosphorIconsRegular.handTap;
  static const addCircle = PhosphorIconsRegular.plusCircle;
  static const crown = PhosphorIconsRegular.crown;
  static const brokenImage = PhosphorIconsRegular.imageBroken;
  static const uploadFile = PhosphorIconsRegular.uploadSimple;
  static const colorize = PhosphorIconsRegular.eyedropperSample;
  static const move = PhosphorIconsRegular.arrowsOutCardinal;
  static const dragHandle = PhosphorIconsRegular.dotsSixVertical;
  static const editPencil = PhosphorIconsRegular.pencilSimpleLine;
  static const orientationPortrait = PhosphorIconsRegular.deviceMobile;
  static const orientationLandscape = PhosphorIconsRegular.deviceTabletSpeaker;
  static const comment = PhosphorIconsRegular.chatCircleDots;
  static const scrollDirection = PhosphorIconsRegular.arrowsHorizontal;
  static const scrollDirectionVertical = PhosphorIconsRegular.arrowsDownUp;
  static const splitView = PhosphorIconsRegular.squareSplitHorizontal;
  static const bringToFront = PhosphorIconsRegular.arrowLineUp;
  static const sendToBack = PhosphorIconsRegular.arrowLineDown;

  // ═══════════════════════════════════════════
  // Audio Icons
  // ═══════════════════════════════════════════

  static const microphone = PhosphorIconsRegular.microphone;
  static const waveform = PhosphorIconsRegular.waveform;
  static const waveformActive = PhosphorIconsFill.waveform;
  static const play = PhosphorIconsRegular.play;
  static const pause = PhosphorIconsRegular.pause;
  static const recordCircle = PhosphorIconsRegular.record;

  // ═══════════════════════════════════════════
  // Page & Document Icons
  // ═══════════════════════════════════════════

  static const page = PhosphorIconsRegular.file;
  static const pageAdd = PhosphorIconsRegular.filePlus;
  static const pageClear = PhosphorIconsRegular.fileX;
  static const pdfFile = PhosphorIconsRegular.filePdf;
  static const folder = PhosphorIconsRegular.folder;
  static const folderOpen = PhosphorIconsRegular.folderOpen;

  // ═══════════════════════════════════════════
  // Navigation Icons
  // ═══════════════════════════════════════════

  static const chevronLeft = PhosphorIconsRegular.caretLeft;
  static const chevronRight = PhosphorIconsRegular.caretRight;
  static const arrowLeft = PhosphorIconsRegular.arrowLeft;

  // ═══════════════════════════════════════════
  // Library
  // ═══════════════════════════════════════════

  static const libraryNotebook = PhosphorIconsRegular.notebook;
  static const libraryNotebookFill = PhosphorIconsFill.notebook;
  static const libraryStar = PhosphorIconsRegular.star;
  static const libraryStarFill = PhosphorIconsFill.star;
  static const libraryTrash = PhosphorIconsRegular.trash;
  static const libraryTrashFill = PhosphorIconsFill.trash;
  static const libraryFolder = PhosphorIconsRegular.folder;
  static const libraryFolderFill = PhosphorIconsFill.folder;
  static const libraryPlus = PhosphorIconsRegular.plus;
  static const libraryCaretDown = PhosphorIconsRegular.caretDown;
  static const libraryCaretRight = PhosphorIconsRegular.caretRight;
  static const librarySearch = PhosphorIconsRegular.magnifyingGlass;
  static const librarySort = PhosphorIconsRegular.sortAscending;
  static const libraryGrid = PhosphorIconsRegular.squaresFour;
  static const libraryRows = PhosphorIconsRegular.rows;
  static const librarySelect = PhosphorIconsRegular.checkCircle;
  static const libraryCheck = PhosphorIconsRegular.check;
  static const libraryClose = PhosphorIconsRegular.x;
  static const libraryCopy = PhosphorIconsRegular.copy;
  static const libraryMove = PhosphorIconsRegular.folderSimple;
  static const libraryCheckSquare = PhosphorIconsRegular.checkSquare;
  static const librarySquare = PhosphorIconsRegular.square;
  static const librarySettings = PhosphorIconsRegular.gearSix;
  static const librarySidebar = PhosphorIconsRegular.sidebar;
  static const libraryMenu = PhosphorIconsRegular.list;
  static const libraryInfo = PhosphorIconsRegular.info;
  static const libraryLock = PhosphorIconsRegular.lock;

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
      ToolType.fountainPen => active ? penNibActive : penNib,
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
