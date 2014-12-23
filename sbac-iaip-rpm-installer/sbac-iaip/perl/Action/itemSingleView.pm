package Action::itemSingleView;

use URI::Escape;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $debug = 1;
  
  our $sth;
  our $sql;
  
  $in{passages} = {};
  
  # Get Item characteristics
  $sql = "SELECT * FROM item_characterization WHERE i_id=$in{itemId}";
  $sth = $dbh->prepare($sql);
  $sth->execute() || warn( "Failed Query:" . $dbh->err );
  
  while ( my $row = $sth->fetchrow_hashref ) {
  
      # Check for assigned GLE
      if ( $row->{ic_type} eq $OC_ITEM_STANDARD ) {
          my $sql1 =
            "SELECT * FROM hierarchy_definition WHERE hd_id=$row->{ic_value}";
          my $sth1 = $dbh->prepare($sql1);
          $sth1->execute() || warn( "Failed Query:" . $dbh->err );
  
          if ( my $row1 = $sth1->fetchrow_hashref ) {
              $in{gleName} = $row1->{hd_value};
              $in{gleText} = $row1->{hd_std_desc};
          }
      }
  
      # Check for assigned passage
      if ( $row->{ic_type} eq $OC_PASSAGE ) {
          my $sql1 = "SELECT * FROM passage WHERE p_id=$row->{ic_value}";
          my $sth1 = $dbh->prepare($sql1);
          $sth1->execute() || warn( "Failed Query:" . $dbh->err );
  
          if ( my $row1 = $sth1->fetchrow_hashref ) {
              $in{passages}->{ $row1->{p_id} }            = {};
              $in{passages}->{ $row1->{p_id} }->{name}    = $row1->{p_name};
              $in{passages}->{ $row1->{p_id} }->{summary} = $row1->{p_summary};
              $in{passageId}                             = $row1->{p_id};
              $in{passageName}                           = $row1->{p_name};
              $in{passageSummary}                        = $row1->{p_summary};
          }
      }
  
  }
   
  return [ $q->psgi_header('text/html'), [ &print_preview( \%in ) ]];
}
### ALL DONE! ###

sub print_preview {
  my $psgi_out = '';

    my $params      = shift;

    my $item = new Item($dbh, $params->{itemId});
    my $content = $item->getDisplayContent();

    my $itemId      = $params->{itemId};
    my $formatName    = $item_formats{ $item->{format} };
    my $difficultyName = $difficulty_levels{$item->{difficulty}};
    my $gleName = ( defined $params->{gleName} ? $params->{gleName} : '' );
    $gleName =~ s/GLE//;
    my $gleText = ( defined $params->{gleText} ? $params->{gleText} : '' );
    $gleText =~ s/\r?\n/<br \/>/g;
    my $passageName =
      ( defined $params->{passageName} ? $params->{passageName} : '' );
    my $passageId =
      ( defined $params->{passageId} ? $params->{passageId} : '' );
    my $passages  = $params->{passages};

    my $charDisplay = "";

    foreach my $type (@ctypes) {
        $charDisplay .=
            '<tr><td>'
          . $labels[$type] . '</td>'
          . '<td><b>'
          . $const[$type]->{ $item->{$type} || 0 }
          . '</b></td></tr>';

    }

    my $itemCssLink = $item->getCssLink();

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <meta http-equiv="X-UA-Compatible" content="IE=9" />
    <title>Item Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css">
    <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
    ${itemCssLink}
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
    <script type="text/javascript" src="${commonUrl}mathjax/MathJax.js?config=MML_HTMLorMML"></script>
    <style type="text/css">
      td { vertical-align: middle; }
  
  </style>
  </head>
  <body>
    <div class="title">SBAC IAIP Item</div>
END_HERE

    if ( $gleName ne '' ) {
        $psgi_out .= <<END_HERE
     <table class="no-style" border="1" cellspacing="3" cellpadding="3">
       <tr><th align="center">GLE ${gleName}</th></tr>
       <tr><td>${gleText}</td></tr>
     </table>
     <br />
END_HERE
    }

    $psgi_out .= <<END_HERE;
    <p>Item:&nbsp;&nbsp;<b>$item->{name}</b>&nbsp;&nbsp;&lt;$item->{bankName}&gt;<br />
    Description:&nbsp;&nbsp;$item->{description}</p>
    <br />
    $content->{itemBody}
    <br />
    $content->{distractorRationale}
    <br />
    $content->{correctResponse}
    <br />
    <table border=1 cellspacing=3 cellpadding=2>
     <tr><td>Item Format:</td><td><b>${formatName}</b></td></tr> 
     ${charDisplay}
     <tr><td>Dev State:</td><td><b>$item->{devStateName}</b></td></tr>
     <tr><td>Difficulty:</td><td><b>${difficultyName}</b></td></tr>
END_HERE

    if (%$passages) {
        $psgi_out .= '<tr><td>Linked Passages:</td><td>';

        foreach my $pkey (%$passages) {
            $psgi_out .= '<div><a href="' 
              . $orcaUrl
              . 'cgi-bin/passageView.pl?passageId='
              . $pkey
              . '" target="_blank">'
              . $passages->{$pkey}->{name}
              . '</a></div>';
        }
        $psgi_out .= '</td></tr>';
    }

    $psgi_out .= <<END_HERE;
     </table>
  </body>
</html>         
END_HERE

  return $psgi_out;
}
1;
