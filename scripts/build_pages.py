#!/usr/bin/env python3
"""Generate every page of mydictionary.org in all site languages.

Strings live in i18n/<lang>.json (English is the source; keep the same keys everywhere), legal
page bodies in i18n/legal/<lang>/<page>.html. Edit those, never the generated HTML.

    python3 scripts/build_pages.py

Writes /index.html, /privacy-policy.html, /terms-of-use.html, /legal.html for English and the
same four pages under /<lang>/ for the others, plus sitemap.xml.
"""
import html
import json
import re
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent
I18N = SITE / "i18n"
APP = "https://apps.apple.com/app/id1588418793"
ORIGIN = "https://www.mydictionary.org"  # GitHub Pages serves www; the apex redirects here

# code, name in its own language, right-to-left
LANGS = [
    ("en", "English", False), ("ar", "العربية", True), ("de", "Deutsch", False), ("es", "Español", False),
    ("fr", "Français", False), ("hr", "Hrvatski", False), ("ja", "日本語", False), ("ko", "한국어", False),
    ("ru", "Русский", False), ("uk", "Українська", False),
]
# Languages with their own section pictures (images/site/<lang>/); the rest use the English ones.
OWN_IMAGES = {"ar", "de", "es", "fr", "ja", "ko", "ru", "uk"}
PAGES = {"index": "", "privacy-policy": "privacy-policy.html", "terms-of-use": "terms-of-use.html", "legal": "legal.html"}


def url(lang, page):
    prefix = "" if lang == "en" else f"/{lang}"
    return f"{prefix}/{PAGES[page]}"


def boxed(text):
    """Escape a string and turn [[phrase]] into the green box."""
    return re.sub(r"\[\[(.+?)\]\]", r'<span class="hl">\1</span>', html.escape(text, quote=False))


def head(lang, page, title, description, rtl, extra=""):
    alternates = "\n".join(
        f'    <link rel="alternate" hreflang="{code}" href="{ORIGIN}{url(code, page)}">' for code, _, _ in LANGS)
    return f"""<!DOCTYPE html>
<html lang="{lang}"{' dir="rtl"' if rtl else ''}>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{html.escape(title)}</title>
    <meta name="description" content="{html.escape(description)}">
    <link rel="canonical" href="{ORIGIN}{url(lang, page)}">
{alternates}
    <link rel="alternate" hreflang="x-default" href="{ORIGIN}{url('en', page)}">
    <meta name="color-scheme" content="light dark">
    <meta name="theme-color" content="#F8F3E8" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#101A13" media="(prefers-color-scheme: dark)">
    <meta name="apple-itunes-app" content="app-id=1588418793">
    <link rel="icon" href="/favicon/favicon.ico" sizes="any">
    <link rel="icon" type="image/svg+xml" href="/favicon/favicon.svg">
    <link rel="apple-touch-icon" href="/favicon/apple-touch-icon.png">
    <link rel="manifest" href="/favicon/site.webmanifest">
{extra}    <link rel="stylesheet" href="/css/site.css">
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-B0DLV1WM03"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){{dataLayer.push(arguments);}}
      gtag('js', new Date());
      gtag('config', 'G-B0DLV1WM03');
    </script>
"""


def picker(lang, page, t):
    current = next(name for code, name, _ in LANGS if code == lang)
    current_attr = ' aria-current="page"'
    items = "\n".join(
        f'                        <li><a href="{url(code, page)}" hreflang="{code}" lang="{code}"'
        f'{current_attr if code == lang else ""}>{name}</a></li>' for code, name, _ in LANGS)
    return f"""                <details class="lang">
                    <summary aria-label="{html.escape(t['language'])}"><svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9.5" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M2.5 12h19M12 2.5c2.6 2.8 3.9 6 3.9 9.5s-1.3 6.7-3.9 9.5c-2.6-2.8-3.9-6-3.9-9.5s1.3-6.7 3.9-9.5z" fill="none" stroke="currentColor" stroke-width="1.8"/></svg><span class="lang-name">{current}</span><span class="lang-code">{lang.upper()}</span></summary>
                    <ul>
{items}
                    </ul>
                </details>"""


