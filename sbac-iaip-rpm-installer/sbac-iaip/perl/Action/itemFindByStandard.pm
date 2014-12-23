package Action::itemFindByStandard;

use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $debug = 1;
  
  our %item_types = (
      '0' => 'NULL',
      '1' => 'X_MC',
      '2' => 'NON_X_MC',
      '3' => 'SHORT_CR',
      '4' => 'EXTENDED_CR'
  );
  
  our $sth;
  
  unless ( defined $in{hierarchyId} ) {
      my $sql = "SELECT * FROM standard_hierarchy";
      $sth = $dbh->prepare($sql);
      $sth->execute()
        || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
      $in{model} = {};
      while ( my $row = $sth->fetchrow_hashref ) {
          $in{model}->{ $row->{sh_id} }   = $row->{sh_name};
          $in{idArray}->{ $row->{sh_id} } = $row->{hd_id};
      }
 
      return [ $q->psgi_header('text/html'), [ &print_first_screen(\%in) ]];
  }
  
  if ( defined( $in{selectedId} ) && $in{selectedId} ne "" ) {
  
      my $itemBankId = $in{itemBankId};
      my $selectedId = $in{selectedId};
      my @itemIds    = ();
      my $sql =
          "SELECT i_external_id FROM item WHERE ib_id=$in{itemBankId} AND i_id IN "
        . "(SELECT i_id FROM item_characterization WHERE ic_type=${OC_ITEM_STANDARD} AND ic_value=${selectedId})";
      $sth = $dbh->prepare($sql);
      $sth->execute(); # || warn( "Failed Query:" . $dbh->err );
      while ( my $row = $sth->fetchrow_hashref ) {
          push @itemIds, $row->{i_external_id};
      }
      my $joinedItemIds = join( ' ', @itemIds );
  
      my $psgi_out = <<END_HERE;
  <html>
    <head>
      <title>Find Item By Standard</title>
    </head>
    <body onLoad="document.itemView.submit();">
  	<form name="itemView" action="itemView.pl" method="POST" enctype="multipart/form-data" >
       	<input type="hidden" name="actionType" value="preview" />
       	<input type="hidden" name="itemBankId" value="$itemBankId" />
       	<input type="hidden" name="itemExternalId" value="$joinedItemIds" />
  	</form>
    </body>
  </html>
END_HERE
  
      return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
  
  $in{text} = {};    #Holds the text descriptions
  for ( my $i = 0 ; $i <= $in{level} ; $i++ ) {
  
      # Build one drop-down list ( 1 step of the hierarchy )
      my $iplus = $i + 1;
      my $sql   = "SELECT * FROM hierarchy_definition WHERE hd_parent_id="
        . $in{"hdId${i}"};
      $sth = $dbh->prepare($sql);
      $sth->execute()
        || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
      $in{"model${iplus}"} = {};    # hd_id to hd_value map
      $in{"pos${iplus}"}   = {};    # hd_id to hd_posn_in_parent map
      while ( my $row = $sth->fetchrow_hashref ) {
          $in{"model${iplus}"}->{ $row->{hd_id} } = $row->{hd_value};
          $in{"pos${iplus}"}->{ $row->{hd_id} }   = $row->{hd_posn_in_parent};
          $in{"type${iplus}"}                     = $row->{hd_type};
  
          if ( $row->{hd_std_desc} ) {
              $in{text}->{ $row->{hd_id} } = $row->{hd_std_desc};
              $in{textType} = $row->{hd_type};
          }
  
      }
  }
  
  unless ( defined $in{label1} ) {
  
      # Save all labels for later use
      my $sql = "SELECT * FROM qualifier_label WHERE sh_id=$in{hierarchyId}";
      $sth = $dbh->prepare($sql);
      $sth->execute()
        || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
      while ( my $row = $sth->fetchrow_hashref ) {
          $in{ 'label' . $row->{ql_type} } = $row->{ql_label};
      }
  }
  
  $in{level} = $in{level} + 1;

  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
}
### ALL DONE! ###

sub print_first_screen {

    my $params = shift;

    my $model      = $params->{model};
    my $itemBankId = $params->{itemBankId};
    my $hd_ids     = $params->{idArray};

    my $jsArray = "var idArray = new Array();\n";
    foreach my $key ( keys %{$hd_ids} ) {
        $jsArray .= 'idArray["' . $key . '"] = "' . $hd_ids->{$key} . "\";\n";
    }

    my $dispList = &hashToSelect(
        'hierarchyId',
        $model,
        '',
'mySubmit(this.options[this.selectedIndex].value,this.options[this.selectedIndex].text); return true;',
        'null'
    );

    return <<END_HERE;
<html>
  <head>
    <title>Find Item By Standard</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
     ${jsArray} 
      
      function mySubmit(strvalue,strtext)
      {
        document.itemFindStandard.hdId0.value = idArray[strvalue];
	document.itemFindStandard.label0.value = strtext;
	document.itemFindStandard.submit();
        return true; 
      }

    //-->
    </script>
  </head>
  <body>
    <h3><span class="text">Find Item By Standard</span></h3>
    <form name="itemFindStandard" action="itemFindByStandard.pl" method="POST">
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="hdId0" value="" />
      <input type="hidden" name="label0" value="" />
      <input type="hidden" name="level" value="0" />
    <table border="0" cellpadding="4" cellspacing="4">
      <tr><td><span class="text">Hierarchy:</span></td><td>${dispList}</td></tr> 
    </table>
    </form>
  </body>
</html>
END_HERE
}

