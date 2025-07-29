#!/usr/bin/env perl
package CCSessions;
use File::AddInc qw($libDir);

use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     [claude_projects => default => "$ENV{HOME}/.claude/projects"],
     [cache_dir => default => "$libDir/../var/tmp"],
     qw(
       _cache
     )
   ];

use File::stat;

sub sessions {
  (my MY $self, my $project) = @_;
  map {
    +{
      dir => $project, fn => File::Basename::basename($_),
      stat => stat($_),
    }
  }
  glob "$self->{claude_projects}/$project/*.jsonl";
}

sub projects {
  (my MY $self) = @_;
  map {
    File::Basename::basename($_)
  }
  glob "$self->{claude_projects}/-*";
}

sub scan {
  (my MY $self, my $fn) = @_;
}

MY->cli_run(\@ARGV) unless caller;

1;
