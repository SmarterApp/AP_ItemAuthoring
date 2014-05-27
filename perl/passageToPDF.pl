#!/usr/bin/perl

BEGIN {

  my $instance_name = $ARGV[0] || '';
  die "Must specify an instance to monitor!" if $instance_name eq '';
  $ENV{instance_name} = $instance_name;
  push @INC, '/www/'  . $instance_name . '/cgi-bin/';

}

use strict;
use DBI;
use UrlConstants;
use Passage;
use Data::Dumper;

my $debug = 1;

my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
my $sth;
my $sql;

my $pdfDir = $orcaPath . 'passage-pdf/';

my $passageId = $ARGV[0];

$sql =
"SELECT ps_id FROM passage_status WHERE p_id=${passageId} ORDER BY ps_timestamp DESC LIMIT 1";
$sth = $dbh->prepare($sql);
$sth->execute();
my $row      = $sth->fetchrow_hashref;
my $statusId = $row->{ps_id};

$sth->finish;

my $passage = new Passage( $dbh, $passageId );
my $html = $passage->toHTML();
$html =~ s/<OBJECT.*?<\/OBJECT>/<span>*SWF Chart\/File*<\/span>/ig;

open OUT, ">/tmp/temp_$$.html";
print OUT $html;
close OUT;

$dbh->disconnect;

mkdir "${pdfDir}lib$passage->{bank}/" unless -e "${pdfDir}lib$passage->{bank}/";
mkdir "${pdfDir}lib$passage->{bank}/${passageId}/"
  unless -e "${pdfDir}lib$passage->{bank}/${passageId}/";

my $html2psCmd =
    "/usr/local/bin/html2ps -o /tmp/temp_$$.ps -s 1 -i 0.6 -g -r ${webPath}"
  . " /tmp/temp_$$.html >/dev/null 2>/dev/null";
my $convertCmd =
"/usr/bin/ps2pdf /tmp/temp_$$.ps ${pdfDir}lib$passage->{bank}/${passageId}/${statusId}.pdf >/dev/null 2>/dev/null";

&syscmd($html2psCmd);
&syscmd($convertCmd);

unlink("/tmp/temp_$$.html");
unlink("/tmp/temp_$$.ps");

exit 0;

### ALL DONE! ###
sub syscmd {
    my $cmd = shift;
    unless ( system($cmd) == 0 ) {
        print STDERR "Error with $cmd";
        exit 0;
    }
}
