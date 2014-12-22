package PXN8Debug;
use strict;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(log $debug, $logfile);

our $debug = 0;

our $logdir = "../";

our @output = ();
sub log {
  #
  # some versions of IIS don't handle STDERR which may result in
  # incorrect headers being sent . To turn off debug
  # set DEBUG => 0 in the config.ini file
  #
  push @output, @_;
  if ($#output > 1000){
	 flushlog();
  }
}

sub flushlog {
  if ($debug){
	 my @gmtime = gmtime();
	 
	 my $logfilename = sprintf("%spxn8-%d-%02d-%02d.log",
										$logdir,
										1900+$gmtime[5],
										1+$gmtime[4],
										$gmtime[3]);
	 
	 if (open (LOGFILE, ">>$logfilename")){
		foreach (@output){
		  print LOGFILE $_;
		}
		close LOGFILE;
	 }
  }
  @output = ();
}
END {
  flushlog();
}
1;

