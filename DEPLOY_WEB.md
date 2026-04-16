# Deploy Gridloq Web (Netlify)

Netlify free tier works for this project.

## Fastest path (no Netlify build setup)

1. Build locally:
   - `flutter build web --release`
2. In Netlify, create a new site.
3. Drag and drop the `build/web` folder into Netlify Deploys.

This is the quickest way to share a playable URL.

## Optional CLI flow

1. Install Netlify CLI:
   - `npm i -g netlify-cli`
2. Build web:
   - `flutter build web --release`
3. Deploy:
   - `netlify deploy --dir=build/web --prod`

## Notes

- `netlify.toml` is included with SPA fallback redirect:
  - all routes -> `index.html`
- If you later want Netlify to build Flutter itself, you'll need a Flutter install step in Netlify build environment.
