package Action::interactionCreate;

use CGI::Cookie;
use URI;
use File::Copy;
use ItemConstants;
use Item;
use Session;
use Data::Dumper;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => join (' ', $q->param($_) ) } $q->param;

  our $debug = 0;

  our $thisUrl    = "${orcaUrl}cgi-bin/interactionCreate.pl";

  our %cookies = CGI::Cookie->fetch;
  our $allowCompare =
  ( exists( $cookies{comparisonModeStatus} )
      && $cookies{comparisonModeStatus}->value eq 'disable' ) ? 0 : 1;

  our $doCompare = ( exists( $in{doCompare} ) && $allowCompare ) ? 1 : 0;
  our $compareState = exists( $in{doCompareState} ) ? $in{doCompareState} : 0;
  our $canCompare = 1;
  
  our $sth;
  our $sql;
  
  # Authorize user (must be user type UT_ITEM_EDITOR)
  our $user = Session::getUser($q->env, $dbh);
  unless ( int( $user->{type} ) == $UT_ITEM_EDITOR )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ];  
  }
  
  $in{interactionId} = 0 unless $in{interactionId};
  $in{myAction} = '' unless $in{myAction};
  
  our $item = new Item($dbh, $in{itemId});
  our $ii = { 
             type => $in{interactionType} || 1,
  	   name => $in{interactionName} || 'RESPONSE',
  	   max_score => $in{maxScore} || 1.0,
  	   attributes => '',
  	   correct => '',
  	   correctMap => '',
  	   content => {}
  	 };
  
  # if no action selected, check for number of interactions this item has
  # if only 1, then put them right in edit mode
  if($in{myAction} eq '' && $in{interactionId} == 0 && scalar keys %{$item->{interactions}} == 1) {
    $in{interactionId} = (keys %{$item->{interactions}})[0];
    $in{myAction} = 'edit';
  }
  
  $ii->{score_type} = ($ii->{type} == $IT_EXTENDED_TEXT) ? $ST_RUBRIC : $ST_MATCH_RESPONSE;
  
  $ii = $item->{interactions}{$in{interactionId}} if $in{interactionId};
  our $ii_atts = &attributeStringToHash($ii->{attributes});
  
  $in{interactionType} = $ii ? $ii->{type} : 1;
  
  if ( $in{myAction} eq '' || $in{myAction} eq 'main') {
    return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
  }
  elsif ( $in{myAction} eq 'edit' ) {
    # nothing to do, just let it fall to print_edit() function
  }
  elsif( $in{myAction} eq 'choice_swap') {
  
    my $a = $in{choiceA};
    my $b = $in{choiceB};
  
    # swap the indices of choices in position $a and $b 
    my $ch_tmp = $ii->{content}{choices}[$a];
    $ii->{content}{choices}[$a] = $ii->{content}{choices}[$b];
    $ii->{content}{choices}[$b] = $ch_tmp;
  
    # also swap the distractor rationale
    my $dr_tmp = $ii->{content}{distractorRationale}[$a];
    $ii->{content}{distractorRationale}[$a] = $ii->{content}{distractorRationale}[$b];
    $ii->{content}{distractorRationale}[$b] = $dr_tmp;
  
    # update their names based on @choice_chars if they are named that way
    my %choice_chars_map = map { $_ => 1 } @choice_chars;
    if( exists $choice_chars_map{$ii->{content}{choices}[$a]{name}} ) {
  
      $ii->{content}{choices}[$a]{name} = $choice_chars[$a];
      $ii->{content}{choices}[$b]{name} = $choice_chars[$b];
      $ii->{content}{distractorRationale}[$a]{name} = $choice_chars[$a];
      $ii->{content}{distractorRationale}[$b]{name} = $choice_chars[$b];
  
      # update the correct answer as well, since we renamed 
      # don't like this logic, but couldn't think of a better way
      my %correct_map = map { $_ => 1 } split(/ /, $ii->{correct});
      if(exists $correct_map{$choice_chars[$a]} && not exists $correct_map{$choice_chars[$b]}) {
        delete $correct_map{$choice_chars[$a]};
        $correct_map{$choice_chars[$b]} = 1;
      } 
      elsif(exists $correct_map{$choice_chars[$b]} && not exists $correct_map{$choice_chars[$a]}) {
        delete $correct_map{$choice_chars[$b]};
        $correct_map{$choice_chars[$a]} = 1;
      } 
      $ii->{correct} = join (' ', keys %correct_map);
    }
  
    $item->save();
  
    $in{message} = 'Swapped choices "' . $choice_chars[$a] . '" and "' . $choice_chars[$b] . '".';
  
  }
  elsif( $in{myAction} eq 'inline_choice_swap') {
  
    my $a = $in{choiceA};
    my $b = $in{choiceB};
  
    # swap the indices of choices in position $a and $b 
    my $ch_tmp = $ii->{content}{choices}[$a];
    $ii->{content}{choices}[$a] = $ii->{content}{choices}[$b];
    $ii->{content}{choices}[$b] = $ch_tmp;
  
    # update their names based on @choice_chars if they are named that way
    my %choice_chars_map = map { $_ => 1 } @choice_chars;
    if( exists $choice_chars_map{$ii->{content}{choices}[$a]{name}} ) {
  
      $ii->{content}{choices}[$a]{name} = $choice_chars[$a];
      $ii->{content}{choices}[$b]{name} = $choice_chars[$b];
    }

    # update the correct answer
    if($ii->{correct} eq $ii->{content}{choices}[$a]{name}) {
      $ii->{correct} = $ii->{content}{choices}[$b]{name};
    }
    elsif($ii->{correct} eq $ii->{content}{choices}[$b]{name}) {
      $ii->{correct} = $ii->{content}{choices}[$a]{name};
    }
  
    $item->save();
  
    $in{message} = 'Swapped choices "' . $ii->{content}{choices}[$a]{text} 
                 . '" and "' . $ii->{content}{choices}[$b]{text} . '".';
  
  }
  elsif( $in{myAction} eq 'set_choice_swap') {
 
    my $set_seq = $in{setSequence};
    my $a = $in{choiceA};
    my $b = $in{choiceB};
    my $seq_id = $set_seq ? 'T' : 'S';
  
    # swap the indices of choices in position $a and $b 
    my $ch_tmp = $ii->{content}{setChoices}[$set_seq][$a];
    $ii->{content}{setChoices}[$set_seq][$a] = $ii->{content}{setChoices}[$set_seq][$b];
    $ii->{content}{setChoices}[$set_seq][$b] = $ch_tmp;
  
    # update their names based on @choice_chars if they are named that way
    my %choice_chars_map = map { $_ => 1 } map { $seq_id . $_ }  @choice_chars;
    if( exists $choice_chars_map{$ii->{content}{setChoices}[$set_seq][$a]{name}} ) {
  
      $ii->{content}{setChoices}[$set_seq][$a]{name} = $seq_id . $choice_chars[$a];
      $ii->{content}{setChoices}[$set_seq][$b]{name} = $seq_id . $choice_chars[$b];
    }

    # update the correct answer using a swap table (i.e. perl magic)
    my $a_str = $ii->{content}{setChoices}[$set_seq][$a]{name};
    my $b_str = $ii->{content}{setChoices}[$set_seq][$b]{name};
    my %table = ( $a_str => $b_str, $b_str => $a_str );
    my $table_re = join '|', keys %table;

    if($set_seq) {
      $ii->{correct} =~ s/:($table_re)/:$table{$1}/g;
    } else {
      $ii->{correct} =~ s/($table_re):/$table{$1}:/g;
    }
  
    $item->save();
  
    $in{message} = 'Swapped ' . $in{setName} . ' choices "' . $ii->{content}{setChoices}[$set_seq][$a]{text} 
                 . '" and "' . $ii->{content}{setChoices}[$set_seq][$b]{text} . '".';
  
  }
  elsif ( $in{myAction} eq 'choice_delete' ) {
  
    my $a = $in{choiceA};
  
    # use pop for now, since we currently limit to deleting the last choice
    my $choice = pop @{$ii->{content}{choices}};
    my $dr = pop @{$ii->{content}{distractorRationale}};
  
    # remove choice and distractor rationale from the database
    $sql = 'DELETE FROM item_fragment WHERE ii_id=' . $in{interactionId} . ' AND if_id=' . $choice->{id}; 
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    $sql = 'DELETE FROM item_fragment WHERE ii_id=' . $in{interactionId} . ' AND if_id=' . $dr->{id}; 
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    # remove the choice as a correct answer
    my %correct_map = map { $_ => 1 } split (/ /, $ii->{correct});
    delete $correct_map{$choice->{name}}
      if exists $correct_map{$choice->{name}};
    $ii->{correct} = join (' ', keys %correct_map);
  
    $item->save();
  
    $in{message} = 'Deleted choice "' . $choice_chars[$a] . '".';
      
  }
  elsif ( $in{myAction} eq 'inline_choice_delete' ) {
  
    my $a = $in{choiceA};
  
    # use pop for now, since we currently limit to deleting the last choice
    my $choice = pop @{$ii->{content}{choices}};
  
    # remove choice from the database
    $sql = 'DELETE FROM item_fragment WHERE ii_id=' . $in{interactionId} . ' AND if_id=' . $choice->{id}; 
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    # remove the choice as the correct answer
    $ii->{correct} = '' if $ii->{correct} eq $choice->{name};
  
    $item->save();
  
    $in{message} = 'Deleted choice "' . $choice->{text} . '".';
      
  }
  elsif ( $in{myAction} eq 'set_choice_delete' ) {
  
    my $set_seq = $in{setSequence};
    my $a = $in{choiceA};
  
    # use pop for now, since we currently limit to deleting the last choice
    my $choice = pop @{$ii->{content}{setChoices}[$set_seq]};
  
    # remove choice from the database
    $sql = 'DELETE FROM item_fragment WHERE ii_id=' . $in{interactionId} . ' AND if_id=' . $choice->{id}; 
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    # remove the choice as the correct answer
    my $a_str = $choice->{name};

    my @correctArray = $set_seq ? grep { my @tmp = split /:/, $_; $tmp[1] ne $a_str;} split(/ /, $ii->{correct})
                                : grep { my @tmp = split /:/, $_; $tmp[0] ne $a_str;} split(/ /, $ii->{correct});
    $ii->{correct} = join (' ', @correctArray);
  
    $item->save();
  
    $in{message} = 'Deleted ' . $in{setName} . ' choice "' . $choice->{text} . '".';
      
  }
  elsif ( $in{myAction} eq 'choice_add' ) {
  
    # use current size as next index
    my $a = scalar @{$ii->{content}{choices}};
  
    my $choice = {};
    $choice->{id} = 0;
    $choice->{name} = $choice_chars[$a];
    $choice->{text} = '';
    push @{$ii->{content}{choices}}, $choice;
  
    my $distractor = {};
    $distractor->{id} = 0;
    $distractor->{name} = $choice_chars[$a];
    $distractor->{text} = '';
    push @{$ii->{content}{distractorRationale}}, $distractor;
  
    $item->save();
  
    $in{message} = 'Added Choice "' . $choice_chars[$a] . '".';
    
  }
  elsif ( $in{myAction} eq 'inline_choice_add' ) {

    # use current size as next index
    my $a = scalar @{$ii->{content}{choices}};
  
    my $choice = {};
    $choice->{id} = 0;
    $choice->{name} = $choice_chars[$a];
    $choice->{text} = $in{newInlineChoiceName};
    push @{$ii->{content}{choices}}, $choice;

    $item->save();
  
    $in{message} = 'Added Choice "' . $in{newInlineChoiceName} . '".';
  }
  elsif ( $in{myAction} eq 'set_choice_add' ) {

    my $set_seq = $in{setSequence};

    # use current size as next index
    my $a = scalar @{$ii->{content}{setChoices}[$set_seq]};
  
    my $choice = {};
    $choice->{id} = 0;
    $choice->{name} = ($set_seq ? 'T' : 'S') . $choice_chars[$a];
    $choice->{text} = $in{newSetChoiceName};
    push @{$ii->{content}{setChoices}[$set_seq]}, $choice;

    $item->save();
  
    $in{message} = 'Added Choice "' . $in{newSetChoiceName} . '" to Set "' . $in{setName} . '".';
  }
  elsif ( $in{myAction} eq 'create' ) {
                            
    # ensure this interaction name follows QTI identifier rules
    unless($in{interactionName} =~ /^[A-Za-z0-9\-\_\.]+$/) {
      $in{message} = "Interaction name must have only alphanumeric or hyphen, underscore, or period characters.";
      return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
    }

    my %atts = ( 'responseIdentifier' => $in{interactionName} );
    my $name_quote = $dbh->quote($in{interactionName});
  
    # ensure this item does not already have an interaction with this name
    $sql = <<SQL;
    SELECT ii_id FROM item_interaction WHERE i_id=$item->{id} AND ii_name=$name_quote
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    if($sth->fetchrow_hashref) {
      $in{message} = "This item already has an interaction $name_quote. Please type a new name.";
      return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
    } 
  
    my $i_obj = { name => $in{interactionName},
                  type => $in{interactionType},
  		score_type => ($in{interactionType} == $IT_EXTENDED_TEXT) ?  $ST_RUBRIC : $ST_MATCH_RESPONSE,
  		max_score => 1.0,
  		correct => '',
  		attributes => &hashToAttributeString(\%atts),
  		content => {}
                };
  
    $in{interactionId} = $item->createInteraction($i_obj);
  
    $ii = $i_obj;
  
    # add extra data per type 
  
    if(  $ii->{type} == $IT_CHOICE 
      || $ii->{type} == $IT_EXTENDED_TEXT
      || $ii->{type} == $IT_MATCH) {
      $ii->{content}{prompt}{id} = 0;
      $ii->{content}{prompt}{name} = 'prompt';
      $ii->{content}{prompt}{text} = '';
    }
  
    if($ii->{type} == $IT_CHOICE) {
  
      $ii->{content}{choices} = [];
      $ii->{content}{distractorRationale} = [];
  
      foreach(0,1,2,3) {
  
        my $choice = {};
        $choice->{id} = 0;
        $choice->{name} = $choice_chars[$_];
        $choice->{text} = '';
        push @{$ii->{content}{choices}}, $choice;
  
        my $distractor = {};
        $distractor->{id} = 0;
        $distractor->{name} = $choice_chars[$_];
        $distractor->{text} = '';
        push @{$ii->{content}{distractorRationale}}, $distractor;
      }
    }

    if($ii->{type} == $IT_MATCH) {
      $ii->{content}{setChoices}[0] = {};
      $ii->{content}{setChoices}[1] = {};
    }

    $item->{interactions}{$in{interactionId}} = $ii;
  
    $item->save();
  
  } elsif ( $in{myAction} eq 'save' ) {
  
    if(  $ii->{type} == $IT_CHOICE 
      || $ii->{type} == $IT_EXTENDED_TEXT
      || $ii->{type} == $IT_MATCH ) {
      $ii->{content}{prompt}{text} = $in{fragmentPrompt};
    }
  
    if($ii->{type} == $IT_TEXT_ENTRY || $ii->{type} == $IT_INLINE_CHOICE) {
      $ii->{correct} = $in{correctAnswer};
    }
  
    if($ii->{type} == $IT_CHOICE || $ii->{type} == $IT_MATCH) {
      $ii->{correct} = $in{'correct[]'};
    }
  
    if($ii->{type} == $IT_CHOICE) {
  
      $ii->{content}{choices} = [] unless exists $ii->{content}{choices};
      $ii->{content}{distractorRationale} = [] unless exists $ii->{content}{distractorRationale};
     
      for(my $i=0; $i < 10; $i++) {
      
        if(exists $in{"fragmentChoice${i}"}) { 
  
          unless (exists $ii->{content}{choices}[$i]) {
            $ii->{content}{choices}[$i] = {}; 
  	  $ii->{content}{choices}[$i]{id} = 0;
  	  $ii->{content}{choices}[$i]{name} = $choice_chars[$i];
          }
  
          $ii->{content}{choices}[$i]{text} = $in{"fragmentChoice${i}"};
        } 
  
        if(exists $in{"distractor${i}"}) { 
  
          unless (exists $ii->{content}{distractorRationale}[$i]) {
            $ii->{content}{distractorRationale}[$i] = {}; 
  	  $ii->{content}{distractorRationale}[$i]->{id} = 0;
  	  $ii->{content}{distractorRationale}[$i]->{name} = $choice_chars[$i];
          }
  
          $ii->{content}{distractorRationale}[$i]{text} = $in{"distractor${i}"};
          $ii->{content}{distractorRationale}[$i]{name} = $ii->{content}{choices}[$i]{name}; 
        } 
      } 
    }

    $ii->{max_score} = $in{maxScore} || 1.0;
  
    # update interaction attributes
    $ii_atts = &attributeStringToHash($ii->{attributes});
    foreach (qw/maxChoices matchMaxSource matchMaxTarget shuffle 
                expectedLength expectedLines/) {
      $ii_atts->{$_} = $in{$_} if exists $in{$_};
    }

    $ii->{attributes} = &hashToAttributeString($ii_atts);
  
    $item->{interactions}{$in{interactionId}} = $ii;
    $item->save();
    $in{message} = 'Saved Interaction.';
  
  } elsif ( $in{myAction} eq 'delete' ) {
  }

  return [ $q->psgi_header('text/html'), [ &print_edit() ] ];
}

