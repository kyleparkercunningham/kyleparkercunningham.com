# Hosting: a Worker on the TorC account

*Written 2026-10-15. Staged, not cut over: the site is still served by GitHub
Pages until the DNS swap below, which waits for Kyle.*

## Why it moved

The archive at archive.kyleparkercunningham.com is the catalogue of record, and
this site stops keeping a second copy of it (foundation D5,
`docs/2027-review.md` § 3). Its catalogue addresses have to go to the archive,
and an address that has moved should say so with a **301**: search engines then
carry a page's standing to its new home and drop the old one.

GitHub Pages cannot answer 301. Zola's aliases are pages that refresh
themselves, which search engines treat as a weaker hint, and there is no way to
send a whole page, rather than an alias of it, anywhere else. A Cloudflare
Worker serving the same build can: `public/_redirects` is read by the platform
and wins over any file at the same address. Kyle chose this on 2026-10-15
("Worker in TorC, real 301s") over proxying GitHub Pages through Cloudflare,
which risks the Pages certificate renewing, and over keeping the refresh pages.

It is also where the showcase will live (foundation D7): the next front page is
a Worker reading the archive's API, and this one moves there first so that the
cutover is a deploy, not a migration.

## What is served

- **The Zola build**, unchanged, as static assets (`wrangler.jsonc`). Zola's
  addresses end in a slash; `html_handling = auto-trailing-slash` sends a
  request without one to it (307), and `404.html` answers anything missing.
- **`public/_redirects`**, written by `scripts/redirects.py` from the content
  tree and the archive's public API after every build, never by hand. On
  2026-10-15 it held 1,006 rules: 156 work pages and 294 of their aliases to
  `/works/<slug>`, 38 oeuvre index pages and 41 of their aliases to the
  matching `/works?category=…&year=…`, and 477 tag pages to `/works?tag=…`.
  Every target was fetched and answered 200. The platform allows 2,000 static
  rules, and the script refuses to write more.
- **What stays here**: B-sides & Rarities and the Meaning Is Use essays (the
  archive has no exhibitions or writing yet), `/oeuvre/book-binding/` (no such
  category there), and 14 tags the archive does not use. The script prints the
  list with `--report`.
- **Links name the final address.** `scripts/finalize_links.py` runs after
  the redirects are written and rewrites every `<a href>` in the build whose
  target is a redirected address to that redirect's target, so the site links
  straight to the archive page rather than through a hop (Kyle, 2026-10-15:
  "everything gets updated to the final source"). Works whose archive slug
  has changed are found through the archive's own forwards, so a renamed
  print is linked at its new address on the next build.
- **`src/worker.js`**, the only code: it sends `www` and plain `http` to
  `https://kyleparkercunningham.com`, as GitHub Pages did, and hands everything
  else to the assets. It runs first (`run_worker_first`), or `www` would be
  served the matching file; `_redirects` still applies to what it hands on,
  checked on a preview version on 2026-10-15. The zone's `always_use_https`
  stays off because it would change every subdomain, and the API token cannot
  write the zone's redirect rules.
- **`sitemap.xml`** with every redirected address taken out, and Zola's empty
  `/topics/`: 68 addresses, each answering 200.

## Build and deploy

```bash
scripts/deploy-worker.sh             # build, write the redirects, deploy
scripts/deploy-worker.sh --dry-run   # everything but the upload
```

### Deploys on merge

