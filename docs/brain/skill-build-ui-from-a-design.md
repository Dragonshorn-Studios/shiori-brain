---
layout: default
title: "Skill — Build UI from a Design"
shiori_source_id: "jB0f1VJ1LX"
---

> Implements UI from a FigCraft design in any stack: detect the stack, load the matching companion skills, then apply a stack-neutral core of tokens first, semantic structure, every state, hard accessibility checks, a real mobile layout, a screenshot-versus-frame QA loop and a definition of done. Never introduces Tailwind or a new design system into a repository that lacks it. Use after Skill — Read a FigCraft Design (View-Only), or whenever you build or restyle screens that have a design.

# Build UI from a Design

The design is the spec. Your job is to reproduce its structure, character and states in maintainable code, and prove it with screenshots. First extract the inputs with [Skill — Read a FigCraft Design (View-Only)](skill-read-a-figcraft-design-view-only.md)): frame inventory, tokens, components and states, verbatim copy, reference PNGs.

Repository rules (`AGENTS.md`, `.ai/rules/`) and the ticket win over this page. Reuse the repository's existing components, build and styling approach.

## 0\. Detect the stack, then load companions

Look at the repository before writing anything, and load every companion that applies:
- **Tailwind already in use** (`tailwindcss` or `@tailwindcss/*` in `package.json`, `@import "tailwindcss";` or `@tailwind` in a stylesheet, a `tailwind.config.*`, or a `tailwindcss` binary in the build): [Skill — Design Tokens: Tailwind](skill-design-tokens-tailwind.md)).
- **Web UI without Tailwind** (Go `html/template` or templ, static HTML, Blade with its own CSS, React with CSS modules or plain stylesheets): [Skill — Design Tokens: Plain CSS](skill-design-tokens-plain-css.md)).
- **React + TypeScript** (`react` and `typescript` in `package.json`): [Skill — UI in React + TypeScript](skill-ui-in-react-typescript.md)), together with one of the two token skills above.
- **Any web UI**: [Skill — Web UI Checks (Playwright + axe)](skill-web-ui-checks-playwright-axe.md)) for screenshots and accessibility checks.
- **Flutter** (`pubspec.yaml` with the `flutter` SDK dependency): [Skill — UI in Flutter](skill-ui-in-flutter.md)).
- Laravel projects also follow Laravel & PHP Applications, Go projects Go Services & CLIs, TypeScript projects TypeScript Services & Automation.

Never introduce Tailwind, a CSS-in-JS library, a UI kit, a component framework, Storybook or a new design system into a repository that lacks it. Do not upgrade the styling stack as a side effect. If the existing approach really cannot express the design, stop and ask.

## 1\. Tokens first
- Tokens come from the design's variables via `variable.export`: `css` (CSS custom properties) for web and `dart` for Flutter. Use the `tailwind` format only when the repository already uses Tailwind. The companion says where the file lives.
- Keep the generated tokens in exactly one file and regenerate it from the design instead of hand-editing values. Project-only tokens go in a separate, clearly named place.
- **No magic values** in components, templates or widgets: no raw hex, no inline `style` colours, no arbitrary utility values, no `Color(0xFF...)` in widgets, no one-off pixel sizes when a spacing or radius token exists.
- A value the design uses that has no token: add a semantic token, list it in the PR. Never inline it.
- Modes (light, dark) follow the export: one set of names, values switched per mode (the `[data-<collection>="<mode>"]` selector on the web, light and dark theme instances in Flutter). Never a second hand-made dark palette.
- Fonts: the families from `file.fontReport`, loaded the way the repository already loads fonts, only the weights used.

## 2\. Structure and semantics
- Build from the outside in: shell, page layout, sections, components. Flow layout (flex, grid, rows, columns) with gaps; never absolute positions copied from `inspect.code`.
- Use the platform's semantic elements: on the web `header`, `nav`, `main`, headed `section`s, `button` for actions, `a` for navigation, `table` for tabular data, labelled form controls, an accessible dialog; one `h1` per page with headings in order. Flutter equivalents are in its companion.
- One reusable unit per repeated design element (button, badge, field, card, banner, dialog) with variants as parameters, in whatever the stack calls a unit: component, partial, template, widget.
- Copy exactly as in the ticket or frame, including `·`, quotes and capitalisation, through the project's translation helper if one exists.

## 3\. Every state, not just the happy path