### ALL DONE! ###

sub print_welcome {

  my %interaction_list = map { $_ => $item->{interactions}{$_}{name} . ' (' . $item_interactions{$item->{interactions}{$_}{type}} . ')' } 
                         keys %{$item->{interactions}};

  my $typeDisplay = &hashToSelect( 'interactionType', \%item_interactions, $ii->{type} );
  my $selectDisplay = &hashToSelect( 'interactionId', \%interaction_list, $in{interactionId} );

  $in{message} = '' unless defined $in{message};
  my $msgColor = ($in{message} =~ /^Error/) ? 'red' : 'blue';

  my $msg = ($in{message} ne '')
        ? '<div style="color:' . $msgColor . ';font-weight:bold;font-family: arial;font-size:12pt;">'
          . $in{message}
          . "</div><br />"
        : "";

  return <<HTML;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Interaction Editor</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <script language="JavaScript">
      function doEditSubmit() {
        document.interactionCreate.myAction.value='edit';
	document.interactionCreate.submit();
      }

      function doCreateSubmit() {
        document.interactionCreate.myAction.value = 'create';
        document.interactionCreate.interactionId.value = 0;
	document.interactionCreate.submit();
      }
    </script>
  </head>
  <body>
    <form name="interactionCreate" action="${thisUrl}" method="POST">
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="itemId" value="$item->{id}" />
    <div class="title">Create/Edit Interaction</div>
    $msg
    <table class="no-style" border="0" cellpadding="2" cellspacing="2">
      <tr>
        <td colspan="3">Edit Interaction</td>
      </tr>
      <tr>
        <td>Select:</td>
	<td>$selectDisplay</td>
	<td><input type="button" value="Edit" onClick="doEditSubmit();" /></td>
      </tr>
      <tr><td colspan="3">&#160;</td></tr>
      <tr>
        <td colspan="3">Create Interaction</td>
      </tr>
      <tr>
        <td>Type:</td>
	<td>$typeDisplay</td>
	<td>&#160;</td>
      </tr>
      <tr>
        <td>Name:</td>
	<td><input type="text" size="15" name="interactionName" value="" /></td>
	<td><input type="button" value="Create" onClick="doCreateSubmit();" /></td>
      </tr>
    </table>
    </form>
  </body>
</html>
HTML
}

