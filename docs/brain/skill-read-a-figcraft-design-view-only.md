---
layout: default
title: "Skill — Read a FigCraft Design (View-Only)"
shiori_source_id: "cPnAwyN3xu"
---

> Opens a FigCraft design from a view-only share link through the FigCraft MCP and turns it into implementation inputs: a frame inventory, design tokens as CSS custom properties or Dart (Tailwind only when the repository already uses it), component and state lists, verbatim copy, and reference PNG/SVG exports. Use whenever a ticket or person hands you a FigCraft link, join code or file id. Read-only: never edits, comments on or publishes the design, and never commits the share token.

# Read a FigCraft Design (View-Only)

You received a FigCraft design to implement, usually as a view-only link. Your job here is to extract everything the build needs, accurately, without changing the design and without leaking the link. Building the UI is covered by [Skill — Build UI from a Design](skill-build-ui-from-a-design.md)).

All calls below go through the FigCraft MCP (`figcraft-cli mcp`, tested on 0.18.0). The named tools are `open_file`, `inspect_document`, `get_node`, `export`, `screenshot`, `select`, `list_commands` and `run_command`. Everything else is a command run with `run_command {"command": "<id>", "params": {...}}`. If no FigCraft MCP is configured in your environment, stop and say so; do not scrape the web app.

## Hard rules
1. **The share link is a secret.** It carries a token. Never put it in a commit, branch name, PR, issue, code comment, log line, fixture, screenshot name or test. Reference the design by its file id only (for example `FigCraft file aebb273c0bceb09e`).
2. **Read-only.** Do not run mutating commands (anything marked `*` in `list_commands`, `set_properties`, `create_node`, `type_text`, `comment.*` writes, `collab.publish`, `collab.share`, `collab.manageFile`, `version.*` changes). With a view link they are refused anyway; do not look for a way around it.
3. **Never paste raw MCP output into the repository.** `collab.join` and `collab.peers` echo the full link, token included, in `link`, `url` and `sessions[].link`.
4. **Write exports outside the repository** (for example `/tmp/design/<file-id>/`), then copy only the assets the build needs. The output folder must already exist: `export` and `variable.export` fail with `No such file or directory` otherwise.

## 1\. Join from the link

Link shapes you may receive (placeholders, never real values):
- Server share link: `figcraft://join?server=wss://<host>/<path>/&file=<file-id>&token=<view-token>`
- Local-network link: `figcraft://join?host=<ip>:<port>&file=<id>&token=<token>`
- Team link with no secret: `figcraft://join?server=…&file=…&team=1`
- Short join code such as `K7M-2QX-9TD`. A code is resolved against the server set in FigCraft Preferences, which in a headless MCP is the built-in server, not ours. Ask for the full link instead of a code.

Steps:
1. Join: `run_command {"command": "collab.join", "params": {"link": "<link from the ticket author, never written down>"}}`. It returns `status: "connecting"` and opens the file in a new tab.
2. Find the tab: `run_command {"command": "doc.list"}` returns `[{index, id, name, active}]`. Note the `id` of the joined file and pass it as `document` on every later call, so you never act on the wrong tab.
3. Confirm it is live and what you may do: `run_command {"command": "collab.peers", "document": <id>}`. Expect `status: "live"`, `role: "guest"`, `access: "view"`, `readOnly: true`. On `failed`, read `reason`, try `run_command {"command": "collab.reconnect", "document": <id>}` once, then stop and report.
4. Save a local working copy if the session may drop during a long task: `save_file {"document": <id>, "path": "/tmp/design/<file-id>/design.figcraft"}`. Allowed on a view-only tab. Keep it out of the repository; later you can reopen it with `open_file`.
5. When finished: `run_command {"command": "collab.leave", "document": <id>}`.

If you were given a `.figcraft`, `.fig`, `.penpot` or REST JSON file instead of a link, use `open_file {"path": "..."}` and skip the join.

