---
name: react-bits-animated-ui
description: Add animated React components from React Bits (reactbits.dev — text animations, backgrounds, micro-interactions, cards, galleries) to a Power Apps code app, SPFx web part or custom React/Vite app — install with the shadcn or jsrepo CLI, choose the TS/JS and CSS/Tailwind variant, keep the licence (MIT + Commons Clause) respected, respect prefers-reduced-motion, keep bundles small, and stay inside the code app Content Security Policy. Use when someone asks to "make the app look modern", add animations, an animated background, split/typewriter text, count-up numbers, hover effects, or mentions React Bits.
---

# Animated UI with React Bits

## Purpose
- **What it does:** a safe way to use React Bits components in business apps: install, adapt, make accessible, keep fast, and keep within platform rules (code app CSP, SPFx bundles).
- **When to use it:** dashboards, welcome banners, empty states, celebrations ("task done"), landing screens — places where motion helps people notice something.
- **Expected outcome:** a few purposeful animations that switch off for users who ask for reduced motion, add little to the main bundle, and pass the CSP of the target host.

## Expertise
- **What React Bits is:** an open-source library of animated React components by David Haz — README: 215+ components in Text Animations, Animations, Components, Micro-interactions and Backgrounds; official Vue and Svelte ports; a paid Pro tier **[React Bits]**.
- **Components are copied into your project as source** (you own and edit them), like shadcn/ui — not an npm runtime dependency **[React Bits]**.
- **Four variants per component:** JavaScript or TypeScript × plain CSS or Tailwind, chosen by the suffix `-JS-CSS`, `-JS-TW`, `-TS-CSS`, `-TS-TW` **[React Bits]**.
- **UX practice:** in business apps motion is a signal, not decoration. One animated element per screen is usually enough.

## Instructions

### Design approach
1. Pick by purpose:
   | Purpose | Category (examples from the site) |
   |---|---|
   | Draw attention to a heading / number | Text Animations (e.g. Split Text, count-up style text) |
   | Feedback on an action | Micro-interactions (buttons, toggles, indicators) |
   | Hero / empty state | Backgrounds (gradients, particles, shader effects) |
   | Browsing content | Components (cards, carousels, galleries) |
2. Prefer **CSS-only or light** components in forms and lists. Keep WebGL backgrounds (three.js / OGL / react-three-fiber based) for one-off screens.
3. Match your design tokens (colours, radius, font) — edit the copied source rather than layering overrides.

### Development standards
- **Install** (per the React Bits docs) **[React Bits]**:
  ```bash
  # shadcn CLI (project with components.json)
  npx shadcn@latest add @react-bits/SplitText-TS-CSS
  # jsrepo (no shadcn setup needed)
  npx jsrepo@latest add https://reactbits.dev/r/SplitText-TS-CSS
  ```
  Registry entry for `components.json`:
  ```json
  { "registries": { "@react-bits": "https://reactbits.dev/r/{name}.json" } }
  ```
  Or copy the code from the component's **Code** tab and install the dependencies it lists.
- Use the **TS** variant in TypeScript projects and the **CSS** variant unless the project already uses Tailwind.
- Put copied components in `src/components/react-bits/` with a header comment: source URL, variant, date copied, and your changes.
- **Dependencies vary by component.** The React Bits repo itself depends on, among others, `gsap`, `motion`, `three`, `@react-three/fiber`, `@react-three/drei`, `ogl`, `matter-js` **[React Bits package.json]**. Install only what the chosen component's Code tab lists, then check bundle size.
- **Reduced motion (required).** React Bits docs don't describe reduced-motion handling, so add it yourself:
  ```tsx
  import { useEffect, useState } from 'react';
  export function usePrefersReducedMotion(): boolean {
    const query = '(prefers-reduced-motion: reduce)';
    const [reduced, setReduced] = useState(() =>
      typeof window !== 'undefined' && window.matchMedia?.(query).matches === true);
    useEffect(() => {
      const mq = window.matchMedia?.(query);
      if (!mq) return;
      const onChange = () => setReduced(mq.matches);
      mq.addEventListener('change', onChange);
      return () => mq.removeEventListener('change', onChange);
    }, []);
    return reduced;
  }
  // usage: reduced ? <h1>{title}</h1> : <SplitText text={title} />
  ```
- **Lazy-load heavy components:**
  ```tsx
  const Aurora = lazy(() => import('./components/react-bits/Aurora'));
  <Suspense fallback={<div className="hero-fallback" />}>{!reduced && <Aurora />}</Suspense>
  ```
- Animations must not block input or hide content: text is in the DOM for screen readers, focus order unchanged, no flashing more than 3 times per second (WCAG 2.3.1).

