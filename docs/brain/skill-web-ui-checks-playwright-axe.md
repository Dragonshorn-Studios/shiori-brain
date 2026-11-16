---
layout: default
title: "Skill — Web UI Checks (Playwright + axe)"
shiori_source_id: "UpAosbdfHO"
---

> Visual QA and accessibility checks for any web UI built from a design (Blade, React, Go html/template or templ, static HTML, with or without Tailwind): Playwright screenshots at the frame sizes, side-by-side comparison with exported frames, axe scans, keyboard and zoom checks. Dev-time tooling only; nothing is added to the runtime.

# Web UI Checks (Playwright + axe)

Companion to [Skill — Build UI from a Design](skill-build-ui-from-a-design.md)). It is the web implementation of its visual QA loop and accessibility checks.

## Does this apply?

Any UI that renders in a browser: Laravel, React, Go, static sites. Flutter web renders to a canvas, so axe cannot see it; use [Skill — UI in Flutter](skill-ui-in-flutter.md)) there.

## Set up without polluting the repository
- If the repository already has Playwright, Dusk, Pest browser tests or Cypress, use that.
- Otherwise run Playwright from a scratch folder outside the repository (`npm init -y && npm i -D playwright @axe-core/playwright && npx playwright install chromium`). Do not add `package.json` or Node tooling to a Go or static repository without approval.

## Run the app
- Laravel: `php artisan serve` (plus `npm run dev` when it uses Vite), or the project's Sail or Herd setup.
- React with Vite: `npm run dev`, or `npm run build && npx vite preview`.
- Go: `go run ./cmd/<app>` (build CSS first if the project has a CSS build step).
- Static: `python3 -m http.server 8000` in the site folder.
Use seed or demo data that matches the frame's sample content.

## Screenshots

```ts
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });
await page.goto('http://localhost:8000/endpoints');
await page.screenshot({ path: 'shots/endpoints-light@2x.png' });
await page.evaluate(() => document.documentElement.setAttribute('data-fumika', 'Dark'));
await page.screenshot({ path: 'shots/endpoints-dark@2x.png' });
await page.setViewportSize({ width: 390, height: 844 });
await page.screenshot({ path: 'shots/endpoints-mobile@2x.png' });
```
- Use the frame sizes from the design inventory and the mode attribute from the token export.
- Reach every state: routes, query flags the app already supports, form submissions, or mocked responses with `page.route('**/api/**', route => route.fulfill({ status: 500 }))`.
- Compare each screenshot side by side with the exported `<frame-slug>@2x.png`, list differences as element, expected, actual, fix, repeat. `compare` from ImageMagick can highlight areas, but look at both images.
- Keep `shots/` out of the repository unless it already stores visual baselines.

## Accessibility
- axe on every state and mode:

```ts
import AxeBuilder from '@axe-core/playwright';
const results = await new AxeBuilder({ page }).analyze();
console.log(results.violations.map(v => `${v.id}: ${v.nodes.length}`));
```

Zero violations is the bar; any exception goes in the PR with its reason.
- Keyboard: walk the flow with `page.keyboard.press('Tab')` and check `document.activeElement`, focus visibility in screenshots, dialog focus trap and `Escape`.
- Zoom and text: screenshot at 200% (`page.evaluate(() => document.body.style.zoom = '2')` as a quick check, or a 720px-wide viewport) and look for clipped text.
- Reduced motion: `browser.newPage({ reducedMotion: 'reduce' })` and confirm nothing essential depends on animation.
- Target size: check icon buttons and row actions measure at least 44x44 CSS px (`await locator.boundingBox()`).
