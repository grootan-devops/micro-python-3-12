#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'image test failed: %s\n' "$1" >&2
  exit 1
}

[[ "$(id -u)" == "10001" ]] || fail "expected UID 10001, got $(id -u)"
[[ "$(id -g)" == "10001" ]] || fail "expected GID 10001, got $(id -g)"
[[ "${PYTHONDONTWRITEBYTECODE}" == "1" ]] || fail "PYTHONDONTWRITEBYTECODE is not enabled"
[[ "${PYTHONUNBUFFERED}" == "1" ]] || fail "PYTHONUNBUFFERED is not enabled"
[[ "${PYTHONUTF8}" == "1" ]] || fail "PYTHONUTF8 is not enabled"
[[ "${PYTHONFAULTHANDLER}" == "1" ]] || fail "PYTHONFAULTHANDLER is not enabled"
python3.12 --version | grep -q '3\.12\.14' || fail "unexpected Python version"
[[ "${PYTHON_HOME}" == "/usr/local" ]] || fail "unexpected PYTHON_HOME"

for command in gcc g++ cpp make ld as ar rpm dnf microdnf yum pip pip3; do
  if command -v "${command}" >/dev/null 2>&1; then
    fail "development command remains: ${command}"
  fi
done

command -v uv >/dev/null 2>&1 || fail "uv is missing"
test_dir="$(mktemp -d)"
trap 'rm -rf "${test_dir}"' EXIT
printf '%s\n' \
  '[project]' \
  'name = "image-smoke-test"' \
  'version = "0.0.0"' \
  'requires-python = ">=3.12,<3.13"' \
  > "${test_dir}/pyproject.toml"
(
  cd "${test_dir}"
  UV_CACHE_DIR="${test_dir}/uv-cache" uv lock --offline --no-cache --no-python-downloads
  UV_CACHE_DIR="${test_dir}/uv-cache" uv sync --frozen --offline --no-cache --no-python-downloads --no-install-project
)
"${test_dir}/.venv/bin/python" -I -c \
  'import ssl, sys; assert sys.version_info[:2] == (3, 12); print(ssl.OPENSSL_VERSION)'

python3.12 -P <<'PY'
import bz2
import decimal
import hashlib
import importlib.util
import lzma
import os
import pathlib
import sqlite3
import sys
import sysconfig
import uuid
import zlib

assert sys.version_info[:2] == (3, 12), sys.version
assert sys.flags.utf8_mode == 1
assert sys.dont_write_bytecode
config_args = sysconfig.get_config_var("CONFIG_ARGS") or ""
assert "--enable-optimizations" in config_args, config_args
assert "--with-lto=full" in config_args, config_args
assert "--without-doc-strings" in config_args, config_args
for module_name in (
    "_curses", "_curses_panel", "_dbm", "_gdbm", "_tkinter",
    "_testbuffer", "_testcapi", "_testclinic", "_testimportmultiple",
    "_testinternalcapi", "_testmultiphase", "nis", "readline",
    "xxlimited", "xxlimited_35", "xxsubtype",
):
    assert importlib.util.find_spec(module_name) is None, module_name
for removed_package in (
    "curses", "ensurepip", "idlelib", "lib2to3", "tkinter", "turtledemo", "venv",
):
    assert importlib.util.find_spec(removed_package) is None, removed_package
assert importlib.util.find_spec("pip") is None
assert importlib.util.find_spec("_uuid") is not None
assert not hasattr(sqlite3.Connection, "enable_load_extension")
assert "md5" in hashlib.algorithms_guaranteed
assert uuid.uuid4().version == 4
assert decimal.Decimal("0.1") + decimal.Decimal("0.2") == decimal.Decimal("0.3")
assert zlib.decompress(zlib.compress(b"runtime-ok")) == b"runtime-ok"
assert bz2.decompress(bz2.compress(b"runtime-ok")) == b"runtime-ok"
assert lzma.decompress(lzma.compress(b"runtime-ok")) == b"runtime-ok"
stdlib_pyc = importlib.util.cache_from_source(pathlib.__file__)
assert os.path.isfile(stdlib_pyc), f"missing precompiled bytecode: {stdlib_pyc}"
PY

test ! -e /usr/local/lib/python3.12/sqlite3/test || fail "sqlite3 tests remain"
