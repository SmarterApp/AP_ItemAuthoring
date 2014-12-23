package Action::itemContentView;

use ItemConstants;
use Item;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $sth;
  our $sql;

  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );

  return [ $q->psgi_header('text/html'), [ &print_item(\%in) ]];
}

### ALL DONE! ###

sub print_item {

    my $params = shift;

    my $item = new Item( $dbh, $params->{itemId} );

    return &printNoAuthPage unless $banks->{$item->{bankId}};

    my $c = $item->getDisplayContent();

    return <<END_HERE;
<html>
  <head>
    <title>Item Viewer</title>
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css">
    <style type="text/css">
      td { vertical-align: middle; }

    </style>
  </head>
  <body>
    <p>Item:&nbsp;&nbsp;<b>$item->{name}</b>&nbsp;&nbsp;&lt;$item->{bankName}&gt;<br />
    $c->{itemBody}
  </body>
</html>
END_HERE
}
1;
