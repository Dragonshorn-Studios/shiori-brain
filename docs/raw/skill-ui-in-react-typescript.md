> Builds React + TypeScript UI from a FigCraft design: typed component variants, state coverage through fixtures and mocked APIs, Testing Library and axe checks, and the styling approach the repository already has (Tailwind, CSS modules or plain CSS). Load it from Skill — Build UI from a Design when package.json lists react and typescript.

# UI in React + TypeScript

Companion to [Skill — Build UI from a Design](skill-build-ui-from-a-design.md)). Styling is not decided here: use [Skill — Design Tokens: Tailwind](skill-design-tokens-tailwind.md)) if the repository uses Tailwind, else [Skill — Design Tokens: Plain CSS](skill-design-tokens-plain-css.md)).

## Does this apply?

`package.json` lists `react` and `typescript` (often with `vite`). Check `src/` for the existing components folder, routing, data fetching and test setup before adding anything.

## Components
- One component per design element in the existing components folder; variants as union types: `type ButtonProps = { variant?: 'primary' | 'secondary' | 'danger'; size?: 'sm' | 'md' } & React.ButtonHTMLAttributes<HTMLButtonElement>`.
- Render native elements (`button`, `a`, `input`, `dialog`) and forward their props; do not rebuild them from `div`.
- Class merging and variant helpers: only what the project already uses.
- Tokens needed in TypeScript (charts, canvas): read the CSS variable at runtime, `getComputedStyle(document.documentElement).getPropertyValue('--color-accent').trim()`. Do not copy hexes into TS files.
- `inspect.componentCode` with `react`, and `inspect.code` with `react` or `tailwind`, are reference only: they use absolute positions and raw colours.
- No new UI kit, headless library, CSS-in-JS or Storybook without approval.

## States
- Model loading, empty, error, success and permission explicitly (for example a discriminated union `{ status: 'loading' } | { status: 'error'; error } | { status: 'ready'; data }`), so every frame state has a code path.
- Make each state reachable for QA through the project's fixtures, mocks or dev routes.

## Checks
- `tsc --noEmit` (or the project's typecheck script) and the project's lint.
- Component tests, if the project has Testing Library: query by role and label (`getByRole('button', { name: 'Set secret' })`); a query that only works by test id is a label bug.
- Screenshots and axe: [Skill — Web UI Checks (Playwright + axe)](skill-web-ui-checks-playwright-axe.md)), with `npm run dev` or `vite preview` and `page.route` for API states.
