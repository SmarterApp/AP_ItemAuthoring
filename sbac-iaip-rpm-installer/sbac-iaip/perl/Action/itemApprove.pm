package Action::itemApprove;

use UrlConstants;

sub run {

  my $q = shift;
  my %in  = map { $_ => $q->param($_) } $q->param;

  my $psgi_out = <<END_HERE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">
<html>
  <head>
    <title>SBAC IAIP: Item Edit/Review</title>
    <meta http-equiv="x-ua-compatible" content="IE=9" />
  </head>
  <frameset rows="60px,*,20px">
    <frame name="menuFrame" src="${orcaUrl}cgi-bin/itemApproveMenu.pl" frameborder="0" scrolling="no"/>
    <frame name="rightFrame" src="${orcaUrl}blank.html" frameborder="0"/>
    <frame name="footerFrame" src="${orcaUrl}footer.html" frameborder="0" scrolling="no"/>
  </frameset>
</html>
END_HERE

  return [ $q->psgi_header('text/html'), [ $psgi_out ] ];
}
1;
