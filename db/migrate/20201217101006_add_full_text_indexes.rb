# frozen_string_literal: true

class AddFullTextIndexes < ActiveRecord::Migration[6.0]
  def self.up
    execute('CREATE FULLTEXT INDEX city_name ON cities(name, area);')
    execute('CREATE FULLTEXT INDEX meeting_name ON meetings(description, code);')
    execute('CREATE FULLTEXT INDEX swimmer_name ON swimmers(last_name, first_name, complete_name);')
    execute('CREATE FULLTEXT INDEX swimming_pool_name ON swimming_pools(name);')
    execute('CREATE FULLTEXT INDEX team_name ON teams(name, editable_name, name_variations);')
    execute('CREATE FULLTEXT INDEX team_affiliation_name ON team_affiliations(name);')
  end

  def self.down
    execute('ALTER TABLE cities DROP INDEX city_name;')
    execute('ALTER TABLE meetings DROP INDEX meeting_name;')
    execute('ALTER TABLE swimmers DROP INDEX swimmer_name;')
    execute('ALTER TABLE swimming_pools DROP INDEX swimming_pool_name;')
    execute('ALTER TABLE teams DROP INDEX team_name;')
    execute('ALTER TABLE team_affiliations DROP INDEX team_affiliation_name;')
  end
end
