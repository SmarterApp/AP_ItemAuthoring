#!/usr/bin/perl -w

use strict;
use Config::General;
use DBI;
use Getopt::Whatever;


$ARGV{$_}++ for @ARGV;
&USAGE if( $ARGV{'-h'} || $ARGV{'-help'} || $ARGV{'help'} );
&USAGE( msg => 'Must supply CDE Instance Name!' ) unless( $ARGV{instance} && $ARGV{instance} ne '' );

print "Encryption starting!\n";
my $htpasswd = '/usr/bin/htpasswd -mnb';
my $cge = new Config::General( -ConfigFile => '/etc/httpd/conf/cde_clients.conf', 
                               -IncludeRelative => 1,
                               -InterPolateVars => 1 );
my %config = $cge->getall;

print "Connecting to DB...\n" if $ARGV{v};
my $dbh = DBI->connect( $config{$ARGV{instance}}->{db_dsn}, 
			$config{$ARGV{instance}}->{db_user}, 
			$config{$ARGV{instance}}->{db_pass},
                        { RaiseError => 1, AutoCommit => 1 } 
) or die "Unable to connect:$DBI::errstr";

print "Retrieving Users...\n" if $ARGV{v};
my $sql = "SELECT * FROM user";
my $users = $dbh->selectall_arrayref($sql, { Slice => {} } );
printf "Found %d Users...\n", scalar @$users if $ARGV{v};

$sql = "UPDATE user SET u_password=? WHERE u_id=?";
my $sth = $dbh->prepare($sql);

print "Encrypting Passwords...\n" if $ARGV{v};
for( @$users ) {
   print "$_->{u_id} => $_->{u_username} => $_->{u_password} => " if $ARGV{v};
   if( $_->{u_password} =~ /^\$apr1/ ) {
	printf "\n\tPassword for user %s appears to be encrypted already. Skipping.\n\n", $_->{u_username};
	next;
   }

   my $new_pswd = (split /:/, `$htpasswd $_->{u_username}  $_->{u_password}`)[1];
   $new_pswd =~ s/\n+//g;
   printf "%s\n", $new_pswd if $ARGV{v};

   my @bv = ( $new_pswd, $_->{u_id}, );
   my $rc = $sth->execute(@bv);
   #my $rc = 1;
   printf "\tPassword Update %s!\n\n", ($rc ? 'Successful' : 'Unsuccesful') if $ARGV{v};
}

print "Encryption complete!\n";

exit;

sub USAGE {
    my %p = @_;

    printf STDERR "*** %s ***\n", $p{msg} if $p{msg};
    print <<__EOU;

Usage: encrypt_pswd.pl --instance --v

Description:
  MD5 Encrypts Passwords In User Table.

Options:
  --instance [*Required] # CDE Instance Name e.g. devcdesbac
  --v [optional]         # Shows what's going on.
  --help, -help, -h      # This Usage
__EOU

    exit(1);
}
