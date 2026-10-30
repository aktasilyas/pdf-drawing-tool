# #514 — One unreadable element must not make a notebook unopenable

**Goal:** `Layer.fromJson` decodes each element on its own; an element that
fails is kept raw and written back on save.

**Reference check:** GoodNotes, StarNote and Flexcil open partly damaged
notebooks instead of refusing the whole file (issue #514, architect-verified).
We do the same; nothing is user-visible.

## Steps
1. `drawing_core`: new immutable `UnreadableElement { listKey, raw }`, exported.
2. `Layer.unreadableElements` (default empty, unmodifiable, part of equality,
   `copyWith`). Every `_LayerStrokeOps` / `_LayerElementOps` method that builds a
   new `Layer` passes it through (including `clear()`: the user cannot see these
   elements, so clearing never discards data they did not know about).
3. Move JSON code to `layer_json.dart` (part of `layer.dart`):
   - per-element try/catch for strokes, shapes, texts, images, sticky notes;
     failures go to `unreadableElements` and are logged with `dart:developer`
     (drawing_core has no logger dependency; same as `page_background_json.dart`);
   - `toJson` appends the raw entries to their original list; `elementOrder`
     is kept as stored, so their ids survive. Renderers already skip ids that
     resolve to no element.
   - non-string `elementOrder` entries are skipped instead of failing the layer.
4. `TextAlignment` decodes leniently (unknown → `left`). `ShapeType` stays
   strict on purpose: an unknown shape type is the case that must become an
   unreadable element.
5. Tests: `drawing_core/test/models/layer_unreadable_test.dart` and
   `example_app/test/.../load_document_unreadable_element_test.dart` (real
   Drift DB through `LibraryFixture`).

Out of scope: page-level decode failures. `Page.copyWithFreshIds` (duplicate
page) explicitly drops unreadable elements: their ids cannot be remapped (tested).
