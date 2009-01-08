#
# Copyright 2005 David LaPorte <david@davidlaporte.org>
# Copyright 2005 Kevin Amorin <kev@amorin.org>
#
# See the enclosed file COPYING for license information (GPL).
# If you did not receive this file, see
# http://www.fsf.org/licensing/licenses/gpl.html.
#

package pf::class;

use strict;
use warnings;

our ($class_view_sql, $class_exist_sql, $class_add_sql, $class_delete_sql, $class_cleanup_sql,
     $class_modify_sql, $class_view_all_sql, $class_view_actions_sql, $class_trappable_sql, $class_db_prepared);

BEGIN {
  use Exporter ();
  our (@ISA, @EXPORT);
  @ISA    = qw(Exporter);
  @EXPORT = qw(class_db_prepare class_view class_view_all class_trappable class_view_actions class_add class_delete class_merge);
}

use Log::Log4perl;
use pf::db;
use pf::action qw(action_delete_all action_add);
use pf::trigger qw(trigger_add);

$class_db_prepared = 0;
#class_db_prepare($dbh) if (!$thread);

sub class_db_prepare {
  my ($dbh) = @_;
  db_connect($dbh);
  my $logger = Log::Log4perl::get_logger('pf::class');
  $logger->debug("Preparing pf::class database queries");
  $class_view_sql=$dbh->prepare( qq [ select class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable,group_concat(action.action order by action.action asc) as action from class left join action on class.vid=action.vid where class.vid=? GROUP BY class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable ]);
  $class_view_all_sql=$dbh->prepare( qq [ select class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable,group_concat(action.action order by action.action asc) as action from class left join action on class.vid=action.vid GROUP BY class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable ] );
  $class_view_actions_sql=$dbh->prepare( qq [ select vid,action from action where vid=? ]);
  $class_exist_sql=$dbh->prepare( qq [ select vid from class where vid=? ]);
  $class_delete_sql=$dbh->prepare( qq [ delete from class where vid=? ]);
  $class_add_sql=$dbh->prepare( qq [ insert into class(vid,description,auto_enable,max_enables,grace_period,priority,url,max_enable_url,redirect_url,button_text,disable) values(?,?,?,?,?,?,?,?,?,?,?) ]);
  $class_modify_sql=$dbh->prepare( qq [ update class set description=?,auto_enable=?,max_enables=?,grace_period=?,priority=?,url=?,max_enable_url=?,redirect_url=?,button_text=?,disable=? where vid=? ]);
  $class_cleanup_sql=$dbh->prepare( qq [ delete from class where vid not in (?) and vid < 1200000 and vid > 1200100 ]);
  $class_trappable_sql=$dbh->prepare( qq [select c.vid,c.description,c.auto_enable,c.max_enables,c.grace_period,c.priority,c.url,c.max_enable_url,c.redirect_url,c.button_text,c.disable from class c left join action a on c.vid=a.vid where a.action="trap" ]);
  $class_db_prepared = 1;
}

sub class_exist {
  my ($id) = @_;
  class_db_prepare($dbh) if (! $class_db_prepared);
  $class_exist_sql->execute($id) || return(0);
  my ($val) = $class_exist_sql->fetchrow_hashref();
  $class_exist_sql->finish();
  return($val);
}

sub class_view {
  my ($id) = @_;
  class_db_prepare($dbh) if (! $class_db_prepared);
  $class_view_sql->execute($id) || return(0);
  my ($val) = $class_view_sql->fetchrow_hashref();
  $class_view_sql->finish();
  return($val);
}

sub class_view_all {
  class_db_prepare($dbh) if (! $class_db_prepared);
  return db_data($class_view_all_sql);
}

sub class_trappable {
  class_db_prepare($dbh) if (! $class_db_prepared);
  return db_data($class_trappable_sql);
}

sub class_view_actions {
  my ($id) = @_;
  class_db_prepare($dbh) if (! $class_db_prepared);
  return db_data($class_view_actions_sql,$id);
}

sub class_add {
  my $id = $_[0];
  class_db_prepare($dbh) if (! $class_db_prepared);
  my $logger = Log::Log4perl::get_logger('pf::class');
  if (class_exist($id)) {
    $logger->warn("attempt to add existing class $id");
    return(2);
  }
  $class_add_sql->execute(@_) || return(0);
  $logger->info("class $id added");
  return(1);
}

sub class_delete {
  my ($id) = @_;
  class_db_prepare($dbh) if (! $class_db_prepared);
  my $logger = Log::Log4perl::get_logger('pf::class');
  $class_delete_sql->execute($id) || return(0);
  $logger->info("class $id deleted");
  return(1)  
}

sub class_cleanup {
  class_db_prepare($dbh) if (! $class_db_prepared);
  my $logger = Log::Log4perl::get_logger('pf::class');
  $class_cleanup_sql->execute() || return(0);
  $logger->info("class cleanup completed");
  return(1)  
}

sub class_modify {
  my $id = shift(@_);
  class_db_prepare($dbh) if (! $class_db_prepared);
  my $logger = Log::Log4perl::get_logger('pf::class');
  push(@_, $id);
  if (class_exist($id)) {
    $logger->info("modify existing existing class $id");
  }
  $class_modify_sql->execute(@_) || return(0);
  $logger->info("class $id modified");
  return(1);
}

sub class_merge {
  my $id = shift(@_);
  my $logger = Log::Log4perl::get_logger('pf::class');
  my $triggers = pop(@_);
  my $actions = pop(@_);

  $logger->info("inserting $id");
  # delete existing violation actions
  if (!action_delete_all($id)) {
    $logger->error("error deleting actions for class $id");
    return(0);
  }

  unshift(@_, $id);
  #Check for violations
  if (class_exist($id)) {
    class_modify(@_);
  } else {
    #insert violation class
    class_add(@_);
  }

  # add violation actions
  foreach my $action (split(/\s*,\s*/, $actions)) {
    action_add($id,$action);
  }
  
  #Add scan table id's -> violation class maps
  if (scalar(@{$triggers}) > 0) {
    foreach my $array (@{$triggers}) {
      my ($tid_start,$tid_end,$type) = @{$array};
      trigger_add($id,$tid_start,$tid_end,$type);
    }
  }
}

1
