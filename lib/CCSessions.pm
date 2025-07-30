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
  (my MY $self, my ($id, $ix, $project)) = @_;
  my $fn = $self->session_filepath($id, $project);
  my $list = $self->scan_session($id, $project);
  my $pos = $list->[$ix];

  open my $fh , '<', $fn or Carp::croak "no such file: $fn";
  seek $fh, $pos, 0;
  scalar <$fh>;
}

sub scan_session {
  (my MY $self, my ($id, $project)) = @_;
  my $fn = $self->session_filepath($id, $project);

  my $list = $self->{_session_cache}{$id} //= do {
    open my $fh, '<', $fn or Carp::croak "no such file: $fn";
    my @result;
    my $fpos = 0;
    while (my $json = <$fh>) {
      push @result, $fpos;
      $fpos = tell $fh;
    }
    \@result;
  };

  wantarray ? (0 .. $#$list) : $list;
}

sub session_filepath {
  (my MY $self, my ($id, $project)) = @_;
  my FileInfo $rec = $self->session_fileinfo($id, $project);
  "$self->{claude_projects}/$rec->{dir}/$id.jsonl";
}

sub session_fileinfo {
  (my MY $self, my ($id, $project)) = @_;
  my FileInfo $rec = $self->{_id_cache}{$id} //= do {
    if ($project) {
      my FileInfo $rec = $self->make_session_record($project, $id);
      unless ($self->check_session_exists($rec)) {
        Carp::croak "No such session: $id, $project";
      }
      $rec;
    } else {
      Carp::croak "No such session: $id";
    }
  }
}

sub session_list {
  (my MY $self, my $project) = @_;
  map {
    my $id = File::Basename::basename($_);
    $id =~ s/\.jsonl\z//;
    my FileInfo $rec = $self->make_session_record($project, $id);
    $rec->{stat} = stat($_);
    $rec;
  }
  glob "$self->{claude_projects}/$project/*.jsonl";
}

sub make_session_record {
  (my MY $self, my ($project, $id)) = @_;
  my FileInfo $rec = +{};
  $rec->{dir} = $project;
  $rec->{id} = $id;
  $self->{_id_cache}{$id} = $rec;
  $rec;
}

sub check_session_exists {
  (my MY $self, my FileInfo $rec) = @_;
  my $fn = "$self->{claude_projects}/$rec->{dir}/$rec->{id}.jsonl";
  -e $fn;
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