def header(lang, page, t):
    home = url(lang, "index")
    return f"""<body>
    <a href="#main" class="skip">{html.escape(t['skip'])}</a>

    <header class="site-header">
        <div class="wrap">
            <a href="{home}" class="brand"><img src="/favicon/favicon.svg" alt="" width="30" height="30">My Dictionary</a>
            <nav class="nav" aria-label="Main">
                <a href="{home}#features">{t['nav_features']}</a>
                <a href="{home}#mac">{t['nav_mac']}</a>
                <a href="{home}#faq">{t['nav_faq']}</a>
{picker(lang, page, t)}
                <a href="{APP}" class="get">{t['nav_download']}</a>
            </nav>
        </div>
    </header>
"""


def footer(lang, t):
    return f"""
    <footer class="site-footer">
        <div class="wrap">
            <span>© 2026 My Dictionary</span>
            <nav aria-label="Footer">
                <a href="mailto:hello@mydictionary.org">{t['footer_support']}</a>
                <a href="{url(lang, 'privacy-policy')}">{t['footer_privacy']}</a>
                <a href="{url(lang, 'terms-of-use')}">{t['footer_terms']}</a>
                <a href="{url(lang, 'legal')}">{t['footer_legal']}</a>
                <a href="/docs/mcp/">{t['footer_mcp']}</a>
                <a href="https://x.com/xander1100001" rel="noopener">X</a>
                <a href="https://www.instagram.com/ar_x101/" rel="noopener">Instagram</a>
            </nav>
        </div>
    </footer>

    <script>
      document.documentElement.classList.add('js');
      const io = new IntersectionObserver((entries) => entries.forEach((e) => {{
        if (e.isIntersecting) {{ e.target.classList.add('in'); io.unobserve(e.target); }}
      }}), {{ rootMargin: '0px 0px -60px 0px' }});
      document.querySelectorAll('.reveal').forEach((el) => io.observe(el));
      // Close the language menu when clicking elsewhere
      document.addEventListener('click', (e) => document.querySelectorAll('details.lang[open]').forEach((d) => {{ if (!d.contains(e.target)) d.open = false; }}));
    </script>
</body>
</html>
"""


def picture(lang, name, alt, size, eager=False):
    folder = f"{lang}/" if lang in OWN_IMAGES and name in ("hero", "capture", "definitions", "games") else ""
    w2 = size[0] * 2
    attrs = 'fetchpriority="high"' if eager else 'loading="lazy"'
    cls = "" if eager else ' class="reveal"'
    sizes = "(min-width: 900px) 600px, 92vw" if name == "mac" else "(min-width: 900px) 520px, 92vw"
    src = f"/images/site/{folder}{name}"
    return (f'<img{cls} src="{src}.webp" srcset="{src}.webp {size[0]}w, {src}@2x.webp {w2}w" sizes="{sizes}" '
            f'width="{size[0]}" height="{size[1]}" alt="{html.escape(alt)}" {attrs}>')


def image_size(lang, name):
    from PIL import Image
    folder = f"{lang}/" if lang in OWN_IMAGES and name in ("hero", "capture", "definitions", "games") else ""
    return Image.open(SITE / "images" / "site" / f"{folder}{name}.webp").size


def feature(lang, t, key, name, flip=False, bullets=3, anchor=""):
    items = "".join(f"\n                        <li>{html.escape(t[f'{key}_{i}'])}</li>" for i in range(1, bullets + 1))
    lst = f"\n                    <ul>{items}\n                    </ul>" if bullets else ""
    return f"""
        <section class="section feature{' flip' if flip else ''}"{f' id="{anchor}"' if anchor else ''}>
            <div class="wrap">
                <div class="copy reveal">
                    <p class="eyebrow">{t[f'{key}_eyebrow']}</p>
                    <h2>{boxed(t[f'{key}_title'])}</h2>
                    <p>{html.escape(t[f'{key}_text'])}</p>{lst}
                </div>
                {picture(lang, name, t[f'{key}_alt'], image_size(lang, name))}
            </div>
        </section>
"""