For every screen and component, implement and make reachable:
- **Empty**: the design's empty frame, with its call to action.
- **Loading**: skeleton or spinner as drawn; no layout jump when data arrives. Server-rendered pages still need pending states for forms and buttons.
- **Error**: inline field errors, a banner or panel for page errors, retry where drawn. Never a blank screen.
- **Success**: confirmation as drawn.
- **Permission or locked**: disabled control with the reason shown, or the locked-row pattern.
- **Destructive confirm**: the confirm dialog, focus on the safe action, the destructive one clearly labelled.
- **Interaction**: hover, pressed, focus, disabled, selected. Missing ones are derived from tokens and noted.
- **Light and dark** if the design has both.

## 4\. Accessibility as hard checks

Pass or fail, in every mode. The companions name the tools.
- Contrast: body text at least 4.5:1; large text (24px, or 18.66px bold) and UI parts such as input borders, focus indicators and icons at least 3:1. Check token pairs, not one screen.
- Focus: visible focus on every interactive element, at least 2px and 3:1 against its background. Focus order follows reading order; dialogs trap focus, return it on close and close on Escape or back.
- Targets: at least 44x44 CSS px on the web, 48x48 dp in Flutter, including icon buttons and row actions.
- Labels: every control has an accessible name; errors are tied to their field and announced.
- Status never by colour alone: colour plus icon plus text.
- Motion: honour the platform's reduced-motion setting; no information only in animation.
- Scaling: 200% browser zoom and large system text (Flutter text scale 2.0) without clipping or overlap.

## 5\. Mobile is its own design
- If mobile frames exist, implement them as drawn; do not shrink the desktop layout.
- Primary actions in the thumb zone when the mobile frame puts them there; secondary actions in a menu or sheet.
- Respect safe areas (notch, home indicator, rounded corners).
- Tables become cards or stacked rows on narrow screens as drawn. Never horizontal page scroll.
- Breakpoints: the project's own; otherwise mobile first, switching layouts around 640, 768, 1024 and 1280px, with the desktop layout where the desktop frame fits. Check widths 360, 390, 768, 1024, 1280 and 1440.
- Without a mobile frame: keep tokens and components, collapse navigation, stack columns, keep target sizes, and list the screen in the PR as "mobile derived".

## 6\. Keep the design's character

Reproduce what is drawn, not a generic dashboard. Unless the design has them, do not add:
- Purple or blue SaaS gradients, glow, glassmorphism or blurred backgrounds.
- Inter, Roboto or the system font everywhere instead of the families in the file.
- Pill buttons everywhere, oversized radii, or one radius for everything.
- Heavy shadows on every card, emoji as icons, a different icon set than the design's.
- Framework default looks: stock Material purple, default Cupertino blue, unstyled library themes.
- Extra hero sections, illustrations, marketing copy or decorative badges.
A quiet design (paper backgrounds, thin borders, serif wordmark, one accent) stays quiet. Colours marked as ornament stay ornament: never text or status.

## 7\. Visual QA loop

Repeat until no fixable differences remain. The companion for your stack gives the commands.
1. Run the app with seed or demo data matching the frame's sample content.
2. Screenshot each implemented state at the frame's size (for example 1440x900 desktop, 390x844 mobile) at 2x, in every mode.
3. Compare side by side with the exported frame PNG (`<frame-slug>@2x.png`). Look at both; an image diff only helps find areas.
4. List the differences: element, expected (design), actual (build). Example: `Stopped banner body: 13px IBM Plex Sans danger colour; build uses 14px muted`.
5. Fix them and repeat from step 2.
6. Keep only intentional differences, each listed in the PR with its reason (real data length, platform control, accessibility fix).
Screenshot tooling is development-only. Do not commit screenshots, exports or a new test framework unless the repository already keeps visual baselines.

## 8\. Definition of done
- [ ] Stack detected and the matching companion skills followed.
- [ ] One generated token file in the format the repository already uses; no raw hex or arbitrary values in components, templates or widgets.
- [ ] No Tailwind, UI kit, Storybook or design system introduced where there was none.
- [ ] Every frame in scope implemented, in every mode the design has, and on mobile.
- [ ] Empty, loading, error, success, permission and confirm states exist and are reachable.
- [ ] Copy matches the ticket or frame verbatim.
- [ ] Contrast, focus, targets, labels, reduced motion, scaling and non-colour status pass with the stack's tooling.
- [ ] Keyboard (web) or screen reader (Flutter) walk-through of the flow works, including dialogs.
- [ ] Visual QA loop done for each state at desktop and mobile sizes; remaining differences listed with reasons.
- [ ] No share link or token anywhere in the diff, PR, commits or logs; the design is referenced by file id only.
- [ ] Project lint, typecheck, tests and formatter pass.
- [ ] PR lists derived states, derived mobile layouts, new tokens and open design questions.
