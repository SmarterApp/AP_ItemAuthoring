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
use Item;

my $debug = 0;

print STDERR "itemToPDF.pl: instance = ${instance_name}" if $debug;


my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
my $sth;
my $sql;

my $pdfDir = $orcaPath . 'item-pdf/';

my $itemId = $ARGV[1];

$sql =
"SELECT is_id FROM item_status WHERE i_id=${itemId} ORDER BY is_timestamp DESC LIMIT 1";
$sth = $dbh->prepare($sql);
$sth->execute();
my $row      = $sth->fetchrow_hashref;
my $statusId = $row->{is_id};

$sth->finish;

my $item = new Item( $dbh, $itemId );
my $html = $item->toHTML();

# ps2pdf doesn't handle svg
$html =~ s/<OBJECT.*?<\/OBJECT>/<span>*SVG or Flash Image*<\/span>/igs;

# ps2pdf doesn't handle mathml
$html =~ s/<math.*?<\/math>/<span>*MathML*<\/span>/igs;

open OUT, ">/tmp/temp_$$.html";
print OUT $html;
close OUT;

$dbh->disconnect;

# create the data folders, unless they exists

my $bankPdfDir = "${pdfDir}lib$item->{bankId}/";

unless( -e $bankPdfDir) {

  mkdir $bankPdfDir;
  system("chmod a+rwx $bankPdfDir");
}

my $itemPdfDir = $bankPdfDir . "${itemId}/";

unless( -e $itemPdfDir) {

  mkdir $itemPdfDir;
  system("chmod a+rwx $itemPdfDir");
}

# build the HTML -> PS command

my $html2psCmd =
    "/usr/bin/html2ps -o /tmp/temp_$$.ps -s 1 -i 0.6 -g -r ${webPath}"
  . " /tmp/temp_$$.html >/dev/null 2>/dev/null";

# build the PS -> PDF command

my $convertCmd =
"/usr/bin/ps2pdf /tmp/temp_$$.ps ${itemPdfDir}${statusId}.pdf >/dev/null 2>/dev/null";

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
