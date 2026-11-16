---
layout: default
title: "Skill — Design Tokens: Tailwind"
shiori_source_id: "FeCIngmaI-"
---

> Wires FigCraft design tokens into a repository that already uses Tailwind CSS (Laravel Blade, React, Go with the Tailwind CLI, static sites): v4 @theme from variable.export, v3 config mapped to CSS variables, modes, and class discipline. Load it from Skill — Build UI from a Design only when the detection check below passes; never add Tailwind to a repository that lacks it.

# Design Tokens: Tailwind

Companion to [Skill — Build UI from a Design](skill-build-ui-from-a-design.md)). The core rules there still apply; this page only covers Tailwind wiring.

## Does this apply?

Use this skill only if the repository already uses Tailwind. Check any of:
- `package.json` lists `tailwindcss`, `@tailwindcss/vite`, `@tailwindcss/postcss` or `@tailwindcss/cli`.
- A stylesheet contains `@import "tailwindcss";` (v4) or `@tailwind base;` (v3).
- A `tailwind.config.js`, `.cjs`, `.mjs` or `.ts` exists (usually v3).
- A Makefile, script or Dockerfile runs the standalone `tailwindcss` binary (common in Go and static sites).
If none match, stop and use [Skill — Design Tokens: Plain CSS](skill-design-tokens-plain-css.md)) instead.

## Tailwind v4
1. Export: `run_command {"command": "variable.export", "params": {"format": "tailwind", "path": "/tmp/design/<file-id>/theme.css"}}`. It contains `@import "tailwindcss";`, an `@theme static { --color-*, --radius-*, --text-*, --spacing-*, --font-* }` block for the default mode, and one override block per other mode, for example `[data-fumika="Dark"] { ... }`.
2. Put it in the stylesheet that already imports Tailwind: `resources/css/app.css` (Laravel with Vite), the CSS imported by `src/main.tsx` (React with `@tailwindcss/vite`), or the CLI input file such as `web/styles/input.css` (Go, static). Keep exactly one `@import "tailwindcss";`.
3. Keep the generated block as a whole and regenerate it from the design when tokens change. Project-only tokens go in a separate `@theme` block below it, with a comment saying they are not from the design.
4. Modes: Tailwind v4 utilities read the CSS variables, so `bg-accent` follows `[data-fumika="Dark"]` on `<html>` without `dark:` classes. If the project needs the `dark:` variant for other things, bind it to the same attribute: `@custom-variant dark (&:where([data-fumika="Dark"], [data-fumika="Dark"] *));`.
5. Go and static sites build with the standalone CLI, no Node at runtime: `tailwindcss -i web/styles/input.css -o web/static/app.css --minify`. Add `@source "../templates";` (or the folder with `.templ`, `.tmpl` or `.html` files) when classes live outside the automatically scanned paths.

## Tailwind v3
- The `tailwind` export is v4 syntax; do not paste it into a v3 project and do not upgrade Tailwind as a side effect.
- Use the `css` export as `tokens.css` (custom properties on `:root` and the mode selectors), import it before the Tailwind layers, and map names in `tailwind.config.*`: `theme.extend.colors.accent = 'var(--color-accent)'`, likewise for radius, spacing and font families.

## Class discipline
- Use token utilities only: `bg-surface`, `text-muted`, `border-border`, `rounded-md` if the radius token is named that way. No arbitrary values such as `bg-[#5D6782]` or `p-[13px]`; a missing value becomes a new token.
- Repeated class sets belong in the project's component unit (Blade component, React component, templ component, html/template partial), not in `@apply` chains everywhere. Use `@apply` only where the project already does.
- `inspect.code` with `tailwind` gives React + Tailwind v4 reference markup (add `mobile: <mobile-frame-id>` for mobile-first classes). Read it for spacing and type values only; its absolute positions and raw hexes never go into the code.
- Breakpoints: the project's configured ones, else the defaults `sm` 640, `md` 768, `lg` 1024, `xl` 1280\.
- Focus and motion helpers: `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent`, `motion-safe:` and `motion-reduce:`.

## Checks
- Search the diff for `[#`, `-[`, and `#` inside class attributes; each hit is a missing token or a bug.
- Visual QA and accessibility checks: [Skill — Web UI Checks (Playwright + axe)](skill-web-ui-checks-playwright-axe.md)), or [Skill — UI in React + TypeScript](skill-ui-in-react-typescript.md)) for React specifics.
