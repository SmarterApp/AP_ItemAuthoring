package Action::getItemsByStandard;

use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $hd_pivot_type = 4;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  our $sth;
  
  $in{myAction} = '' unless defined $in{myAction};
  
  if ( $in{myAction} eq 'getGLEs' ) {
      my @strandIds = split / /, $in{ "hdId$in{level}" . '[]' };
      $in{strands} = {};
      my $sql = "SELECT * FROM hierarchy_definition WHERE hd_id IN ("
        . join( ',', @strandIds ) . ')';
      $sth = $dbh->prepare($sql);
      $sth->execute() || warn( "Failed Query:" . $dbh->err );
      while ( my $row = $sth->fetchrow_hashref ) {
          $in{strands}->{ $row->{hd_id} }         = {};
          $in{strands}->{ $row->{hd_id} }->{name} = $row->{hd_value};
          $in{strands}->{ $row->{hd_id} }->{posn} = $row->{hd_posn_in_parent};
  
          $in{strands}->{ $row->{hd_id} }->{gles} = {};
  
          # Test to see if the next level is GLE
          my @hdIds  = ();
          my %hdPosn = ();
          my $sql2 =
  "SELECT * FROM hierarchy_definition WHERE hd_parent_id=$row->{hd_id} LIMIT 1";
          my $sth2 = $dbh->prepare($sql2);
          $sth2->execute() || warn( "Failed Query:" . $dbh->err );
  
          if ( my $row2 = $sth2->fetchrow_hashref ) {
              if ( $row2->{hd_type} == $HD_GLE ) {
                  push @hdIds, $row->{hd_id};
                  $hdPosn{ $row->{hd_id} } = 0;
              }
              else {
                  $sql2 =
  "SELECT * FROM hierarchy_definition WHERE hd_parent_id=$row->{hd_id}";
                  $sth2 = $dbh->prepare($sql2);
                  $sth2->execute() || warn( "Failed Query:" . $dbh->err );
                  while ( my $row3 = $sth2->fetchrow_hashref ) {
                      push @hdIds, $row3->{hd_id};
                      $hdPosn{ $row3->{hd_id} } =
                        100 * $row3->{hd_posn_in_parent};
                  }
              }
          }
  
          $sql2 = 'SELECT * FROM hierarchy_definition WHERE hd_parent_id IN ('
            . join( ',', @hdIds ) . ')';
          $sth2 = $dbh->prepare($sql2);
          $sth2->execute() || warn( "Failed Query:" . $dbh->err );
  
          while ( my $row4 = $sth2->fetchrow_hashref ) {
              $row4->{hd_value} =~ s/^GLE ?//;
  
              # strip benchmark strings
              while ( $row4->{hd_std_desc} =~ m/\([^\)]*\)\s*$/ ) {
                  $row4->{hd_std_desc} =~ s/\([^\)]*\)\s*$//;
              }
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row4->{hd_id} } = {};
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row4->{hd_id} }->{id} =
                $row4->{hd_id};
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row4->{hd_id} }
                ->{name} = $row4->{hd_value};
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row4->{hd_id} }
                ->{text} = $row4->{hd_std_desc};
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row4->{hd_id} }
                ->{posn} =
                $row4->{hd_posn_in_parent} + $hdPosn{ $row4->{hd_parent_id} };
          }
      }

      return [ $q->psgi_header('text/html'), [ &print_strands(\%in) ]];
  }
  elsif ( $in{myAction} eq 'getItems' ) {
      my @strandIds = split / /, $in{ 'hdId' . $in{level} . '[]' };
      my @gleIds    = split / /, $in{gleList};
      $in{strands} = {};
      my $sql = "SELECT * FROM hierarchy_definition WHERE hd_id IN ("
        . join( ',', @strandIds ) . ')';
      $sth = $dbh->prepare($sql);
      $sth->execute() || warn( "Failed Query:" . $dbh->err );
      while ( my $row = $sth->fetchrow_hashref ) {
          $in{strands}->{ $row->{hd_id} }         = {};
          $in{strands}->{ $row->{hd_id} }->{name} = $row->{hd_value};
          $in{strands}->{ $row->{hd_id} }->{posn} = $row->{hd_posn_in_parent};
  
          $in{strands}->{ $row->{hd_id} }->{gles} = {};
  
          # Test to see if the next level is GLE
          my @hdIds  = ();
          my %hdPosn = ();
          my $sql2 =
  "SELECT * FROM hierarchy_definition WHERE hd_parent_id=$row->{hd_id} LIMIT 1";
          my $sth2 = $dbh->prepare($sql2);
          $sth2->execute() || warn( "Failed Query:" . $dbh->err );
  
          if ( my $row2 = $sth2->fetchrow_hashref ) {
              if ( $row2->{hd_type} == $HD_GLE ) {
                  push @hdIds, $row->{hd_id};
                  $hdPosn{ $row->{hd_id} } = 0;
              }
              else {
                  $sql2 =
  "SELECT * FROM hierarchy_definition WHERE hd_parent_id=$row->{hd_id}";
                  $sth2 = $dbh->prepare($sql2);
                  $sth2->execute() || warn( "Failed Query:" . $dbh->err );
                  while ( my $row3 = $sth2->fetchrow_hashref ) {
                      push @hdIds, $row3->{hd_id};
                      $hdPosn{ $row3->{hd_id} } =
                        100 * $row3->{hd_posn_in_parent};
                  }
              }
          }
  
          $sql2 = 'SELECT * FROM hierarchy_definition WHERE hd_parent_id IN ('
            . join( ',', @hdIds ) . ')';
          $sth2 = $dbh->prepare($sql2);
          $sth2->execute() || warn( "Failed Query:" . $dbh->err );
  
          while ( my $row2 = $sth2->fetchrow_hashref ) {
              next unless &arrayContains( $row2->{hd_id}, \@gleIds ) == 1;
              $row2->{hd_value} =~ s/^GLE ?//;
  
              # strip benchmark strings
              while ( $row2->{hd_std_desc} =~ m/\([^\)]*\)\s*$/ ) {
                  $row2->{hd_std_desc} =~ s/\([^\)]*\)\s*$//;
              }
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} } = {};
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                ->{name} = $row2->{hd_value};
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                ->{text} = $row2->{hd_std_desc};
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                ->{posn} =
                $row2->{hd_posn_in_parent} + $hdPosn{ $row2->{hd_parent_id} };
              $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                ->{items} = {};
              my $sql3 =
                  'SELECT i_id, i_external_id, i_description FROM item'
                . " WHERE ib_id=$in{itemBankId}"
                . ' AND i_id IN (SELECT i_id FROM item_characterization'
                . " WHERE ic_type=${OC_ITEM_STANDARD}"
                . " AND ic_value=$row2->{hd_id})"
                . ' ORDER BY i_external_id';
              my $sth3 = $dbh->prepare($sql3);
              $sth3->execute() || warn( "Failed Query:" . $dbh->err );
              my $itemPos = 0;
  
              while ( my $row3 = $sth3->fetchrow_hashref ) {
                  $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                    ->{items}->{ $row3->{i_id} } = {};
                  $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                    ->{items}->{ $row3->{i_id} }->{name} = $row3->{i_external_id};
                  $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                    ->{items}->{ $row3->{i_id} }->{text} = $row3->{i_description};
                  $in{strands}->{ $row->{hd_id} }->{gles}->{ $row2->{hd_id} }
                    ->{items}->{ $row3->{i_id} }->{posn} = $itemPos++;
                  $itemPos++;
              }
  
          }
      }
      
      return [ $q->psgi_header('text/html'), [ &print_gles(\%in) ]];
  }
  elsif ( $in{myAction} eq 'getOrder' ) {
      my @strandIds = split / /, $in{ 'hdId' . $in{level} . '[]' };
      my @gleIds    = split / /, $in{gleList};
      my @itemIds   = split / /, $in{itemList};
  
      # next 2 lines removes duplicates
      my $prev;
      @itemIds = grep( $_ ne $prev && ( $prev = $_, 1 ), sort @itemIds );
      $in{items} = {};
  
      my $sql =
          'SELECT i_id, i_external_id, i_description FROM item'
        . ' WHERE i_id IN ('
        . join( ',', @itemIds ) . ')'
        . ' ORDER BY i_external_id';
      $sth = $dbh->prepare($sql);
      $sth->execute() || warn( "Failed Query:" . $dbh->err );
      my $itemPos = 0;
      while ( my $row = $sth->fetchrow_hashref ) {
          $in{items}->{ $row->{i_id} }         = {};
          $in{items}->{ $row->{i_id} }->{name} = $row->{i_external_id};
          $in{items}->{ $row->{i_id} }->{text} = $row->{i_description};
          $in{items}->{ $row->{i_id} }->{posn} = $itemPos;
          $itemPos++;
      }

      return [ $q->psgi_header('text/html'), [ &print_items(\%in) ]];
  }
  elsif ( $in{myAction} eq 'orderItems' ) {
      my @itemList     = split / /, $in{itemList};
      my @itemNameList = split / /, $in{itemNameList};
  
      $in{items} = {};
  
      for ( my $i = 0 ; $i < @itemList ; $i++ ) {
          $in{items}->{ $itemList[$i] }         = {};
          $in{items}->{ $itemList[$i] }->{name} = $itemNameList[$i];
          $in{items}->{ $itemList[$i] }->{posn} = $i;
      }
  
      return [ $q->psgi_header('text/html'), [ &print_items(\%in) ]];
  }
  
  if ( $in{myAction} eq 'returnItems' ) {
  
      #my $joinedItemIds = join(' ',@itemIds);
  
      my $psgi_out = <<END_HERE;
  <html>
    <head>
      <title></title>
      <script language="JavaScript">
      <!--
        function loadItemsAndClose()
        {
          window.opener.document.itemView.itemBankId.value=;
  	window.opener.document.itemView.itemExternalId.value='';
          window.opener.document.itemView.submit();	
  	self.close();
  	return true;
        }
      //-->
      </script>
    </head>
    <body onLoad="loadItemsAndClose();">
    </body>
  </html>
END_HERE
 
    return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
  
  my $sql = "SELECT * FROM standard_hierarchy";
  $sth = $dbh->prepare($sql);
  $sth->execute()
    || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  $in{hierarchy} = {};
  while ( my $row = $sth->fetchrow_hashref ) {
      $in{hierarchy}->{ $row->{hd_id} } = $row->{sh_name};
      $in{hdId0} = $row->{hd_id} unless defined $in{hdId0};
      if ( $in{hdId0} eq $row->{hd_id} ) {
          $in{hierarchyId} = $row->{sh_id};
      }
  }
  
  $in{level} = 0 unless defined $in{level};
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
  
  #while(my ($k,$v) = each %in) {
  #  warn "$k = $v\n";
  #}
  $in{level} = $in{level} + 1;

  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
}
### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';
    my $params = shift;

    my $hierarchy = $params->{hierarchy};
    my $itemBankId =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : 0 );
    my $level    = $params->{level};
    my $type     = $params->{"type${level}"};
    my $hId      = $params->{hierarchyId};
    my $hdIdRoot = $params->{hdId0};
    my $hLabel   = $params->{label0};

    my $hList = '<select name="hdId0" onChange="mySubmit(0); return true;">';
    foreach my $key ( keys %{$hierarchy} ) {
        $hList .=
            '<option value="' 
          . $key . '"'
          . ( $key eq $hdIdRoot ? ' SELECTED' : '' ) . '>'
          . $hierarchy->{$key}
          . '</option>';
    }
    $hList .= '</select>';

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $itemBankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $itemBankId, '', '' );

    my $selectHtml = "";

    for ( my $i = 1 ; $i <= $level ; $i++ ) {
        $selectHtml .=
            '<tr><td><span class="text">'
          . $params->{ 'label' . $params->{"type${i}"} }
          . ':</span></td><td>';

        if ( $params->{"type${i}"} eq $hd_pivot_type ) {
        }
        else {
            $selectHtml .=
                '<select name="hdId' 
              . $i
              . '" onChange="mySubmit('
              . $i
              . ');"><option value=""></option>';
        }

        my $model = $params->{"model${i}"};
        my $pos   = $params->{"pos${i}"};

        foreach my $key ( sort { $pos->{$a} <=> $pos->{$b} } keys %$pos ) {

            if ( $params->{"type${i}"} eq $hd_pivot_type ) {
                $selectHtml .=
                    '<input type="checkbox" name="hdId' 
                  . $i
                  . '[]" value="'
                  . $key
                  . '" />&nbsp;&nbsp;'
                  . $model->{$key}
                  . '<br />';
            }
            else {
                $selectHtml .=
                    '<option value="' 
                  . $key . '"'
                  . ( defined( $params->{"hdId${i}"} )
                      && $params->{"hdId${i}"} eq $key ? ' SELECTED' : '' )
                  . '>'
                  . $model->{$key}
                  . '</option>';
            }
        }

        unless ( $params->{"type${i}"} eq $hd_pivot_type ) {
            $selectHtml .= '</select>';
        }

        $selectHtml .= '</td></tr>';
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
    <title>Get Items By Standard</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/tabber.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      
      ${jsArray}
      
      function mySubmit(level)
      {
        document.itemFindStandard.level.value = level;	
	document.itemFindStandard.myAction.value = ''; 
        document.itemFindStandard.target = '_self';	
	document.itemFindStandard.submit();
        return true; 
      }

      function doStrandSubmit() {
	 document.itemFindStandard.level.value = ${level}; 
	 document.itemFindStandard.myAction.value = 'getGLEs'; 
	 document.itemFindStandard.target = 'gleFrame';
	 document.itemFindStandard.submit();
	 document.getElementById('mainTab').tabber.tabShow(1);
      }

      function doGleSubmit() {

        var gleForm; 
	if(navigator.appName.indexOf('Microsoft') != -1) { 
             gleForm = document.gleFrame.gleForm;
        } else {
             gleForm = window.frames['gleFrame'].document.gleForm;
	}

        var gleArray = new Array();
	for(var i=0; i < gleForm["gle[]"].length; i++) {
	  if(gleForm["gle[]"][i].checked == true) {
	    gleArray.push(gleForm["gle[]"][i].value);
          }
	}  

        document.itemFindStandard.gleList.value = gleArray.join(' ');

	document.itemFindStandard.level.value = ${level}; 
	document.itemFindStandard.myAction.value = 'getItems'; 
	document.itemFindStandard.target = 'itemFrame';
	document.itemFindStandard.submit();
	document.getElementById('mainTab').tabber.tabShow(2);
      }
      
      function doItemSubmit() {

        var itemForm; 
	if(navigator.appName.indexOf('Microsoft') != -1) { 
             itemForm = document.itemFrame.itemForm;
        } else {
             itemForm = window.frames['itemFrame'].document.itemForm;
	}

        var itemArray = new Array();
	for(var i=0; i < itemForm["itemId[]"].length; i++) {
	  if(itemForm["itemId[]"][i].checked == true) {
	    itemArray.push(itemForm["itemId[]"][i].value);
          }
	}  

        document.itemFindStandard.itemList.value = itemArray.join(' ');

	document.itemFindStandard.level.value = ${level}; 
	document.itemFindStandard.myAction.value = 'getOrder'; 
	document.itemFindStandard.target = 'orderFrame';
	document.itemFindStandard.submit();
	document.getElementById('mainTab').tabber.tabShow(3);
      }

      var tabberOptions = {
      
        'onClick': function(argsObj) {
	  var t = argsObj.tabber;
          var id = t.id;
	  var i = argsObj.index;

	  if(i == 1) {
	  }
        }
      
      };

    //-->
    </script>
    <script type="text/javascript" src="${orcaUrl}js/tabber.js"></script>
  </head>
  <body>
    <form name="itemFindStandard" action="getItemsByStandard.pl" method="POST">
      <input type="hidden" name="hierarchyId" value="${hId}" />
      <input type="hidden" name="level" value="" />
      <input type="hidden" name="gleList" value="" />
      <input type="hidden" name="itemList" value="" />
      <input type="hidden" name="myAction" value="" />
      ${hiddenHtml}
      <span class="text">Get Items From Bank:</span>
      &nbsp;&nbsp;&nbsp;
      ${itemBankDisplay}
      <div class="tabber" id="mainTab">
        <div class="tabbertab" title="1) Select Strands">
          <table border="0" cellpadding="4" cellspacing="4" class="no-style">
            <tr><td><span class="text">Hierarchy:</span></td><td>${hList}</td></tr> 
            ${selectHtml}
END_HERE

    if ( $type eq $hd_pivot_type ) {
        $psgi_out .= '<tr><td>&nbsp;</td>'
          . '<td><input type="button" value="Next Step" onClick="doStrandSubmit();" /></td></tr>';
    }

    $psgi_out .= <<END_HERE;
	  </table>
        </div>
	<div class="tabbertab" title="2) View GLE Codes">
	  <table border="0" cellpadding="3" cellspacing="3" class="no-style">
	    <tr><td>
          <iframe name="gleFrame" width="550" height="350" frameborder="no" scrolling="auto">GLE Frame</iframe>	
            </td></tr>
	    <tr><td>&nbsp;</td></tr>
	    <!--
	    <tr><td style="text-align:right;">
	      <input type="button" value="Next Step" onClick="doGleSubmit();" /> 
	    </td></tr>
	    -->
          </table>
	</div>
	<!--
	<div class="tabbertab" title="3) Select Items">
	  <table border="0" cellpadding="3" cellspacing="3" class="no-style">
	    <tr><td>
              <iframe name="itemFrame" width="550" height="350" frameborder="no" scrolling="auto">Select Item Frame</iframe>	
            </td></tr>
	    <tr><td>&nbsp;</td></tr>
	    <tr><td style="text-align:right;">
	      <input type="button" value="Next Step" onClick="doItemSubmit();" /> 
	    </td></tr>
          </table>
	</div>
	<div class="tabbertab" title="4) Order Items">
	  <table border="0" cellpadding="3" cellspacing="3" class="no-style">
	    <tr><td>
              <iframe name="orderFrame" width="550" height="350" frameborder="no" scrolling="auto">Order Item Frame</iframe>	
            </td></tr>
	    <tr><td>&nbsp;</td></tr>
	    <tr><td style="text-align:right;">
	      <input type="button" value="Select Items" onClick="alert('Coming Soon!');" /> 
	    </td></tr>
          </table>
	</div>
	-->

      </div> 
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_strands {
  my $psgi_out = '';

    my $params  = shift;
    my $strands = $params->{strands};

    $psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Get Items By Standard</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <body>
      <form name="gleForm">
END_HERE

    foreach
      my $skey ( sort { $strands->{$a}->{posn} <=> $strands->{$b}->{posn} }
        keys %$strands )
    {
        my $strand = $strands->{$skey};
        $psgi_out .= '<table border="0" cellspacing="3" cellpadding="3" class="no-style">'
          . '<tr><th style="background-color:#cfcfcf; text-align:left;" colspan="3">'
          . $strand->{name}
          . '</th></tr>';

        foreach my $gkey (
            sort {
                $strand->{gles}->{$a}->{posn} <=> $strand->{gles}->{$b}->{posn}
            } keys %{ $strand->{gles} }
          )
        {
            my $gle = $strand->{gles}->{$gkey};
            my $starIndex = index( $gle->{text}, '*' );
            if ( $starIndex > 0 ) {
                my @gleDetail = split /\*/,
                  substr( $gle->{text}, $starIndex + 1 );
                $gle->{text} = substr( $gle->{text}, 0, $starIndex );
                $gle->{text} .=
                    '<ul style="margin-top:0px;"><li>'
                  . join( '</li><li>', @gleDetail )
                  . '</li></ul>';
            }
            $psgi_out .= '<tr>'
              . '<td><input type="checkbox" name="gle[]" value="'
              . $gkey
              . '" /></td>'
              . '<td><b>'
              . $gle->{name}
              . '</b>&nbsp;&nbsp;<small>('
              . $gle->{id}
              . ')</small></td>' . '<td>'
              . $gle->{text} . '</td>' . '</tr>';
        }
        $psgi_out .= '</table><br />' . "\n";
    }

    $psgi_out .= '</form></body></html>';

  return $psgi_out;
}

sub print_gles {

    my $params  = shift;
    my $strands = $params->{strands};

    $psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Get Items By Standard</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <body>
      <form name="itemForm">
END_HERE

    foreach
      my $skey ( sort { $strands->{$a}->{posn} <=> $strands->{$b}->{posn} }
        keys %$strands )
    {
        my $strand = $strands->{$skey};
        next unless keys %{ $strand->{gles} };
        $psgi_out .= '<table border="0" cellspacing="3" cellpadding="3" class="no-style">'
          . '<tr><th style="background-color:#cfcfcf; text-align:left;" colspan="3">'
          . $strand->{name}
          . '</th></tr>';

        foreach my $gkey (
            sort {
                $strand->{gles}->{$a}->{posn} <=> $strand->{gles}->{$b}->{posn}
            } keys %{ $strand->{gles} }
          )
        {
            my $gle = $strand->{gles}->{$gkey};
            next unless keys %{ $gle->{items} };
            my $starIndex = index( $gle->{text}, '*' );
            if ( $starIndex > 0 ) {
                $gle->{text} = substr( $gle->{text}, 0, $starIndex );
            }
            $psgi_out .= '<tr style="background-color:#e0e0e0;">'
              . '<td><b>'
              . $gle->{name}
              . '</b></td>'
              . '<td colspan="2"><span style="font-size:0.8em;">'
              . $gle->{text}
              . '</span></td></tr>';

            foreach my $ikey (
                sort {
                    $gle->{items}->{$a}->{posn} <=> $gle->{items}->{$b}->{posn}
                } keys %{ $gle->{items} }
              )
            {
                my $item = $gle->{items}->{$ikey};
                $psgi_out .= '<tr>'
                  . '<td><input type="checkbox" name="itemId[]"'
                  . ' value="'
                  . $ikey
                  . '" /></td>'
                  . '<td><b>'
                  . $item->{name}
                  . '</b></td>' . '<td>'
                  . $item->{text}
                  . '</td></tr>';
            }
            $psgi_out .= '<tr><td colspan="3">&nbsp;</td></tr>';
        }
        $psgi_out .= '</table><br />' . "\n";
    }

    $psgi_out .= '</form></body></html>';

  return $psgi_out;
}

sub print_items {
  my $psgi_out = '';

    my $params = shift;
    my $items  = $params->{items};

    $psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Get Items By Standard</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <style type="text/css">
      td { text-align: center; } 
      th { text-align: center; } 
      a:visited { color: #0000ff; }
      a:link { color: #0000ff; }
    </style>
    <script type="text/javascript">
    <!--
      function doRemove(num) {
	var itemList = document.orderForm.itemList.value.split(' ');
	var itemNameList = document.orderForm.itemNameList.value.split(' ');
        itemList.splice(num-1,1);  
        itemNameList.splice(num-1,1);  
	document.orderForm.itemList.value = itemList.join(' ');
	document.orderForm.itemNameList.value = itemNameList.join(' ');
        document.orderForm.submit(); 
      }

      function doMoveUp(num) {
        if(num==1) { return; }	
	var itemList = document.orderForm.itemList.value.split(' ');
	var itemNameList = document.orderForm.itemNameList.value.split(' ');
        var item1 = itemList[num-1];	
        var itemName1 = itemNameList[num-1];	
        var item2 = itemList[num-2];	
        var itemName2 = itemNameList[num-2];	
        itemList[num-1] = item2;
	itemNameList[num-1] = itemName2;
        itemList[num-2] = item1;
	itemNameList[num-2] = itemName1;
	document.orderForm.itemList.value = itemList.join(' ');
	document.orderForm.itemNameList.value = itemNameList.join(' ');
        document.orderForm.submit(); 
      }

      function doMoveDown(num) {
	var itemList = document.orderForm.itemList.value.split(' ');
	var itemNameList = document.orderForm.itemNameList.value.split(' ');
        if(num >= itemList.length) { return; } 
	var item1 = itemList[num-1];	
        var itemName1 = itemNameList[num-1];	
        var item2 = itemList[num];	
        var itemName2 = itemNameList[num];	
        itemList[num-1] = item2;
	itemNameList[num-1] = itemName2;
        itemList[num] = item1;
	itemNameList[num] = itemName1;
	document.orderForm.itemList.value = itemList.join(' ');
	document.orderForm.itemNameList.value = itemNameList.join(' ');
        document.orderForm.submit(); 
      }
    //-->
    </script>
    <body>
      <form name="orderForm" action="getItemsByStandard.pl" method="POST">
        <input type="hidden" name="myAction" value="orderItems" />
      <table border="0" cellspacing="2" cellpadding="2" class="no-style">
        <tr>
	<th width="28px;">&nbsp;</th>
	  <th style="text-align: left;" width="120px;">Item ID</th><th width="100px;">Change Order</th><th width="70px;">&nbsp;</th>
        </tr>
END_HERE
    my $itemCount    = 1;
    my @itemList     = ();
    my @itemNameList = ();
    foreach my $key ( sort { $items->{$a}->{posn} <=> $items->{$b}->{posn} }
        keys %{$items} )
    {
        $psgi_out .= '<tr>'
          . '<td style="text-align:left;">'
          . $itemCount . '</td>'
          . '<td style="text-align:left;">'
          . $items->{$key}->{name} . '</td>'
          . '<td><input type="button" value="Up" onClick="doMoveUp('
          . $itemCount
          . ');" />&nbsp;&nbsp;&nbsp;'
          . '<input type="button" value="Down" onClick="doMoveDown('
          . $itemCount
          . ');" /></td>'
          . '<td><a href="javascript://" onClick="doRemove('
          . $itemCount
          . ');" >Remove</a></td>' . '</tr>';
        push @itemList,     $key;
        push @itemNameList, $items->{$key}->{name};
        $itemCount++;
    }

    $psgi_out .= '</table>';

    $psgi_out .= '<input type="hidden" name="itemList" value="'
      . join( ' ', @itemList ) . '" />'
      . '<input type="hidden" name="itemNameList" value="'
      . join( ' ', @itemNameList ) . '" />';

    $psgi_out .= '</form></body></html>';

  return $psgi_out;
}

sub arrayContains {

    my $target      = shift;
    my $targetArray = shift;

    my $contains = 0;
    foreach (@$targetArray) {
        $contains = 1 if $_ eq $target;
    }
    return $contains;
}
1;
