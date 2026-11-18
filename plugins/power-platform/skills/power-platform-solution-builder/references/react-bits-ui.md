# React Bits animated UI — summary

Read this when the request adds animation to any React UI (code app, SPFx, custom app). Full detail: skill **`react-bits-animated-ui`** (plugin `react`).

- Install as source: `npx jsrepo@latest add https://reactbits.dev/r/<Component>-TS-CSS` or `npx shadcn@latest add @react-bits/<Component>-TS-CSS` **[React Bits]**.
- Licence MIT + Commons Clause: fine inside apps (including commercial); never sell or redistribute the components themselves **[React Bits]**.
- Always add a `prefers-reduced-motion` fallback; lazy-load WebGL components (three / ogl).
- Code apps: CSP blocks remote fonts/images and workers by default — bundle assets **[Microsoft]**.