## 2\. Inventory pages and frames
1. `run_command {"command": "page.list"}` returns pages with `id`, `name` and child count.
2. For each relevant page: `get_node {"id": <page-id>, "depth": 1, "fields": ["name", "type", "width", "height"]}`. Page ids work as node ids. This lists the top-level frames (screens) with sizes.
3. Read a screen's structure cheaply: `get_node {"id": <frame-id>, "depth": 6, "outline": true}`. Outline gives id, name, type and the first 120 characters of text per layer.
4. Find things by text or name: `run_command {"command": "node.find", "params": {"root": <page-id>, "text": "Stopped by", "limit": 20}}` (also `name`, `type`, `component`). Returns `{ids, total}`.
5. Check handoff markers: `run_command {"command": "inspect.readyForDev", "params": {"status": "any"}}`. An empty list means nobody marked frames; the ticket defines scope.
6. Check the version you are reading: `run_command {"command": "version.list"}`. Record the newest version name in your notes or PR so later diffs are traceable.
7. Read open design comments: `run_command {"command": "comment.list", "params": {"page": "all", "filter": "open"}}`.

Write a short inventory in your working notes: page, frame name, frame id, size, light or dark, breakpoint (desktop, mobile), state (default, empty, loading, error, stopped, confirm dialog). Frame names usually encode these, for example `Endpoint detail · backend unreachable — light`.

## 3\. Pull the tokens

Variables are the source of truth for colour, radius, spacing and type tokens. Pick the export format by what the repository already uses; the matching companion skill (linked from Skill — Build UI from a Design) says where the file goes.
- List them: `run_command {"command": "variable.list"}` returns collections, modes (for example `Light`, `Dark`) and raw values.
- **Web, default:** CSS custom properties, `run_command {"command": "variable.export", "params": {"format": "css", "path": "/tmp/design/<file-id>/tokens.css"}}`. The default mode goes on `:root`, other modes on `[data-<collection>="<mode>"]`. This also works as a readable list of values per mode for any stack.
- **Flutter:** `run_command {"command": "variable.export", "params": {"format": "dart", "path": "/tmp/design/<file-id>/tokens.dart"}}`. Writes `import 'dart:ui';` and one `abstract final class` of `static const Color ...` per collection and mode (for example `Fumika` for the default mode), to be wrapped in a `ThemeExtension`.
- **Only if the repository already uses Tailwind v4:** `"format": "tailwind"` writes `@import "tailwindcss";`, an `@theme static` block and per-mode overrides. Never use it to introduce Tailwind.
- Without `path` the export comes back as `{text}`.
- Styles: `run_command {"command": "style.list"}`. Often empty. In that case typography comes from the text layers (see section 5).

Layers are often not bound to variables. A fill may be a raw `#A8362B` even though `--color-danger` is `#A8362B`. Map every raw hex back to its token by value, per mode. If a colour has no token, list it as a gap and ask; do not invent a new token silently.

## 4\. Components and states
- `run_command {"command": "component.list"}` returns `[{id, name, type, page, instances, folder, label}]`. Variants are often separate components with slash names such as `Button/Primary/Default` and `Button/Primary/Hover`, not one component set. The list can also be empty when screens were drawn without components; then derive components from repeated layer names (`Button`, `Badge`, `Field`, `Dialog · Step-up`).
- For a real component or instance: `run_command {"command": "component.properties", "params": {"id": <id>}}` and `run_command {"command": "inspect.componentCode", "params": {"id": <id>, "language": "react"}}` (or `flutter`, `vue`).
- States live in separate frames, not in hover tricks. Collect every variant per screen: default, empty, loading, error, success, disabled, permission-denied, destructive confirm, light and dark, desktop and mobile. Missing ones go to the gap list.

