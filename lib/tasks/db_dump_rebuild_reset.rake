# frozen_string_literal: true

require 'date'
require 'rubygems'
require 'find'
require 'fileutils'

#
# = Local Deployment helper tasks
#
#   - (p) FASAR Software 2007-2024
#   - for Goggles framework vers.: 7.00
#   - author: Steve A.
#
#   (ASSUMES TO BE rakeD inside Rails.root)
#
#-- ---------------------------------------------------------------------------
#++

# DB Dumps have the same name as current environment and are considered as "current":
DB_DUMP_DIR = Rails.root.join('db/dump').freeze unless defined? DB_DUMP_DIR
# (add here any other needed folder as additional constants)
#-- ---------------------------------------------------------------------------
#++

# [Steve, 20130808] The following will remove the task db:test:prepare
# to avoid having to wait each time a test is run for the db test to reset
# itself:
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
Rake.application.remove_task 'db:reset'
Rake.application.remove_task 'db:test:prepare'

desc 'Check and creates missing directories needed by the structure assumed by some of the maintenance tasks.'
task(check_needed_dirs: :environment) do
  [
    DB_DUMP_DIR
    # (add here any other needed folder)
  ].each do |folder|
    puts "Checking existence of #{folder} (and creating it if missing)..."
    FileUtils.mkdir_p(folder) unless File.directory?(folder)
  end
  puts "\r\n"
end
#-- ---------------------------------------------------------------------------
#++

