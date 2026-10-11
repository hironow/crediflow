set shell := ["bash", "-euo", "pipefail", "-c"]

check: lint-workflows install lint type build browsers test

install:
    cd web && bun install --frozen-lockfile

# Verify all tarballs against official npm with a fresh cache.
install-fresh:
    cd web && bun install --frozen-lockfile --force

lint:
    cd web && bun run lint

type:
    cd web && bun run check --fail-on-warnings

build:
    cd web && bun run build

browsers:
    cd web && bunx playwright install --with-deps chromium

test:
    cd web && bun run test

install-actionlint:
    go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.12
    if [ -n "${GITHUB_PATH:-}" ]; then printf '%s/bin\n' "$(go env GOPATH)" >> "$GITHUB_PATH"; fi

lint-workflows:
    actionlint .github/workflows/*.yaml

update-node-types:
    cd web && bun add --dev --exact @types/node@24

fmt:
    cd web && bun run fmt
