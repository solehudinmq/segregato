# Segregato

Segregato is a Ruby library that implements CQRS, separating the responsibility for writing and reading data across two or more databases. This optimizes database performance, increases flexibility, and makes our databases more scalable.

With the Segregato library, read and write capabilities can now be maximized. Because the databases are separated, our applications will be more scalable and optimized.

## High Flow

Potential problems if our database already has large data :
![Logo Ruby](https://github.com/solehudinmq/segregato/blob/development/high_flow/Segregato-problem.jpg)

With Segregato, our applications can now have good performance for write and read processes. :
![Logo Ruby](https://github.com/solehudinmq/segregato/blob/development/high_flow/Segregato-solution.jpg)

## Installation

The minimum version of Ruby that must be installed is 3.0.
Only runs on 'activerecord', and install the 'dotenv' gem for the development/test environment.

Add this line to your application's Gemfile :
```ruby
gem 'segregato', git: 'git@github.com:solehudinmq/segregato.git', branch: 'main'
```

Open terminal, and run this : 
```bash
cd your_ruby_application
bundle install
```

Setup database replication, here is an example in pgsql :
```bash
# create a folder
sudo mkdir <folder-master-location>/master
sudo mkdir <folder-replication-1-location>/standby1
sudo mkdir <folder-replication-N-location>/standbyN

# change user folder privileges to postgres
sudo chown -R postgres:postgres <folder-master-location>/master
sudo chown -R postgres:postgres <folder-replication-1-location>/standby1
sudo chown -R postgres:postgres <folder-replication-N-location>/standbyN

# master data initialization (port 5432)
sudo -u postgres <postgresql-installation-location>/bin/initdb -D <folder-master-location>/master

# check standby1 & standbyN folders must belong to the postgres user
ls -ld <folder-replication-1-location>/standby1
ls -ld <folder-replication-N-location>/standbyN

# master database configuration
sudo nano <folder-master-location>/master/postgresql.conf

# start content
listen_addresses = '<listen-from-ip>'
port = <database-master-port>
wal_level = replica
max_wal_senders = <maximum-number-of-wal-sender-processes-that-can-run-concurrently>
max_replication_slots = <maximum-number-of-replication-slots>
hot_standby = on
# end content

# postgreSQL client authentication configuration file
sudo -u postgres nano <folder-master-location>/master/pg_hba.conf

# start content
host    replication     replication_user       <ip-address>/32            scram-sha-256
# end content

# stop postgresql default (if any)
sudo systemctl stop postgresql

# start database master
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl start -D <folder-master-location>/master -l <folder-master-location>/master/master.log

# check if the master database is running
sudo ss -nlt | grep <database-master-port>

# replica database initialization (port 5433 & 5434)
# stop & delete replica 1
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl stop -D <folder-replication-1-location>/standby1
sudo -u postgres rm -rf <folder-replication-1-location>/standby1/*

# stop & delete replica N
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl stop -D <folder-replication-N-location>/standbyN
sudo -u postgres rm -rf <folder-replication-N-location>/standbyN/*

# login to psql cli
sudo -u postgres psql

CREATE USER <replication-user> WITH REPLICATION LOGIN ENCRYPTED PASSWORD '<replication-user-password>';

SELECT * FROM pg_create_physical_replication_slot('standby1_slot');
SELECT * FROM pg_create_physical_replication_slot('standbyN_slot');
SELECT slot_name, slot_type, active FROM pg_replication_slots;
# logout from psql cli

# creating a Base Backup (initial data copy) from the primary PostgreSQL server and preparing the current server to become a Standby server (Replica), using the Streaming Replication and Replication Slot methods.
sudo -u postgres pg_basebackup -h <master-ip-address> -p <database-master-port> -U <replication-user> -D <folder-replication-1-location>/standby1 -F p -X stream -R -W -v --slot=standby1_slot
sudo -u postgres pg_basebackup -h <master-ip-address> -p <database-master-port> -U <replication-user> -D <folder-replication-N-location>/standbyN -F p -X stream -R -W -v --slot=standbyN_slot

# replica1 database configuration
sudo -u postgres nano <folder-replication-1-location>/standby1/postgresql.conf

# start content
port = <replica1-port>
# end content

# replicaN database configuration
sudo -u postgres nano <folder-replication-N-location>/standbyN/postgresql.conf

# start content
port = <replicaN-port>
# end content

# update replica permissions
sudo chmod 0700 <folder-replication-1-location>/standby1
sudo chmod 0700 <folder-replication-N-location>/standbyN

# start database replica
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl start -D <folder-replication-1-location>/standby1 -l <folder-replication-1-location>/standby1/standby1.log
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl start -D <folder-replication-N-location>/standbyN -l <folder-replication-N-location>/standbyN/standbyN.log

# check if the replica database is running
sudo ss -nlt | grep <replica1-port>
sudo ss -nlt | grep <replicaN-port>

# login to psql cli
sudo -u postgres psql

SELECT client_addr, state, sync_state, application_name
FROM pg_stat_replication;

CREATE DATABASE <db-name>;

\c <db-name>;

CREATE TABLE <your-table> (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field1 <type-data>,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

# logout from psql cli

```

Example : 
```bash
# create a folder
sudo mkdir /var/lib/postgresql/16/master
sudo mkdir /var/lib/postgresql/16/standby1
sudo mkdir /var/lib/postgresql/16/standby2

# change user folder privileges to postgres
sudo chown -R postgres:postgres /var/lib/postgresql/16/master
sudo chown -R postgres:postgres /var/lib/postgresql/16/standby1
sudo chown -R postgres:postgres /var/lib/postgresql/16/standby2

# master data initialization (port 5432)
sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/master

# check standby1 & standbyN folders must belong to the postgres user
ls -ld /var/lib/postgresql/16/standby1
ls -ld /var/lib/postgresql/16/standby2

# master database configuration
sudo nano /var/lib/postgresql/16/master/postgresql.conf

# start content
listen_addresses = '*'
port = 5432
wal_level = replica
max_wal_senders = 4
max_replication_slots = 2
hot_standby = on
# end content

# postgreSQL client authentication configuration file
sudo -u postgres nano /var/lib/postgresql/16/master/pg_hba.conf

# start content
host    replication     replication_user       127.0.0.1/32            scram-sha-256
# end content

# stop postgresql default (if any)
sudo systemctl stop postgresql

# start database master
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl start -D /var/lib/postgresql/16/master -l /var/lib/postgresql/16/master/master.log

# check if the master database is running
sudo ss -nlt | grep 5432

# replica database initialization (port 5433 & 5434)
# stop & delete replica 1
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl stop -D /var/lib/postgresql/16/standby1
sudo -u postgres rm -rf /var/lib/postgresql/16/standby1/*
# stop & delete replica N
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl stop -D /var/lib/postgresql/16/standby2
sudo -u postgres rm -rf /var/lib/postgresql/16/standby2/*

# login to psql cli
sudo -u postgres psql

CREATE USER replication_user WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'replication_user';

SELECT * FROM pg_create_physical_replication_slot('standby1_slot');
SELECT * FROM pg_create_physical_replication_slot('standby2_slot');
SELECT slot_name, slot_type, active FROM pg_replication_slots;
# logout from psql cli

# creating a Base Backup (initial data copy) from the primary PostgreSQL server and preparing the current server to become a Standby server (Replica), using the Streaming Replication and Replication Slot methods.
sudo -u postgres pg_basebackup -h 127.0.0.1 -p 5432 -U replication_user -D /var/lib/postgresql/16/standby1 -F p -X stream -R -W -v --slot=standby1_slot
sudo -u postgres pg_basebackup -h 127.0.0.1 -p 5432 -U replication_user -D /var/lib/postgresql/16/standby2 -F p -X stream -R -W -v --slot=standby2_slot

# replica1 database configuration
sudo -u postgres nano /var/lib/postgresql/16/standby1/postgresql.conf

# start content
port = 5433
# end content

# replicaN database configuration
sudo -u postgres nano /var/lib/postgresql/16/standby2/postgresql.conf

# start content
port = 5434
# end content

# update replica permissions
sudo chmod 0700 /var/lib/postgresql/16/standby1
sudo chmod 0700 /var/lib/postgresql/16/standby2

# start database replica
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl start -D /var/lib/postgresql/16/standby1 -l /var/lib/postgresql/16/standby1/standby1.log
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl start -D /var/lib/postgresql/16/standby2 -l /var/lib/postgresql/16/standby2/standby2.log

# check if the replica database is running
sudo ss -nlt | grep 5433
sudo ss -nlt | grep 5434

# login to psql cli
sudo -u postgres psql

SELECT client_addr, state, sync_state, application_name
FROM pg_stat_replication;

CREATE DATABASE coba_cqrs;

\c coba_cqrs;

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

# logout from psql cli
```

If you already have a replicated database and want to run it in pgsql, you can do the following :
```bash
# stop postgresql default (if any)
sudo systemctl stop postgresql

# running the database
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl start -D <folder-master-location>/master -l <folder-master-location>/master/master.log
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl start -D <folder-replication-1-location>/standby1 -l <folder-replication-1-location>/standby1/standby1.log
sudo -u postgres <postgresql-installation-location>/bin/pg_ctl start -D <folder-replication-N-location>/standbyN -l <folder-replication-N-location>/standbyN/standbyN.log

# check that the master and replica databases are running
sudo ss -nlt | grep <master-port>
sudo ss -nlt | grep <replica1-port>
sudo ss -nlt | grep <replicaN-port>
```

Example : 
```bash
# stop postgresql default (if any)
sudo systemctl stop postgresql

# running the database
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl start -D /var/lib/postgresql/16/master -l /var/lib/postgresql/16/master/master.log
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl start -D /var/lib/postgresql/16/standby1 -l /var/lib/postgresql/16/standby1/standby1.log
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl start -D /var/lib/postgresql/16/standby2 -l /var/lib/postgresql/16/standby2/standby2.log

# check that the master and replica databases are running
sudo ss -nlt | grep 5432
sudo ss -nlt | grep 5433
sudo ss -nlt | grep 5434
```

Make sure there's a configuration file in the database, for example 'database.yml' (the file is located in the root folder of your application). Here's an example for pgsql :
```ruby
# database.yml
<env>: # you can change it to : development/test/production
  master: # master keyword is required
    adapter: postgresql
    database: <db-master-name> # change according to your master database
    username: <db-master-username> 
    password: <db-master-password> # change according to your master database password
    host: <db-master-host> # change according to your master host
    port: <db-master-port> # change according to your master database port
    pool: <db-master-pool>

  # There must be at least 1 replica database
  replica1:
    adapter: postgresql
    database: <db-replica1-name> # change according to your replica 1 database
    username: <db-replica1-username> 
    password: <db-replica1-password> # change according to your replica 1 database password
    host: <db-replica1-host> # change according to your replica1 host
    port: <db-replica1-port> # change according to your replica 1 database port
    pool: <db-replica1-pool>

  replica2:
    adapter: postgresql
    database: <db-replica2-name> # change according to your replica N database
    username: <db-replica2-username>
    password: <db-replica2-password> # change according to your replica N database password
    host: <db-replica2-host> # change according to your replicaN host
    port: <db-replica2-port> # change according to your replica N database port
    pool: <db-replica2-pool>
```

Specifically for development and test environments, ensure there's an .env file in your application folder. Here's an example :
```ruby
#.env
DB_ENV=<db-environment> # you can change it to : development/test/production
DB_CONFIG=<config-file-name> # this is the .yml config file
```

## Usage

To use this library, add this to your code :
```ruby
require 'segregato'

include Segregato
```

In the model that will be implemented for the command (write to database master) : 
```ruby
class YourModel < StrictWriteBase
end
```

Example : 
```ruby
class PostCommand < StrictWriteBase
  self.table_name = 'posts'

  validates :title, presence: true, length: { minimum: 1 }
end
```

In the model that will be implemented for the query (read to database replication) : 
```ruby
class YourModel < StrictReadBase
end
```

Example : 
```ruby
class PostQuery < StrictReadBase
  self.table_name = 'posts'
end
```

The following is an example of use in the application :
- Gemfile : 
```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gem "byebug"
gem "sinatra"
gem "activerecord"
gem "pg"
gem "dotenv", groups: [:development, :test]
gem "segregato", git: "git@github.com:solehudinmq/segregato.git", branch: "main"
gem "rackup", "~> 2.2"
gem "puma", "~> 7.1"

```

- database.yml
```ruby
# database.yml
development: # you can change it to : development/test/production
  master: # master keyword is required
    adapter: postgresql
    database: coba_cqrs # change according to your master database
    username: postgres 
    password: password # change according to your master database password
    host: localhost # change according to your master host
    port: 5432 # change according to your master database port
    pool: 5

  # There must be at least 1 replica database
  replica1:
    adapter: postgresql
    database: coba_cqrs # change according to your replica 1 database
    username: postgres
    password: password # change according to your replica 1 database password
    host: localhost # change according to your replica1 host
    port: 5433 # change according to your replica 1 database port
    pool: 5

  replica2:
    adapter: postgresql
    database: coba_cqrs # change according to your replica N database
    username: postgres
    password: password # change according to your replica N database password
    host: localhost # change according to your replicaN host
    port: 5434 # change according to your replica N database port
    pool: 5
```

- .env
```ruby
#.env
DB_ENV=development # you can change it to : development/test/production
DB_CONFIG=database.yml # you can change it according to your config database name
```

- models/post_command.rb
```ruby
class PostCommand < StrictWriteBase
  self.table_name = 'posts'

  validates :title, presence: true, length: { minimum: 1 }
end
```

- models/post_query.rb
```ruby
class PostQuery < StrictReadBase
  self.table_name = 'posts'
end
```

- app.rb : 
```ruby
# app.rb
require 'sinatra'
require 'json'
require 'byebug'
require 'segregato'
require 'dotenv/load'

include Segregato

require_relative 'models/post_command'
require_relative 'models/post_query'

before do
  content_type :json
end

# write operations
post '/posts' do
  begin
    data = JSON.parse(request.body.read)
        
    post = PostCommand.create!(
      title: data['title'], 
      content: data['content']
    )
    
    status 201
    { message: "Post berhasil dibuat.", id: post.id }.to_json
  rescue => e
    status 500
    return { error: e.message }.to_json
  end
end

# read operations
get '/posts' do
  begin
    posts = PostQuery.all.map do |post|
      { 
        id: post.id, 
        title: post.title, 
        content: post.content 
      }
    end

    { count: posts.size, posts: posts }.to_json
  rescue => e
    status 500
    return { error: e.message }.to_json
  end
end

# bundle install
# bundle exec ruby app.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solehudinmq/segregato.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
