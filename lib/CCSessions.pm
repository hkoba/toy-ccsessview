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
   SessionItemInfo => [[fields => qw(pos type role tool summary)]],
   # Message types for different session items
   UserMessage => [[fields => qw(type message uuid timestamp parentUuid userType cwd sessionId version gitBranch isSidechain)]],
   AssistantMessage => [[fields => qw(type message uuid timestamp parentUuid isSidechain toolInvocations)]],
   ToolUseMessage => [[fields => qw(type toolName toolInput uuid timestamp parentUuid)]],
   ToolResultMessage => [[fields => qw(type content toolUseId uuid timestamp parentUuid isError)]],
   # FileCache => [[fields => qw(mtime lines)]],
  );

sub read_session_item {
  (my MY $self, my ($id, $ix, $project)) = @_;
  my $fn = $self->session_filepath($id, $project);
  my $list = $self->scan_session($id, $project);
  my SessionItemInfo $item = $list->[$ix];
  my $pos = $item->{pos};

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
    while (my $json_line = <$fh>) {
      my SessionItemInfo $item = {};
      $item->{pos} = $fpos;
      
      # JSONをデコードして概要情報を抽出
      eval {
        require JSON;
        my $data = JSON::decode_json($json_line);
        $item->{type} = $data->{type} // 'unknown';
        
        # typeに応じて概要を生成 (dynamic dispatch)
        my $methodName = 'parse_item__' . ($data->{type} // 'unknown');
        if (my $parser = $self->can($methodName)) {
          $parser->($self, $item, $data);
        } else {
          $self->parse_item__unknown($item, $data);
        }
      };
      if ($@) {
        # JSONパースエラーの場合
        $item->{type} = 'error';
        $item->{summary} = 'Parse error';
      }
      
      push @result, $item;
      $fpos = tell $fh;
    }
    \@result;
  };

  wantarray ? @$list : $list;
}

sub parse_item__user {
  (my MY $self, my SessionItemInfo $item, my UserMessage $data) = @_;
  $item->{role} = 'user';
  my $content = ref($data->{message}{content}) eq 'ARRAY' 
    ? $data->{message}{content}[0]{text} // ''
    : $data->{message}{content} // '';
  $item->{summary} = substr($content, 0, 50);
  $item;
}

sub parse_item__assistant {
  (my MY $self, my SessionItemInfo $item, my AssistantMessage $data) = @_;
  $item->{role} = 'assistant';
  my $content = ref($data->{message}{content}) eq 'ARRAY'
    ? $data->{message}{content}[0]{text} // ''
    : $data->{message}{content} // '';
  $item->{summary} = substr($content, 0, 50);
  $item;
}

sub parse_item__tool_use {
  (my MY $self, my SessionItemInfo $item, my ToolUseMessage $data) = @_;
  $item->{tool} = $data->{toolName} // 'unknown';
  $item->{summary} = "Tool: $item->{tool}";
  $item;
}

sub parse_item__tool_result {
  (my MY $self, my SessionItemInfo $item, my ToolResultMessage $data) = @_;
  $item->{summary} = $data->{isError} ? "Error" : "Success";
  $item;
}

sub parse_item__unknown {
  (my MY $self, my SessionItemInfo $item, my $data) = @_;
  $item->{summary} = $item->{type};
  $item;
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
