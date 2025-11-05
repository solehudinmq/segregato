# Segregato

Segregato is a Ruby library that implements CQRS, separating the responsibility for writing and reading data across two or more databases. This optimizes database performance, increases flexibility, and makes our databases more scalable.

With the Segregato library, read and write capabilities can now be maximized. Because the databases are separated, our applications will be more scalable and optimized.

## High Flow

Potential problems if our database already has large data :
![Logo Ruby](https://github.com/solehudinmq/segregato/blob/development/high_flow/Segregato-problem.jpg)

With Segregato, our applications can now have good performance for write and read processes :
![Logo Ruby](https://github.com/solehudinmq/segregato/blob/development/high_flow/Segregato-solution.jpg)

## Requirement

The minimum version of Ruby that must be installed is 3.0.

Requires dependencies to the following gems :
- activerecord

- pg

- dotenv (for the development/test environment)

## Installation

Add this line to your Gemfile :

```ruby
# Gemfile
gem 'segregato', git: 'git@github.com:solehudinmq/segregato.git', branch: 'main'
```

Open terminal, and run this : 

```bash
cd your_ruby_application
bundle install
```

### Replication Database Setup

The following are the database replication steps for the pgsql database :

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

For more details, you can see the example in the folder [example/db_replication_setup.txt](https://github.com/solehudinmq/segregato/blob/development/example/db_replication_setup.txt).

### Running Replication Database

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

For more details, you can see the example in the folder [example/running_db_replication.txt](https://github.com/solehudinmq/segregato/blob/development/example/running_db_replication.txt).

## Configuration Database

Make sure your application has files for the configuration database in the root folder, for example :

```ruby
# database.yml
<your-environment>: # you can change it to : development/test/production
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

  replicaN:
    adapter: postgresql
    database: <db-replicaN-name> # change according to your replica N database
    username: <db-replicaN-username>
    password: <db-replicaN-password> # change according to your replica N database password
    host: <db-replicaN-host> # change according to your replicaN host
    port: <db-replicaN-port> # change according to your replica N database port
    pool: <db-replicaN-pool>
```

For more details, you can see the example in the folder [example/database.yml](https://github.com/solehudinmq/segregato/blob/development/example/database.yml).

## Environment Configuration

For 'development' or 'test' environments, make sure the '.env' file is in the root of your application :

```ruby
#.env
DB_ENV=<db-environment> # you can change it to : development/test/production
DB_CONFIG=<config-file-name> # this is the .yml config file
```

For more details, you can see the example in the folder [example/.env](https://github.com/solehudinmq/segregato/blob/development/example/.env).

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

For more details, you can see the example in the folder [example/models/post_command.rb](https://github.com/solehudinmq/segregato/blob/development/example/models/post_command.rb).

In the model that will be implemented for the query (read to database replication) : 
```ruby
class YourModel < StrictReadBase
end
```

For more details, you can see the example in the folder [example/models/post_query.rb](https://github.com/solehudinmq/segregato/blob/development/example/models/post_query.rb).

## Example Implementation in Your Application

For examples of applications that use this gem, you can see them here : [example](https://github.com/solehudinmq/segregato/tree/development/example).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solehudinmq/segregato.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
