# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.1.3] - 2026-10-07

### Changed

- Updated [`docker/login-action`](https://github.com/docker/login-action) from [`v3@dbcb813` to `v3@c94ce9f`](https://github.com/docker/login-action/compare/dbcb813823bdd20940b903addbd779551569679f...c94ce9fb468520275223c153574b00df6fe4bcc9)

## [1.1.2] - 2026-09-29

### Fixed

- Doc string not found issues in project code

## [1.1.1] - 2026-09-23

### Changed

- Use the fully qualified `docker.io/grootantech/micro-root` reference so Buildah does not require interactive short-name resolution.

## [1.1.0] - 2026-09-22

### Changed

- Pinned the GitHub Actions build, verification, and release workflows to `github-ci-library` 1.0.0.

## [1.0.0] - 2026-09-22

### Added

- Initial optimized CPython 3.12 Buildah image based on micro-root 1.5.1.
- GitHub Actions build, smoke-test, security-scan, and release workflows.
