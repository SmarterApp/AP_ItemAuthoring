package Action::itemAssignPassage;

use ItemConstants;
use Item;
use Passage;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/itemAssignPassage.pl";
  
  our $sth;
  our $sql;
  our @model = ();
  
  our $item = new Item( $dbh, $in{itemId} );
  
  if ( exists( $in{myAction} ) and $in{myAction} eq 'Remove' ) {
      $item->deleteChar( $OC_PASSAGE, $in{passageId} );
      delete $in{myAction};
  }
  
  unless ( defined $in{myAction} ) {
  
      # Look for Assigned Passages
      $in{passages} = {};
  
      foreach ( @{ $item->{passages} } ) {
          my $psg = new Passage( $dbh, $_ );
          $in{passages}->{ $psg->{id} } = $psg if $psg->{id} > 0;
      }
  
      if ( scalar( keys %{ $in{passages} } ) ) {
        return [ $q->psgi_header('text/html'), [ &print_assigned_passage(\%in) ]];
      }
      else {
        return [ $q->psgi_header('text/html'), [ &print_search_passage(\%in) ]];
      }
  }
  
  if ( $in{myAction} eq 'Search' ) {
    return [ $q->psgi_header('text/html'), [ &print_search_passage(\%in) ]];
  }
  elsif ( $in{myAction} eq 'View' ) {
      $sql = 'SELECT * FROM passage WHERE ';
      if ( $in{genre} > 0 ) {
          $sql .= 'p_genre=' . $in{genre};
          if ( $in{pname} ne '' ) {
              $sql .= ' AND p_name LIKE ' . $dbh->quote( '%' . $in{pname} . '%' );
          }
      }
      else {
          if ( $in{pname} ne '' ) {
              $sql .= 'p_name LIKE ' . $dbh->quote( '%' . $in{pname} . '%' );
          }
          else {
              $sql .= '1';
          }
      }
      $sql .=
  " AND p_id IN (SELECT oc_object_id FROM object_characterization WHERE oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_GRADE_LEVEL} AND oc_int_value=$in{gradeLevel})"
        unless $in{gradeLevel} eq '';
      $sql .=
  " AND p_id IN (SELECT oc_object_id FROM object_characterization WHERE oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_CONTENT_AREA} AND oc_int_value=$in{contentArea})"
        unless $in{contentArea} eq '';
      $sql .= " AND ib_id=$in{itemBankId} ORDER BY p_name";
  
      $sth = $dbh->prepare($sql);
      $sth->execute()
        || warn("Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
      while ( my $row = $sth->fetchrow_hashref ) {
          my %pdata = ();
          $pdata{id}    = $row->{p_id};
          $pdata{name}  = $row->{p_name};
          $pdata{genre} = $row->{p_genre};
          $pdata{count} = $row->{p_word_count};
          push @model, \%pdata;
      }
 
      return [ $q->psgi_header('text/html'), [ &print_search_passage(\%in) ]];
  }
  elsif ( $in{myAction} eq 'Assign' ) {
  
      $item->insertChar( $OC_PASSAGE, $in{passageId} );
  
      my $psgi_out = <<END_HERE;
  <html>
    <head>
      <title></title>
    </head>
    <body onLoad="self.close();">
    </body>
  </html>
END_HERE
  
    return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
}
### ALL DONE! ###

sub print_assigned_passage {
  my $psgi_out = '';

    my $params = shift;

    my $itemId     = $params->{itemId};
    my $itemBankId = $params->{itemBankId};

    my $passages = $params->{passages};

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Passage</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      
      function mySubmit(strvalue,strtext)
      {
	document.itemStandard.submit();
        return true; 
      }

      function doRemoveSubmit(num) {
        document.itemPassage.myAction.value = 'Remove';
	document.itemPassage.passageId.value = num;
	document.itemPassage.submit();
      }

    //-->
    </script>
  </head>
  <body>
    <div class="title">Assigned Passages</div>
    <form name="itemPassage" action="itemAssignPassage.pl" method="POST">
      <input type="hidden" name="itemId" value="${itemId}" />
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="passageId" value="" />
      <input type="hidden" name="myAction" value="" />
END_HERE

    foreach ( keys %$passages ) {

        my $genreName = $genres{ $passages->{$_}->{genre} };

        $psgi_out .= '<table border="0" cellpadding="2" cellspacing="2" class="no-style">'
          . '<tr><td><span class="text">Name:</span></td><td>'
          . $passages->{$_}->{name}
          . '</td></tr>'
          . '<tr><td><span class="text">Genre:</span></td><td>'
          . $genreName
          . '</td></tr>'
          . ( $item->{readOnly}
            ? ''
            : '<tr><td><input type="button" value="Remove" onClick="doRemoveSubmit('
              . $_
              . ');" /></td><td></td></tr>' )
          . '</table>'
          . '<table border="1" cellpadding="2" cellspacing="2" class="no-style">'
          . '<tbody>'
          . '  <tr>'
          . '   <td valign="top">'
          . (isHTMLContentEmpty($passages->{$_}->{content})?'No Content to Display':$passages->{$_}->{content})
          . '   </td></tr></tbody></table><br /><br />';
    }

    $psgi_out .= <<END_HERE;
    </form>
END_HERE

    unless ( $item->{readOnly} ) {
        $psgi_out .= <<END_HERE;
    <div><a href="${orcaUrl}cgi-bin/itemAssignPassage.pl?itemId=${itemId}&itemBankId=${itemBankId}&myAction=Search" target="_self">Assign Another Passage</a> </div> 
END_HERE
    }

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_search_passage {
  my $psgi_out = '';

    my $params = shift;

    my $itemId     = $params->{itemId};
    my $itemBankId = $params->{itemBankId};
    my $pname      = defined( $params->{pname} ) ? $params->{pname} : '';

    my $genre = defined( $params->{genre} ) ? $params->{genre} : '0';
    my $genreList = &hashToSelect( 'genre', \%genres, $genre, '', '' );

    my $contentArea =
      defined( $params->{contentArea} ) ? $params->{contentArea} : '';
    my $contentAreaList =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        $contentArea, '', 'null' );

    my $gradeLevel =
      defined( $params->{gradeLevel} ) ? $params->{gradeLevel} : '';
    my $gradeLevelList =
      &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], $gradeLevel, '',
        'null' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>    
<html>
  <head>
    <title>Item Passage</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--

      function doPassageAssign(num) {
        document.itemPassage.passageId.value = num;
	document.itemPassage.myAction.value = 'Assign';
	document.itemPassage.submit();
      }

      function doSearchSubmit() {
        document.itemPassage.myAction.value = 'View';
	document.itemPassage.submit();
      }

    //-->
    </script>
  </head>
  <body>
    <div class="title">Assign Passage</div>
    <form name="itemPassage" action="itemAssignPassage.pl" method="POST">
      <input type="hidden" name="itemId" value="${itemId}" />
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="myAction" value="View" />
      <input type="hidden" name="passageId" value="" />
    <div><span class="text">Search By</span></div> 
    <table border="0" cellpadding="4" cellspacing="4" class="no-style">
      <tr><td><span class="text">Name:</span></td><td><input name="pname" type="text" size="25" value="${pname}" /></td></tr> 
      <tr><td><span class="text">Content Area:</span></td><td>${contentAreaList}</td></tr>
      <tr><td><span class="text">Grade Level:</span></td><td>${gradeLevelList}</td></tr>
      <tr><td><span class="text">Genre:</span></td><td>${genreList}</td></tr>
      <tr><td colspan="2"><input type="button" value="View" onClick="doSearchSubmit();" /></td></tr>
    </table>
    </form>
END_HERE

    if ( @model > 0 ) {

        $psgi_out .= '<table border="1" cellpadding="4" cellspacing="4" class="no-style">';
        $psgi_out .=
'<tr><th><span class="text">Name</span></th><th><span class="text">Genre</span></th><th><span class="text">Estimated Word Count</span></th></tr>';

        foreach my $pdata (@model) {
        	# modified by Mithun
				$sql = sprintf( "SELECT * FROM external_content_metadata WHERE p_id=%d", $pdata->{id} );
				$sth = $dbh->prepare( $sql );  
				$sth->execute();	
			# end
            $psgi_out .= ($sth->rows == 0 ?'<tr><td><a href="' 
              . $orcaUrl
              . 'cgi-bin/passageView.pl?passageId='
              . $pdata->{id}
              . '" target="_blank">'
              . $pdata->{name}
              . '</a></td>' . '<td>'
              . $genres{ $pdata->{genre} } . '</td>' . '<td>'
              . $pdata->{count} . '</td>'
              . '<td><input type="button" value="Assign" onClick="doPassageAssign('
              . $pdata->{id}
              . ');"/></td></tr>': '');
        }

        $psgi_out .= '</table>';
    } else {

      if($in{myAction} eq 'View') {
        $psgi_out .= '<p>No Search results were found matching your query.</p>';
      }
    }

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
