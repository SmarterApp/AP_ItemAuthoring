package Action::assetCreateFrameset;

use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $itemId     = $in{itemId};
  our $itemBankId = $in{itemBankId};
  our $version    = $in{version};

  our $psgi_out = <<END_HERE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html>
  <head>
    <title>Asset Create/Edit</title>
  </head>
  <frameset cols="*, 39%">
    <frame name="acFrame" scrolling="no" src="${assetCreateUrl}?itemBankId=${itemBankId}&itemId=${itemId}&version=${version}" />
    <frame name="imageOutFrame" src="${assetBlankUrl}" />
  </frameset>
</html>
END_HERE

  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
}
1;
