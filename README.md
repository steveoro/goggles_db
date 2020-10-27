# goggles_db

[![Build Status](https://semaphoreci.com/api/v1/steveoro/goggles_db/branches/master/shields_badge.svg)](https://semaphoreci.com/steveoro/goggles_db)
[![Build Status](https://steveoro.semaphoreci.com/badges/goggles_db/branches/master.svg)](https://steveoro.semaphoreci.com/projects/goggles_db)

DB structure and base Rails models for the main Goggles application.


## Requires

- Ruby 2.6+
- Rails 6+
- MySql


## Usage
TODO


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'goggles_db'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install goggles_db
```


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



## How to run the test suite

Although builds are automatically launched remotely on any `push`, for any branch or pull-request, make sure the test suite is locally green before pushing changes, in order to save build machine time and not clutter the build queue with tiny commits.

For local testing, just keep your Guard friend running in the background, in a dedicated console:

```bash
$> guard
```

As of Rails 6.0.3, most probably there are issues with the combined usage of Guard, Spring together with the new Zeitwerk mode for constant autoloading & reloading during the Brakeman checks: the `brakeman` plugin for Guard doesn't seem to notice actual changes in the source code, even when you fix or create issues (or maybe it's just a combined mis-configuration).

In any case, although the Guard plugin for Brakeman runs correctly at start, it's always better to re-run the `brakeman` checks before pushing the changes to the repository with:

```bash
$> bundle exec brakeman -Aq
```

_Please, commit & push any changes only when the test suite is :green:._


## Contributing
1. Clone the project
2. Make a pull request based on the branch most relevant to you
3. Await the PR's review by the maintainers


## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
