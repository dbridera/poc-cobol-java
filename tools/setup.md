# Toolchain setup

This machine is missing the entire toolchain (`cobc`, `java`, `mvn`, `docker`).
Pick one of the install options below.

## Option 1 — Homebrew (simplest, recommended for the PoC)

```bash
# COBOL compiler (GnuCOBOL bundles `cobc`)
brew install gnu-cobol

# Java 21 (Temurin LTS) + Maven
brew install --cask temurin@21
brew install maven

# Postgres via Docker
brew install --cask docker
# launch Docker.app once, then:
docker run --name poc-postgres \
  -e POSTGRES_PASSWORD=poc \
  -e POSTGRES_USER=poc \
  -e POSTGRES_DB=poc \
  -p 5432:5432 -d postgres:16
```

Verify:

```bash
cobc --version | head -1     # -> cobc (GnuCOBOL) 3.x.x
java -version                # -> openjdk 21.x
mvn -v | head -1             # -> Apache Maven 3.x
docker ps                    # -> running poc-postgres
```

## Option 2 — Use `sdkman` for Java + Maven

If you prefer per-shell version management:

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 21-tem
sdk install maven
```

(Still need `brew install gnu-cobol` for `cobc`, and Docker for Postgres.)

## Option 3 — Devcontainer / Docker-only

If you'd rather not install on the host, we can later add a `.devcontainer/` with everything baked in. **Not done yet.** Ask if you want this.

## Postgres without Docker

```bash
brew install postgresql@16
brew services start postgresql@16
createuser poc -s
createdb -O poc poc
psql -d poc -c "ALTER USER poc WITH PASSWORD 'poc';"
```

## Sanity check after install

From the repo root:

```bash
./tools/run-cobol.sh --self-test    # compiles a hello-world COBOL program
```