def badges(t, lazy=False):
    la = ' loading="lazy"' if lazy else ""
    return f"""<div class="badges">
                        <a href="{APP}" aria-label="{html.escape(t['badge_ios'])}"><img src="/images/download-on-the-app-store.svg" alt="{html.escape(t['badge_ios'])}" width="117" height="30"{la}></a>
                        <a href="{APP}" aria-label="{html.escape(t['badge_mac'])}"><img src="/images/download-for-macos.svg" alt="{html.escape(t['badge_mac'])}" width="163" height="30"{la}></a>
                    </div>"""


QUOTES = [  # real App Store reviews, quoted as written
    ("This little app definitely has everything for building your own dictionary! Best dictionary app ever.", "_lynn！"),
    ("Simple personal dictionary/glossary that syncs across iCloud. Multiple types of quizzes for the terms+definitions.", "Leviathan.22"),
    ("I love using this app! It’s definitely helping me build my vocab!", "JBluhvzYeshua"),
]


def home(lang, rtl, t):
    faq = [("free", True), ("lang", False), ("sync", False), ("data", False), ("pip", False)]
    ld_app = {"@context": "https://schema.org", "@type": "SoftwareApplication", "name": "My Dictionary - Learn Words",
              "operatingSystem": "iOS, iPadOS, macOS", "applicationCategory": "EducationalApplication",
              "url": f"{ORIGIN}{url(lang, 'index')}", "downloadUrl": APP, "inLanguage": lang,
              "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
              "aggregateRating": {"@type": "AggregateRating", "ratingValue": "4.8", "ratingCount": "101"}}
    ld_faq = {"@context": "https://schema.org", "@type": "FAQPage", "inLanguage": lang, "mainEntity": [
        {"@type": "Question", "name": t[f"faq_{k}_q"], "acceptedAnswer": {"@type": "Answer", "text": t[f"faq_{k}_a"]}} for k, _ in faq]}
    hero_src = f"/images/site/{lang + '/' if lang in OWN_IMAGES else ''}hero"
    extra = f"""    <meta name="robots" content="index,follow,max-image-preview:large">
    <meta property="og:type" content="website">
    <meta property="og:url" content="{ORIGIN}{url(lang, 'index')}">
    <meta property="og:title" content="{html.escape(t['og_title'])}">
    <meta property="og:description" content="{html.escape(t['og_description'])}">
    <meta property="og:image" content="{ORIGIN}/images/site/og.jpg">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:image" content="{ORIGIN}/images/site/og.jpg">
    <link rel="preload" as="image" href="{hero_src}.webp" imagesrcset="{hero_src}.webp 720w, {hero_src}@2x.webp 1440w" imagesizes="(min-width: 900px) 520px, 92vw">
    <script type="application/ld+json">{json.dumps(ld_app, ensure_ascii=False)}</script>
    <script type="application/ld+json">{json.dumps(ld_faq, ensure_ascii=False)}</script>
"""
    faq_html = "".join(f"""
                <details>
                    <summary>{html.escape(t[f'faq_{k}_q'])}</summary>
                    <p>{html.escape(t[f'faq_{k}_a'])}{f' <a href="{url(lang, "privacy-policy")}">{t["privacy_link"]}</a>' if k == 'data' else ''}</p>
                </details>""" for k, _ in faq)
    quotes = "".join(f"""
                    <figure class="quote reveal" lang="en" dir="ltr">
                        <span class="stars" aria-label="5 ★">★★★★★</span>
                        <blockquote>“{html.escape(q)}”</blockquote>
                        <figcaption>{html.escape(who)} · App Store</figcaption>
                    </figure>""" for q, who in QUOTES)
    return (head(lang, "index", t["meta_title"], t["meta_description"], rtl, extra) + "</head>\n" + header(lang, "index", t) + f"""
    <main id="main">
        <section class="hero">
            <div class="wrap">
                <div>
                    <h1 class="display">{boxed(t['hero_title'])}</h1>
                    <p class="lede">{html.escape(t['hero_lede'])}</p>
                    {badges(t)}
                    <p class="rating"><span class="stars" aria-hidden="true">★★★★★</span><span>{t['rating']}</span></p>
                </div>
                {picture(lang, 'hero', t['hero_alt'], image_size(lang, 'hero'), eager=True)}
            </div>
        </section>
{feature(lang, t, 'capture', 'capture', anchor='features')}{feature(lang, t, 'define', 'definitions', flip=True)}{feature(lang, t, 'games', 'games')}{feature(lang, t, 'grow', 'progress', flip=True, bullets=0)}
        <section class="section band" id="mac">
            <div class="wrap">
                <div class="reveal">
                    <p class="eyebrow">{t['mac_eyebrow']}</p>
                    <h2>{boxed(t['mac_title'])}</h2>
                    <p class="lede">{html.escape(t['mac_text'])}</p>
                    <a class="text-link" href="/docs/mcp/">{t['mac_link']}</a>
                </div>
                {picture(lang, 'mac', t['mac_alt'], image_size(lang, 'mac'))}
            </div>
        </section>

        <section class="section">
            <div class="wrap">
                <div class="reviews-head reveal">
                    <p class="score">4.8</p>
                    <p class="rating"><span class="stars" aria-hidden="true">★★★★★</span><span>{t['reviews_count']}</span></p>
                </div>
                <div class="quotes">{quotes}
                </div>
            </div>
        </section>

        <section class="section" id="faq">
            <div class="wrap faq">
                <h2>{t['faq_title']}</h2>{faq_html}
            </div>
        </section>

        <section class="section cta">
            <div class="wrap">
                <img class="duck" src="/images/site/duck.webp" alt="" width="150" height="232" loading="lazy">
                <h2>{boxed(t['cta_title'])}</h2>
                <p class="lede" style="margin-left:auto;margin-right:auto">{html.escape(t['cta_text'])}</p>
                {badges(t, lazy=True)}
            </div>
        </section>
    </main>
""" + footer(lang, t))


