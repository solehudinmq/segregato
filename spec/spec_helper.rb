# frozen_string_literal: true
require 'fileutils'
require 'active_record'
require "dotenv"
require "byebug"

Dotenv.load(".env", "spec/.env.test")

require "segregato"

include Segregato

ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.table_exists?(:posts)
    create_table :posts do |t|
      t.string :title
      t.string :content
      t.integer :view, default: 0
      t.timestamps
    end
  end
end

require_relative 'post_command'
require_relative 'post_query'
require_relative 'replica_simulation'

PostCommand.reset_column_information
PostQuery.reset_column_information

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
