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
| `ar/ de/ es/ fr/ hr/ ja/ ko/ ru/ uk/` | The same four pages in each language (generated) |

## Languages

English plus Arabic, German, Spanish, French, Croatian, Japanese, Korean, Russian and Ukrainian,
switched with the language menu in the header. **The pages are generated — don't edit the HTML**:

- strings: `i18n/<lang>.json` (English `i18n/en.json` is the source; every language has the same keys,
  `[[…]]` marks the green-box phrase)
- legal page bodies: `i18n/legal/<lang>/<page>.html`
- then run `python3 scripts/build_pages.py` (also writes `sitemap.xml` and the hreflang tags)

The MCP docs page (`docs/mcp/`) is English only and edited by hand.

All pages share `css/site.css` (the "duck editorial" palette of the App Store screenshots: cream,
forest green, green-boxed key phrase; light and dark). No build step and no JavaScript besides a few
inline lines.

## Images

`images/site/*.webp` are built from the App Store screenshot sources in the app repo
(`docs/ASO/screenshots/source`, `docs/ASO/DuckPNG`). Languages with their own captures get their own
hero, capture, definitions and flashcard pictures in `images/site/<lang>/`; Croatian, Progress and
the Mac picture use the English ones.

```bash
python3 scripts/build_images.py            # English and every language
python3 scripts/build_images.py ja ko      # just these
```

## Facts on the page

The rating (4.8, 101 ratings) and the three review quotes are real (App Store Connect / App Store,
October 2026). Update them from App Store Connect rather than writing new ones.
