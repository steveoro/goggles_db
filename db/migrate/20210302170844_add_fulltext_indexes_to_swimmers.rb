# frozen_string_literal: true

class AddFulltextIndexesToSwimmers < ActiveRecord::Migration[6.0]
  def self.up
    execute('CREATE FULLTEXT INDEX swimmer_first_name ON swimmers(first_name);')
    execute('CREATE FULLTEXT INDEX swimmer_last_name ON swimmers(last_name);')
    execute('CREATE FULLTEXT INDEX swimmer_complete_name ON swimmers(complete_name);')
  end

  def self.down
    execute('ALTER TABLE swimmers DROP INDEX swimmer_first_name;')
    execute('ALTER TABLE swimmers DROP INDEX swimmer_last_name;')
    execute('ALTER TABLE swimmers DROP INDEX swimmer_complete_name;')
  end
end