sub print_edit {
  my $psgi_out = '';

  my $hiddenFields = '';
  my $onLoadFunction = '';

  my $comp = $item->getCompareContent($compareState);
  $canCompare = 0 unless scalar ( keys %{$comp} );
  $doCompare  = 0 unless $doCompare && scalar ( keys %{$comp} ); 

  $in{message} = '' unless defined $in{message};
  my $msgColor = ($in{message} =~ /^Error/) ? 'red' : 'blue';

  my $msg = ($in{message} ne '')
        ? '<div style="color:' . $msgColor . ';font-weight:bold;font-family: arial;font-size:12pt;">'
          . $in{message}
          . "</div><br />"
        : "";

  my $readOnlyWarn =
      $in{readOnly}
      ? "&#160;&#160;&#160;<span style='color:#ff0000'>Read Only: Some functions disabled</span>"
      : '';

  my $mediaAssets = &getMediaAssetAttributes($dbh, $item->{id}, $in{interactionId});
  my $typeDisplay = $item_interactions{$ii->{type}};
  my $locale_code = $item->{lang} == 2 ? 'es-ES' : 'en-US';

  my $matchSourceSize = ($ii->{type} == $IT_MATCH) ? (scalar(@{$ii->{content}{setChoices}[0]}) || 0) : 0;
  my $matchTargetSize = ($ii->{type} == $IT_MATCH) ? (scalar(@{$ii->{content}{setChoices}[1]}) || 0) : 0;

  # Print Main document
  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>SBAC IAIP Interaction Editor</title>
    <link rel="stylesheet" href="${orcaUrl}style/text.css" type="text/css" />
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    <script language="JavaScript" src="${commonUrl}eong3/lib/js/jquery/jquery.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="JavaScript" src="${commonUrl}eong3/lib/js/edit-on-ng.js"></script>
    <link rel="stylesheet" type="text/css" media="screen" href="${commonUrl}eong3/lib/css/edit-on-ng.css" />
    <script language="JavaScript">
    <!--
      \$(document).ready(function() {
         jQuery("#mediaAssetTable").tablesorter({headers:{4:{sorter:false}}});
      });

      var tmpEditorObj;
      var cssStylesheet = '$item->{stylesheet}';
      var defaultEditorHeight = 300;
      var defaultEditorWidth = 530;
      var largeEditorHeight = 500;
      var matchSourceArray = new Array();
      var matchTargetArray = new Array();

      var compareHeader = "<html><head><title>title</title></head><body>";
      var compareFooter = "</body></html>";

      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
    return true; 
      }

      function openGraphicWindow(editorObj) {
        tmpEditorObj = editorObj;   
        myOpen('insertGraphicWin','${orcaUrl}cgi-bin/assetInsert.pl?itemBankId=$item->{bankId}&itemId=$item->{id}&itemExternalId=$item->{name}&version=$item->{version}',400,500);
      } 

      function doChoiceSwap(a,b) {

        /* these need to be sequential, for now */
        document.interactionCreate.myAction.value='choice_swap';
	document.interactionCreate.choiceA.value=a;
	document.interactionCreate.choiceB.value=b;
	document.interactionCreate.submit();
      }

      function doInlineChoiceSwap(a,b) {

        /* these need to be sequential, for now */
        document.interactionCreate.myAction.value='inline_choice_swap';
	document.interactionCreate.choiceA.value=a;
	document.interactionCreate.choiceB.value=b;
	document.interactionCreate.submit();
      }

      function doSetChoiceSwap(set_seq,a,b) {

        /* a and b be sequential, for now */
        document.interactionCreate.myAction.value='set_choice_swap';
	document.interactionCreate.setSequence.value= set_seq;
	document.interactionCreate.setName.value = ( set_seq ? "Target" : "Source" );
	document.interactionCreate.choiceA.value=a;
	document.interactionCreate.choiceB.value=b;
	document.interactionCreate.submit();
      }

      function doChoiceDelete(a) {
        document.interactionCreate.myAction.value='choice_delete';
	document.interactionCreate.choiceA.value=a;
	document.interactionCreate.submit();
      }

      function doInlineChoiceDelete(a) {
        document.interactionCreate.myAction.value='inline_choice_delete';
	document.interactionCreate.choiceA.value=a;
	document.interactionCreate.submit();
      }

      function doSetChoiceDelete(set_seq,a) {
        document.interactionCreate.myAction.value='set_choice_delete';
	document.interactionCreate.setSequence.value= set_seq;
	document.interactionCreate.setName.value = ( set_seq ? "Target" : "Source" );
	document.interactionCreate.choiceA.value=a;
	document.interactionCreate.submit();
      }

      function doChoiceAdd() {
        document.interactionCreate.myAction.value='choice_add';
	document.interactionCreate.submit();
      }

      function doInlineChoiceAdd() {
        document.interactionCreate.myAction.value='inline_choice_add';
	document.interactionCreate.submit();
      }

      function doSetChoiceAdd(set_seq,set_choice_name) {
        document.interactionCreate.myAction.value='set_choice_add';
	document.interactionCreate.newSetChoiceName.value= set_choice_name;
	document.interactionCreate.setSequence.value= set_seq;
	document.interactionCreate.setName.value = ( set_seq ? "Target" : "Source" );
	document.interactionCreate.submit();
      }

     // hash used to track changes to content by editor
     var editorContent = {};

     function editorChangedEvent(editorRef, charCount) {
       var fragLabel = eval(editorRef.Helper.jsObjName+"PartName");

       var fragContent = editorRef.getBodyFragment();

       // check, does editor contain any media asset tags?
       var fragContainsMedia = (jQuery(fragContent).filter("div[class^=orca:media:]").length || 
                                jQuery(fragContent).find("div[class^=orca:media:]").length);

       if (${debug}) alert("Fragement contains media: " + fragContainsMedia);

       if (fragContainsMedia) {
          // set up hash reference for media assets (true/false: should media asset should include label for item part)
          var labelMedia = {};

          jQuery("#mediaAssetTable tbody tr").each(function() {
            var fragContainsThisMedia = (jQuery(fragContent).filter("div[class=orca:media:" + this.id + "]").length || 
                                         jQuery(fragContent).find("div[class^=orca:media:" + this.id + "]").length);

            if (${debug}) alert("Fragment contains " + this.id + " media: " + fragContainsThisMedia);

            labelMedia[this.id] = fragContainsThisMedia;
          });

          // for each media asset item part table data:
          jQuery("#mediaAssetTable tbody tr").each(function() {
             // load the media asset item part table data into an array (ordered by editor item part)
             var mediaFragLabels = jQuery(this).children("td:first").text().split(", ");

             // check, does the item part table data contain label for this editor item part?
             var mediaTableContainsLabel = (jQuery.inArray(fragLabel, mediaFragLabels) != -1);

             if (${debug}) alert("Media asset table contains " + fragLabel + ": " + mediaTableContainsLabel);

             if (mediaTableContainsLabel) {
                // check, hash for whether item part table data should contain label for this item part
                if (${debug}) alert("Should item part " + jQuery(this).attr("id") + " have label: " + labelMedia[jQuery(this).attr("id")]);                
                if (labelMedia[jQuery(this).attr("id")] == 0) {
                   // remove label for this editor item part from array
                   mediaFragLabels.splice(jQuery.inArray(fragLabel, mediaFragLabels),1);

                   // check, does the item part table data contain any item part labels?
                   if (mediaFragLabels.length == 0) {
                      // add Unassigned label
                      jQuery(this).children("td:first").replaceWith("<td><i>Unassigned</i></td>");
                   } else {
                      // sort labels reverse alphabetical first (Stem before Choice) than alpha-numerically
                      mediaFragLabels.sort(function(a,b){
                        var aa = a.split(" "), bb = b.split(" ");
                        return (aa[0] === bb[0]?  (aa[1]<bb[1]?  -1: (aa[1]>bb[1]?1:0)): (aa[0]>bb[0]?  -1: (aa[0]<bb[0]?1:0)));
                      });

                      jQuery(this).children("td:first").replaceWith("<td>"+mediaFragLabels.join(", ")+"</td>");
                   }
                }
             } else {
                if (${debug}) alert("Should item part " + jQuery(this).attr("id") + " have label: " + labelMedia[jQuery(this).attr("id")]);                
                if (labelMedia[jQuery(this).attr("id")]) {
                   // check, does this item part table data contain Unassigned label
                   var mediaTableContainsUnassignedLabel = (jQuery.inArray("Unassigned", mediaFragLabels) != -1);

                   if (${debug}) alert("Media asset table contains unassigned label: " + mediaTableContainsUnassignedLabel);

                   if (mediaTableContainsUnassignedLabel) {
                      // remove Unassigned label from array
                      mediaFragLabels.splice(0,1);
                   }

                   // add label for this editor item part to array
                   mediaFragLabels.push(fragLabel);

                   // sort labels reverse alphabetical first (Stem before Choice) than alph-numerically
                   mediaFragLabels.sort(function(a,b){
                      var aa = a.split(" "), bb = b.split(" ");
                      return (aa[0] === bb[0]?  (aa[1]<bb[1]?  -1: (aa[1]>bb[1]?1:0)): (aa[0]>bb[0]?  -1: (aa[0]<bb[0]?1:0)));
                   });

                   jQuery(this).children("td:first").replaceWith("<td>"+mediaFragLabels.join(", ")+"</td>");
                }
             }
          });
       } else {
          // check, does media asset table contain labels for this editor item part?
          // for each media asset item part table data:
          jQuery("#mediaAssetTable tbody tr").each(function() {
             var mediaTableContainsLabel = (jQuery(this).children("td:first").text().indexOf(fragLabel) != -1);

             if (${debug}) alert("Media asset table contains " + fragLabel + ": " + mediaTableContainsLabel);

             if (mediaTableContainsLabel) {
                // load the media asset item part table data into an array (ordered by editor item part)
                var mediaFragLabels = jQuery(this).children("td:first").text().split(", ");

                // remove label for this editor item part from array
                mediaFragLabels.splice(jQuery.inArray(fragLabel, mediaFragLabels),1);

                // check, does the item part table data contain any item part labels?
                if (mediaFragLabels.length == 0) {
                   // add Unassigned label to array
                   jQuery(this).children("td:first").replaceWith("<td><i>Unassigned</i></td>");
                } else {
                   // sort labels reverse alphabetical first (Stem before Choice) than alpha-numerically
                   mediaFragLabels.sort(function(a,b){
                      var aa = a.split(" "), bb = b.split(" ");
                      return (aa[0] === bb[0]?  (aa[1]<bb[1]?  -1: (aa[1]>bb[1]?1:0)): (aa[0]>bb[0]?  -1: (aa[0]<bb[0]?1:0)));
                   });
 
                   jQuery(this).children("td:first").replaceWith("<td>"+mediaFragLabels.join(", ")+"</td>");
                }
             }
          });
       }
     }

     function loadMatchArray() {

       var i = 0;
       for(var j=0; j < ${matchSourceSize}; j++) {
         matchSourceArray[j] = 0;
       }

       for(var k=0; k < ${matchTargetSize}; k++) {
         matchTargetArray[k] = 0;
       }

       for(var j=0; j < ${matchSourceSize}; j++) {

	 for(var k=0; k < ${matchTargetSize}; k++) {

	   if (document.interactionCreate["correct[]"][i].checked == true) {
	     matchSourceArray[j]++;
	     matchTargetArray[k]++;
           }

	   i++;
	 }
       } 
     }

     function doMatchCorrectCheck(a) {

       /* this will enforce the "match max" values, and prevent additional checkboxes from being checked */
       loadMatchArray();

       var max_checked = 0;
       var max_checked_str = 'source: ';
       var maxSource = parseInt(document.interactionCreate.matchMaxSource.value);
       var maxTarget = parseInt(document.interactionCreate.matchMaxTarget.value);

       for(var j=0; j < ${matchSourceSize}; j++) {

         if(maxSource > 0 && matchSourceArray[j] > maxSource) {
	   document.interactionCreate["correct[]"][a].checked = false;  
	   return;
	 }

	 max_checked_str += matchSourceArray[j] + ', ';
       }

       max_checked_str+= '. target: ';

       for(var j=0; j < ${matchTargetSize}; j++) {

         if(maxTarget > 0 && matchTargetArray[j] > maxTarget) {
	   document.interactionCreate["correct[]"][a].checked = false;  
	   return;
	 }
	 max_checked_str += matchTargetArray[j] + ', ';
       }

       //alert(max_checked_str);
     }

      function doChoiceCorrect(a) {

        // if maxChoices is 1, then unset the other options for convenience
        if(parseInt(document.interactionCreate.maxChoices.value) <= 1) {
          for(var i=0; i < document.interactionCreate["correct[]"].length; i++) {
            if(i != a) {
              document.interactionCreate["correct[]"][i].checked = false;
            }
          }
        }

	// if maxChoices > 1, then only allow a max number of selected choices
        if(parseInt(document.interactionCreate.maxChoices.value) > 1) {
	  var number_checked = 0;
          for(var i=0; i < document.interactionCreate["correct[]"].length; i++) {
	    if(document.interactionCreate["correct[]"][i].checked == true) {
	      number_checked++;
	    }
          }
          if(number_checked > parseInt(document.interactionCreate.maxChoices.value)) {
              document.interactionCreate["correct[]"][a].checked = false;
          }
        }
      }
      

      function updateHtmlBody() {
        if(typeof(window['oEditP']) != 'undefined' && oEditP.getObj() && oEditP.getBodyFragment() != '') { document.interactionCreate.fragmentPrompt.value = convertEntities(oEditP.getBodyFragment()); } 
      
        if(typeof(window['oEditC0']) != 'undefined' && oEditC0.getObj() && oEditC0.getBodyFragment() != '') { document.interactionCreate.fragmentChoice0.value = convertEntities(oEditC0.getBodyFragment()); } 
        if(typeof(window['oEditC1']) != 'undefined' && oEditC1.getObj() && oEditC1.getBodyFragment() != '') { document.interactionCreate.fragmentChoice1.value = convertEntities(oEditC1.getBodyFragment()); } 
        if(typeof(window['oEditC2']) != 'undefined' && oEditC2.getObj() && oEditC1.getBodyFragment() != '') { document.interactionCreate.fragmentChoice2.value = convertEntities(oEditC2.getBodyFragment()); } 
        if(typeof(window['oEditC3']) != 'undefined' && oEditC3.getObj() && oEditC1.getBodyFragment() != '') { document.interactionCreate.fragmentChoice3.value = convertEntities(oEditC3.getBodyFragment()); } 
        if(typeof(window['oEditC4']) != 'undefined' && oEditC4.getObj() && oEditC1.getBodyFragment() != '') { document.interactionCreate.fragmentChoice4.value = convertEntities(oEditC4.getBodyFragment()); } 
        if(typeof(window['oEditC5']) != 'undefined' && oEditC5.getObj() && oEditC1.getBodyFragment() != '') { document.interactionCreate.fragmentChoice5.value = convertEntities(oEditC5.getBodyFragment()); } 
        if(typeof(window['oEditC6']) != 'undefined' && oEditC6.getObj() && oEditC1.getBodyFragment() != '') { document.interactionCreate.fragmentChoice6.value = convertEntities(oEditC6.getBodyFragment()); } 
        if(typeof(window['oEditC7']) != 'undefined' && oEditC7.getObj() && oEditC1.getBodyFragment() != '') { document.interactionCreate.fragmentChoice7.value = convertEntities(oEditC7.getBodyFragment()); } 
      }

      function doSaveSubmit() {
        updateHtmlBody();
	document.interactionCreate.myAction.value = 'save';
        document.interactionCreate.submit();
      }

      function doBackSubmit() {
	document.interactionCreate.myAction.value = 'main';
	document.interactionCreate.interactionId.value = '0';
        document.interactionCreate.submit();
      }

