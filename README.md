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
