# -*- perl -*-
use strict;
use warnings;

use FindBin; BEGIN {FindBin->again}
use lib "$FindBin::Bin/lib", "$FindBin::Bin/local/lib/perl5";

use Plack::Builder;

use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite qw/Entity *CON/;

# use YATT::Lite::WebMVC0::Partial::Session2 -as_base;

{
  my $app_root = $FindBin::Bin;

  my MY $site = MY->load_factory_for_psgi(
    $0,
    # ↓拡張子を変更したいときはこれを変える
    # ext_public => "html",

    doc_root => "$app_root/public",

    # 設定ファイルを隣のディレクトリに置きたい時
    # use_sibling_config_dir => 1,
    # config_dir => "$app_root.config.d",
  );

  if (-d (my $staticDir = "$app_root/static")) {
    $site->mount_static("/static" => $staticDir);
  }

  require CCSessions;
  my $cc_sessions = CCSessions->new;

  Entity cc_sessions => sub {
    $cc_sessions;
  };

  return $site->wrapped_by(builder {

    # enable "SimpleLogger", level => "warn";

    $site->to_app;
  });
}
