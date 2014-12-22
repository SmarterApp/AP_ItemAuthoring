package Action::rubricView;

use ItemConstants;
use Rubric;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $this_url = "${orcaUrl}cgi-bin/rubricView.pl";

  return [ $q->psgi_header('text/html'), [ &print_show_rubric() ]];
}
### ALL DONE! ###

sub print_show_rubric {

    my $rubric = new Rubric( $dbh, $in{rubricId} );

    return <<END_HERE;
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>View Rubric</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
  <body>
    <div class="title">View Rubric</div>
    
    <table class="no-style" border="0" cellpadding="2" cellspacing="2">
      <tr><td><span class="text">Name:</span></td><td>$rubric->{name}</td></tr> 
      <tr><td><span class="text">Description:</span></td><td>$rubric->{summary}</td></tr>
    </table>
    <table class="no-style" border="1" cellpadding="2" cellspacing="2">
      <tbody>
        <tr>
	   <td valign="top">
	   $rubric->{content}
	   </td>
        </tr>
      </tbody>
    </table>
  </body>
</html>
END_HERE
}
1;
