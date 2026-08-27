# Goggles DB Agent Notes

## Test database dump

- The test suite relies on the fixture database dump at `spec/dummy/db/dump/test.sql.bz2`.
- Whenever migrations or Scenic view definitions change the database structure, migrate the test database and regenerate the fixture dump with `RAILS_ENV=test bundle exec rake db:dump` through the project RVM gemset.
- Include the updated test dump in the same change so clean test and CI environments use the new structure.
