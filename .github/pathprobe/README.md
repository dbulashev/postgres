# postgres-pathprobe image

PostgreSQL from this branch (master of this fork) with the pathprobe core
hooks patch applied and the pathprobe extension installed.  Built and pushed
by `.github/workflows/pathprobe-image.yml` for `linux/amd64` and
`linux/arm64`.

Not for production: the core hooks patch changes `add_path()`, and pathprobe
is a diagnostic tool for targeted runs, not for tracing every query.

This is a different image from `postgres-path-probe` (branch
`path-probe-image`), which carries the injection point series meant for
pgsql-hackers.  The two instrument the same planner boundaries in different
ways and are not combined.

## Source

Nothing from pathprobe is copied here.  The workflow checks out
<https://github.com/obartunov/pathprobe> at `PATHPROBE_REF` (pinned to a
commit in the workflow) into `pathprobe-src/`, applies
`pathprobe-src/patches/pathprobe-core-hooks.patch` to the tree with
`apply-patches.sh`, and builds the extension from the same checkout, so the
hooks and the extension always come from one commit.

To take a newer pathprobe, change `PATHPROBE_REF` in the workflow, or run it
manually with the `pathprobe_ref` input.

## Image

```sh
docker run -d --name pathprobe -e POSTGRES_PASSWORD=postgres -p 5432:5432 \
    dbulashev/postgres-pathprobe:latest
```

Tags:

- `<version>-<upstream sha>-pp<pathprobe sha>`, e.g.
  `20devel-425daf545d91-ppd56ffe5`;
- `<version>`, e.g. `20devel`, and `latest`: the most recent build.

The image uses the entrypoint of the official `postgres` image, so
`POSTGRES_PASSWORD`, `POSTGRES_DB` and `/docker-entrypoint-initdb.d` work as
usual.  Data lives under `/var/lib/postgresql`, the same layout as the
official 18+ images.

```sql
CREATE EXTENSION pathprobe;
SELECT pathprobe('SELECT ...');                 -- text, for people
SELECT pathprobe_json('SELECT ...')::jsonb;     -- events, summary, coverage
```

`coverage.add_path_precheck = true` in the JSON confirms the hooks are
compiled in; on a stock server the extension runs with reduced coverage.

## CI

- `test`: patched server with `--enable-cassert`, pathprobe installed into
  it, `make installcheck` of the extension.  The Perl TAP model tests (`t/`)
  are not run.
- `build`: image per platform, smoke test (coverage of the core hooks,
  `listen_addresses = '*'`), push by digest.
- `merge`: one manifest list with the tags above.

## Updating

CI commits on this branch touch only `.github/`.  The workflow treats the
most recent commit that changes anything outside `.github/` as the upstream
base, so a CI commit must not touch the source tree.  Subjects by convention
start with `pathprobe:`, but the base does not depend on them.  To rebuild
against a newer master:

```sh
git rebase master pathprobe-image
git push --force-with-lease origin pathprobe-image
```
