package TinyTemplate;
our $VERSION = '0.01';

=head1 NAME

TinyTemplate - A Tiny Inline-Perl Template module with an execution model similar to JSP's.
 
Templates are strings which are converted to Perl code for evaluation. 

=head1 SYNOPSIS

   use TinyTemplate ':all';
   print "Content-type: text/html\n\n";
   #
   # parse will convert a template (in the form of a string)
   # into equivalent perl code. The following sample uses Perl's here document syntax...
   # 
   eval parse <<'END';
   <html>
   <body>
   <table>
     [% foreach my $row ({name=>"Walter Higgins", address=>"Cork,Ireland"},
                         {name=>"John Doe", address=>"Surrey,England"}) 
        { %]
     <tr>
       <td>$row->{name}</td>
       <td>$row->{address}</td>
     </tr>
     [% } %]
   </table>
   </body>
   </html>
   END

=head1 DESCRIPTION

TinyTemplate is a tiny template system that parses a string and converts it into Perl code.

Inline perl code must be enclosed in [% %] markers. 

 For example: 
 [% if ($age > 65) { %]
    Please avail of our special offer for Senior Citizens
 [% } %]

You can send directives to the parser using [%! %] markers.

 For example:
 [%!include "header.html" %] 
 will include (and parse) the content of header.html.

Currently there is only one directive (include) supported. 

Everything that isn't enclosed in [% %] will be printed in double-quotes (interpolated), 
so to print a variable name ...

 You are connected to $hostname

...This means that if you want to include an email address in your template you should
escape the @ character like so...

 <a href="mailto:walterh\@rocketmail.com">Contact</a>

=head1 SAMPLE CODE
 
 #!/usr/bin/perl
 #
 # A simple CGI program
 #
 use strict;
 use TinyTemplate ':all';
 print "Content-Type: text/html\n\n";
 eval include "my_template.html";
 exit;


 Contents of my_template.html...
  
 <html>
  [%!include "header.html" %]
 <body>
   <table>
     [% foreach my $person ({name=>"Jane Malone", 
                             age=> 64, 
                             address=>"Cork,Ireland"},

                            {name=>"John Doe", 
                             age=> 68, 
                             address=>"Surrey,England"}) { %]
     <tr>
       <td>$person->{name}</td>
       <td>$person->{address}</td>
       <td>
        [% if ($person->{age} > 65) { %]
          Please avail of our Senior Citizens Offers
        [% } %]
       </td>
     </tr>
     [% } %]
   </table>
 </body>
 </html>


 Contents of header.html...

 <head>
   <title>People List</title>
 </head>

=cut

use strict;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(parse include);
our %EXPORT_TAGS = (all => \@EXPORT_OK,);


#
# Parse a string splitting it into tokens then
# joining it back to form a string which can be evaluated
# as perl code.
#
sub parse 
{
  my $perl = join "\n",map {
    my ( $enclosed, $directive, $text) = $_ =~ /(\[%)*(!)*(.+)/s;
	 if ($directive){
		my $result = eval($text);
		die "directive failed: could not evaluate $text\n$@" if $@;
		$result;
	 }elsif ($enclosed){
		$text;
	 }else{
		$text =~ s/\n/\\n/g;
		$text =~ s/"/\\"/g;
		"print \"$text\";"; 
	 }
  } split /(\[%.*?)%\]/s, $_[0];
}
#
# Include content from another file for evaluation
#
sub include 
{
    my ($filename) = @_;
    open FILE, $filename or die "COULDN'T OPEN FILE $filename because $!\n";
    my $contents = join '', <FILE>;
    close FILE;
    parse $contents;
}

1;
