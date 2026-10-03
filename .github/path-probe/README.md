# postgres-path-probe image

PostgreSQL from this branch (master of this fork) with the planner
path-pruning injection point series applied, built with
`--enable-injection-points`.  Built and pushed by
`.github/workflows/path-probe-image.yml` for `linux/amd64` and `linux/arm64`.

Not for production: injection points are a testing facility.

## Patches

The files in `patches/` are copies.  The original series, with its
authorship, cover letter, review notes and demo, lives in the
running-postgresql repository:

<https://github.com/obartunov/running-postgresql/tree/main/experiments/ch08-path-probe/hackers>

Change the series there first, then copy the files here.

The series was generated against upstream `c62b330`.  CI applies it with
`git am --3way` to the current master of this fork.

## Image

```sh
docker run -d --name pp -e POSTGRES_PASSWORD=postgres -p 5432:5432 \
    dbulashev/postgres-path-probe:latest
```

Tags:

- `<version>-<upstream sha>`, e.g. `20devel-425daf545d91`: the PostgreSQL
  commit the series was applied to;
- `<version>`, e.g. `20devel`, and `latest`: the most recent build.

The image uses the entrypoint of the official `postgres` image, so
`POSTGRES_PASSWORD`, `POSTGRES_DB` and `/docker-entrypoint-initdb.d` work as
usual.  Data lives under `/var/lib/postgresql`, the same layout as the
official 18+ images.

To trace the planner, attach the points in a session:

```sql
CREATE EXTENSION injection_points;
SELECT injection_points_set_local();
SELECT injection_points_attach(name, 'path-prune-notice')
FROM (VALUES ('planner-add-path-accept'), ('planner-add-path-reject'),
             ('planner-add-path-displace'), ('planner-add-path-precheck-reject')) AS p(name);
EXPLAIN SELECT ...;   -- one NOTICE "PLANNER_PATH event=..." per decision
```

## Updating

Every CI commit on this branch has a subject starting with `path-probe:`.
The workflow treats the first commit without that prefix as the upstream
base.  To rebuild against a newer master:

```sh
git rebase master path-probe-image
git push --force-with-lease origin path-probe-image
```
