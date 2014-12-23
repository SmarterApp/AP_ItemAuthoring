package UrlConstants;

use warnings;
use strict;
use Config::General;

BEGIN {

    use Exporter ();
    use vars qw(@ISA @EXPORT @EXPORT_OK);

    @ISA       = qw(Exporter);
    @EXPORT_OK = qw();
    @EXPORT    = qw(
      $dbDsn  $dbUser $dbPass
      $webPath $orcaPath $orcaUrl $javaUrl $authUrl
      $webHost $commonPath $commonUrl %CDE_CONFIG $instance_name
      $ITEM_ACTION_MAP $PASSAGE_ACTION_MAP %_config
    );

}

our @EXPORT;

our $instance_name  = $ENV{instance_name};
if( $ENV{SCRIPT_FILENAME} ) {
    my @dir_nodes = split /\//, $ENV{SCRIPT_FILENAME};
    $instance_name  = $dir_nodes[scalar(@dir_nodes) - 4];
}

my $conf_file = '/etc/httpd/conf/cde_clients.conf';
my $cge = new Config::General( -ConfigFile => $conf_file, -IncludeRelative => 1, );
my %_config = $cge->getall;

our $CDE_CONFIG = $_config{$instance_name};
our $dbDsn  	= $CDE_CONFIG->{db_dsn};
our $dbUser 	= $CDE_CONFIG->{db_user};
our $dbPass 	= $CDE_CONFIG->{db_pass};

our $webHost    = $CDE_CONFIG->{web_host};
our $webPath    = $CDE_CONFIG->{web_path};
our $javaUrl    = $CDE_CONFIG->{java_url};
our $authUrl    = $CDE_CONFIG->{auth_url};
our $orcaUrl    = $CDE_CONFIG->{orca_url};
our $orcaPath   = $webPath . $orcaUrl;
our $commonUrl  = $CDE_CONFIG->{common_url};
our $commonPath = $webPath . $commonUrl;
our $ITEM_ACTION_MAP 	= $CDE_CONFIG->{item_action_map};
our $PASSAGE_ACTION_MAP = $CDE_CONFIG->{passage_action_map};

1;
