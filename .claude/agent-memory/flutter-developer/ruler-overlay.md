# Ruler Overlay Coordinate System

## Widget Tree
```
Positioned(left: position.dx, top: position.dy)
  GestureDetector (body drag - screen-space deltas)
    Transform.rotate(angle, alignment: Alignment.centerLeft)
      SizedBox(rulerContentWidth x rulerContentHeight)
        Stack
          Positioned(ruler body at top: handleRadius/2)
          Positioned(rotation handle - has its own GestureDetector)
```

## Key Constants (from ruler_overlay.dart, public)
- `rulerBodyWidth = 600`
- `rulerBodyHeight = 60`
- `rulerHandleRadius = 18`
- `rulerContentWidth = rulerBodyWidth + rulerHandleRadius * 2 = 636`
- `rulerContentHeight = rulerBodyHeight + rulerHandleRadius = 78`

## Rotation Pivot
- `Alignment.centerLeft` on Transform.rotate = center-left of SizedBox child.
- In screen/Stack space: `(position.dx, position.dy + rulerContentHeight / 2)`.
- The pivot is NOT at `position + Offset(0, rulerBodyHeight/2)` (the old incorrect value was off by 9px).

## Hit Test (_isPointOnRuler)
- Pivot: `rulerPos + Offset(0, rulerContentHeight / 2)`
- Un-rotate the test point around the pivot by `-angle`
- Local body bounds: `x: [0, rulerBodyWidth]`, `y: [-rulerBodyHeight/2, rulerBodyHeight/2]`

## Snap Line (_snapToRuler)
- Snap line = bottom edge of ruler body.
- Bottom edge origin in screen space:
  `pivot + rotate((0, rulerBodyHeight/2), angle)`
  = `pivot + Offset(-sin(angle)*h/2, cos(angle)*h/2)`
- Direction: `(cos(angle), sin(angle))`

## Bug History
- Original bug: GestureDetector was inside Transform.rotate, causing inverted drag after rotation.
- Fix: Move GestureDetector outside Transform.rotate.
- Rotation handle uses GlobalKey + localToGlobal() to find pivot in global coordinates.
