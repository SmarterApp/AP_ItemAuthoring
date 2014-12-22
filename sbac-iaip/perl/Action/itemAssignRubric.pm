package Action::itemAssignRubric;

use ItemConstants;
use Item;
use Rubric;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/itemAssignRubric.pl";
  
  our $sth;
  our $sql;
  our @model = ();
  
  our $item = new Item( $dbh, $in{itemId} );
  
  if ( $in{myAction} eq 'Remove' ) {
      $item->deleteChar( $OC_RUBRIC, $in{rubricId} );
  
      $item = new Item( $dbh, $in{itemId} );
  
      delete $in{myAction};
  }
  
  unless ( defined $in{myAction} ) {
      if ( scalar @{ $item->{rubrics} } ) {
        return [ $q->psgi_header('text/html'), [ &print_assigned_rubric(\%in) ]];
      }
      else {
        return [ $q->psgi_header('text/html'), [ &print_search_rubric(\%in) ]];
      }
  }
  
  if ( $in{myAction} eq 'Search' ) {
      return [ $q->psgi_header('text/html'), [ &print_search_rubric(\%in) ]];
  }
  elsif ( $in{myAction} eq 'View' ) {
      $sql = 'SELECT * FROM scoring_rubric WHERE ';
      if ( $in{rname} ne '' ) {
          $sql .= 'sr_name LIKE ' . $dbh->quote( '%' . $in{rname} . '%' );
      }
      else {
          $sql .= '1';
      }
      $sql .=
  " AND sr_id IN (SELECT oc_object_id FROM object_characterization WHERE oc_object_type=${OT_RUBRIC} AND oc_characteristic=${OC_GRADE_LEVEL} AND oc_int_value=$in{gradeLevel})"
        unless $in{gradeLevel} eq '';
      $sql .=
  " AND sr_id IN (SELECT oc_object_id FROM object_characterization WHERE oc_object_type=${OT_RUBRIC} AND oc_characteristic=${OC_CONTENT_AREA} AND oc_int_value=$in{contentArea})"
        unless $in{contentArea} eq '';
      $sql .= " AND ib_id=$item->{bankId} ORDER BY sr_name";
  
      $sth = $dbh->prepare($sql);
      $sth->execute()
        || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
      while ( my $row = $sth->fetchrow_hashref ) {
          my %pdata = ();
          $pdata{id}          = $row->{sr_id};
          $pdata{name}        = $row->{sr_name};
          $pdata{description} = $row->{sr_description};
          push @model, \%pdata;
      }
  
      return [ $q->psgi_header('text/html'), [ &print_search_rubric(\%in) ]];
  }
  elsif ( $in{myAction} eq 'Assign' ) {
  
      $item->insertChar( $OC_RUBRIC, $in{rubricId} );
  
      my $psgi_out = <<END_HERE;
  <!DOCTYPE HTML>
  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
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

sub print_assigned_rubric {
  my $psgi_out = '';

    my $params = shift;

    my $itemId = $params->{itemId};

  $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Item Rubric</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      
      function mySubmit(strvalue,strtext)
      {
	document.itemStandard.submit();
        return true; 
      }

      function doRemoveSubmit(num) {
        document.itemRubric.myAction.value = 'Remove';
	document.itemRubric.rubricId.value = num;
	document.itemRubric.submit();
      }

    //-->
    </script>
  </head>
  <body>
    <div class="title">Assigned Rubrics</div>
    <form name="itemRubric" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemId" value="${itemId}" />
      <input type="hidden" name="rubricId" value="" />
      <input type="hidden" name="myAction" value="" />
END_HERE

    foreach ( @{ $item->{rubrics} } ) {

        my $rubric = new Rubric( $dbh, $_ );

        $psgi_out .= '<table border="0" cellpadding="2" cellspacing="2" class="no-style">'
          . '<tr><td><span class="text">Name:</span></td><td>'
          . $rubric->{name}
          . '</td></tr>'
          . '<tr><td><span class="text">Description:</span></td><td>'
          . $rubric->{description}
          . '</td></tr>'
          . ( $item->{readOnly}
            ? ''
            : '<tr><td><input type="button" value="Remove" onClick="doRemoveSubmit('
              . $rubric->{id}
              . ');" /></td><td></td></tr>' )
          . '</table>'
          . '<table border="1" cellpadding="2" cellspacing="2" class="no-style">'
          . '<tbody>'
          . '  <tr>'
          . '   <td valign="top">'
          . $rubric->{content}
          . '   </td></tr></tbody></table><br /><br />';
    }

    $psgi_out .= <<END_HERE;
    </form>
END_HERE

    unless ( $item->{readOnly} ) {
        $psgi_out .= <<END_HERE;
    <div><a href="${thisUrl}?itemId=${itemId}&myAction=Search" target="_self">Assign Another Rubric</a> </div> 
END_HERE
    }

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out; 
}

sub print_search_rubric {
  my $psgi_out = '';

    my $params = shift;

    my $itemId = $params->{itemId};
    my $rname = defined( $params->{rname} ) ? $params->{rname} : '';
    my $description =
      defined( $params->{description} ) ? $params->{description} : '';

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
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Item Rubric</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--

      function doRubricAssign(num) {
        document.itemRubric.rubricId.value = num;
	document.itemRubric.myAction.value = 'Assign';
	document.itemRubric.submit();
      }

      function doSearchSubmit() {
        document.itemRubric.myAction.value = 'View';
	document.itemRubric.submit();
      }

    //-->
    </script>
  </head>
  <body>
    <div class="title">Assign Rubric</div>
    <form name="itemRubric" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemId" value="${itemId}" />
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="rubricId" value="" />
    <div><span class="text">Search By</span></div> 
    <table border="0" cellpadding="4" cellspacing="4" class="no-style">
      <tr><td><span class="text">Name:</span></td><td><input name="rname" type="text" size="25" value="${rname}" /></td></tr> 
      <tr><td><span class="text">Content Area:</span></td><td>${contentAreaList}</td></tr>
      <tr><td><span class="text">Grade Level:</span></td><td>${gradeLevelList}</td></tr>
      <tr><td colspan="2"><input type="button" value="View" onClick="doSearchSubmit();" /></td></tr>
    </table>
    </form>
END_HERE

    if ( @model > 0 ) {

        $psgi_out .= '<table border="1" cellpadding="4" cellspacing="4" class="no-style">';
        $psgi_out .=
'<tr><th><span class="text">Name</span></th><th><span class="text">Description</span></th></tr>';

        foreach my $rdata (@model) {
            $psgi_out .= '<tr><td><a href="' 
              . $orcaUrl
              . 'cgi-bin/rubricView.pl?rubricId='
              . $rdata->{id}
              . '" target="_blank">'
              . $rdata->{name}
              . '</a></td>' . '<td>'
              . $rdata->{description} . '</td>'
              . '<td><input type="button" value="Assign" onClick="doRubricAssign('
              . $rdata->{id}
              . ');"/></td></tr>';
        }

        $psgi_out .= '</table>';
    }

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
