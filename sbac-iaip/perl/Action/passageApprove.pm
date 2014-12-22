package Action::passageApprove;

use UrlConstants;

sub run {

  my $q = shift;
  my %in  = map { $_ => $q->param($_) } $q->param;

  my $psgi_out = <<END_HERE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html>
  <head>
    <title>Item Edit/Review</title>
  </head>
  <frameset rows="45px,*,20px">
    <frame name="menuFrame" src="${orcaUrl}cgi-bin/passageApproveMenu.pl" frameborder="0" scrolling="no"/>
    <frame name="rightFrame" src="${orcaUrl}blankPassage.html" frameborder="0"/>
    <frame name="footerFrame" src="${orcaUrl}footer.html" frameborder="0" scrolling="no"/>
  </frameset>
</html>
END_HERE

  return [ $q->psgi_header('text/html'), [ $psgi_out ] ];
}
1;
