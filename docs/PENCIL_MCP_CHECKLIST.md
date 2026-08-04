# Pencil MCP Checklist

## Before Editing

- [ ] Pencil editor is open.
- [ ] Target `.pen` file is active and saved in `pencil/`.
- [ ] `get_editor_state({ include_schema: true })` has been called.
- [ ] Correct guideline has been loaded, usually `Mobile App`.
- [ ] Existing nodes have been checked with `batch_get` before modification.

## During Editing

- [ ] Top-level screen being edited has `placeholder: true`.
- [ ] New nodes have semantic names.
- [ ] No ordinary UI nodes are inserted directly under `document`.
- [ ] Text nodes have explicit `fill`.
- [ ] Text width/height only used with proper `textGrowth`.
- [ ] Images are applied as frame or rectangle fills.
- [ ] Layout containers do not rely on child `x/y`.
- [ ] Repeated UI is copied from a representative component or consistent structure.

## After Each Screen

- [ ] `snapshot_layout(problemsOnly: true)` has no unintended problems.
- [ ] A screenshot has been checked against the source image.
- [ ] Intended clipping is documented if layout reports it.
- [ ] Screen placeholder has been set to `false`.
- [ ] Export or screenshot is saved under `exports/screenshots/` if needed.

