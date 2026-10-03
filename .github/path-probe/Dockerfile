# PostgreSQL master + planner path-pruning injection points
# (.github/path-probe/patches), built with --enable-injection-points.
#
# The build context is the repository root with the patches already applied
# (see .github/path-probe/apply-patches.sh).  The runtime stage reuses the
# entrypoint of the official postgres image, so POSTGRES_PASSWORD,
# POSTGRES_DB, /docker-entrypoint-initdb.d etc. behave as usual.
#
# Not for production: injection points are a testing facility.

ARG DEBIAN=trixie
ARG ENTRYPOINT_IMAGE=postgres:18-trixie

FROM ${ENTRYPOINT_IMAGE} AS entrypoint

FROM debian:${DEBIAN}-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        bison build-essential ca-certificates flex gettext libicu-dev \
        liblz4-dev libreadline-dev libssl-dev libxml2-dev libzstd-dev \
        perl pkg-config zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN ./configure --prefix=/usr/local/pgsql \
        --enable-injection-points \
        --with-icu --with-libxml --with-lz4 --with-openssl --with-zstd \
    && make -j"$(nproc)" world-bin \
    && make install-world-bin \
    && make -C src/test/modules/injection_points install
# Separate step: a failed strip of a non-ELF file must not mask a failed build.
RUN find /usr/local/pgsql/bin /usr/local/pgsql/lib -type f \
        \( -perm -u+x -o -name '*.so*' \) -exec strip --strip-unneeded {} + 2>/dev/null; true

FROM debian:${DEBIAN}-slim
ARG PG_MAJOR=20
ENV PG_MAJOR=${PG_MAJOR} \
    PATH=/usr/local/pgsql/bin:$PATH \
    PGDATA=/var/lib/postgresql/${PG_MAJOR}/docker \
    LANG=en_US.utf8
RUN apt-get update && apt-get install -y --no-install-recommends \
        libicu76 liblz4-1 libreadline8t64 libssl3t64 libxml2 libzstd1 \
        locales tzdata zlib1g \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && groupadd -r -g 999 postgres \
    && useradd -r -g postgres -u 999 -d /var/lib/postgresql -s /bin/bash postgres \
    && mkdir -p /var/lib/postgresql /var/run/postgresql /docker-entrypoint-initdb.d \
    && chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql \
    && chmod 3777 /var/run/postgresql
COPY --from=build /usr/local/pgsql /usr/local/pgsql
COPY --from=entrypoint /usr/local/bin/docker-entrypoint.sh /usr/local/bin/gosu /usr/local/bin/
# Fails the build if a runtime library is missing, instead of at first start.
RUN ! ldd /usr/local/pgsql/bin/postgres /usr/local/pgsql/lib/postgresql/*.so | grep 'not found' \
    && postgres --version
# Same layout as the official 18+ images: mount /var/lib/postgresql.
VOLUME /var/lib/postgresql
STOPSIGNAL SIGINT
EXPOSE 5432
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
