# syntax=docker/dockerfile:1.7
#
# Commit-image Dockerfile for ikos (NASA's abstract-interpretation static analyzer for C/C++),
# built ON TOP of the org C/C++ base image. The base provides debian trixie + clang-19/LLVM-19 +
# libFuzzer + the build-contract ENV (CC/CXX/SANITIZER_FLAGS/LIB_FUZZING_ENGINE/SRC).
#
# Build (from the repo root):
#   DOCKER_BUILDKIT=1 docker build -f mayhem/Dockerfile --build-arg COMMIT=$(git rev-parse HEAD) -t ikos-commit:test .
FROM ghcr.io/savantenvs/base:20260621

ARG COMMIT
ARG REPO_URL
# SOURCE_DATE_EPOCH stays an ARG (build.sh unsets it when empty) — an empty ENV breaks clang-19.
ARG SOURCE_DATE_EPOCH
# Undefaulted: the base's SANITIZER_FLAGS (ASan+UBSan, halting) flows through unless overridden
# with --build-arg SANITIZER_FLAGS="..." (an explicit empty value builds with no sanitizers).
ARG SANITIZER_FLAGS
ARG COVERAGE_FLAGS=
ARG MAYHEM_JOBS=

# ---------------------------------------------------------------------------------------------
# ikos 3.x links against LLVM 14 exactly (frontend/llvm + analyzer CMakeLists FATAL_ERROR on any
# other major). Debian trixie ships no llvm-14 packages, so the LLVM 14 *library* comes from the
# official pinned llvm-project release tarball (14.0.6 is only published for x86_64 Linux as the
# rhel-8.4 build; it needs GLIBC <= 2.27 and the libstdc++ the base already has — no libtinfo/libxml2).
# It is verified against its sha256 before extraction and installed under /opt/toolchains/llvm14
# (SPEC §6.2 item 8: toolchains under /opt/toolchains, root-owned, world-readable). Only the parts
# ikos needs are extracted: llvm-config, the LLVM static libs + headers + cmake modules, and the
# bundled clang-14 (FindClang requires a clang whose version matches the LLVM; it is also the
# compiler that produced the committed bitcode seeds — see mayhem/gen-seeds.sh). ikos ITSELF is
# compiled by the base's clang-19 (see mayhem/build.sh for why).
# The remaining build deps (boost, gmp, sqlite3, tbb) are trixie apt -dev packages, baked here so
# the air-gapped PATCH re-run of build.sh needs no network (SPEC §6.5).
# ---------------------------------------------------------------------------------------------
ARG LLVM14_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang%2Bllvm-14.0.6-x86_64-linux-gnu-rhel-8.4.tar.xz
ARG LLVM14_SHA256=7412026be8bb8f6b4c25ef58c7a1f78ed5ea039d94f0fa633a386de9c60a6942
ARG LLVM14_TOPDIR=clang+llvm-14.0.6-x86_64-linux-gnu-rhel-8.4

USER root
# ccache for the rlenv PATCH-tier budget (see mayhem/build.sh): installed from the base's pinned Debian
# snapshot; the cache dir lives under /opt/toolchains (mayhem-owned cache within the 0:0 toolchain root,
# SPEC §3/§6.2 item 8) and is filled by the `RUN bash mayhem/build.sh` below, so it ships in the image.
RUN [ -n "$SOURCE_DATE_EPOCH" ] && repro-sources-list.sh || true ; \
    apt-get update && apt-get install -yq --no-install-recommends ccache \
 && rm -rf /var/lib/apt/lists/* \
 && install -d -o 2000 -g 2000 /opt/toolchains /opt/toolchains/ccache /opt/toolchains/ccache/ikos
ENV CCACHE_DIR=/opt/toolchains/ccache/ikos \
    CCACHE_MAXSIZE=8G \
    CCACHE_SLOPPINESS=time_macros,locale
RUN set -eu; \
    curl -fsSL --retry 3 -o /tmp/llvm14.tar.xz "$LLVM14_URL"; \
    echo "$LLVM14_SHA256  /tmp/llvm14.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/toolchains/llvm14; \
    tar -xJf /tmp/llvm14.tar.xz -C /opt/toolchains/llvm14 --strip-components=1 \
        "$LLVM14_TOPDIR/bin/llvm-config" \
        "$LLVM14_TOPDIR/bin/clang-14" "$LLVM14_TOPDIR/bin/clang" "$LLVM14_TOPDIR/bin/clang++" \
        "$LLVM14_TOPDIR/include" "$LLVM14_TOPDIR/lib/cmake" "$LLVM14_TOPDIR/lib/clang" \
        --wildcards "$LLVM14_TOPDIR/lib/libLLVM*.a"; \
    rm -f /tmp/llvm14.tar.xz; \
    chmod -R a+rX /opt/toolchains/llvm14; \
    /opt/toolchains/llvm14/bin/llvm-config --version | grep -qx 14.0.6; \
    /opt/toolchains/llvm14/bin/clang --version | head -1

# LLVMConfig.cmake includes LLVMExports.cmake, whose generated sanity check FATAL_ERRORs unless every
# exported target's file exists — including the ~1.5 GB of LLVM tools / shared libs (llvm-tblgen, opt,
# llc, libLTO.so, ...) deliberately NOT extracted above because ikos never uses them (it links only the
# libLLVM*.a archives, which are all present). Create zero-byte placeholders for the missing referenced
# paths so the check passes; anything that actually tried to run or link one would fail loudly.
RUN python3 - <<'PY'
import re, pathlib
root = pathlib.Path("/opt/toolchains/llvm14")
refs = set()
for f in sorted((root / "lib/cmake/llvm").glob("LLVMExports*.cmake")):  # main + per-config (-release)
    refs |= set(re.findall(r'"\$\{_IMPORT_PREFIX\}/([^"]+)"', f.read_text()))
missing = sorted(r for r in refs if not (root / r).exists())
for r in missing:
    p = root / r
    p.parent.mkdir(parents=True, exist_ok=True)
    p.touch()
    p.chmod(0o644)
print("LLVMExports placeholders:", len(missing), "of", len(refs), "referenced files")
assert len(refs) > 0 and (root / "lib/libLLVMCore.a").stat().st_size > 0
PY

# ikos's remaining build deps from trixie apt (libboost-test-dev: core/CMakeLists.txt requires the
# unit_test_framework component even when the tests are not built). Kept AFTER the LLVM layer so an
# apt edit never re-downloads the 600 MB tarball.
RUN [ -n "$SOURCE_DATE_EPOCH" ] && repro-sources-list.sh || true ; \
    apt-get update && apt-get install -yq --no-install-recommends \
        libboost-dev libboost-filesystem-dev libboost-thread-dev libboost-test-dev \
        libgmp-dev libsqlite3-dev libtbb-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*
USER mayhem

# Source enters from the build CONTEXT (the CI checkout): the FULL repo (incl. .git history) is
# copied to /mayhem as `mayhem`; build.sh builds in place (shadow copy + two out-of-tree cmake trees
# under /mayhem/mayhem-build).
WORKDIR /mayhem
COPY --chown=2000:2000 . /mayhem

RUN bash mayhem/build.sh

# Behavioral oracle (known-answer tests through the clean analyzer) — a failing suite fails the build.
RUN if [ -f mayhem/test.sh ]; then bash mayhem/test.sh; else echo "no mayhem/test.sh"; fi

LABEL org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${COMMIT}" \
      rlenv.tier="commit" \
      rlenv.source_date_epoch="${SOURCE_DATE_EPOCH}" \
      rlenv.user="mayhem"

USER mayhem
WORKDIR /mayhem
