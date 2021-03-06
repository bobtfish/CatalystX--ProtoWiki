#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'CatalystX-ProtoWiki';
all_from 'lib/CatalystX/ProtoWiki.pm';

requires 'Catalyst::Runtime' => '5.80005';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'parent';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Authentication::Credential::HTTP';
requires 'DBIx::Class::EncodedColumn';

requires 'Catalyst::Example::InstantCRUD' => '0.033';

test_requires 'String::Random';

install_script glob('script/*.pl');
auto_install;
WriteAll;