END_HERE

  if($canCompare || $doCompare) {

    $psgi_out .= <<END_HERE;

     function compareDocuments(editorObj) {

       editorObj.Helper.jsObj.localCompareDocuments();

     }
END_HERE
  } else {
    $psgi_out .= <<END_HERE;

     function compareDocuments(editorObj) {
       alert('Comparison mode is disabled for this workflow state.');
     }
END_HERE
  }

  # $psgi_out .= the edit-on-NG js callbacks
  $psgi_out .= <<END_HERE;

      // edit-on NG custom actions
      function insertNegative(editorObj) {
          editorObj.insertContent('&#8212;'); 
      }
      
      function insertNonBreakingSpace(editorObj) {
          editorObj.insertContent('&#160;');
      }
      
      function insertIndent(editorObj) {
          editorObj.insertContent('&#160;&#160;&#160;&#160;&#160;');
      }
      
      function insertRightSingleQuote(editorObj) {
          editorObj.insertContent('&#8217;');
      }
      
      function insertLeftDoubleQuote(editorObj) {
          editorObj.insertContent('&#8220;');
      }
      
      function insertRightDoubleQuote(editorObj) {
          editorObj.insertContent('&#8221;');
      }
      
      function insertTimes(editorObj) {
          editorObj.insertContent('&#215;');
      }
      
      function insertDivide(editorObj) {
          editorObj.insertContent('&#247;');
      }
      
      function insertDegree(editorObj) {
          editorObj.insertContent('&#176;');
      }
      
      function insertEnDash(editorObj) {
          editorObj.insertContent('&#8211;');
      }
      
      function insert22Spaces(editorObj) {
          editorObj.insertContent('&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;');
      }
      
      function insertEllipsis(editorObj) {
          editorObj.insertContent('&#8230;');
      }
      
      function insertPi(editorObj) {
          editorObj.insertContent('&#960;');
      }
      
      function insertLessThanEqual(editorObj) {
          editorObj.insertContent('&#8804;');
      }
      
      function insertGreaterThanEqual(editorObj) {
          editorObj.insertContent('&#8805;');
      }
      
      function insertPlusMinus(editorObj) {
          editorObj.insertContent('&#177;');
      }
      
      function removeFontFamily(editorObj) {
        var elementContent = editorObj.getCurrentElement();
        var elementContentFontFamilyRemoved = jQuery(elementContent).removeClass('fontfamilyarial fontfamilytimes fontfamilycourier').text();
        editorObj.setCurrentElementContent(elementContentFontFamilyRemoved);
      }
      
      function removeFontSize(editorObj) {
        var elementContent = editorObj.getCurrentElement();
        var elementContentFontFamilyRemoved = jQuery(elementContent).removeClass('fontsize8 fontsize9 fontsize10 fontsize11 fontsize12 fontsize14 fontsize16 fontsize18 fontsize20 fontsize22 fontsize24 fontsize26 fontsize28 fontsize36 fontsize48 fontsize72').text();
        editorObj.setCurrentElementContent(elementContentFontFamilyRemoved);
      }

    function doResize(editorObj) {
      if(editorObj.obj.height <= defaultEditorHeight)  {  
        //alert('Resize to ' + defaultEditorWidth + ' x ' + largeEditorHeight);
        editorObj.resizeEditor(defaultEditorWidth,largeEditorHeight);
      } else { 
        //alert('Resize to ' + defaultEditorWidth + ' x ' + defaultEditorHeight);
        editorObj.resizeEditor(defaultEditorWidth,defaultEditorHeight);
      }
    }

    function convertEntities (str_in) {
      /*[\\u00A0-\\u00FF\\u2022-\\u2135] */
      var str_out = str_in.replace(/[\\u00A0-\\u2900]/g, function (c) {
                                     return '&#' + c.charCodeAt(0) + ';';
                        });
      return str_out;
    }

    //-->
    </script>
    <style type="text/css">
      div.choice { margin-top:9px; }
    </style>
  </head>
  <body>
    <div>
    <span class="title">Edit Interaction</span>
    &#160;&#160;&#160;<input type="button" value="Back to Create/Edit" onClick="doBackSubmit();" />
    </div>
    <br />
    $readOnlyWarn $msg
    <form name="interactionCreate" action="$thisUrl" method="POST">
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="itemId" value="$item->{id}" />
      <input type="hidden" name="interactionId" value="$in{interactionId}" />
      <!-- these 2 fields are used in the case of a choice swap operation -->
      <input type="hidden" name="choiceA" value="" />
      <input type="hidden" name="choiceB" value="" />
      <!-- these 3 fields are used in the case of a set choice operation -->
      <input type="hidden" name="newSetChoiceName" value="" />
      <input type="hidden" name="setSequence" value="" />
      <input type="hidden" name="setName" value="" />
    <table class="no-style" border="0" cellpadding="2" cellspacing="2">
      <thead />
      <tbody>
       <tr>
         <td style="width:200px;">
          Name: $ii->{name}<br />
          Type: $typeDisplay<br />
         </td>
         <td style="width:50px;">&#160;</td>
         <td valign="bottom">
	   <input type="button" value="Save" onClick="doSaveSubmit();" />&#160;&#160;&#160;
         </td>
       </tr>
       </tbody>
     </table>
     <table class="no-style" border="0" cellpadding="2" cellspacing="2">
       <tr>
         <td>