def summary(body, limit=155):
    """A page's own description: its intro, or the start of its first section, cut at a word."""
    block = re.search(r'class="legal-(?:description|section)">(.*?)</div>', body, re.S)
    text = re.sub(r"\s+", " ", re.sub(r"<h2[^>]*>.*?</h2>|<[^>]+>", " ", block.group(1) if block else body)).strip()
    text = re.sub(r"([。．！？])\s+", r"\1", text)   # no spaces between CJK sentences
    if len(text) <= limit:
        return text
    cut = text[:limit].rsplit(" ", 1)[0] if " " in text[:limit] else text[:limit]
    return cut.rstrip(",;:") + "…"


def legal(lang, rtl, t, page, meta):
    body = (I18N / "legal" / lang / f"{page}.html").read_text().replace('id="main-content"', 'id="main"')
    body = re.sub(r'<div class="legal-subtitle">(.*?)</div>', r'<h1 class="legal-subtitle">\1</h1>', body, count=1)
    body = body.replace('href="./"', f'href="{url(lang, "index")}"')
    m = meta[lang][page]
    return head(lang, page, m["title"], m["description"] or summary(body), rtl) + "</head>\n" + header(lang, page, t) + "\n    " + body + "\n" + footer(lang, t)


def main():
    english = json.loads((I18N / "en.json").read_text())
    meta = json.loads((I18N / "legal" / "meta.json").read_text())
    for lang, _, rtl in LANGS:
        t = {**english, **json.loads((I18N / f"{lang}.json").read_text())}
        missing = set(english) - set(json.loads((I18N / f"{lang}.json").read_text()))
        if missing:
            print(f"{lang}: {len(missing)} strings fall back to English: {sorted(missing)[:5]}")
        folder = SITE if lang == "en" else SITE / lang
        folder.mkdir(exist_ok=True)
        (folder / "index.html").write_text(home(lang, rtl, t))
        for page in ("privacy-policy", "terms-of-use", "legal"):
            (folder / f"{page}.html").write_text(legal(lang, rtl, t, page, meta))
    urls = [url(code, p) for code, _, _ in LANGS for p in PAGES] + ["/docs/mcp/"]
    (SITE / "sitemap.xml").write_text('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
                                      + "".join(f"  <url><loc>{ORIGIN}{u}</loc><lastmod>2026-10-01</lastmod></url>\n" for u in urls)
                                      + "</urlset>\n")
    print(f"{len(LANGS)} languages × {len(PAGES)} pages, sitemap with {len(urls)} URLs")


if __name__ == "__main__":
    main()