Since 2026-11-13 Workers Builds watches this repo's `main` for the Worker
`kpc-site` (Kyle's call that day, with jeannieortiz.com). A merge to main
builds and publishes:

- build command: `bash scripts/ci-build.sh`, which fetches the full git
  history ("recently edited" reads each page's last commit), fetches Zola
  0.22.1 for Linux (checksum pinned in the script) and runs the same steps
  as `deploy-worker.sh`;
- deploy command: `npx wrangler deploy`;
- root `/`, previews off.

So a PR here is a draft merged by hand, and merging is publishing. A failed
build leaves the live site as it was (the redirects step needs the
archive's API, and stops the build if it cannot read it); the Worker's
Builds tab in the dashboard has the log. `scripts/deploy-worker.sh` still
works from the Mac. Never deploy a branch by hand and leave it unmerged:
the next merge would publish main over it.

Zola must be **0.22.1** (`ZOLA=/path/to/zola` if `zola` is another version);
0.23 breaks the templates (`TODO.md` § 2). Wrangler comes from npm
(`WRANGLER=` overrides it) and the credentials from
`~/.config/cloudflare/torc.env`. The script runs CI's two data generators first
and puts their tracked output back afterwards. Zola itself deletes unused
images from `static/processed_images/` as it builds; those deletions are the
build's, not changes to commit.

The Worker is `kpc-site`, on the TorC account
(`0170b714b0ee025091fed8a088f7a65a`), staged at
<https://kpc-site.torc.workers.dev>. **The preview borrows the live site's CSS
and fonts**: `base_url` is absolute, so every page links its stylesheets at
kyleparkercunningham.com. Judge layout only after the cutover.

## Cutover — done 2026-10-15

Kyle ran `scripts/cutover.py` at 22:22 on 2026-10-15. The four A records and
the `www` CNAME are saved in `docs/cutover-github-pages-records.json`, the
Worker holds both names, and every check in step 3 passed in curl and in
Chrome. The site keeps draft PRs after the move, because a deploy is still a
change to the live site.

**What the switch looked like from Kyle's house.** The script's own checks
asked for the apex in the seconds between deleting GitHub's records and
Cloudflare creating its own, and the house's resolvers (the router, then the
Mac's cache) kept that empty answer for the zone's negative-cache time, 1,800
seconds in its SOA. `www` answered at once; the apex came back on this network
about half an hour later, while public resolvers had it within a minute.
Another move of a name in this zone should not query that name until the new
records exist.

1. #7 and #8 are merged (2026-10-15), and the Worker at workers.dev carries
   that build with this branch's redirects.
2. **`scripts/cutover.py`** does the switch in one go. It checks that the staged
   Worker answers and redirects, saves the four apex A records
   (185.199.108–111.153) and the `www` CNAME to `heirloompixels.github.io` to
   `docs/cutover-github-pages-records.json`, deletes them, and runs
   `scripts/deploy-worker.sh`, which attaches both names to the Worker;
   Cloudflare creates the records and the certificate. It then waits until both
   names answer from Cloudflare. Nothing else in the zone is touched: MX, SPF,
   Mailgun, `tzprofiles`, the Google verification record and the subdomains
   stay as they are. Until this has run, `deploy-worker.sh` refuses a real
   deploy (`scripts/cutover.py --check`), because the domains in
   `wrangler.jsonc` cannot attach while GitHub Pages holds the names.
3. Check: `https://kyleparkercunningham.com/` and `www` answer 200 from
   Cloudflare (`server: cloudflare`), http answers 301 to https, a sample of
   `_redirects` answers 301 to the archive, and a real Chrome look at the home
   page, a project page and a redirected work.
4. *Done in the merge of PR #9:* `.github/workflows/main.yml` (the gh-pages
   build) is retired. *Kyle's click, after a few quiet days:* turn GitHub
   Pages off for the repo, so two hosts never claim the domain. From then on a
   merge to main does not deploy; `scripts/deploy-worker.sh` does, by hand,
   until a workflow carries a Cloudflare token (that token in GitHub is
   Kyle's decision).
5. In Search Console (domain property `sc-domain:kyleparkercunningham.com`,
   verified 2026-10-15 by a DNS TXT record), resubmit
   `https://kyleparkercunningham.com/sitemap.xml` and watch Pages → "Page with
   redirect" fill with the old catalogue addresses over the following weeks.

To undo while GitHub Pages is still on: `scripts/cutover.py --undo` detaches
the Worker's domains and puts the saved records back, and Pages serves the
last build on the `gh-pages` branch, from before the workflow was retired.
