---
description: Goggles framework onboarding — architecture, projects, dependencies, deployment topology
auto_execution_mode: 2
---

# Goggles Framework Overview

Use this skill when you need to understand the overall Goggles framework architecture, how the four projects relate, or where a particular piece of functionality lives.

## The Four Projects

### 1. `goggles_db` (Rails Engine Gem)

- **Path**: `/home/steve/Projects/goggles_db`
- **Role**: Shared database structure, models, strategies, decorators, commands, validators, factories
- **Stack**: Rails 6.1, Ruby 3.1.4, MariaDB (mysql2 adapter), Scenic (DB views), Devise, Draper, SimpleCommand
- **Key directories**:
  - `app/models/goggles_db/` — 50+ ActiveRecord models (namespaced under `GogglesDb::`)
  - `app/commands/` — SimpleCommand-based commands
  - `app/decorators/` — Draper decorators (20 files)
  - `app/strategies/goggles_db/` — calculators, db_finders, normalizers, timing_finders
  - `app/validators/` — custom validators
  - `db/migrate/` — all migrations (100+)
  - `db/views/` — Scenic SQL view definitions
  - `spec/` — RSpec test suite
- **Versioning**: `lib/goggles_db/version.rb` defines `GogglesDb::VERSION` (semantic) and `GogglesDb::Version::DB` (internal DB structure version)
- **Published as**: Git-sourced gem (`gem 'goggles_db', git: 'https://github.com/steveoro/goggles_db'`)

### 2. `goggles_api` (Public API)

- **Path**: `/home/steve/Projects/goggles_api`
- **Role**: RESTful JSON API (Grape), main read/write interface for all clients
- **Stack**: Rails 6.1, Ruby 3.1.4, Grape API framework, Kaminari pagination, JWT auth
- **Key directories**:
  - `app/api/goggles/` — 38 Grape API endpoint files (e.g. `swimmers_api.rb`, `meetings_api.rb`)
  - `app/api/goggles/api.rb` — Master API mount point (mounts all sub-APIs)
  - `app/api/goggles/api_helpers.rb` — Shared Grape helpers (JWT check, filtering, pagination)
  - `app/commands/` — API-specific commands
  - `blueprint/` — API Blueprint documentation
- **Deployment**: Docker containers (`Dockerfile.dev`, `Dockerfile.staging`, `Dockerfile.prod`)
  - `docker-compose.prod.yml` runs MariaDB + API as composed service on the public server
  - goggles_main is composed alongside in the same Docker network

### 3. `goggles_main` (Public Frontend)

- **Path**: `/home/steve/Projects/goggles_main`
- **Role**: Public-facing result browser — read-only interface for swimming competition results
- **Stack**: Rails 6.1, Ruby 3.1.4, Webpacker, Stimulus, HAML, ViewComponent, Datagrid, Devise, Cucumber
- **Key directories**:
  - `app/components/` — 92 ViewComponents
  - `app/controllers/` — 23 controllers
  - `app/decorators/` — 8 decorators (extend GogglesDb decorators)
  - `app/grids/` — 6 Datagrid definitions
  - `app/strategies/` — 26 strategy files
  - `app/views/` — 140 HAML view templates
  - `app/javascript/` — Stimulus controllers and JS
  - `features/` — Cucumber feature specs
- **Deployment**: Composed with goggles_api in Docker on the public server

### 4. `goggles_admin2` (Admin / Data Collector)

- **Path**: `/home/steve/Projects/goggles_admin2`
- **Role**: Result collector and aggregator — imports, parses, merges, and commits swimming results
- **Stack**: Rails 6.1, Ruby 3.1.4, Webpacker, Stimulus, HAML, ViewComponent, Datagrid, Kiba (ETL), ActionCable, caxlsx
- **Key directories**:
  - `app/strategies/pdf_results/` — PDF result parser engine (FormatParser, 46+ YAML format definitions)
  - `app/strategies/import/` — Import pipeline (MacroSolver, MacroCommitter, solvers, committers, adapters)
  - `app/strategies/merge/` — Merge strategies (badge, swimmer, team, meeting deduplication)
  - `app/strategies/parser/` — Parsers for city names, event types, scores, timings, dates
  - `app/components/` — 65 ViewComponents
  - `app/controllers/` — 28 controllers
  - `app/grids/` — 21 Datagrid definitions
  - `app/services/` — 7 service objects
  - `crawler/` — Node.js web crawler (Cheerio-based) for scraping official result sites
  - `app/strategies/api_proxy.rb` — Proxy for sending data to goggles_api
  - `app/strategies/sql_maker.rb` — SQL script generator
- **Deployment**: Localhost-only; sends SQL scripts to the remote server through goggles_api

## Dependency Graph

```text
goggles_db (Rails Engine gem)
    │
    ├── goggles_api (depends_on via Gemfile git source)
    │       │
    │       └── deployed as Docker container on public server
    │
    ├── goggles_main (depends_on via Gemfile git source)
    │       │
    │       └── deployed as Docker container on public server (same network as api)
    │
    └── goggles_admin2 (depends_on via Gemfile git source)
            │
            └── localhost-only, pushes SQL via API
```

All three consumer projects include an `update_engine.sh` script that runs:

```bash
GIT_LFS_SKIP_SMUDGE=1 bundle update goggles_db
```

## Deployment Topology

- **Public server**: `goggles_api` + `goggles_main` + MariaDB in Docker Compose
  - Three environments: dev, staging, prod (separate Dockerfile and docker-compose per env)
  - Volume mounts for DB data, storage, logs, backups, master keys
  - CI: CircleCI (config: `.circleci/config.yml`; DB config: `config/database_ci.yml`)
  - Legacy Semaphore 2 configs (`config/database.semaphore_2.yml`) kept for reference but no longer active
  - Pipeline: green test suite → container image build → automatic deployment

- **Localhost**: `goggles_admin2` runs locally with direct DB access (no CI pipeline)
  - Uses `docker-compose.yml` for local MariaDB
  - Crawls results from official sites (JS crawler)
  - Processes PDFs and HTML into structured data
  - Generates SQL scripts, sends them to the remote API via `ApiProxy`

## Common Patterns Across Projects

1. **GogglesDb:: namespace** — All shared models, commands, strategies are namespaced
2. **Draper decorators** — Used in goggles_db (base), extended in main/admin2
3. **Datagrid** — Used in goggles_main (6 grids) and goggles_admin2 (21 grids)
4. **ViewComponent** — Used in goggles_main (92) and goggles_admin2 (65)
5. **RSpec** — All projects use RSpec; main and admin2 also use Cucumber
6. **Guard** — All projects have a Guardfile for auto-running specs
7. **Scenic** — DB views defined in goggles_db, adapter gem in api/main/admin2
8. **Factory Bot + FFaker** — Shared factories published from goggles_db gem

## Key Decision: Where Does New Code Go?

- **Database structure, models, associations, validations, scopes** → `goggles_db`
- **API endpoints, serialization, authorization** → `goggles_api`
- **Public UI pages, components, user-facing features** → `goggles_main`
- **Data import, PDF parsing, crawling, merging, admin tools** → `goggles_admin2`
- **Shared business logic, calculations, finders** → `goggles_db/app/strategies/`
- **Shared decorators** → `goggles_db/app/decorators/`
