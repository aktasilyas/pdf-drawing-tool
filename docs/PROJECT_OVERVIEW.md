# Project Overview

## What is this project?

This project is a **StarNote-like drawing and note-taking platform** built with Flutter.

It has TWO equally important goals:

1. A **production-grade end-user application**
2. A **reusable, high-quality drawing library** to be published on pub.dev

The same codebase serves both purposes.

---

## Core Principles

- Library-first architecture
- UI and drawing engine are strictly separated
- Clean Architecture and Clean Code
- Performance-sensitive drawing engine
- Extensible design (tools, AI, premium features)

---

## Phase-Based Development

### Phase 1 (COMPLETED)
- UI Skeleton only
- No real drawing logic
- Mock state and placeholders
- Golden and widget tests
- UI is now considered FROZEN

### Phase 2 (CURRENT)
- Drawing core domain models
- Stroke, tool, renderer contracts
- No UI changes
- No performance optimization yet

### Phase 3 (UPCOMING)
- Undo/Redo execution
- Selection and eraser logic
- AI and premium integration (app layer only)

---

## What this project is NOT

- Not a quick prototype
- Not a monolithic app
- Not UI-driven architecture
- Not a hacky Canvas demo

---

## Important Constraints

- drawing_core must be UI-agnostic
- drawing_ui must not contain business logic
- example_app must not leak logic into the library
- No phase skipping
- No speculative features

---

## Reference Products

- StarNote (primary UX reference)
- GoodNotes
- Notability

---

## Final Goal

To produce:
- A scalable drawing engine
- A polished application
- A pub.dev-quality open-source library