## 5\. Exact values and copy
- Properties panel as data: `run_command {"command": "inspect.properties", "params": {"id": <layer-id>}}` gives size, position, font family, style, size, line height, letter spacing, fills, strokes and effects, with style or variable names when bound.
- Raw fields: `get_node {"id": <layer-id>, "depth": 0, "fields": ["characters", "fontFamily", "fontSize", "fontStyle", "lineHeight", "letterSpacing", "fills", "boundVariables"]}`.
- Fonts in use: `run_command {"command": "file.fontReport"}`.
- Generated reference code: `run_command {"command": "inspect.code", "params": {"id": <frame-id>, "language": "html"}}`. Tested languages: `html` (markup plus a `<style>` block), `react`, `flutter`, and `tailwind` (React with Tailwind v4 classes; `mobile: <mobile-frame-id>` gives mobile-first classes). The command reference also lists `css`, `vue`, `swiftui`, `compose`, `leptos` and `arkui`.
- There is no output for Blade, Go html/template, templ or static-site templates. Read `html` for those (or `tailwind` when the repository uses Tailwind) and translate into the project's own templates and tokens.
- Use generated code to read measurements only. When the design has no auto layout or variable bindings it emits absolutely positioned boxes and raw hex values. Never paste it as production code.
- Copy: take `characters` verbatim, including punctuation such as `·` and curly quotes, capitalisation and placeholder brackets. Demo values in frames (names, times, counts) are sample data, not strings to hard-code.

## 6\. Export visual references
- One frame to PNG at 2x: `export {"document": <id>, "ids": [<frame-id>], "format": "png", "scale": 2, "path": "/tmp/design/<file-id>/<frame-slug>@2x.png"}`.
- Icons or the logo to SVG: `export {"ids": [<layer-ids>], "format": "svg", "path": ".../mark.svg"}`. Several ids are composited into one file. Add `"svgOutlineText": false` to keep `<text>` elements.
- Quick look without writing a file: `screenshot {"ids": [<frame-id>], "maxSize": 1600}`.
- All icons and images under a frame: `run_command {"command": "inspect.assets", "params": {"ids": [<frame-id>]}}` lists them; `run_command {"command": "file.exportLayers", "params": {"ids": [<frame-id>], "assets": true, "dir": "/tmp/design/<file-id>/assets"}}` writes them (icons as SVG, images as PNG; it creates `dir`).
Name exports after the frame, for example `endpoints-stopped-light@2x.png`. These are the targets for the visual QA loop in the build skill.

## 7\. Missing frames and conflicts

Resolve in this order:
1. The ticket or issue copy beats frame text. Tickets often fix wording after the design was drawn.
2. The design beats your own taste and beats ad-hoc guesses: spacing, colours, type, layout and states come from the file.
3. Tokens beat raw values. If a layer's hex and a token disagree slightly, use the token and note it.
4. Desktop and mobile frames are separate sources. Do not derive mobile from desktop when a mobile frame exists.
5. A state with no frame: build it from the closest existing pattern in the same file (same banner, same empty-state layout), keep it minimal, and list it in the PR under "Not in design, derived from …". Do not invent a new visual language.
6. A real contradiction you cannot resolve (two frames disagree, copy conflicts with a ticket you cannot see): ask before building that part.

## Output of this skill

Before writing UI code, have these ready (in notes or the PR description, never with the link):
- File id, version name, list of frames in scope with ids.
- Token file(s) generated from `variable.export`, plus a list of raw colours with no token.
- Component list with variants and states, and the gap list.
- Verbatim copy per screen.
- Reference PNGs for each frame in scope, stored outside the repository.

## View-only limits (verified)
- Edits are refused with `View only: the link you joined with lets you see this file, not change it`. This covers `set_properties` (`node.set`) and `comment.add`.
- Allowed: every read listed above, `select`, `screenshot`, `export`, `variable.export` (also with `path`), `inspect.*` and `save_file` to a local path.
- A comment link (`access: "comment"`) allows comment threads only, per the command reference. Even then, ask a human before commenting on someone's design.
- Tested with figcraft-cli 0.18.0. `collab.reconnect` and comment links come from `list_commands` and were not exercised. When a command behaves differently, trust `list_commands {"filter": "<word>"}` over this page.