### Governance and licensing
- **Licence: MIT + Commons Clause** **[React Bits LICENSE.md]**. You may use, modify and ship components *as part of* an application, website or product, including commercial ones. You may **not** sell, sublicense or redistribute the components themselves (alone or as a pack), or offer the React Bits tools as a hosted service.
- Practical rules:
  - OK: components inside your company's code app, SPFx web part or client project.
  - Not OK: publishing a "component pack" or template repo that is mostly React Bits source; copying component source into a **public skills/docs repo** (link to the component instead).
  - Some tool exports are adapted from Apache-2.0 / MIT third-party shaders; keep their notices **[React Bits]**.
- Record every copied component (name, variant, URL) in `THIRD_PARTY.md` in the app repo.

### Security
- Copied source is your code now: review it like any PR (no remote script loading, no `eval`, no tracking).
- Install from the official registry URL only (`https://reactbits.dev/r/...`).

### Performance
- WebGL components add a large chunk and use the GPU continuously; pause them when off-screen or the tab is hidden (`IntersectionObserver`, `document.visibilityState`).
- Check chunk sizes in the `vite build` output; keep the initial chunk free of `three`/`ogl`.
- Cap device pixel ratio for canvases (`Math.min(window.devicePixelRatio, 2)`).
- Test on a low-end laptop and in the Power Apps player, not only in `npm run dev`.

### Platform rules (where the component runs)
| Host | Rule | Effect on React Bits |
|---|---|---|
| Power Apps code app | CSP default `img-src 'self' data:`, `font-src 'self'`, `worker-src 'none'`, `connect-src 'none'` **[Microsoft]** | Bundle textures/images/fonts locally (or `data:` URLs); no CDN fonts; components that use Web Workers or fetch remote assets fail unless an admin changes CSP |
| Power Apps code app | `blob:` image URLs blocked in the player **[Field-tested]** | Convert generated images to `data:` URLs |
| SPFx | Bundle size affects page load for every visitor | Lazy-load; prefer CSS variants |
| Any | Users with vestibular disorders | `prefers-reduced-motion` fallback |

### ALM
- Components are source in your repo → normal code review, lint and tests.
- Re-copying a newer version is a manual diff; note the date copied so you know what changed.

## Examples

### Beginner — animated welcome heading
`npx jsrepo@latest add https://reactbits.dev/r/SplitText-TS-CSS` → `<SplitText text={`Welcome, ${firstName}`} />` with the reduced-motion fallback.

### Intermediate — "task done" celebration in a code app
A micro-interaction or confetti-style effect triggered after a successful save, only when the save succeeded (never optimistic), shown once, with a text toast that screen readers announce (`role="status"`).

### Advanced (enterprise) — dashboard hero with a WebGL background
Lazy-loaded background component, paused when hidden, disabled for reduced motion and on low-power devices (`navigator.hardwareConcurrency <= 4`), all assets bundled to satisfy code app CSP, verified in the player with DevTools → Console filtered for CSP errors, and the chunk size recorded in the PR.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Animations everywhere | Slow, distracting app | One purposeful effect per screen |
| No reduced-motion fallback | Accessibility failure | `usePrefersReducedMotion` |
| WebGL in the initial bundle | Slow first load | `lazy()` + `Suspense` |
| Remote fonts/textures in a code app | Blocked by CSP, blank effect | Bundle assets / `data:` |
| Copying React Bits source into a public repo or selling a pack | Licence breach (Commons Clause) | Link to the component; use only inside products |
| Tailwind variant in a non-Tailwind app | Unstyled component | Use the `-CSS` variant |

## Validation checklist
### Security
- [ ] Copied source reviewed; installed only from `reactbits.dev/r/`
- [ ] Licence respected; component recorded in `THIRD_PARTY.md`
### Performance
- [ ] Heavy components lazy-loaded; initial chunk checked
- [ ] Canvas paused when hidden; DPR capped
### ALM
- [ ] Components in `src/components/react-bits/` with source header
### Solution packaging
- [ ] No runtime dependency on external URLs (CSP-safe)
### Deployment readiness
- [ ] Reduced-motion fallback tested (OS setting on)
- [ ] Tested in the real host (Power Apps player / SharePoint page) with the console open

## References
- [React Bits] [GitHub repository](https://github.com/DavidHDev/react-bits) and [licence](https://github.com/DavidHDev/react-bits/blob/main/LICENSE.md)
- [React Bits] [Installation](https://reactbits.dev/get-started/installation) and [MCP setup](https://reactbits.dev/get-started/mcp)
- [Microsoft] [Code apps Content Security Policy](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/content-security-policy)
- [W3C] [WCAG 2.2 — Animation from interactions (2.3.3)](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)
