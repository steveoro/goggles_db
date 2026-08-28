# Goggles DB Agent Notes

## Database structure changes
- `goggles_db' is the source of truth for the database, so start structure changes here and propagate them to the rest of the framework only after.
- Each time a new migration or view version is created, the test database dump must be updated (see below).
- Always make sure the migration file is copied as in project `goggles_main` (under `db/migrate`). If any view file is added or updated, copy it as well (under `db/views`).
- `goggles_main` is the only other project that needs to be updated with migration and view changes because its entrypoint runs those during container bootstrap.

## Test database dump

- The test suite relies on the fixture database dump at `spec/dummy/db/dump/test.sql.bz2`.
- Whenever migrations or Scenic view definitions change the database structure, migrate the test database and regenerate the fixture dump from `spec/dummy` with `RAILS_ENV=test bundle exec rake db:dump` through the project RVM gemset.
- Include the updated test dump in the same change so clean test and CI environments use the new structure.
