JPaaS Monitor API on Rack
=================

Run
---
bundle install
rackup

Note
---
The app should be run under /home/work/dashboard/ dir.

#mysql init

create database jpaas;
grant all privileges on jpaas.* to jpaas@'%' identified by 'mhxzkhl' with grant option;
grant all privileges on jpaas.* to jpaas@localhost identified by 'mhxzkhl' with grant option;
flush privileges;

#make changes to db
rake db:new_migration name=foo_bar_migration
edit db/migrate/20081220234130_foo_bar_migration.rb

#create database
rake DATABASE=jpaas DB=production db:migrate

#standalone_migrations help 
db:create creates the database for the current env
db:create:all creates the databases for all envs
db:drop drops the database for the current env
db:drop:all drops the databases for all envs
db:migrate runs migrations for the current env that have not run yet
db:migrate:up runs one specific migration
db:migrate:down rolls back one specific migration
db:migrate:status shows current migration status
db:rollback rolls back the last migration
db:forward advances the current schema version to the next one
db:seed (only) runs the db/seed.rb file
db:schema:load loads the schema into the current env's database
db:schema:dump dumps the current env's schema (and seems to create the db as well)
db:setup runs db:schema:load, db:seed
db:reset runs db:drop db:setup
db:migrate:redo runs (db:migrate:down db:migrate:up) or (db:rollback db:migrate:migrate) depending on the specified migration
db:migrate:reset runs db:drop db:create db:migrate

