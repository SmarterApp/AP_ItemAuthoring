#!/usr/bin/perl -w
use strict;
use File::Copy;
use File::Finder;
use File::Path qw(make_path remove_tree);
use Getopt::Whatever;
use Timestamp::Simple qw(stamp);

$ARGV{$_}++ for @ARGV;
$ARGV{build_num}   ||= 0;
$ARGV{client_name} ||= 'cde';
$ARGV{client_name} =~ s/\s+//g;

## USAGE method doesn't return... EXITs
&USAGE if ( $ARGV{'-h'} || $ARGV{'-help'} || $ARGV{'help'} );
&USAGE( msg => 'Must supply branch_name!' ) unless ( $ARGV{branch_name} && $ARGV{branch_name} ne '' );

# TODO: clean environment first

# TODO: update /www

# ensure svn is installed.
`bash -c "type -P svn"` or die "Could not locate svn binary!: $!\n";

# svn executables
# TODO: seperate user account to do builds
# TODO: remove username/password from code
my $svn_tag    = 'svn --trust-server-cert --non-interactive --username tturner --password \!Pacmet12 copy';
my $svn_export = 'svn --trust-server-cert --non-interactive --username tturner --password \!Pacmet12 export';

my $svn_base_url = 'https://code01.pacificmetrics.com/svn/CDE';

my $build_timestamp = stamp;

my $build_dir = '/builds/cde';

# build information for SBAC COMMON
my $common_branch_name = "sbac_common";
my $common_svn_tag     = sprintf "%s-build%s-%s", $common_branch_name, $ARGV{build_num}, $build_timestamp;
my $common_build_label = sprintf "%s/%s", $build_dir, $common_svn_tag;
my $common_svn_url     = "$svn_base_url/branches/$common_branch_name";
my $common_export_cmd  = "$svn_export $common_svn_url $common_build_label";

# build SBAC COMMON
print "Building $common_branch_name $ARGV{build_num}....\n" if $ARGV{verbose};
`$common_export_cmd` or die "Could not export common code from $common_svn_url: $!\n";
chdir '/www';
`rm common` if -e "common" or die "Could not remove softlink to common!: $!\n";
`ln -s $common_build_label common`; # or die "Could not create softlink to common!: $!\n";

# tag SBAC COMMON
print "Tagging common $common_build_label...\n";
`$svn_tag $common_svn_url $svn_base_url/tags/$common_svn_tag -m "Tagging the $ARGV{build_num} 'SBAC Common' project."`
  or die "Could not create svn tag for common!: $!\n";

# build information for SBAC CDE
my $build_svn_tag = sprintf "%s-build%s-%s", $ARGV{branch_name}, $ARGV{build_num}, $build_timestamp;
my $build_label   = sprintf "%s/%s",         $build_dir,         $build_svn_tag;
my $svn_url       = "$svn_base_url/branches/$ARGV{branch_name}";
my $export_cmd    = "$svn_export $svn_url $build_label";

# build SBAC CDE
print "Building $ARGV{branch_name} $ARGV{build_num}....\n" if $ARGV{verbose};
`$export_cmd` or die "Could not export sbac code from $svn_url: $!\n";

chdir "$build_label/cgi-bin";
`chmod 755 *.pl *.pm`;

# ensure dos2unix is installed
`bash -c "type -P dos2unix"` or die "Could not locate dos2unix binary!: $!\n";
`dos2unix -q *.pl`;# or die "Failed to update cgi-bin/*.pl file format!: $!\n";
`dos2unix -q *.pm`;# or die "Failed to update cgi-bin/*.pm file format!: $!\n";

chdir '/www';
`rm $ARGV{client_name}` if -e $ARGV{client_name} or die "Could not remove softlink to $ARGV{client_name}!: $!\n";
`ln -s $build_label $ARGV{client_name}`;# or die "Could not create softlink to $ARGV{client_name}!: $!\n";

chdir "$ARGV{client_name}";
my $chmod = 0777;

# tag SBAC CDE
print "Tagging $ARGV{branch_name} $build_label...\n";
`$svn_tag $svn_url $svn_base_url/tags/$build_svn_tag -m "Tagging the $ARGV{build_num} 'SBAC CDE' project."`
  or die "Could not create svn tag for sbac!: $!\n";

# add link to common js
`rm js` if -e "js";# or die "Could not remove softlink to js!: $!\n";
`ln -s /www/common/js js`;# or die "Could not create softlink to js!: $!\n";

# add SBAC CDE resource directories
use Config::General;
my $cge = new Config::General(
  -ConfigFile      => '/etc/httpd/conf/cde_clients.conf',
  -IncludeRelative => 1,
  -InterPolateVars => 1
);
my %config = $cge->getall;

use DBI;

my $dbh = DBI->connect(
  $config{ $ARGV{client_name} }->{db_dsn},
  $config{ $ARGV{client_name} }->{db_user},
  $config{ $ARGV{client_name} }->{db_pass},
  { RaiseError => 1, AutoCommit => 1 }
) or die "Unable to connect:$DBI::errstr: $!\n";