END_HERE

  if($ii->{type} == $IT_INLINE_CHOICE) {

    if(scalar @{$ii->{content}{choices}}) {
      $psgi_out .= <<END_HERE;
      <table border="1" cellpadding="2" cellspacing="2">
        <tr><th>Choices</th><th>Action</th></tr>
END_HERE

      my $i = 0;
      foreach my $choice (@{$ii->{content}{choices}}) {
        $psgi_out .= '<tr><td>' . $choice->{text} . '</td><td>';

        if($i > 0) {
	  $psgi_out .= '<input type="button" value="Up" onClick="doInlineChoiceSwap(' . $i . ',' . ($i-1) . ');" />&#160;&#160;';
	}

        if($i + 1 < scalar @{$ii->{content}{choices}}) {
	  $psgi_out .= '<input type="button" value="Down" onClick="doInlineChoiceSwap(' . $i . ',' . ($i+1) . ');" />&#160;&#160;';
	}

        if($i + 1 == scalar @{$ii->{content}{choices}}) {
	  $psgi_out .= '<input type="button" value="Delete" onClick="doInlineChoiceDelete(' . $i . ');" />&#160;&#160;';
	}

	$psgi_out .= '</td></tr>';
	$i++;
      }
      
      $psgi_out .= '</table>';
      
    } else {
      $psgi_out .= <<END_HERE;
      <p>No Choices have been created.</p> 
END_HERE
    } 
    
    $psgi_out .= <<END_HERE;
    <br />
    <p>New Choice:&#160;<input type="text" size="30" name="newInlineChoiceName" value="" />&#160;&#160;
                        <input type="button" value="Add" onClick="doInlineChoiceAdd();" />
    </p>
END_HERE
  }

  if($ii->{type} == $IT_MATCH) {

    $ii->{content}{setChoices}[0] = [] unless exists $ii->{content}{setChoices}[0];
    $ii->{content}{setChoices}[1] = [] unless exists $ii->{content}{setChoices}[1];

    if(scalar @{$ii->{content}{setChoices}[0]}) {
      $psgi_out .= <<END_HERE;
      <table border="1" cellpadding="2" cellspacing="2">
        <tr><th>Source Choices</th><th>Action</th></tr>
END_HERE

      my $i = 0;
      foreach my $choice (@{$ii->{content}{setChoices}[0]}) {
        $psgi_out .= '<tr><td>' . $choice->{text} . '</td><td>';

        if($i > 0) {
	  $psgi_out .= '<input type="button" value="Up" onClick="doSetChoiceSwap(0,' . $i . ',' . ($i-1) . ');" />&#160;&#160;';
	}

        if($i + 1 < scalar @{$ii->{content}{setChoices}[0]}) {
	  $psgi_out .= '<input type="button" value="Down" onClick="doSetChoiceSwap(0,' . $i . ',' . ($i+1) . ');" />&#160;&#160;';
	}

        if($i + 1 == scalar @{$ii->{content}{setChoices}[0]}) {
	  $psgi_out .= '<input type="button" value="Delete" onClick="doSetChoiceDelete(0,' . $i . ');" />&#160;&#160;';
	}

	$psgi_out .= '</td></tr>';
	$i++;
      }
      
      $psgi_out .= '</table>';
      
    } else {
      $psgi_out .= <<END_HERE;
      <p>No Source Choices have been created.</p> 
END_HERE
    } 
    
    $psgi_out .= <<END_HERE;
    <br />
    <p>New Source Choice:&#160;<input type="text" size="30" name="newSetSourceChoiceName" value="" />&#160;&#160;
                        <input type="button" value="Add" onClick="doSetChoiceAdd(0,document.interactionCreate.newSetSourceChoiceName.value);" />
    </p>
    <br />
END_HERE

    if(scalar @{$ii->{content}{setChoices}[1]}) {
      $psgi_out .= <<END_HERE;
      <table border="1" cellpadding="2" cellspacing="2">
        <tr><th>Target Choices</th><th>Action</th></tr>
END_HERE

      my $i = 0;
      foreach my $choice (@{$ii->{content}{setChoices}[1]}) {
        $psgi_out .= '<tr><td>' . $choice->{text} . '</td><td>';

        if($i > 0) {
	  $psgi_out .= '<input type="button" value="Up" onClick="doSetChoiceSwap(1,' . $i . ',' . ($i-1) . ');" />&#160;&#160;';
	}

        if($i + 1 < scalar @{$ii->{content}{setChoices}[1]}) {
	  $psgi_out .= '<input type="button" value="Down" onClick="doSetChoiceSwap(1,' . $i . ',' . ($i+1) . ');" />&#160;&#160;';
	}

        if($i + 1 == scalar @{$ii->{content}{setChoices}[1]}) {
	  $psgi_out .= '<input type="button" value="Delete" onClick="doSetChoiceDelete(1,' . $i . ');" />&#160;&#160;';
	}

	$psgi_out .= '</td></tr>';
	$i++;
      }
      
      $psgi_out .= '</table>';
      
    } else {
      $psgi_out .= <<END_HERE;
      <p>No Target Choices have been created.</p> 
END_HERE
    } 
    
    $psgi_out .= <<END_HERE;
    <br />
    <p>New Target Choice:&#160;<input type="text" size="30" name="newSetTargetChoiceName" value="" />&#160;&#160;
                        <input type="button" value="Add" onClick="doSetChoiceAdd(1,document.interactionCreate.newSetTargetChoiceName.value);" />
    </p>
END_HERE
  }

  if(  $ii->{type} == $IT_CHOICE 
    || $ii->{type} == $IT_EXTENDED_TEXT
    || $ii->{type} == $IT_MATCH ) { 

    my $promptContent = '';
    my $promptContentCompare = '';

    if( defined $ii->{content}{prompt}{text} ) {
      $promptContent = &escapeHTML($ii->{content}{prompt}{text});
      $promptContent =~ s/&amp;/&/g;
      $promptContentCompare = ($canCompare 
                                  ? &escapeHTML( defined($comp->{$ii->{content}{prompt}{id}}) 
				                  ? $comp->{$ii->{content}{prompt}{id}} : '' ) 
				  : '');
    }

    $psgi_out .= <<END_HERE;
      <div class="prompt">
        <div><strong>Prompt</strong></div> 
        <textarea style="display:none;" id="fragmentPrompt" name="fragmentPrompt" rows="6" cols="30">${promptContent}</textarea>
        <textarea style="display:none;" id="fragmentPromptCompare" name="fragmentPromptCompare" rows="6" cols="30">${promptContentCompare}</textarea> 
        <script>
        <!--

        var oEditP = new eongApplication(defaultEditorWidth,defaultEditorHeight,"myEditorP","myEditorP","oEditP");
        oEditP.setCodebase("${commonUrl}eong3/lib/bin");
        oEditP.clearUserPreferences();
        oEditP.clearUserStyles();

        oEditP.setUIConfigURL("${commonUrl}eong3/lib/config/uiconfig.json");
        oEditP.setConfigURL("${commonUrl}eong3/lib/config/config.json");
        oEditP.setActionExtensionURL("${commonUrl}eong3/extension/actionmap.ext.json");
        //oEditP.addLocaleExtensionURL("${commonUrl}eong3/lib/locale/en-US.json");
        oEditP.setContentCaching(false);

        oEditP.addUserStylesFromURL("${orcaUrl}style/item-style.css");
        oEditP.addUserStylesFromURL("${commonUrl}eong3/lib/css/custom.css");
	if(cssStylesheet != '') {
	  oEditP.addUserStylesFromURL(cssStylesheet);
	}

        oEditP.setUserAttributes("Username","$user->{userName}");

        oEditP.invokeAction("live-document-language", "$locale_code");

        var oEditPPartName = "Prompt";
END_HERE

    if ( $canCompare  || $doCompare ) {
      $psgi_out .= <<END_HERE;

        function localCompareDocumentsP() {

           document.interactionCreate.fragmentPrompt.value = oEditP.getBodyFragment();

           if(document.interactionCreate.fragmentPromptCompare.value == document.interactionCreate.fragmentPrompt.value) {
           
             //alert('Content matches original.');

           } else if(document.interactionCreate.fragmentPromptCompare.value != '' &&
                   document.interactionCreate.fragmentPrompt.value != '') {

             oEditP.compareDocumentsFromContent(
                compareHeader + document.interactionCreate.fragmentPromptCompare.value + compareFooter,
                compareHeader + document.interactionCreate.fragmentPrompt.value + compareFooter);

             oEditP.invokeAction("show-changes-inline-diff");

           } else {

             alert('Comparison content not available.');
           }

        }

        oEditP.Helper.jsObj.localCompareDocuments = localCompareDocumentsP;

END_HERE
    }

    if ($doCompare) {
      $psgi_out .= <<END_HERE;
          oEditP.registerEventHandler('ONEDITORLOADED', 'localCompareDocumentsP');
END_HERE
    }

    $psgi_out .= <<END_HERE;
        oEditP.setBodyFragment(document.interactionCreate.fragmentPrompt.value);
        oEditP.registerEventHandler('ONCHARACTERCOUNTCHANGED', 'editorChangedEvent');
      //-->  
      </script>
      <div id="myEditorP"></div>
  </div>
END_HERE

    $onLoadFunction .= "oEditP.loadEditor();\n";

  } # for the prompt

  if($ii->{type} == $IT_CHOICE) {

    my $choices = scalar @{$ii->{content}{choices}};
    my $choicesDisplay = &hashToSelect( 'choices', \%mc_answer_choices, $choices); 

    my %correct_map = map { $_ => 1 } split(/ /, $ii->{correct});

    for ( my $j = 0 ; $j < $choices ; $j++ ) {

      my $correctText = 
          ( exists $correct_map{$ii->{content}{choices}[$j]{name}} ? 'CHECKED' : '' );

      my $choiceText =
          defined( $ii->{content}{choices}[$j] )
          ? &escapeHTML( $ii->{content}{choices}[$j]{text} )
          : "";
      $choiceText =~ s/&amp;/&/g;

      my $compareText =
          $canCompare ? &escapeHTML( $comp->{$ii->{content}{choices}[$j]{id}} ) : "";

      my $drText = 
          defined( $ii->{content}{distractorRationale}[$j] )
          ? $q->escapeHTML( $ii->{content}{distractorRationale}[$j]{text} )
          : '';

      my $jminus      = $j - 1;
      my $jplus       = $j + 1;

      my $swapDiv = '<div>';

      if ( $j > 0 ) {
        $swapDiv .= <<END_HERE;
         <input type="button" style="font-family:Arial;font-size:12px;width:80px;" onClick="doChoiceSwap(${j},${jminus});" value="Move Up" />&#160;&#160;&#160;
END_HERE
      }
      else { $swapDiv .= ''; }

      if ( $jplus < $choices ) {
        $swapDiv .= <<END_HERE;
    <input type="button" style="font-family:Arial;font-size:12px;width:80px;"  onClick="doChoiceSwap(${j},${jplus});" value="Move Down" />&#160;&#160;&#160;
END_HERE
      }
      else { 
        $swapDiv .= <<END_HERE;
    <input type="button" style="font-family:Arial;font-size:12px;width:100px;"  onClick="doChoiceDelete(${j});" value="Delete Choice" />&#160;&#160;&#160;
END_HERE
      }

      $swapDiv .= '</div>';

      $psgi_out .= <<END_HERE;
      <div class="choice">
        <div><strong>Choice $choice_chars[$j]</strong></div> 
        <textarea style="display:none;" id="fragmentChoice${j}" name="fragmentChoice${j}" rows="6" cols="30">${choiceText}</textarea>
        <textarea style="display:none;" id="fragmentChoiceCompare${j}" name="fragmentChoiceCompare${j}" rows="6" cols="30">${compareText}</textarea>
      <script>
      <!--
        var oEditC${j} = new eongApplication(defaultEditorWidth,defaultEditorHeight,"myEditorC${j}","myEditorC${j}","oEditC${j}");
        oEditC${j}.setCodebase("${commonUrl}eong3/lib/bin");

        oEditC${j}.clearUserPreferences();
        oEditC${j}.clearUserStyles();

        oEditC${j}.setUIConfigURL("${commonUrl}eong3/lib/config/uiconfig.json");
        oEditC${j}.setConfigURL("${commonUrl}eong3/lib/config/config.json");
        oEditC${j}.setActionExtensionURL("${commonUrl}eong3/extension/actionmap.ext.json");
        //oEditC${j}.addLocaleExtensionURL("${commonUrl}eong3/lib/locale/en-US.json");
        oEditC${j}.setContentCaching(false);

        oEditC${j}.addUserStylesFromURL("${orcaUrl}style/item-style.css");
        oEditC${j}.addUserStylesFromURL("${commonUrl}eong3/lib/css/custom.css");
	if(cssStylesheet != '') {
	  oEditC${j}.addUserStylesFromURL(cssStylesheet);
	}

        oEditC${j}.setUserAttributes("Username","$user->{userName}");

        oEditC${j}.invokeAction("live-document-language", "$locale_code");

        oEditC${j}PartName = "Choice " + String.fromCharCode(65 + ${j});
END_HERE

      if ( $canCompare || $doCompare ) {

        $psgi_out .= <<END_HERE;
        function localCompareDocumentsC${j}() {

           document.interactionCreate.fragmentChoice${j}.value = oEditC${j}.getBodyFragment();

           if(document.interactionCreate.fragmentChoiceCompare${j}.value == document.interactionCreate.fragmentChoice${j}.value) {
           
             //alert('Content matches original.');

           } else if(document.interactionCreate.fragmentChoiceCompare${j}.value != '' &&
                     document.interactionCreate.fragmentChoice${j}.value != '') {

             oEditC${j}.compareDocumentsFromContent(
			compareHeader + document.interactionCreate.fragmentChoiceCompare${j}.value + compareFooter,
			compareHeader + document.interactionCreate.fragmentChoice${j}.value + compareFooter);

             oEditC${j}.invokeAction("show-changes-inline-diff");

           } else {

             alert('Comparison content not available.');
           }

        }

        oEditC${j}.Helper.jsObj.localCompareDocuments = localCompareDocumentsC${j};

END_HERE
      }

      if ($doCompare) {
        $psgi_out .= <<END_HERE;
          oEditC${j}.registerEventHandler('ONEDITORLOADED', 'localCompareDocumentsC${j}');
END_HERE
      }

      $psgi_out .= <<END_HERE;
      oEditC${j}.setBodyFragment(document.interactionCreate.fragmentChoice${j}.value);
      oEditC${j}.registerEventHandler('ONCHARACTERCOUNTCHANGED', 'editorChangedEvent');
END_HERE


      $psgi_out .= <<END_HERE;
          //-->  
        </script>
        <div id="myEditorC${j}"></div>
        ${swapDiv}
        <div>
            Correct&#160;
              <input type="checkbox" name="correct[]" value="$choice_chars[$j]" onClick="doChoiceCorrect(${j});" ${correctText} />
        </div>
        <div>Error Type:&#160;
END_HERE

      $onLoadFunction .= "oEditC${j}.loadEditor();\n";

      if ( $CODED_ERROR_TYPE == 0 ) {

       $psgi_out .= "<input type=\"text\" name=\"distractor${j}\" size=\"35\" value=\"${drText}\" />";

      }
      else {

        $psgi_out .= '<select name="distractor' 
              . $j . '">'
              . '<option value=""></option>';
        foreach my $key ( sort { $a cmp $b } keys %error_types ) {
          $psgi_out .= '<option value="' 
                  . $key . '"'
                  . ( $key eq $drText ? " SELECTED" : "" ) . '>'
                  . $error_types{$key}
                  . '</option>';
        }
        $psgi_out .= '</select>';

      }

      $psgi_out .= <<END_HERE;
      </div>
    </div>
END_HERE
    }    # foreach choice
  
    $psgi_out .= <<END_HERE;
    <br />
    <div>
      <input type="button" value="Add a New Choice" onClick="doChoiceAdd();" />
    </div>
END_HERE

  } # if type = choice
   
  $psgi_out .= <<END_HERE;
  </td> 
  <td style="width:10px;">&#160;</td>
  <td valign="top">
