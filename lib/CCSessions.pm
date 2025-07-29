#!/usr/bin/env perl
package CCSessions;
use File::AddInc qw($libDir);

use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     [claude_projects => default => "$ENV{HOME}/.claude/projects"],
     [cache_dir => default => "$libDir/../var/tmp"],
     qw(
       _id_cache
       _session_cache
     )
   ];

use File::stat;

use MOP4Import::Types
  (FileInfo => [[fields => qw(id dir stat)]],
   # FileCache => [[fields => qw(mtime lines)]],
  );

sub read_session_item {
  (my MY $self, my ($id, $ix)) = @_;
  
}

sub scan_session {
  (my MY $self, my ($id)) = @_;
  my $fn = $self->session_filepath($id);

  $self->{_session_cache}{$id} //= do {
    open my $fh, '<', $fn or Carp::croak "no such file: $fn";
    my @result;
    my $fpos = 0;
    while (my $json = <$fh>) {
      push @result, $fpos;
      $fpos = tell $fh;
    }
    \@result;
  };
}

sub session_filepath {
  (my MY $self, my ($id)) = @_;
  my FileInfo $rec = $self->session_fileinfo($id);
  "$self->{claude_projects}/$rec->{dir}/$id.jsonl";
}

sub session_fileinfo {
  (my MY $self, my ($id)) = @_;
  my FileInfo $rec = $self->{_id_cache}{$id}
    or Carp::croak "No such session: $id";
}

sub session_list {
  (my MY $self, my $project) = @_;
  map {
    my $id = File::Basename::basename($_);
    $id =~ s/\.jsonl\z//;
    my FileInfo $rec = +{};
    $rec->{dir} = $project;
    $rec->{id} = $id;
    $rec->{stat} = stat($_);
    $self->{_id_cache}{$id} = $rec;
    $rec;
  }
  glob "$self->{claude_projects}/$project/*.jsonl";
}

sub project_list {
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