# TODO checking if directories exist, but should also ensure owner.group on cde_log, cde_tmp, and cde_resources
for (qw(cde_log cde_tmp)) {
  unless ( -d "/www/$_" ) {
    make_path("/www/$_", {owner=>'pacific', group=>'pacific'});
  }
}

unless (-d "/www/cde_resources") {
  make_path("/www/cde_resources", {owner=>'apache', group=>'pacific'});
}

print "Creating resource directories if they don't exist....\n" if $ARGV{verbose};
for (
  qw(images itembank-metafiles item-import item-metafiles item-pdf passages
  passage-metafiles passage-pdf rubrics workflow)
  )
{
  my $resource_dir = "/www/cde_resources/$ARGV{client_name}/$_";
  unless ( -d $resource_dir ) {
    # create path with correct owner.group
    if ( $_ eq 'itembank-metafiles' ) {
      make_path($resource_dir, {owner=>'tomcat', group=>'tomcat'});
    } else {
      make_path($resource_dir, {owner=>'apache', group=>'pacific'});
    }
    chmod $chmod, "$resource_dir";
  }

  if ( $_ eq 'workflow' ) {
    for (qw(passage-rejection-report rejection-report supplemental-info)) {
      unless ( -d "$resource_dir/$_" ) {
        make_path("$resource_dir/$_", {owner=>'apache', group=>'apache'});
        chmod $chmod, "$resource_dir/$_";
      }
    }
  }
  # ensure itembank-metafiles and subdirectories are writable by tomcat process
  elsif ( $_ eq 'itembank-metafiles' ) {
    `bash -c "type -P id"` or die "Could not locate id command!: $!\n";
    my $tomcat_uid = `id -u tomcat` or die "Could not get tomcat uid!: $!\n";
    my $tomcat_gid = `id -g tomcat` or die "Could not get tomcat gid!: $!\n";
    
    chown $tomcat_uid, $tomcat_gid, File::Finder->in("/www/cde_resources/$ARGV{client_name}/$_");
  }
  # create symbolic links to item import user home directories for each program
  elsif ( $_ eq 'item-import' ) {
    my $sql = "SELECT u_username, CONCAT('lib',CAST(ib_id AS CHAR)) AS 'ib_import_dir'"
      . " FROM item_bank JOIN user ON user.u_id=item_bank.ib_importer_u_id;";
    my $import_users = $dbh->selectall_arrayref($sql);

    # ensure the orcacde home directory exists
    unless ( -d "/home/orcacde" ) {
      die "orcacde directory does not exist!: $!\n";
    }

    foreach my $import_user (@$import_users) {

      # ensure each item import directory exists
      unless ( -d "/home/orcacde/$import_user->{u_username}" ) {
        make_path("/home/orcacde/$import_user->{u_username}");
      }

      # create symbolic link to import directory for each program
      `ln -s /home/orcacde/$import_user->{u_username} /www/$ARGV{client_name}/item-import/$import_user->{ib_import_dir}`;
#        or die "Could not create softlink to item import directory for $import_user->{ib_import_dir}: $!\n";
    }
  }

  # create required program directories
  else {
    my $sql        = "SELECT CONCAT('lib',CAST(ib_id AS CHAR)) AS 'ib_import_dir' FROM item_bank;";
    my $item_banks = $dbh->selectall_arrayref($sql);

    foreach my $item_bank (@$item_banks) {
      unless ( -d "$resource_dir/$_/$item_bank->[0]" ) {
        make_path("$resource_dir/$_/$item_bank->->[0]");
        chmod $chmod, "$resource_dir/$_/$item_bank->[0]";
      }

      if ( $_ eq 'rubrics' or $_ eq 'passages' ) {
        unless ( -d "$resource_dir/$_/$item_bank->[0]/images" ) {
          make_path("$resource_dir/$_/$item_bank->[0]/images");
          chmod $chmod, "$resource_dir/$_/$item_bank->[0]/images";
        }
      }
    }

    # remove symbolic links to resource directories
    `rm /www/$ARGV{client_name}/$_` if -e "/www/$ARGV{client_name}/$_";# or die "Could not remove softlink to $_!: $!\n";
    `ln -s $resource_dir /www/$ARGV{client_name}/$_`;# or die "Could not create softlink to $_!: $!\n";
  }

  # TODO ensure database passwords are encrypted

  print "Build Complete!\n" if $ARGV{verbose};

  exit;
}

sub USAGE {
  my %p = @_;

  printf "*** %s ***\n", $p{msg} if $p{msg};
  print <<__EOU;

Usage: build_cde.pl --client_name=instance_name --branch_name=0_0_0 --build_num=0 --verbose=1

Description:
  Builds CDE code base from SVN.

Options:
  --branch_name	[*Required] defaults to 'cde'
  --client_name	[optional] name of the Client or Instance using the CDE. Defaults to 'cde'
  --build_num	[optional] just an arbitrary number used be CM to keep track of builds. Defaults to 0.
  --verbose	    [optional] . Defaults to 1.
  --help, -help, -h	[] This Usage
__EOU

  exit(1);
}