END_HERE

  if(  $ii->{type} == $IT_CHOICE  ) {
 #   || $ii->{type} == $IT_EXTENDED_TEXT
 #   || $ii->{type} == $IT_MATCH ) {

    $psgi_out .= &getMediaTableHtml($mediaAssets, 1, $item->{bankId}, $item->{id}, $item->{name}, $item->{version}, $in{interactionId});
  }

  # add any extra metadata

  $psgi_out .= <<END_HERE;
    <table class="no-style" border="0" cellspacing="3" cellpadding="3">
      <tr>
        <td>Max Score:</td>
	<td align="left"><input type="text" size="5" name="maxScore" value="$ii->{max_score}" /></td>
      </tr>
END_HERE

  if($ii->{type} == $IT_CHOICE) { 

    my $maxChoices = $ii_atts->{maxChoices} || 1;
    my $shuffleDisplay = &hashToSelect('shuffle', { 'false' => 'false', 'true' => 'true' },
                                        $ii_atts->{shuffle} || 'false');
    $psgi_out .= <<END_HERE;
      <tr>
        <td>Max Choices:</td>
	<td><input type="text" size="5" name="maxChoices" value="$maxChoices" /></td>
      </tr>
      <tr>
        <td>Allow Shuffle:</td>
	<td>$shuffleDisplay</td>
      </tr>
END_HERE
  }

  if($ii->{type} == $IT_TEXT_ENTRY) {
    $psgi_out .= <<END_HERE;
      <tr>
        <td>Correct Answer:</td>
	<td><input type="text" size="40" name="correctAnswer" value="$ii->{correct}" /></td>
      </tr>
END_HERE
  }
  elsif($ii->{type} == $IT_INLINE_CHOICE) {
    my %correctAnswerMap = map { $_->{name} => $_->{text} } @{$ii->{content}{choices}};
    my $correctAnswerDisplay = scalar(@{$ii->{content}{choices}})
                             ? &hashToSelect('correctAnswer', \%correctAnswerMap , $ii->{correct}, '', '')
			     : 'No Choices to Select.';

    $psgi_out .= <<END_HERE;
      <tr>
        <td>Correct Answer:</td>
	<td>${correctAnswerDisplay}</td>
      </tr>
END_HERE
  }
  elsif($ii->{type} == $IT_MATCH) {

    my $matchMaxSource = $ii_atts->{matchMaxSource} || 1;
    my $matchMaxTarget = $ii_atts->{matchMaxTarget} || 1;

    $psgi_out .= <<END_HERE;
      <tr>
        <td>Source Match Max:</td>
	<td><input type="text" size="5" name="matchMaxSource" value="$matchMaxSource" /></td>
      </tr>
      <tr>
        <td>Target Match Max:</td>
	<td><input type="text" size="5" name="matchMaxTarget" value="$matchMaxTarget" /></td>
      </tr>
END_HERE
    

    # set up a table to allow selection of correct answer

    $ii->{content}{setChoices}[0] = [] unless exists $ii->{content}{setChoices}[0];
    $ii->{content}{setChoices}[1] = [] unless exists $ii->{content}{setChoices}[1];

    my $ansTable = '';

    if(  scalar(@{$ii->{content}{setChoices}[0]}) 
      && scalar(@{$ii->{content}{setChoices}[1]}) ) {

      my %correct_map = map { $_ => 1 } split(/ /, $ii->{correct});

      $ansTable .= '<table border="1" cellpadding=2" cellspacing="2">';

      # print the header row, these are the choices in the "target set"
      $ansTable .= '<thead><tr><th>&#160;</th>';

      foreach my $choice (@{$ii->{content}{setChoices}[1]}) {
        $ansTable .= '<th>' . $choice->{text} . '</th>';    
      }

      $ansTable .= '</tr></thead><tbody>';

      # now print a row for each of the choices in the "source set"
      my $choice_cnt = 0;
      foreach my $choice (@{$ii->{content}{setChoices}[0]}) {
        $ansTable .= '<tr><th>' . $choice->{text} . '</th>';    

        for (my $i=0; $i < scalar @{$ii->{content}{setChoices}[1]}; $i++) {
          my $correct_val = $choice->{name} . ':' . $ii->{content}{setChoices}[1][$i]->{name}; 
          my $is_correct = ( exists $correct_map{$correct_val} ? 'CHECKED' : '' );

          $ansTable .= '<td><input type="checkbox" name="correct[]" onClick="doMatchCorrectCheck(' . $choice_cnt . ');"'
	             . ' value="' . $correct_val . '" ' . $is_correct . '/></td>';
          $choice_cnt++;
        }

        $ansTable .= '</tr>';
      }

      $ansTable .= '</tbody></table>';
    } else {
      $ansTable .= 'Must define at least one Source and one Target.';
    }

    $psgi_out .= <<END_HERE;
      <tr>
        <td align="left" colspan="2">Correct Answer:</td>
      </tr>
      <tr>
        <td align="left" colspan="2">${ansTable}</td>
      </tr>
END_HERE
  }

  if($ii->{type} == $IT_TEXT_ENTRY || $ii->{type} == $IT_EXTENDED_TEXT) { 

    my $defaultLength = $ii->{type} == $IT_TEXT_ENTRY ? 60 : 240;
    my $expectedLength = $ii_atts->{expectedLength} || $defaultLength;

    $psgi_out .= <<END_HERE;
      <tr>
        <td>Expected Length:</td>
	<td><input type="text" size="5" name="expectedLength" value="$expectedLength" /></td>
      </tr>
END_HERE
  }

  if($ii->{type} == $IT_EXTENDED_TEXT) { 

    my $expectedLines = $ii_atts->{expectedLines} || 4;

    $psgi_out .= <<END_HERE;
      <tr>
        <td>Expected Lines:</td>
	<td><input type="text" size="5" name="expectedLines" value="$expectedLines" /></td>
      </tr>
END_HERE
  }

  $psgi_out .= <<END_HERE;
    </table>
  </td>
 </tr>
</table>
<script type="text/javascript">
<!--

  window.onload = function () {

    ${onLoadFunction}

    if($ii->{type} == $IT_MATCH) {
      //loadMatchArray();
    }
  }
//-->
</script>
</form>
</body>
</html>         
END_HERE

  return $psgi_out;
}

sub encodeHTML {
    my $html = shift;
    $html =~ s/&/&amp;/g;
    $html =~ s/</&lt;/g;
    $html =~ s/>/&gt;/g;
    return $html;
}

sub setError {
    my $params  = shift;
    my $message = shift;
    my %p       = %{$params};

    my $itemBankId = $p{itemBankId};

    %p             = ();
    $p{externalId} = '';
    $p{itemBankId} = $itemBankId;
    $p{message}    = $message;

    return %p;
}
1;