namespace :db do
  namespace :test do
    desc 'NO-OP task: not needed for this project (always safe to run, shouldn\'t affect the DB dump)'
    task prepare: :environment do |_t|
      # (Rewrite the task to *not* do anything you don't want)
      puts 'Nothing to prepare, moving on...'
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  desc <<~DESC
      This is an override of the standard Rake db:reset task.
    It actually DROPS the Database recreating it using a mysql shell command.

    Options: [Rails.env=#{Rails.env}]

  DESC
  task reset: :environment do |_t|
    puts '*** Task: Custom DB RESET ***'
    rails_config  = Rails.configuration # Prepare & check configuration:
    db_name       = rails_config.database_configuration[Rails.env]['database']
    db_user       = rails_config.database_configuration[Rails.env]['username']
    db_pwd        = rails_config.database_configuration[Rails.env]['password']
    db_host       = rails_config.database_configuration[Rails.env]['host']
    # Display some info:
    puts "DB name:      #{db_name}"
    puts "DB user:      #{db_user}"
    puts "\r\nDropping DB..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=\"#{db_pwd}\" --execute=\"drop database if exists #{db_name}\""
    puts "\r\nRecreating DB..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=\"#{db_pwd}\" --execute=\"create database #{db_name}\""
  end
  #-- -------------------------------------------------------------------------
  #++

  desc <<~DESC
      "db:dump" creates a bzipped MySQL dump of the whole DB for the current environment that
    can be easily rebuildd to any other database name using "db:rebuild".

    The result file does not contain any DB namespaces, nor any "CREATE database" or "USE"
    statements, thus it can be freely executed for any empty destination database, with any
    given database name of choice.

    The file is stored as:

      - 'db/dump/#{Rails.env}.sql.bz2'

      This can be kept inside the source tree of the main app repository to be used for quick
      recovery of the any of the environment DB, using "db:rebuild".

    Options: [Rails.env=#{Rails.env}]

  DESC
  task(dump: [:check_needed_dirs]) do
    puts '*** Task: DB dump ***'
    # Prepare & check configuration:
    rails_config  = Rails.configuration
    db_name       = rails_config.database_configuration[Rails.env]['database']
    db_user       = rails_config.database_configuration[Rails.env]['username']
    db_pwd        = rails_config.database_configuration[Rails.env]['password']
    db_host       = rails_config.database_configuration[Rails.env]['host']
    db_dump(db_host, db_user, db_pwd, db_name, Rails.env)
  end

  # Performs the actual operations required for a DB dump update given the specified
  # parameters.
  #
  # Note that the dump takes the name of the Environment configuration section.
  #
  def db_dump(db_host, db_user, db_pwd, db_name, dump_basename)
    puts "\r\nUpdating recovery dump '#{dump_basename}' (from #{db_name} DB)..."
    # Display some info:
    puts "DB name: #{db_name}"
    puts "DB user: #{db_user}"
    file_name = File.join(DB_DUMP_DIR, "#{dump_basename}.sql")
    puts "\r\nProcessing #{db_name} => #{file_name} ...\r\n"

    create_sql_transaction_header(file_name)
    # To disable extended inserts, add this option: --skip-extended-insert
    # (The Resulting SQL file will be much longer, though -- but the bzipped
    #  version can result more compressed due to the replicated strings, and it is
    #  indeed much more readable and editable...)
    cmd = "mysqldump --host=#{db_host} -u #{db_user} --password=\"#{db_pwd}\" --add-drop-table " \
          "--routines --events --triggers --single-transaction #{db_name} >> #{file_name}"
    sh cmd
    append_sql_transaction_footer(file_name)
    puts "\r\nRecovery dump created."

    compressed_file = "#{file_name}.bz2"
    FileUtils.rm_f(compressed_file)
    puts 'Compressing as bz2...'
    sh "bzip2 #{file_name}"
    puts "\r\nDone.\r\n\r\n"
  end

  # Creates a new +file_name+ with a single-transaction start, in case the dump
  # wasn't built with autocommit toggled off.
  def create_sql_transaction_header(file_name)
    File.open(file_name, 'w+') do |f|
      f.puts "-- #{file_name}\r\n"
      f.puts 'SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";'
      f.puts 'SET AUTOCOMMIT = 0;'
      f.puts 'START TRANSACTION;'
      f.puts "\r\n--\r\n"
    end
  end

  # Adds to +file_name+ a commit statement at the end.
  def append_sql_transaction_footer(file_name)
    File.open(file_name, 'a+') do |f|
      f.puts "\r\n--\r\n"
      f.puts 'COMMIT;'
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  desc <<~DESC
      Recreates the current DB from a recovery dump created with db:dump.

    Options: [Rails.env=#{Rails.env}]
             [from=dump_base_name|<#{Rails.env}>]
             [to='production'|'development'|'test']

      - from: when not specified, the source dump base name will be the same of the
            current Rails.env

      - to: when not specified, the destination database will be the same of the
            current Rails.env

  DESC
  task(rebuild: [:check_needed_dirs]) do
    puts '*** Task: DB rebuild ***'
    # Prepare & check configuration:
    rails_config  = Rails.configuration
    db_name       = rails_config.database_configuration[Rails.env]['database']
    db_user       = rails_config.database_configuration[Rails.env]['username']
    db_pwd        = rails_config.database_configuration[Rails.env]['password']
    db_host       = rails_config.database_configuration[Rails.env]['host']
    dump_basename = ENV.include?('from') ? ENV['from'] : Rails.env
    output_db     = ENV.include?('to')   ? rails_config.database_configuration[ENV['to']]['database'] : db_name
    rebuild(dump_basename, output_db, db_host, db_user, db_pwd)
  end

  # Performs the actual sequence of operations required by a single db:rebuild
  # task, given the specified parameters.
  #
  # The source_basename comes from the name of the file dump.
  # Note that the dump takes the name of the Environment configuration section.
  #
  def rebuild(source_basename, output_db, db_host, db_user, db_pwd)
    puts "\r\nRebuilding..."
    puts "DB name: #{source_basename} (dump) => #{output_db} (DEST)"
    puts "DB user: #{db_user}"

    file_name = File.join(DB_DUMP_DIR, "#{source_basename}.sql.bz2")
    sql_file_name = File.join('tmp', "#{source_basename}.sql")

    puts "\r\nUncompressing dump file '#{file_name}' => '#{sql_file_name}'..."
    sh "bunzip2 -ck #{file_name} > #{sql_file_name}"

    puts "\r\nDropping destination DB '#{output_db}'..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=\"#{db_pwd}\" --execute=\"drop database if exists #{output_db}\""
    puts "\r\nRecreating destination DB..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=\"#{db_pwd}\" --execute=\"create database #{output_db}\""

    puts "\r\nExecuting '#{file_name}' on #{output_db}..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=\"#{db_pwd}\" --database=#{output_db} --execute=\"\\. #{sql_file_name}\""
    puts "Deleting uncompressed file '#{sql_file_name}'..."
    FileUtils.rm(sql_file_name)

    puts "Rebuild from dump for '#{source_basename}', done.\r\n\r\n"
  end
  #-- -------------------------------------------------------------------------
  #++

  desc <<~DESC
      Fixes the current gzipped DB dump so that it can be used with older MariaDB versions used
    by CircleCI.

    Until CircleCI adopts releases a usable container for MariaDB with vers. 11.4.2+,
    each updated test DB dump needs to be edited to remove the sandbox mode parameter which isn't
    recognized by older MariaDB versions.

    The task extracts the dump in its folder, removes the sandbox parameter special comment
    (usually at line 7 of the SQL dump), and then re-zips the file overwriting the original one.

    Options: [Rails.env=#{Rails.env}]
             [from=dump_base_name|<#{Rails.env}>]

      - from: when not specified, the source dump base name will be the same of the
            current Rails.env

  DESC
  task(dump_remove_sandbox: [:check_needed_dirs]) do
    puts '*** Task: DB dump_remove_sandbox ***'
    dump_basename = ENV.include?('from') ? ENV['from'] : Rails.env
    file_name = File.join(DB_DUMP_DIR, "#{dump_basename}.sql.bz2")
    sql_file_name = File.join('tmp', "#{dump_basename}.sql")

    puts "\r\nUncompressing dump file '#{file_name}' => '#{sql_file_name}'..."
    sh("bunzip2 -ck #{file_name} > #{sql_file_name}")
    puts("\r\nFirst 10 lines of the dump file:\r\n-----8<-----")
    sh("head -n 10 #{sql_file_name}")
    puts("-----8<-----\r\n")

    puts("\r\nRemoving line 7 with the special sandbox parameter...")
    sh("head -n 6 #{sql_file_name} > t1.sql")
    sh("tail -n +8 #{sql_file_name} > t2.sql")

    puts("\r\nRejoining the split parts into new destination dump file...")
    sh("cat t1.sql t2.sql > #{sql_file_name}")

    puts("\r\nConfirmation that the special comment line has been removed (first 10 lines):\r\n-----8<-----")
    sh("head -n 10 #{sql_file_name}")
    puts("-----8<-----\r\n")

    puts("\r\nRemoving temp files and bzipping the dump...")
    sh("rm #{file_name}")
    sh('rm t?.sql')
    sh("bzip2 #{sql_file_name}")
  end
  #-- -------------------------------------------------------------------------
  #++
end
