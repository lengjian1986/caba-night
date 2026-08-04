# CABAKURA Pencil Design Project

This project is the working folder for converting the provided CABAKURA app design images into editable Pencil `.pen` design files.

## Source References

Primary workflow documents:

- `../visual-design-to-pencil-workflow.md`
- `../pencil-mcp-usage-guide.md`

Original design images:

- `../app设计图/`

## Directory Structure

```text
.
├── design/
│   ├── final/              # Final reference exports and selected page images
│   ├── references/         # Cropped references, measurement notes, comparison images
│   └── assets/
│       ├── common/         # Shared UI assets, icons, logos, badges
│       └── pages/          # Page-specific extracted or generated assets
├── docs/                   # Project docs and implementation notes
├── exports/
│   ├── screenshots/        # Pencil screenshots and visual QA exports
│   └── html/               # Optional Pencil HTML exports
├── notes/                  # Work logs, uncertainties, decisions
└── pencil/                 # Saved .pen files when created from Pencil
```

## Critical Pencil Rule

Do not create, read, or modify `.pen` files with command line tools, scripts, or text editors.

Valid `.pen` work must happen through Pencil and Pencil MCP only:

- `get_editor_state`
- `get_guidelines`
- `batch_get`
- `batch_design`
- `snapshot_layout`
- `get_screenshot`
- `export_nodes`
- `export_html`

## Recommended First Pencil File

Create the actual design file in Pencil and save it as:

```text
pencil/cabakura-app.pen
```

After that, all changes should be made through Pencil MCP.

