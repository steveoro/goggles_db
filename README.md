# GogglesDb README

[![Build Status](https://semaphoreci.com/api/v1/steveoro/goggles_db/branches/master/shields_badge.svg)](https://semaphoreci.com/steveoro/goggles_db)
[![Build Status](https://steveoro.semaphoreci.com/badges/goggles_db/branches/master.svg)](https://steveoro.semaphoreci.com/projects/goggles_db)
[![Maintainability](https://api.codeclimate.com/v1/badges/ba9e005076a6aa97f788/maintainability)](https://codeclimate.com/github/steveoro/goggles_db/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ba9e005076a6aa97f788/test_coverage)](https://codeclimate.com/github/steveoro/goggles_db/test_coverage)
[![codecov](https://codecov.io/gh/steveoro/goggles_db/branch/master/graph/badge.svg?token=G4E7NVC4T4)](undefined)
[![Coverage Status](https://coveralls.io/repos/github/steveoro/goggles_db/badge.svg?branch=master)](https://coveralls.io/github/steveoro/goggles_db?branch=master)


DB structure and base Rails models for the Goggles Framework applications.


## Wiki & HOW-TOs

Official Framework Wiki, [here](https://github.com/steveoro/goggles_db/wiki) (v. 7+)


## Requires

- Ruby 2.6+
- Rails 6+
- MySql



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'goggles_db', git: 'https://github.com/steveoro/goggles_db'
```

The Engine will add a bunch of rake tasks to the application, among which:

- `db:dump` & `db:rebuild` will assume the existence of any SQL dump files you may have or create under the `db/dump` folder;
- `check_needed_dirs` will be invoked automatically by these tasks to ensure the existence of any other required folder;

WIP :construction:



## How to run the test suite

For local testing, just keep your Guard friend running in the background, in a dedicated console:

```bash
$> guard
```

If you want to run the full test suite, just hit enter on the Guard console.

As of Rails 6.0.3, most probably there are some issues with the combined usage of Guard & Spring together with the new memory management modes in Rails during the Brakeman checks. These prevent the `brakeman` plugin for Guard to actually notice changes in the source code: the checks get re-run, but the result doesn't change. Or maybe it's just a combined mis-configuration.

In any case, although the Guard plugin for Brakeman runs correctly at start, it's always better to re-run the `brakeman` checks before pushing the changes to the repository with:

```bash
$> bundle exec brakeman -Aq
```

_Please, again, commit & push any changes only when the test suite is :green_heart:._



## Database setup

You'll need a proper DB for both the test suite and the local development.

GogglesDb, among others, adds these tasks:

- `db:dump`: dumps current Rails environment DB;
- `db:rebuild`: restores any *.sql.bz2 dump file stored in `db/dump`, provided it is a DB dump without any DB namespaces in it. (No `USE` or `CREATE` database statements)

If you don't have a proper test seed dump, either ask Steve A. nicely for one, or build one yourself by force-loading the SQL structure file after resetting the current DB:

```bash
$> rails db:reset
$> rails structure:load
```

Then, you'll need to use the Factories in spec/factories to create fixtures.

A fully randomized `seed.rb` script is still a work-in-progress. Contributions are welcome.

Assuming we want the `test` environment DB up and running:

- Make sure you have a running MariaDB server & client installation.

- Given you have a valid `db/dump/test.sql.bz2` (the dump must be un-namespaced to be copied or renamed from any other environment - as those created by `db:dump` typically are), use the dedicated rake tasks:

```bash
$> bin/rails db:rebuild from=test to=test
$> RAILS_ENV=test bin/rails db:migrate
```

(It will take some time, depending of the dump size: sit back and relax.)


* * *


## Contributing
1. Clone the project
2. Make a pull request based on the branch most relevant to you
3. Await the PR's review by the maintainers


## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
