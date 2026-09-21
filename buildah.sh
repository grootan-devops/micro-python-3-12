#!/usr/bin/env bash

set -euo pipefail

# renovate: datasource=github-tags depName=python/cpython extractVersion=^v?(?<version>.+)$
PYTHON_VERSION="3.12.14"
PYTHON_HOME="/usr/local"
PYTHON_SRC="/tmp/cpython"
PYTHON_PACKAGE_FILE_NAME="python_src.tgz"
PYTHON_RUNTIME_LIB_FILE_NAME="py_runtime_libs.txt"

for variable in PYTHON_VERSION PYTHON_HOME PYTHON_SRC PYTHON_PACKAGE_FILE_NAME PYTHON_RUNTIME_LIB_FILE_NAME; do
  buildah config --env "${variable}=${!variable}" "${BASE_CONTAINER}"
done
buildah config --env PYTHONDONTWRITEBYTECODE=1 "${BASE_CONTAINER}"
buildah config --env PYTHONUNBUFFERED=1 "${BASE_CONTAINER}"
buildah config --env PYTHONHASHSEED=random "${BASE_CONTAINER}"
buildah config --env PYTHONUTF8=1 "${BASE_CONTAINER}"
buildah config --env PYTHONFAULTHANDLER=1 "${BASE_CONTAINER}"
buildah config --env LD_LIBRARY_PATH=/usr/local/lib "${BASE_CONTAINER}"

mkdir -p "${CONTAINER_MOUNT}${PYTHON_SRC}"
curl --fail --show-error --location --proto '=https' --tlsv1.2 --retry 3 --output "${PYTHON_PACKAGE_FILE_NAME}" "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
tar -xf "${PYTHON_PACKAGE_FILE_NAME}" -C "${CONTAINER_MOUNT}${PYTHON_SRC}" --strip-components=1
rm -f "${PYTHON_PACKAGE_FILE_NAME}"

run_in_container_mount "
  printf '%s\n' \
    '*disabled*' \
    '_curses' '_curses_panel' '_dbm' '_gdbm' '_tkinter' \
    '_testbuffer' '_testcapi' '_testclinic' '_testimportmultiple' \
    '_testinternalcapi' '_testmultiphase' 'nis' 'readline' 'xxlimited' \
    'xxlimited_35' 'xxsubtype' \
    >> ${PYTHON_SRC}/Modules/Setup.local
  cd ${PYTHON_SRC}
  export CXX=g++
  export CFLAGS='-O3 -pipe -fno-semantic-interposition -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2'
  export LDFLAGS='-Wl,-O1 -Wl,--as-needed -Wl,-z,relro,-z,now -Wl,--strip-all,-rpath=\$\$ORIGIN/../lib'
  ./configure --with-ensurepip=install --enable-optimizations --with-lto=full --enable-shared --enable-option-checking=fatal --with-computed-gotos --without-static-libpython --without-doc-strings --without-readline --with-openssl-rpath=auto --prefix=${PYTHON_HOME}
  make -j\$(nproc) PROFILE_TASK='-m test --pgo --timeout=120'
  make -j\$(nproc) altinstall
  ${PYTHON_HOME}/bin/python3.12 -m pip install --no-cache-dir --root-user-action=ignore --no-compile --upgrade pip uv
  cd ${PYTHON_HOME}
  find lib -type f \( -name '*.o' -o -name '*.la' -o -name '*.pdb' -o -name '*_d.so' \) -delete
  find lib/python3.12 -depth -type d \( -name 'test' -o -name 'tests' -o -name 'idle_test' -o -name '__pycache__' \) -exec rm -rf -- {} +
  rm -rf -- lib/python3.12/{turtledemo,pydoc_data,lib2to3,idlelib,ensurepip,venv,curses,tkinter}
  rm -rf -- bin/{2to3*,idle*,pydoc*,pip,pip3,wheel,wheel3}
  rm -rf -- lib/python3.12/site-packages/{pip,setuptools,wheel}*
  rm -rf -- include share lib/pkgconfig lib/python3.12/config-* lib/libpython*.a
  find /tmp /var/tmp -mindepth 1 -delete
  ${PYTHON_HOME}/bin/python3.12 -m compileall -q -f -j\$(nproc) lib/python3.12
  find bin lib -type f -name '*.so*' -exec strip --strip-unneeded -- {} + 2>/dev/null || true
  find bin -type f -executable -exec strip --strip-unneeded -- {} + 2>/dev/null || true
  find bin lib -type f \( -name '*.so*' -o -executable \) -print0 |
    while IFS= read -r -d '' bin; do
      ldd \"\${bin}\" 2>/dev/null | awk '/=>/ {print \$3}' | grep '^/' || true
    done | sort -u > /tmp/${PYTHON_RUNTIME_LIB_FILE_NAME}
"

printf 'Runtime python libraries:\n'
cat "${CONTAINER_MOUNT}/tmp/${PYTHON_RUNTIME_LIB_FILE_NAME}"
find "${CONTAINER_MOUNT}/tmp" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
