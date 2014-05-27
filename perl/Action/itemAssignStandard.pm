package Action::itemAssignStandard;

use ItemConstants;
use Item;
use Data::Dumper;
use HTML::Entities;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $thisUrl = "${orcaUrl}cgi-bin/itemAssignStandard.pl";
  
  our $sth;
  
  $in{myAction} = '' unless defined $in{myAction};
  
  if ( $in{myAction} eq 'assign' ) {
  
      unless ( defined $in{hierarchyId} ) {
          my $sql = "SELECT * FROM standard_hierarchy";
          $sth = $dbh->prepare($sql);
          $sth->execute()
            || print( STDERR "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
          $in{model} = {};
          while ( my $row = $sth->fetchrow_hashref ) {
              $in{model}->{ $row->{sh_id} }   = $row->{sh_name};
              $in{idArray}->{ $row->{sh_id} } = $row->{hd_id};
          }
 
          return [ $q->psgi_header('text/html'), [ &print_select_hierarchy(\%in) ]];
      }
  
      if ( defined( $in{assignId} ) && $in{assignId} ne "" ) {
  
          my $item = new Item( $dbh, $in{itemId} );
  
          my $nextStandardIndex = 0;
  
          #my $contentStandard =
          #  &getContentStandard( $dbh, $in{assignId}, $item->{$OC_CONTENT_AREA} );
  
          foreach ( @{ $item->{standards} } ) {
              $nextStandardIndex++ if $_->{gle};
          }
  
          $item->updateChar( $itemStandardChar{$nextStandardIndex}{gle},
              $in{assignId} );
          #$item->updateChar( $itemStandardChar{$nextStandardIndex}{standard},
          #    $contentStandard );
  
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
  
      $in{text} = {};    #Holds the text descriptions
      for ( my $i = 0 ; $i <= $in{level} ; $i++ ) {
  
          # Build one drop-down list ( 1 step of the hierarchy )
          my $iplus = $i + 1;
          my $sql   = "SELECT * FROM hierarchy_definition WHERE hd_parent_id="
            	    . $in{"hdId${i}"} . ' ORDER BY hd_posn_in_parent';
          $sth = $dbh->prepare($sql);
          $sth->execute()
            || print( STDERR "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
          $in{"model${iplus}"} = {};    # hd_id to hd_value map
          $in{"pos${iplus}"}   = {};    # hd_id to hd_posn_in_parent map
          while ( my $row = $sth->fetchrow_hashref ) {
              $in{"model${iplus}"}->{ $row->{hd_id} } = $row->{hd_value};
              $in{"pos${iplus}"}->{ $row->{hd_id} }   = $row->{hd_posn_in_parent};
              $in{"type${iplus}"}                     = $row->{hd_type};
  
              $in{text}->{ $row->{hd_id} } = $row->{hd_std_desc};
              $in{lastType} = $row->{hd_type};
          }
  	unless( $sth->rows ) {
  	    $in{dont}++; 
  	    $in{"last_level$i"}++; 
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
  
      $in{level} = $in{level} + 1 unless $in{dont};
 
      return [ $q->psgi_header('text/html'), [ &print_select_gle(\%in) ]];
  }
 
  return [ $q->psgi_header('text/html'), [ &print_display_standard() ]];
}
### ALL DONE! ###

sub print_display_standard {
  my $psgi_out = '';

    my $item = new Item( $dbh, $in{itemId} );

    if ( defined $in{remove} ) {
        $item->deleteChar( $itemStandardChar{ $in{remove} }{gle} );
        #$item->deleteChar( $itemStandardChar{ $in{remove} }{standard} );
        $item->deleteChar( $itemStandardChar{ $in{remove} }{benchmark} );
        $item->deleteChar( $itemStandardChar{ $in{remove} }{category} );

        $item = new Item( $dbh, $in{itemId} );
    }

    if ( defined( $in{saveId} ) && $in{saveId} ne '' ) {

        my $benchmark = 0;
        if ( $in{"benchmark_$in{saveId}"} =~ /(\d+)/ ) {
            $benchmark = $1;
        }

        my $category = 0;
        if ( $in{"category_$in{saveId}"} =~ /(\d+)/ ) {
            $category = $1;
        }

        #$item->updateChar(
        #    $itemStandardChar{ $in{saveId} }{standard},
        #    $in{"contentStandard_$in{saveId}"}
        #);
        $item->updateChar( $itemStandardChar{ $in{saveId} }{benchmark},
            $benchmark );
        $item->updateChar( $itemStandardChar{ $in{saveId} }{category},
            $category );

        $item = new Item( $dbh, $in{itemId} );
    }

    if ( defined $in{makePrimary} ) {
        my $i       = $in{makePrimary};
        my $primary = $item->{standards}[0];

        $item->updateChar( $itemStandardChar{'0'}{gle},
            $item->{standards}[$i]{gle} );
        #$item->updateChar(
        #    $itemStandardChar{'0'}{standard},
        #    $item->{standards}[$i]{contentStandard}
        #);
        $item->updateChar(
            $itemStandardChar{'0'}{benchmark},
            $item->{standards}[$i]{benchmark}
        );
        $item->updateChar(
            $itemStandardChar{'0'}{category},
            $item->{standards}[$i]{category}
        );
        $item->updateChar( $itemStandardChar{$i}{gle}, $primary->{gle} );
        #$item->updateChar( $itemStandardChar{$i}{standard},
        #    $primary->{contentStandard} );
        $item->updateChar( $itemStandardChar{$i}{benchmark},
            $primary->{benchmark} );
        $item->updateChar( $itemStandardChar{$i}{category},
            $primary->{category} );

        $item = new Item( $dbh, $in{itemId} );
    }

    my $m  = {};
    my $sh = {};

    foreach my $standard ( grep { $_->{gle} } @{ $item->{standards} } ) {
        my $id        = $standard->{gle};
        my $currentId = $id;
        my $parentId  = $id;
        $m->{$id} = &getStandard( $dbh, $currentId );

        # $currentId should be the hd_id in standard_hierarchy
        my $sql = "SELECT * FROM standard_hierarchy WHERE hd_id="
          . $m->{$id}{$HD_ROOT}{id};
        my $sth = $dbh->prepare($sql);
        $sth->execute()
          || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );

        $sh->{$id} = {};
        if ( my $row = $sth->fetchrow_hashref ) {
            $sh->{$id}->{id}   = $row->{sh_id};
            $sh->{$id}->{name} = $row->{sh_name};
        }

        # Get the qualifier_labels once we've found the 'sh_id'
        $sql = "SELECT * FROM qualifier_label WHERE sh_id=" . $sh->{$id}->{id};
        $sth = $dbh->prepare($sql);
        $sth->execute()
          || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
        $sh->{$id}->{labels} = {};
        while ( my $row = $sth->fetchrow_hashref ) {
            $sh->{$id}->{labels}->{ $row->{ql_type} } = $row->{ql_label};
        }
        $sth->finish;
    }

    my @headers =
      ( 'Primary Standard', 'Secondary Standard', 'Tertiary Standard' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
	  <title>Assign Standard</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      function doSave(id)
      {
        document.itemStandard.saveId.value = id;
        document.itemStandard.submit();
	      return true;
      }
    //-->
    </script>
  </head>
	<body>
    <form name="itemStandard" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemId" value="$in{itemId}" />
      <input type="hidden" name="saveId" value="" />
END_HERE

    my @standardList = grep { $_->{gle} } @{ $item->{standards} };
    if( scalar @standardList == 0 ) {
	$psgi_out .= qq|<script>window.location="${thisUrl}?itemId=$in{itemId}&myAction=assign";</script>\n|;
    }

    unless ( $item->{readOnly} || scalar(@standardList) >= 3 ) {
        $psgi_out .= <<END_HERE;
	  <a href="${thisUrl}?itemId=$in{itemId}&myAction=assign">Assign New Standard</a><br /><br />
END_HERE
    }

    my $i = 0;
    foreach my $standard (@standardList) {

        my $id = $standard->{gle};

        $psgi_out .= '<div style="font-size:14pt;margin-bottom:2px;">'
          . $headers[$i]
          . '</div>';
        $psgi_out .= '<table border="1" cellpadding="2" cellspacing="2" class="no-style">';

#. '<tr><td><span class="text">Hierarchy</span></td><td>' . $sh->{$id}->{name} . '</td></tr>';

        foreach my $key ( sort { $m->{$id}{$b}{pos} <=> $m->{$id}{$a}{pos} }
            keys %{ $m->{$id} } )
        {
            my $level = $m->{$id}->{$key};
            $psgi_out .= '<tr><td><span class="text">'
              . $sh->{$id}->{labels}->{$key}
              . '</span></td><td>'
              . $level->{value}
              . '</td></tr>';

            if ( $key == $HD_LEAF ) {
                my $contentStandardHtml = '';
		#&hashToSelect(
                #    "contentStandard_${i}",
                #    $contentStandards{ $m->{$id}{$HD_ROOT}{id} }
                #      { $item->{$OC_CONTENT_AREA} },
                #    $standard->{contentStandard}
                #);

		$level->{text} = decode_entities($level->{text});
                $psgi_out .= <<END_HERE;
				<tr><td><span class="text">Description</span></td><td><textarea rows="5" cols="40">$level->{text}</textarea></td></tr>
				<!--
		    <tr><td><span class="text">Content Standard</span></td><td>${contentStandardHtml}</td></tr>
		    -->
				<tr><td><span class="text">Category</span></td>
				    <td><input type="text" size="3" name="category_${i}" value="$standard->{category}" /></td></tr>
				<tr><td><span class="text">Benchmark</span></td>
				    <td><input type="text" size="3" name="benchmark_${i}" value="$standard->{benchmark}" /></td></tr>
END_HERE

                unless ( $item->{readOnly} ) {

                    $psgi_out .= <<END_HERE;
  	      <tr><td><span class="text">Action</span></td>
				    <td><input type="button" value="Save" onClick="doSave('${i}'); return true;" />
END_HERE

                    if ($i) {

                        $psgi_out .= <<END_HERE;
						&nbsp;&nbsp;&nbsp;&nbsp;
  	        <input type="button" value="Make Primary" onClick="document.location='${thisUrl}?itemId=$in{itemId}&makePrimary=${i}'; return true;" />
END_HERE
                    }

                    if ( $i == scalar(@standardList) - 1 ) {

                        $psgi_out .= <<END_HERE;
						&nbsp;&nbsp;&nbsp;&nbsp;
  	        <input type="button" value="Remove" onClick="document.location='${thisUrl}?itemId=$in{itemId}&remove=${i}'; return true;" />
END_HERE
                    }

                    $psgi_out .= '</td></tr>';
                }
            }

        }
        $psgi_out .= '</table><br />';
        $i++;
    }

    $psgi_out .= '</form></body></html>';

  return $psgi_out;
}

sub print_select_hierarchy {

    my $params = shift;

    my $model  = $params->{model};
    my $itemId = $params->{itemId};
    my $hd_ids = $params->{idArray};

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
<!DOCTYPE html>    
<html>
  <head>
    <title>Item Standards</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
     ${jsArray} 
      
      function mySubmit(strvalue,strtext)
      {
        document.itemStandard.hdId0.value = idArray[strvalue];
	document.itemStandard.label0.value = strtext;
	document.itemStandard.submit();
        return true; 
      }

    //-->
    </script>
  </head>
  <body>
    <div class="title">Assign Standard</div>
    <form name="itemStandard" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemId" value="${itemId}" />
      <input type="hidden" name="hdId0" value="" />
      <input type="hidden" name="label0" value="" />
      <input type="hidden" name="level" value="0" />
			<input type="hidden" name="myAction" value="assign" />
    <table border="0" cellpadding="4" cellspacing="4" class="no-style">
      <tr><td><span class="text">Hierarchy:</span></td><td>${dispList}</td></tr> 
    </table>
    </form>
  </body>
</html>
END_HERE
}

sub print_select_gle {
  my $psgi_out = '';

    my $params = shift;

    my $itemId   = $params->{itemId};
    my $hId      = $params->{hierarchyId};
    my $hdIdRoot = $params->{hdId0};
    my $hLabel   = $params->{label0};

    my $selectHtml = "";

    for ( my $i = 1 ; $i <= $params->{level} ; $i++ ) {
        $selectHtml .=
            '<tr><td><span class="text">'
          . $params->{ 'label' . $params->{"type${i}"} }
          . ':</span></td>'
          . '<td><select name="hdId'
          . $i . '"';

        #if ( defined( $in{lastType} )
            #&& $in{lastType} eq $params->{"type${i}"} )
        if ( $in{"last_level$i"} )
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
              . decode_entities($key) . '"'
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

    if ( $in{lastType} == $HD_LEAF ) {
        my $textz = $params->{text};

        foreach my $key ( keys %$textz ) {
            $textz->{$key} =~ s/"/\\"/g;
            $textz->{$key} =~ s/\r/\\r/g;
            $textz->{$key} =~ s/\n/\\n/g;
            $jsArray .=
              'textArray["' . $key . '"] = "' . decode_entities($textz->{$key}) . "\";\n";
        }
    }

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Standards</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      ${jsArray}

      function mySubmit(level)
      {
        document.itemStandard.level.value = level;	
	document.itemStandard.submit();
        return true; 
      }

      function displayText(id)
      {
        document.itemStandard.description.value = textArray[id];
        return true; 
      }

      function doAssign(id)
      {
        document.itemStandard.assignId.value = id;
        document.itemStandard.submit();
	return true;
      }
    //-->
    </script>
  </head>
  <body>
    <div class="title">Assign Standard</div>
    <form name="itemStandard" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemId" value="${itemId}" />
      <input type="hidden" name="hierarchyId" value="${hId}" />
      <input type="hidden" name="hdId0" value="${hdIdRoot}" />
      <input type="hidden" name="assignId" value="" />
      <input type="hidden" name="level" value="$in{level}" />
			<input type="hidden" name="myAction" value="assign" />
      ${hiddenHtml}
    <table border="0" cellpadding="4" cellspacing="4" class="no-style">
      <tr><td><span class="text">Hierarchy:</span></td><td>${hLabel}</td></tr> 
      ${selectHtml}
    </table>
END_HERE

    if($in{lastType} == $HD_LEAF) {

     $psgi_out .= <<END_HERE;
    <table border="0" cellpadding="4" cellspacing="4" class="no-style">
    <tr><td>
    <span class="text">Description</span><br />
    <textarea name="description" rows="9" cols="50"></textarea>
    </td></tr>
    <tr><td><input type="button" onClick="doAssign(document.itemStandard.hdId$in{level}.options[document.itemStandard.hdId$in{level}.selectedIndex].value);" value="Assign" />
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
