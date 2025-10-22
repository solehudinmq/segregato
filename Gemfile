# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in segregato.gemspec
gemspec

gem "activerecord"
gem "concurrent-ruby"
gem "pg"
gem "yaml"

group :development, :test do
  gem "byebug"
end

group :development do
  gem "irb"
  gem "rake"
  gem "rubocop"
end

group :test do
  gem "rspec"
  gem "sqlite3"
end