sub print_welcome {
  my $psgi_out = '';
    my $params = shift;

    my $itemBankId = $params->{itemBankId};
    my $hId        = $params->{hierarchyId};
    my $hdIdRoot   = $params->{hdId0};
    my $hLabel     = $params->{label0};

    my $selectHtml = "";

    for ( my $i = 1 ; $i <= $params->{level} ; $i++ ) {
        $selectHtml .=
            '<tr><td><span class="text">'
          . $params->{ 'label' . $params->{"type${i}"} }
          . ':</span></td>'
          . '<td><select name="hdId'
          . $i . '"';

        if ( defined( $in{textType} )
            && $in{textType} eq $params->{ 'type' . $i } )
        {
            $selectHtml .=
' onChange="displayText(this.options[this.selectedIndex].value); return true;">';
        }
        else {
            $selectHtml .= ' onChange="mySubmit(' . $i . '); return true;">';
        }
        $selectHtml .= '<option value=""></option>';

        my $model = $params->{"model${i}"};
        my $pos   = $params->{"pos${i}"};

        foreach my $key ( sort { $pos->{$a} <=> $pos->{$b} } keys %$pos ) {
            $selectHtml .=
                '<option value="' 
              . $key . '"'
              . ( defined( $params->{"hdId${i}"} )
                  && $params->{"hdId${i}"} eq $key ? ' SELECTED' : '' )
              . '>'
              . $model->{$key}
              . '</option>';
        }

        $selectHtml .= '</select></td></tr>';
    }

    my $hiddenHtml = "";

    foreach my $key ( grep { /^label/ } keys %$params ) {
        $hiddenHtml .=
            '<input type="hidden" name="' 
          . $key
          . '" value="'
          . $params->{$key} . '" />';
    }

    my $jsArray = "var textArray = new Array();\n" . "textArray[\"\"] = '';\n";

    if ( defined $in{textType} ) {
        my $textz = $params->{text};

        foreach my $key ( keys %$textz ) {
            $textz->{$key} =~ s/"/\\"/g;
            $textz->{$key} =~ s/\r/\\r/g;
            $textz->{$key} =~ s/\n/\\n/g;
            $jsArray .=
              'textArray["' . $key . '"] = "' . $textz->{$key} . "\";\n";
        }
    }

    $psgi_out .= <<END_HERE;
<html>
  <head>
    title>Find Item By Standard</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      ${jsArray}

      function mySubmit(level)
      {
        document.itemFindStandard.level.value = level;	
	document.itemFindStandard.submit();
        return true; 
      }

      function displayText(id)
      {
        document.itemFindStandard.description.value = textArray[id];
        return true; 
      }

      function getItemList(id)
      {
        document.itemFindStandard.selectedId.value = id;
        document.itemFindStandard.submit();
	return true;
      }
    //-->
    </script>
  </head>
  <body>
    <h3><span class="text">Find Item By Standard</span></h3>
    <form name="itemFindStandard" action="itemFindByStandard.pl" method="POST">
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="hierarchyId" value="${hId}" />
      <input type="hidden" name="hdId0" value="${hdIdRoot}" />
      <input type="hidden" name="selectedId" value="" />
      <input type="hidden" name="level" value="" />
      ${hiddenHtml}
    <table border="0" cellpadding="4" cellspacing="4">
      <tr><td><span class="text">Hierarchy:</span></td><td>${hLabel}</td></tr> 
      ${selectHtml}
    </table>
END_HERE
    if ( defined $params->{textType} ) {
        my $textId = "";
        for ( my $i = 1 ; $i <= $params->{level} ; $i++ ) {
            if ( $params->{textType} eq $params->{"type${i}"} ) {
                $textId = "hdId${i}";
                last;
            }
        }

        $psgi_out .= <<END_HERE;
    <table border="0" cellpadding="4" cellspacing="4">
    <tr><td>
    <span class="text">Description</span><br />
    <textarea name="description" rows="4" cols="50"></textarea>
    </td></tr>
    <tr><td><input type="button" onClick="getItemList(document.itemFindStandard.${textId}.options[document.itemFindStandard.${textId}.selectedIndex].value);" value="View Items" />
    </td></tr>
    </table>
END_HERE
    }
    $psgi_out .= <<END_HERE;
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
