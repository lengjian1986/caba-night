# CABAKURA Pencil Restoration Plan

## Goal

Restore the CABAKURA app screens from `../app设计图/` into editable Pencil screens that can be inspected, modified, and handed to development.

The output should not be a flat screenshot pasted into Pencil. Text should remain editable, simple UI should be built from Pencil nodes, and complex artwork or photos should be separated into reusable image fills.

## Execution Flow

1. Open or create `pencil/cabakura-app.pen` in Pencil.
2. Call `get_editor_state({ include_schema: true })`.
3. Load the `Mobile App` guideline with `get_guidelines`.
4. Build a page inventory from `docs/PAGE_INVENTORY.md`.
5. For each page, identify:
   - target screen size
   - top bar and safe area
   - scrollable content area
   - bottom navigation or fixed actions
   - repeated cards, list rows, buttons, labels, and tabs
   - image assets that must be extracted or generated
6. Create one top-level Pencil frame per app screen.
7. Keep any screen being edited as `placeholder: true`.
8. Build structure first, then text, then images and visual refinements.
9. Run `snapshot_layout(problemsOnly: true)` after each complete screen or major section.
10. Run `get_screenshot` for visual QA.
11. Close `placeholder` only after the screen passes checks.

## Component Strategy

Create reusable components for repeated UI:

- bottom navigation item
- shop card
- cast card
- cast detail info row
- order step row
- review card
- coupon card
- support list item
- profile menu item
- primary and secondary buttons

Do not componentize one-off page decoration unless it will be reused.

## Asset Strategy

Use this decision order for every image area:

1. Reuse an existing clean source asset if available.
2. Crop from the supplied design image if the source is clear enough.
3. Rebuild simple icons and shapes in Pencil.
4. Generate or recreate missing complex static artwork only when needed.

Image fills should use semantic, versioned paths, for example:

```text
design/assets/pages/home/hero-shop-v1.png
design/assets/pages/cast/cast-avatar-aoi-v1.png
design/assets/common/icon-heart-v1.png
```

Avoid replacing an image file with the same name after Pencil has loaded it. Use a new versioned filename to avoid cache issues.

## QA Standard

Each completed screen must pass:

- major layout and proportions match the reference
- text is editable and visible
- repeated elements are consistent
- image fill mode is correct: `fit`, `fill`, or `stretch`
- no unintended clipping or layout collapse
- top-level frame is no longer `placeholder`

