# frozen_string_literal: true

class ForceVarcharKeysToUseLatin1 < ActiveRecord::Migration[6.0]
  def self.up
    # Force charset to latin1 for index keys using large varchars (> 192), which may yield SQL script errors when
    # running on MySQL (not on MariaDB).
    # (latin1 uses 1 byte per char, utf8 uses 4, utf8mb4 uses 8)
    execute('ALTER TABLE admin_grants CHANGE entity entity varchar(150) CHARACTER SET latin1 DEFAULT NULL;')
    execute('ALTER TABLE api_daily_uses CHANGE route route varchar(255) CHARACTER SET latin1 NOT NULL;')
    execute('ALTER TABLE schema_migrations CHANGE version version varchar(255) CHARACTER SET latin1 DEFAULT NULL;')
    execute('ALTER TABLE sessions CHANGE session_id session_id varchar(255) CHARACTER SET latin1 DEFAULT NULL;')

    execute('ALTER TABLE settings CHANGE var var varchar(255) CHARACTER SET latin1 NOT NULL;')
    execute('ALTER TABLE settings CHANGE target_type target_type varchar(255) CHARACTER SET latin1 NOT NULL;')

    # taggings already set as latin1:
    # execute('ALTER TABLE taggings CHANGE taggable_type taggable_type varchar(255) CHARACTER SET latin1 DEFAULT NULL;')
    # execute('ALTER TABLE taggings CHANGE tagger_type tagger_type varchar(255) CHARACTER SET latin1 DEFAULT NULL;')

    execute('ALTER TABLE users CHANGE name name varchar(190) NOT NULL;')
    execute('ALTER TABLE users CHANGE email email varchar(190) NOT NULL;')

    execute('ALTER TABLE votes CHANGE votable_type votable_type varchar(255) CHARACTER SET latin1 DEFAULT NULL;')
    execute('ALTER TABLE votes CHANGE voter_type voter_type varchar(255) CHARACTER SET latin1 DEFAULT NULL;')
    execute('ALTER TABLE votes CHANGE vote_scope vote_scope varchar(255) CHARACTER SET latin1 DEFAULT NULL;')
  end

  def self.down
    # (no-op)
  end
end
