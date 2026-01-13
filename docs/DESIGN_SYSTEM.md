# Design System
## StarNote-Inspired Drawing UI

This document defines the **visual language, interaction principles,
and UI constraints** for this project.

It exists to ensure:
- Consistent UI across screens and phases
- A calm, professional, drawing-focused experience
- Avoidance of default Flutter / Material look
- Long-term maintainability for both app and library

This document is **binding** for all UI-related work.

---

## 1. Design Philosophy

- Canvas-first experience
- Tools support the canvas, never dominate it
- Calm, paper-like appearance
- Minimal chrome, maximum focus
- UI should feel *light, precise, and professional*

The UI should invite drawing, not distract from it.

---

## 2. Overall Visual Tone

### Keywords
- Calm
- Neutral
- Precise
- Lightweight
- Professional
- Non-flashy

### Must NOT feel like:
- Default Material UI
- Dashboard / admin panel
- Colorful productivity app
- Toy-like or playful interface

---

## 3. Color System

### Canvas
- Off-white background (paper-like)
- Optional subtle grid
- No pure white
- No strong contrast

### Toolbars & Panels
- Neutral light gray backgrounds
- Slight separation from canvas
- No saturated colors

### Accents
- Single accent color (soft blue / indigo)
- Used ONLY for:
  - Active tool
  - Selected preset
  - Focus indicators

### Forbidden
- Strong reds, greens, yellows in base UI
- Multiple accent colors
- High-contrast dark themes (for now)

---

## 4. Spacing & Density

- UI elements are compact, not oversized
- No excessive padding
- No cramped layouts
- Breathing space without feeling empty

### Guidelines
- Prefer horizontal expansion over vertical
- Toolbars should feel dense but readable
- Panels should never feel heavy

---

## 5. Shapes & Corners

- Rounded rectangles everywhere
- Corner radius: **8–12px**
- No sharp edges
- No exaggerated pill shapes

---

## 6. Shadows & Elevation

- Very subtle shadows only
- No Material elevation stacks
- Panels should float gently, not pop

If unsure:
> Remove the shadow.

---

## 7. Icons

### Style
- Line-based icons
- Consistent stroke weight
- Simple geometry
- No filled Material icons

### Behavior
- Active state: color change only
- No size jumps
- No animations unless explicitly designed

---

## 8. Toolbars

### Top Toolbar
- Compact height
- Clear active tool state
- Icons only (text rarely)
- No clutter

### Side Toolbars (Pen Box)
- Vertical layout
- Presets clearly distinguishable
- Visual hierarchy: shape → thickness → color
- Long press for secondary actions

---

## 9. Panels

- Floating card-style panels
- Never block canvas center
- One panel visible at a time
- Panels open close to the related tool

### Panel Content
- Simple controls
- No nested complexity
- Immediate visual feedback

---

## 10. Animations & Transitions

- Subtle and fast
- Ease-out only
- No bouncy or playful animations
- UI should feel responsive, not animated

---

## 11. Responsive Principles

### Tablet (Primary Target)
- Landscape-first
- Generous canvas space
- Toolbars feel natural and reachable

### Phone (Secondary Target)
- More compact UI
- Panels may overlay canvas
- No attempt at perfect parity with tablet

---

## 12. What to Avoid (Very Important)

- Default Material look & feel
- Large paddings
- Strong shadows
- Bright UI colors
- Excessive borders
- Visual noise
- Over-designed components

---

## 13. Reference Material

Visual references are provided in:

