# mydictionary.org

The website for [My Dictionary](https://apps.apple.com/app/id1588418793), served by GitHub Pages from
`main` (`CNAME` → mydictionary.org). Pushing to `main` deploys it.

It lives as the `MyDictionaryWebsite/` submodule of the app repo: commit here first, then commit the
updated submodule pointer in the app repo.

## Pages

| Path | What |
|---|---|
| `index.html` | Landing page: hero, four features, Mac + MCP, reviews, FAQ |
| `privacy-policy.html`, `terms-of-use.html`, `legal.html` | Legal pages (linked from the app and App Store) |
| `docs/mcp/` | MCP server setup (linked from the Mac app) |
| `pack/`, `packs/`, `apple-app-site-association`, `.well-known/` | Vocabulary-pack universal links (notes in the local, git-ignored `Documentation/ASSOCIATED_DOMAINS.md`) |
| `ar/ de/ es/ fr/ hr/ ja/ ko/ ru/ uk/` | Redirects from the old translated pages to English |

All pages share `css/site.css` (the "duck editorial" palette of the App Store screenshots: cream,
forest green, green-boxed key phrase; light and dark). No build step and no JavaScript besides a few
inline lines.

## Images

`images/site/*.webp` are built from the App Store screenshot sources in the app repo
(`docs/ASO/screenshots/source`, `docs/ASO/DuckPNG`):

```bash
python3 scripts/build_images.py
```

## Facts on the page

The rating (4.8, 101 ratings) and the three review quotes are real (App Store Connect / App Store,
October 2026). Update them from App Store Connect rather than writing new ones.
