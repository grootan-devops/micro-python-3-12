# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Updated [`docker/login-action`](https://github.com/docker/login-action) from [`v3` to `v3`](https://app.renovatebot.com/package-diff?name=docker%2Flogin-action&from=v3.7.0&to=v3)
- Updated [`docker/login-action`](https://github.com/docker/login-action) from [`v3` to `v3`](https://app.renovatebot.com/package-diff?name=docker%2Flogin-action&from=v3.7.0&to=v3)

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
