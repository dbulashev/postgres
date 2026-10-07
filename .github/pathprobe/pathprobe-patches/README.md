# Archived pathprobe patches

Not applied by `apply-patches.sh`; local patches go into `../local-patches/`.

These five patches were built and tested here on top of pathprobe a7f1bd7
(image tag suffix `-local81d819a`).  pathprobe adapted them in
`r2d2/dmitry-attribution` (9bcf24c), which the image now builds from, and
links to this directory from its acknowledgements, so the files stay.

What pathprobe took, and under which names:

1. The kept annotation is out of `label`: `kept_reason` on SURVIVED events,
   `origin` is `real` for such paths.
2. `cost_startup` on events; `rows`, `required_outer`, `index_oid`,
   `index_name` and `hypothetical_index` on `paths[]`.  `required_outer` on
   SKIPPED events was not taken.
3. The dominator of a REJECTED path: `dominator_path_id`, `dominator_seq`,
   `dominator_pathtype`.  `gap_cost` of a REJECTED event is still computed
   against the rel's cheapest total path.
4. Paths removed by a new path that is then rejected are reported as a
   separate `removed` event (`remover_path_id`, `remover_seq`,
   `remover_pathtype`, `coverage.add_path_removed`), not as DISPLACED.
5. No `rows` for BitmapAnd and BitmapOr paths.

The output format version stays `1.1`.
