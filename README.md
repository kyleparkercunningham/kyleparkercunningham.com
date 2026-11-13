# kyleparkercunningham.com

The website of the artist Kyle Parker Cunningham: his paintings, prints,
installations, films and writing, and the seasonal front page called the
editions. It is a [Zola](https://www.getzola.org) site served by a Cloudflare
Worker since 2026-10-15, deployed on every merge to main since 2026-11-13 (Workers Builds, `scripts/ci-build.sh`), or by hand with `scripts/deploy-worker.sh`
(`docs/hosting.md`).

**The archive is the record.** The complete catalogue of every work lives at
[archive.kyleparkercunningham.com](https://archive.kyleparkercunningham.com)
(`atelier/oeuvre` in the machinery tree). `content/oeuvre/` here is a copy made
in July 2026, before the archive existed; it is not enriched by hand, and how
it is retired is part of the 2027 work. Where the site is going, and the full
list of what has to happen first, is `docs/2027-review.md` (with the sketches in
`mockups/2027/`) and the brief in `CLAUDE.md`.

## Building

Zola **0.22.1** exactly. 0.23 rewrote the template engine and these templates
predate it (`TODO.md` § 2 lists what breaks).

```bash
./scripts/serve.sh    # regenerate data/, then zola serve at http://127.0.0.1:1111
./scripts/build.sh    # regenerate data/, then zola build into public/
```

Both first run `scripts/update_recently_edited.py` and
`scripts/generate_site_index.py`, which write `data/recently_edited.json` (the
dashboard) and `data/site_index.json` (the manifest). They share
`scripts/zola_paths.py`, which follows Zola's own URL rules and dates edits from
git, so run them in a full clone.

Zola writes resized images into `static/processed_images/`, which is committed
as a cache. A local build rewrites some of those files; `git checkout --
static/processed_images` before committing unless the change is intended.

## Deploying

A push to `main` builds and deploys (`.github/workflows/main.yml`); nothing
else is built yet, so build locally before merging. Because main deploys,
Claude's branches open **draft** pull requests that wait for Kyle
(`claude-branch-pr.yml`).

The site is moving to a Cloudflare Worker, so that the catalogue's addresses can
answer 301 to the archive: staged, with the cutover waiting for Kyle. How it is
built, deployed and cut over is `docs/hosting.md`.

## Where things are

| Path | What |
|---|---|
| `content/editions/` | The front page. One folder per season or project edition; the one with `status = "live"` is the homepage. `docs/editions.md` and `scripts/edition.sh` |
| `content/oeuvre/<discipline>/<year>/<work>/` | One work per folder, with its photographs. Year folders only group; they do not render |
| `content/projects/` | Projects that group works across years |
| `content/cinema/` | One page per film. Players load only when a visitor presses play (`static/film.js`) |
| `content/log/` | Dated posts |
| `content/about/`, `bio/`, `artist-statement/` and siblings | About pages |
| `templates/` | Tera templates. `base.html` sets descriptions and schema.org structured data |
| `sass/style.scss` | The stylesheet |
| `static/fonts/` | Self-hosted Literata, IBM Plex Sans and Inconsolata; no page loads anything from a third party until a film is played |
| `static/robots.txt`, `static/llms.txt` | Every crawler is welcome, including AI training |
| `docs/` | How the site works (`architecture.md`, `content-guide.md`, `editions.md`, `decisions.md`); `docs/archive/` is closed |
| `mockups/` | Design sketches. Not deployed |

## Writing on this site

Kyle's words are his. Prose a model drafted is marked `author = "claude"` in a
page's front matter and is counted on `/manifest/`; machine prose is never
published as Kyle's. No page shows a price.
