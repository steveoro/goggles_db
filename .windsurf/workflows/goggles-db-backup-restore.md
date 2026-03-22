---
description: How the DB backup/restore works in the Docker production setup, including volume mounts and synch scripts
auto_execution_mode: 2
---

# DB Backup & Restore

Use this skill to understand or perform database backup and restore operations across the Goggles framework.

## Production Setup

The production MariaDB runs inside a Docker container defined in `goggles_api/docker-compose.prod.yml`. Persistent data is stored on the host via volume mounts:

```text
~/Projects/goggles_deploy/
├── db.prod/       # MariaDB data directory (mounted as /var/lib/mysql)
├── backups/       # DB dump files (mounted as /app/db/dump in the API container)
├── storage.prod/  # ActiveStorage files
└── log.prod/      # Application logs
```

The `backups/` directory is shared between the host and the API container, making it easy to move dump files in and out.

## Backup

### From Inside the Docker Container

```bash
# Enter the DB container:
docker exec -it goggles-db bash

# Create a dump:
mariadb-dump -u root -p goggles > /var/lib/mysql/backup_YYYYMMDD.sql

# Or from the host, targeting the container:
docker exec goggles-db mariadb-dump -u root -p goggles > ~/Projects/goggles_deploy/backups/backup_YYYYMMDD.sql
```

### Compress the Dump

```bash
cd ~/Projects/goggles_deploy/backups
bzip2 backup_YYYYMMDD.sql
```

## Restore

### On Production (Docker)

```bash
# Copy dump into the backups volume:
cp backup_YYYYMMDD.sql.bz2 ~/Projects/goggles_deploy/backups/

# Decompress:
cd ~/Projects/goggles_deploy/backups
bunzip2 backup_YYYYMMDD.sql.bz2

# Restore into the DB container:
docker exec -i goggles-db mariadb -u root -p goggles < ~/Projects/goggles_deploy/backups/backup_YYYYMMDD.sql
```

### On Localhost (goggles_admin2)

`goggles_admin2` runs with a local MariaDB (via `docker-compose.yml`). To sync from production:

1. Download the production dump to localhost
2. Restore into the local DB:

```bash
# If using Docker locally:
docker exec -i <local_db_container> mariadb -u root -p goggles_development < backup_YYYYMMDD.sql

# If using a native MariaDB:
mariadb -u root -p goggles_development < backup_YYYYMMDD.sql
```

**Critical**: The localhost DB must be in sync with the remote DB for the import pipeline to work correctly. The `Import::MacroCommitter` generates SQL with explicit IDs — any ID mismatch causes failures.

## synch.sh Scripts

Each consumer project has a `synch.sh` script at its root:

- `/home/steve/Projects/goggles_api/synch.sh`
- `/home/steve/Projects/goggles_main/synch.sh`
- `/home/steve/Projects/goggles_admin2/synch.sh`

These scripts pull the latest code and reinstall gems:

```bash
#!/bin/bash
git pull
GIT_LFS_SKIP_SMUDGE=1 bundle install
```

They are for **code** sync, not DB sync. DB synchronization is a separate manual step.

## Test Database

The test DB structure is managed by migrations in `goggles_db`. For CI and local testing:

```bash
# Rebuild test DB from scratch:
cd /home/steve/Projects/goggles_db
RAILS_ENV=test bin/rails app:db:rebuild from=test to=test
RAILS_ENV=test bin/rails db:migrate
```

The `db:rebuild` rake task loads the test dump (stored in `goggles_db` via Git LFS) and applies any pending migrations. The `GIT_LFS_SKIP_SMUDGE=1` flag in `update_engine.sh` skips downloading this dump in consumer projects.

## MariaDB Container Notes

- Image: `mariadb:latest` (production) or `cimg/mariadb:11.4.1` (CI)
- `max_allowed_packet=67108864` set via `--command` to prevent timeout on large queries
- Port mapping: `33060:3306` (production), avoiding conflicts with local MariaDB on 3306
- The `SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO"` statement in import SQL scripts ensures auto-increment columns handle zero values correctly
