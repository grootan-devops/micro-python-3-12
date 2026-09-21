# micro-python-3-12

Minimal optimized CPython image built directly with Buildah on top of the
Grootan micro-root image. The project intentionally contains no Dockerfile.

## Image

- Registry: Docker Hub
- Repository: `grootantec/micro-python-3-12`
- Release: `1.0.0`
- Python: `3.12.14`
- Base: `grootantec/micro-root:1.5.1`

The image uses `/usr/bin/dumb-init --` as its entrypoint and starts
`python3.12` by default. It is built with PGO/LTO, includes `uv`, and removes
development tools and package-manager executables from the runtime image.

## Build and test

The GitHub Actions workflows build the image with Buildah, execute
`ci_image_test.sh` as UID `10001:10001`, and run a blocking Trivy image scan.
The same checks run for pull requests and release candidates.

## License

This project is licensed under the GNU Affero General Public License v3.0.
See [LICENSE.md](LICENSE.md).
