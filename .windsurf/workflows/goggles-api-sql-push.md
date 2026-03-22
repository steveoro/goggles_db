---
description: How admin2 sends SQL scripts to the remote server via the API — ApiProxy + SqlMaker pattern, authentication, and error handling
auto_execution_mode: 2
---

# API SQL Push

Use this skill to understand or debug how `goggles_admin2` sends SQL scripts to the remote `goggles_api` server for execution.

## Overview

The import pipeline in `goggles_admin2` generates SQL scripts locally (via `Import::MacroCommitter` + `SqlMaker`), then pushes them to the remote server through the `goggles_api` REST endpoint. This allows `admin2` to run localhost-only while updating the production database.

```text
goggles_admin2 (localhost)
  │
  │  Import::MacroCommitter
  │    └── SqlMaker (generates INSERT/UPDATE SQL)
  │          └── @sql_log (array of SQL statements)
  │
  │  SQL batch assembled:
  │    SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
  │    SET AUTOCOMMIT = 0;
  │    START TRANSACTION;
  │    -- INSERT/UPDATE statements --
  │    COMMIT;
  │
  └──► APIProxy.call(method: 'post', url: 'import_queues', payload: { sql_batch: ... }, jwt: ...)
         │
         ▼
       goggles_api (remote server)
         └── ImportQueuesAPI endpoint
               └── Executes SQL batch against production DB
```

## Key Components

### SqlMaker (`app/strategies/sql_maker.rb`)

Path: `/home/steve/Projects/goggles_admin2/app/strategies/sql_maker.rb`

Generates replayable SQL from ActiveRecord model instances:

```ruby
maker = SqlMaker.new(row: model_instance)
maker.log_insert    # Generates INSERT statement
maker.log_update    # Generates UPDATE statement (changed columns only)
maker.sql_log       # Array of SQL strings
maker.report        # All statements joined with separator
```

Key methods:

- `log_insert` — generates `INSERT INTO <table> (...) VALUES (...);`
- `log_update(changed_attrs)` — generates `UPDATE <table> SET ... WHERE id = ...;`
- `report(separator)` — joins all log entries into a single string
- `set(row:)` — reuses the maker for a different row without clearing the log
- `force_id_on_insert` — when true (default), includes the `id` column in INSERTs

### APIProxy (`app/strategies/api_proxy.rb`)

Path: `/home/steve/Projects/goggles_admin2/app/strategies/api_proxy.rb`

Singleton REST client wrapping `rest-client`:

```ruby
APIProxy.call(
  method: 'post',
  url: 'import_queues',
  payload: {
    uid: current_user.id,
    request_data: json_data,
    solved_data: solved_json,
    sql_batch: sql_text
  },
  jwt: session_jwt
)
```

Options:

- `:method` — HTTP method (`'get'`, `'post'`, `'put'`, `'delete'`)
- `:url` — API path after `/api/v3/` (e.g. `'import_queues'`)
- `:payload` — body Hash (for POST/PUT)
- `:jwt` — JWT token for authentication
- `:params` — query parameters (for GET)
- `:port_override` — override the API port from settings

The base URL comes from `GogglesDb::AppParameter.config.settings(:framework_urls).api`.

### Authentication

The API requires a JWT token obtained via the session endpoint:

```ruby
# Login to get JWT:
response = APIProxy.call(
  method: 'post',
  url: 'session',
  payload: { e: email, p: password, t: api_token }
)
jwt = JSON.parse(response.body)['jwt']
```

The JWT is then passed in subsequent requests via the `Authorization: Bearer <jwt>` header.

## ImportQueue Model

The `GogglesDb::ImportQueue` model stores queued import jobs:

- `user_id` — who submitted it
- `request_data` — original JSON result data
- `solved_data` — solver output
- `sql_batch` — the SQL script to execute
- `done` — whether it's been processed
- `uid` — unique identifier

The API endpoint creates an `ImportQueue` row, and the server-side processing executes the `sql_batch` against the production database.

## Error Handling

`APIProxy.call` rescues `RestClient::ExceptionWithResponse` and returns the error response object. Check the response:

```ruby
response = APIProxy.call(...)
if response.code == 200 || response.code == 201
  # Success
  result = JSON.parse(response.body)
else
  # Error
  Rails.logger.error("API Error #{response.code}: #{response.body}")
end
```

Common errors:

- **401 Unauthorized** — JWT expired or invalid. Re-authenticate.
- **422 Unprocessable Entity** — Validation failure (e.g. malformed SQL, missing required fields)
- **500 Internal Server Error** — Server-side execution failure (check API logs)
- **Connection refused** — API server down or wrong port

## Critical Prerequisite

**The localhost DB must be in sync with the remote DB.** The SQL uses explicit IDs for INSERT and WHERE clauses. If the local DB has different IDs than remote (due to drift), the SQL will either fail or corrupt data.

Sync procedure:

1. Download a production DB dump
2. Restore it to the localhost DB
3. Then run the import pipeline

See `/goggles-db-backup-restore` skill for details.

## Debugging Tips

- **Inspect SQL before sending**: `committer.sql_log.join("\n")` — review the generated SQL manually
- **Test SQL locally first**: Execute the SQL on the localhost DB to verify it works before pushing
- **Check API logs**: On the server, check `log/api_audit.log` for request details
- **ImportQueue status**: Query `GogglesDb::ImportQueue.last` to check if the queue item was created and its `done` status
