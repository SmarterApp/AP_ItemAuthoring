package Action::itemCreate;

use CGI::Cookie;
use URI;
use File::Copy;
use ItemConstants;
use UrlConstants;
use Item;
use Session;
use Time::HiRes;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => join('|', $q->param($_)) } $q->param;
  our $debug = 0;

  our $start_time;

  our $thisUrl    = "${orcaUrl}cgi-bin/itemCreate.pl";
  our $previewUrl = "${orcaUrl}cgi-bin/itemPreview.pl";

  our %cookies = CGI::Cookie->fetch;
  our $allowCompare =
    ( exists( $cookies{comparisonModeStatus} )
        && $cookies{comparisonModeStatus}->value eq 'disable' ) ? 0 : 1;
  
  our $doCompare = ( exists( $in{doCompare} ) && $allowCompare ) ? 1 : 0;
  warn "1:[doCompare:$doCompare]";
  our $compareState = exists( $in{doCompareState} ) ? $in{doCompareState} : 0;
  our $canCompare = 1;
  warn "1:[canCompare:$canCompare]";
  our %itemNotesTag =
    ( exists( $in{itemNotesTag} )
        && $in{itemNotesTag} ? %{ $itemNotesTags{ $in{itemNotesTag} } } : () );
  
  our $sth;
  our $sql;
  
  # Authorize user (must be user type UT_ITEM_EDITOR) 
  our $user = Session::getUser($q->env, $dbh);
  unless ( int( $user->{type} ) == $UT_ITEM_EDITOR )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ];
  }
  our $isAdmin = $user->{adminType} ? 1 : 0;
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  if ( ! defined $in{myAction} ) #|| $in{externalId} eq '' )
  {
    $in{externalId} = "New_Item_Id";
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
  }
  
  $in{externalId} =~ s/[\\\/\s]/_/g;
  
  our $editors = &getEditors($dbh, $in{itemBankId} || 0);
  
  our %editFieldPermission = (
      'itemDevState'   => 1,
      'assignedEditor' => 1,
      'ct2'            => 1,
      'ct3'            => 1 
  );
  
  our %filteredDevStates =  map { $_ => $dev_states{$_} } grep { exists $dev_states{$_} } @dev_states_workflow_ordered_keys;
  
  our %fieldHash = (
      'itemDevState'   => \%filteredDevStates,
      'assignedEditor' => $editors,
      'ct2'            => $const[$OC_CONTENT_AREA],
      'ct3'            => $const[$OC_GRADE_LEVEL]
  );
  
  unless ( defined $in{saveAction} ) {
  
    # User is coming from the First Screen
  
  
    if ( $in{myAction} eq "edit" ) {
  
      $start_time = [Time::HiRes::gettimeofday()];
      # Check for existing Item ID, and read-only state
      # If found, enter edit mode
      # If not found, display error message
  
      $sql =
              "SELECT has_outdated_metafiles(i_id) flag, i_id, i_read_only, i_is_old_version FROM item WHERE i_external_id="
          . $dbh->quote( $in{externalId} )
          . " AND ib_id=$in{itemBankId} ORDER BY i_version DESC LIMIT 1";
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      my $xml_data         = "";
      my $xml_data_compare = "";
      if ( my $row = $sth->fetchrow_hashref ) {
  
        #if($row->{i_read_only} eq '1') {
        #  %in = &setError(\%in,"Item '$in{externalId}' is Read Only!");
        #} else {
          $in{itemId}   = $row->{i_id};
          $in{readOnly} = ($row->{i_read_only} || $row->{i_is_old_version}) ? 1 : 0;
          $in{outdated} = $row->{flag};
        #}
      }
      else {
        %in = &setError( \%in, "Item '$in{externalId}' not found!" );
      }
      $in{adminMode}++;
 
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
    }
    elsif ( $in{myAction} eq 'create' ) {
  
      my $item = new Item($dbh);
      unless ( $item->create( $in{itemBankId}, $in{externalId}, undef, $user->{writer_code} ) ) {
        %in = &setError( \%in,
                  "Item '$in{externalId}' exists! Please Enter a different ID." );

        return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
      }

      $in{externalId} = $item->{name};
      $in{itemId} = $item->{id};
  
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
    }
  }
}

### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

  my $params       = shift;
  my %value        = ();
  my $hiddenFields = '';
  my $onLoadFunction = '';

  my ( $item, $comp, $gle, $primaryContentCode, $secondaryContentCode,
        $tertiaryContentCode );

  if ( exists $params->{itemId} ) {
    $item       = new Item( $dbh, $params->{itemId} );
    $gle        = $item->getGLE();
    $comp       = $item->getCompareContent($compareState);
    $canCompare = 0 unless ( scalar(keys %{$comp} ));
    warn "2:[canCompare:$canCompare]";
    $doCompare  = 0 unless $doCompare && scalar(keys %{$comp});
    warn "2:[doCompare:$doCompare]";

    $primaryContentCode   = $item->getPrimaryContentCode();
    $secondaryContentCode = $item->getSecondaryContentCode();
    $tertiaryContentCode  = $item->getTertiaryContentCode();
  }
  else {
    $primaryContentCode   = '';
    $secondaryContentCode = '';
    $tertiaryContentCode  = '';
  }

  my $msg = (
    defined( $params->{message} )
    ? "<br /><div style='color:#ff0000;font-weight:bold;font-family: arial;font-size:12pt;'>"
      . $params->{message}
      . "</div>"
    : "" );
  my $readOnlyWarn =
    ($params->{readOnly})
    ? "&#160;&#160;&#160;<span style='color:#ff0000'>Read Only: Some functions disabled</span>"
    : '';
  my $externalId     = $item->{name} || '';
  my $externalIdSafe = $q->escapeHTML($externalId);
  my $itemId         = $params->{itemId} || '';
  my $stems   = $item->{stemCount} || "1";
  my $notes   = $item->{notes} || '';
  my $sourceDocument = $item->{sourceDoc} || '';
  my $comprehensiveCurriculum = $item->{$OC_COMP_CURRICULUM} || '';
  $primaryContentCode   = '' if $primaryContentCode   eq '0.0.0.0.0';
  $secondaryContentCode = '' if $secondaryContentCode eq '0.0.0.0.0';
  $tertiaryContentCode  = '' if $tertiaryContentCode  eq '0.0.0.0.0';
  my $version      = $item->{version}      || '0';
  my $adminMode      = $params->{adminMode} || '0';
  my $answerFormat = $item->{answerFormat} || '9.99';
  my $furl = ( defined $params->{furl} ? $params->{furl} : '' );
  my $due_date = $item->{due_date} || '';
  my $ibankId   = $item->{bankId} || "1";
  my $ibankName = $banks->{$ibankId}{name};
  my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;
  my $bankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $ibankId, '', '' );

  my $mediaAssets = &getMediaAssetAttributes($dbh, $itemId);

  my $title =
      '<span class="title">CREATE&#160;ITEM:&#160;&#160;'
      . ( $externalId eq ''
        ? ''
        : '<b>' . $externalId . '</b>&#160;&#160;&lt;' . $ibankName . '&gt;' )
      . '</span>';

  my $descrip =
      $item->{description} ? $q->escapeHTML( $item->{description} ) : "";

  my $itemFormat = $item->{format} || 1;
  my $itemFormatDisplay =
      &hashToSelect( 'itemFormat', \%item_formats, $itemFormat, '', '', '', 'width:165px;' );

  $value{assignedEditor} = $item->{author}   || 4856;
  $value{itemDevState}   = $item->{devState} || 1;

  my $defaultDifficulty = $item->{difficulty} || 0;
  my $difficultyDisplay =
      &hashToSelect( 'itemDifficulty', \%difficulty_levels, $defaultDifficulty,
        '', '0:' );

  my $publicationStatus = $item->{publicationStatus} || 0;
  my $publicationStatusDisplay =
      &hashToSelect( 'publicationStatus', \%publication_status,
        $publicationStatus, '', 'null', '', 'width:205px;' );

  my $readability_index = $q->escapeHTML($item->{readability_index} || '');

  my $languageDisplay = &hashToSelect('language',\%languages, $item->{lang},'','', '', 'width:205px;');
  my $locale_code = $item->{lang} == 2 ? 'es-ES' : 'en-US';

  # Use display (and editFieldPermission) hash to determine if field should be displayed read-only
  my %display = (
        'assignedEditor' => &hashToSelect(
            'assignedEditor',
            $fieldHash{'assignedEditor'},
            $value{'assignedEditor'},
            '', '0', 'value', 'width:205px;'
        ),
        'itemDevState' => &hashToSelect(
            'itemDevState', $fieldHash{'itemDevState'},
            $value{'itemDevState'}, '', '', 'value', 'width:205px;',
        )
    );

  # Otherwise, make the value a hidden field
  foreach ( keys %display ) {
    unless ( $user->{adminType} ) {
      $display{$_} = $fieldHash{$_}->{ $value{$_} };
      $hiddenFields .=
        "<input type=\"hidden\" name=\"$_\" value=\"$value{$_}\" />";
    }
  }

  my $stemText =
      defined( $item->{item_body}{content}{text} )
      ? &escapeHTML( $item->{item_body}{content}{text} )
      : "";
  $stemText =~ s/&amp;/&/g;

  my $compareText =
          $canCompare ? &escapeHTML( $comp->{$item->{item_body}{content}{id}} ) : "";

  # Create Item characteristic Drop-Down lists
  my $charDisplay = "";
  foreach my $type (@ctypes) {
    if ( defined($item) && defined( $item->{$type} ) ) {
      $params->{"ct${type}"} = $item->{$type};
    }
    else {
     $params->{"ct${type}"} = '';
    }

    $charDisplay .= "<tr><td>$labels[$type]</td><td>";

    if ( exists( $editFieldPermission{"ct${type}"} )
            and not( $user->{adminType}  ) )
    {
      $charDisplay .= $const[$type]->{ $params->{"ct${type}"} };
      $hiddenFields .=
         '<input type="hidden" name="ct' 
         . $type
         . '" value="'
         . $params->{"ct${type}"} . '" />';
    }
    else {
      if( $type == 5 || $type == 6 ) {
        $charDisplay .= qq|<select name="ct$type" onChange="compareGradeSpan(this.form, this)">|;
      }
      else {
        $charDisplay .= qq|<select name="ct$type">|;
      }

      $charDisplay .= '<option value="0"></option>'
        unless exists( $const[$type]->{'0'} );

      foreach my $key ( sort { $a <=> $b } keys %{ $const[$type] } ) {
        $charDisplay .=
           '<option value="' 
           . $key . '" '
           . (
               (
                 defined( $params->{"ct${type}"} )
                 and $params->{"ct${type}"} eq $key
               )
               || ( defined( $default{$type} )
                        and $default{$type} eq $key ) ? "SELECTED " : ""
             )
           . '>'
           . $const[$type]->{$key}
           . '</option>';
      }
      $charDisplay .= '</select>';
    }
    $charDisplay .= '</td></tr>';
  }

  # Create Item tools Drop-Down lists
  my $toolDisplay = "";
  foreach my $type (@tools) {

    $toolDisplay .=
      '<tr><td>' 
      . $labels[$type] 
      . '</td><td>'
      . &hashToSelect( "ct${type}", $const[$type], $item->{$type} || '',
         '', 'null' )
      . '</td></tr>';
  }

  my $onLoadJs = "";

  my $tabContent = '';

  $tabContent .= <<END_HERE;
    <div class="stem">
      <div><strong>Item Body</strong></div> 
        <textarea style="display:none;" id="mixedStem" name="mixedStem" rows="6" cols="30">${stemText}</textarea>
          <textarea style="display:none;" id="mixedStemCompare" name="mixedStemCompare" rows="6" cols="30">${compareText}</textarea> 
      <script>
      <!--

        function convertEntities (str_in) {
          /*[\\u00A0-\\u00FF\\u2022-\\u2135] */
          var str_out = str_in.replace(/[\\u00A0-\\u2900]/g, function (c) {
                                     return '&#' + c.charCodeAt(0) + ';';
                        });
          //alert(str_out);
          return str_out;
        }

        // modifying to use edit-on-NG, will have commented edit-on-Pro code above each line

        var oEdit = new eongApplication(defaultEditorWidth,defaultEditorHeight,"myEditor","myEditor","oEdit");
        oEdit.setCodebase("${commonUrl}eong3/lib/bin");
        oEdit.clearUserPreferences();
        oEdit.clearUserStyles();

        oEdit.setUIConfigURL("${commonUrl}eong3/lib/config/uiconfig-item-body.json");
        oEdit.setConfigURL("${commonUrl}eong3/lib/config/config.json");
        oEdit.setActionExtensionURL("${commonUrl}eong3/extension/actionmap-item-body.ext.json");
        oEdit.setContentCaching(false);

        oEdit.addUserStylesFromURL("${orcaUrl}style/item-style.css");
        oEdit.addUserStylesFromURL("${commonUrl}eong3/lib/css/custom.css");
	if(cssStylesheet != '') {
	  oEdit.addUserStylesFromURL(cssStylesheet);
	}

        oEdit.setUserAttributes("Username","$user->{userName}");

	oEdit.registerEventHandler('ONEDITORLOADED', 'showEditor');

        oEdit.invokeAction("live-document-language", "$locale_code");

        var oEditPartName = "Stem";

	function showEditor(editorObj) {
             jQuery("#myEditor").css("position", "").css("left", "");
             jQuery("#spinner").css("display", "none");

END_HERE
  if($doCompare) {

    $tabContent .= <<HTML;
    compareDocuments(editorObj);
    //window.location.hash='myEditor_tab_panel_Track';
HTML
  } 
  $tabContent .= "\n}\n";

  warn "3:[doCompare:$doCompare]";
  warn "3:[canCompare:$canCompare]";
  if ( $canCompare  || $doCompare ) {
    $tabContent .= <<END_HERE;

        function localCompareDocuments(editorObj) {

           document.itemCreate.mixedStem.value = editorObj.getBodyFragment();

           if(document.itemCreate.mixedStemCompare.value == document.itemCreate.mixedStem.value) {
           
             //alert('Content matches original.');

           } else if(document.itemCreate.mixedStemCompare.value != '' &&
                   document.itemCreate.mixedStem.value != '') {

             editorObj.compareDocumentsFromContent(
                compareHeader + document.itemCreate.mixedStemCompare.value + compareFooter,
                compareHeader + document.itemCreate.mixedStem.value + compareFooter);

             editorObj.invokeAction("show-changes-inline-diff");

           } else {

             alert('Comparison content not available.');
           }

        }

END_HERE
  }

  $tabContent .= <<END_HERE;
   oEdit.setBodyFragment(document.itemCreate.mixedStem.value);
   oEdit.registerEventHandler('ONCHARACTERCOUNTCHANGED', 'editorChangedEvent');
END_HERE

  $onLoadFunction .= "oEdit.loadEditor();\n";

  $tabContent .= <<END_HERE;
      //-->  
      </script>
      <div id="spinner"><img src="${commonUrl}images/LoadingProgressBar.gif" /></div>
      <div id="myEditor" style="position: absolute; left: -10000px;"></div>
  </div>
END_HERE

  my $gleHtml = '';
  if ( exists $gle->{name} ) {
     $gleHtml =
'<table class="no-style" border="0" width="320px" cellpadding="1" cellspacing="1"><tr><th style="font-size:10pt;text-align:left;">'
      . $gle->{name}
      . '</th></tr><tr><td style="font-size:10pt;">'
      . $gle->{text}
      . '</td><tr></table>';

  }

  my $rejectionReport1Row = '';
  if (
        -e "${orcaPath}workflow/rejection-report/state-1/${itemId}.html"
      )
  {
     $rejectionReport1Row =
"<tr><td colspan=\"2\"><a href=\"${orcaUrl}cgi-bin/itemRejectionReport.pl?myAction=get&itemBankId=${ibankId}&itemId=${itemId}&rejectState=1\" target=\"_blank\">Content Review Rejection Report</a></td></tr>";
  }

  my $rejectionReport9Row = '';
  if (
        -e "${orcaPath}workflow/rejection-report/state-9/${itemId}.html"
      )
  {
        $rejectionReport9Row =
"<tr><td colspan=\"2\"><a href=\"${orcaUrl}cgi-bin/itemRejectionReport.pl?myAction=get&itemBankId=${ibankId}&itemId=${itemId}&rejectState=9\" target=\"_blank\">Client Review Rejection Report</a></td></tr>";
  }

  my $artRequestRow = '';
    #if ( -e "${orcaPath}workflow/art-request/${itemId}.html" )
    #{
    #    $artRequestRow =
#"<tr><td colspan=\"2\"><a href=\"${orcaUrl}cgi-bin/itemArtRequest.pl?myAction=get&itemBankId=${ibankId}&itemId=${itemId}\" target=\"_blank\">Art Request Form</a></td></tr>";
#    }

  # Print Main document
  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Item Editor</title>
        <link rel="stylesheet" href="${commonUrl}style/tabber.css" type="text/css" media="screen" />
        <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
        <link rel="stylesheet" href="${orcaUrl}style/text.css" type="text/css" />
      <style type="text/css">

        div.stem { margin-top:7px; }

            div.choice { margin-top:7px; }

        </style>
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
      var defaultEditorHeight = 470;
      var defaultEditorWidth = 530;
      var largeEditorHeight = 680;
      var interactionFrameIsOpen = 0;

      var compareHeader = "<html><head><title>title</title></head><body>";
      var compareFooter = "</body></html>";

      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
    return true; 
      }

      function openGraphicWindow(editorObj) {
        tmpEditorObj = editorObj;   
    myOpen('insertGraphicWin','${orcaUrl}cgi-bin/assetInsert.pl?itemBankId=${ibankId}&itemId=${itemId}&itemExternalId=${externalId}&version=${version}',400,500);
      } 

      function openInteractionWindow(editorObj) {
        tmpEditorObj = editorObj;   
    myOpen('insertInteractionWin','${orcaUrl}cgi-bin/interactionInsert.pl?itemId=${itemId}',400,400);
      } 

     // hash used to track changes to content by editor
     var editorContent = {};

     function editorChangedEvent(editorRef, charCount) {
       var fragLabel = eval(editorRef.Helper.jsObjName+"PartName");

       var fragContent = editorRef.getBodyFragment();

       // check, does editor contain any media asset tags?
       var fragContainsMedia = (jQuery(fragContent).filter("div[class^=orca:media:]").length || 
                                jQuery(fragContent).find("div[class^=orca:media:]").length);

       if (${debug}) alert("Fragment contains media: " + fragContainsMedia);

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


      var tabberOptions = {
        'onClick' : function(argsObj) {
          var t = argsObj.tabber;
          var id=t.id;
          var i=argsObj.index;

          if(id == 'tabMain') {
            if(document.itemCreate.itemId.value == '') {
              return false;
            }
          }

          if(id == 'tabMain' && i==2) {
            // User clicked the Create Graphic tab
            if('$params->{readOnly}' == '1') {
              return false;
            }
          } 

	  if(id == 'tabMain' && i==1 && interactionFrameIsOpen == 0) {
	    // User clicked the Interactions tab
	    parent.rightFrame.interactionFrame.location.href='${orcaUrl}cgi-bin/interactionCreate.pl?itemId=${itemId}';
	    interactionFrameIsOpen = 1;
          }

          if(id == 'tabMain' && i==2) {
            // User clicked the Create Graphic tab
            parent.rightFrame.graphicFrame.location.href='${assetCreateFramesetUrl}?itemBankId=${ibankId}&itemId=${externalId}&version=${version}'; 
          }

          if(id == 'tabMain' && i==4) {
            // User clicked the Imported Data tab
           parent.rightFrame.importedDataFrame.location.href='${javaUrl}ItemMetadata.jsf?item=${itemId}'; 
          }

        if(id == 'tabMain' && i==5) {
       // User clicked the Notes tab
       parent.rightFrame.notesFrame.location.href='${orcaUrl}cgi-bin/itemNotes.pl?itemId=${itemId}'; 
      }
        
        if(id == 'tabMain' && i==6) {
       // User clicked the History tab
       parent.rightFrame.historyFrame.location.href='${orcaUrl}cgi-bin/itemHistory.pl?itemId=${itemId}'; 
      }
        
      if(id == 'tabMain' && i==7) {
          // User clicked the Publication History tab
          parent.rightFrame.publicationFrame.location.href='${orcaUrl}cgi-bin/cde.pl?action=displayPublicationHistory&item_id=${itemId}&instance_name=$instance_name'; 
      }

      if(id == 'tabMain' && i==8) {
       // User clicked the Rendering tab
       parent.rightFrame.renderingFrame.location.href = '${javaUrl}ItemAlternate.jsf?itemId=${itemId}';
      }
      if(id == 'tabMain' && i==9) {
       // User clicked the Preview tab
       updateHtmlBody(); 
       document.itemCreate.target = 'previewFrame'; 
       document.itemCreate.action = '${orcaUrl}cgi-bin/itemPreview.pl';
       document.itemCreate.submit();
      }

    },

    'addLinkId' : true,
    'manualStartup' : true
      };

      function updateHtmlBody() {
        if(typeof(window['oEdit']) != 'undefined' && oEdit.getObj() && oEdit.getBodyFragment() != '') { 
	    document.itemCreate.mixedStem.value = convertEntities(oEdit.getBodyFragment()); 
	} 
      }

      function doCreateSubmit() {
        document.itemCreate.target = '_self';
    document.itemCreate.action = '${thisUrl}';
        document.itemCreate.myAction.value = 'create';
    document.itemCreate.submit();
      }
      
      function doEditSubmit() {
        document.itemCreate.target = '_self';
    document.itemCreate.action = '${thisUrl}';
        document.itemCreate.myAction.value = 'edit';
    document.itemCreate.submit();
      }

    function doQuitSubmit() {
        if(document.itemCreate.furl.value != '') {
            document.location.href=document.itemCreate.furl.value;
        }
        else {
            document.location.href= 'items_manager.pl?instance_name=$instance_name&ib_id=$in{itemBankId}';
        }
     }

END_HERE
  warn "7:[canCompare:$canCompare]";
  warn "7:[doCompare:$doCompare]";

  if($canCompare || $doCompare) {

    $psgi_out .= <<END_HERE;

     function compareDocuments(editorObj) {

       localCompareDocuments(editorObj);

     }
END_HERE
  } else {
    $psgi_out .= <<END_HERE;

     function compareDocuments(editorObj) {
       //alert('Comparison mode is disabled for this workflow state.');
     }
END_HERE
  }
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
        //editorObj.pumpEvents();
            }

            function addItemNotesText(text) {
              document.itemCreate.itemNotes.value = document.itemCreate.itemNotes.value + text;
      }
    
    function compareGradeSpan(f, ct) {
        var gs_start;
        var gs_end;
        if( ct.name == 'ct5' ) {
        gs_start = ct.text;
            gs_end   = f.ct6.options[f.ct6.selectedIndex].text;
        }
        else {
            gs_start = f.ct5.options[f.ct5.selectedIndex].text;
        gs_end   = ct.text;
        }

        if( gs_start == '' || gs_end == '' ) return;
        if( gs_start == '-' || gs_end == '-' ) return;

        if( f.ct5.selectedIndex >= f.ct6.selectedIndex ) {
        alert( 'Grade Span End must be greater than Grade Span Start!' );
        ct.selectedIndex = 0;
        ct.focus();
        }
    }
    //-->
    </script>
        <script type="text/javascript" src="${commonUrl}js/tabber.js"></script>
        <script src="${commonUrl}js/calendar/cal2.js" type="text/javascript"></script>
    <script language="javascript">
    addCalendar("calendar1", "Select Date", "dueDate", "itemCreate");
    setWidth(90, 1, 15, 1);
    setFormat("yyyy-mm-dd");
    </script>

    </head>
  <body onLoad="${onLoadJs}">
    <form name="itemCreate" action="${thisUrl}" method="POST">
      <input type="hidden" name="myAction" value="" />
      
      <input type="hidden" name="version" value="${version}" />
      <input type="hidden" name="adminMode" value="${adminMode}" />
      <input type="hidden" name="stems" value=${stems}" />
            ${hiddenFields}
    <table class="no-style" width="100%" border="0" cellspacing="3" cellpadding="2">
      <tr>
        <td align="left">${title}&#160;&#160;&#160;&#160;<a href="#" onClick="myOpen('printWin','${orcaUrl}cgi-bin/itemPrintList.pl?viewType=4&myAction=print&autoPrint=1&itemBankId=$item->{bankId}&itemExternalId=$item->{name}&view_itemId=1&view_itemContent=1',600,600);">Print Item</a>
END_HERE


  $psgi_out .= <<END_HERE;
          ${readOnlyWarn}
                ${msg}</td>
  <td align="center">${gleHtml}</td>    
    <td align="right">
    &#160;
    <input type="hidden" name="externalId" value="${externalId}" />
    <input type="hidden" name="itemBankId" value="${ibankId}" />
    <br /><br />
    </td>
      </tr> 
      <tr> 
      </tr> 
    </table>
    <div class="tabber" id="tabMain" style="margin-top:-9px;">
      <div class="tabbertab" title="Content">
	 <table class="no-style" border="0" cellpadding="2" cellspacing="2">
       <tr>
         <td valign="top" style="vertical-align:top;">
           ${tabContent}
	   <br />
           <table class="no-style" border="0" cellpadding="2" cellspacing="2">	    
             <tr>
               <td>Notes:</td>
               <td><textarea name="itemNotes" rows="6" cols="53">${notes}</textarea></td>
             </tr>
           </table>
         </td> 
         <td style="width:10px;">&#160;</td>
             <td valign="top">
           <table class="no-style" border="0" cellspacing="2" cellpadding="2">
             <tr><td style="width:65px;">&#160;</td>
             <td style="width:300px;">&#160;</td> 
         </tr>
             <tr>
           <td style="width:60px;">Files:</td>
           
END_HERE

  unless ( $params->{readOnly} ) {
        $psgi_out .= <<END_HERE;
    <td style="text-align:left;">
    <input type="button" onClick="myOpen('assetUploadWindow','${assetUploadUrl}?itemBankId=${ibankId}&itemId=${itemId}&itemExternalId=${externalId}&version=${version}',550,450);" value="Upload Images" style="width:140px;" />
    <tr><td/>
END_HERE
  }

  $psgi_out .= <<END_HERE;
    <td style="text-align:left;">
    <input type="button" onClick="myOpen('itemMetafileWindow','${orcaUrl}cgi-bin/itemMetafiles.pl?itemId=${itemId}',600,550);" value="View Metafiles" style="width:140px;" />
        &#160;&#160;
           </td>
         </tr>
	  <tr><td/>
	  <td style="text-align:left;">
         <input type="button" onClick="myOpen('programMetafilesWindow','${javaUrl}IBMetafilesView.jsf?item=${itemId}',750,450);" value="Program Metafiles" style="width:140px;" />


END_HERE

  if ( $in{outdated} eq "Y" ) {
    $psgi_out .= <<END_HERE;
<tr><td>Note:</td><td><span style="color: red">This Item has outdated Program Metafiles</span>
END_HERE
  }

  my $enemyWarning = (scalar @{$item->{enemies}}) ? '*' : '';

  $psgi_out .= <<END_HERE;

         <tr><td colspan="2">&#160;</td></tr>
             <tr>
           <td>Assign:</td>
           <td>
    <input type="button" onClick="myOpen('assignStandardWindow','${assignStandardUrl}?itemId=${itemId}',594,480);" value="Standard" />
          &#160;&#160; 
    <input type="button" onClick="myOpen('assignPassageWindow','${assignPassageUrl}?itemId=${itemId}&itemBankId=${ibankId}',500,480);" value="Passage" />
          &#160;&#160;
    <input type="button" onClick="myOpen('assignRubricWindow','${assignRubricUrl}?itemId=${itemId}&itemBankId=${ibankId}',500,480);" value="Rubric" />
          &#160;&#160;
    <input type="button" onClick="myOpen('assignEnemyWindow','${orcaUrl}cgi-bin/itemAssignEnemy.pl?itemId=${itemId}',500,480);" value="Enemy" />${enemyWarning}
           </td>
         </tr>
         <tr><td colspan="2">&#160;</td></tr>
END_HERE

    $psgi_out .= '<tr><td colspan="2">' . &getMediaTableHtml($mediaAssets, 1, $ibankId, $itemId, $externalId, $version) . '</td></tr>';
    $psgi_out .= '<tr><td colspan="2">&#160;</td></tr>';

    $psgi_out .= <<END_HERE;
         <tr>
           <th style="text-align:left;" colspan="2">Math Tools:</th>
                 </tr>
         ${toolDisplay}
         <tr><td colspan="2">&#160;</td></tr>
END_HERE

    foreach ( keys %itemNotesTag ) {
        $psgi_out .= <<END_HERE;
         <tr>
           <td align="right"><input type="button" value="&gt;" width="6" onClick="addItemNotesText('$itemNotesTag{$_}');" /></td>
             <td>$_</td>
         </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
       </table>
       </td>
     </tr>
     </table>
      </div>
      <div class="tabbertab" title="Interactions">
       <iframe name="interactionFrame" id="interactionFrame" width="97%" height="500" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Create Interactions</iframe> 
      </div>

      <div class="tabbertab" title="Create Graphic">
       <iframe name="graphicFrame" id="graphicFrame" width="97%" height="500" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Create Graphic</iframe> 
      </div>
      <div class="tabbertab" title="Metadata">
    <table class="no-style" border="0" cellspacing="3" cellpadding="3"><tr>
    <td style="align:left; vertical-align:top;">
    <table class="no-style" border="0" cellspacing="3" cellpadding="3">
      <tr>
        <td><span style="color:red;">Description:</span></td>
    <td><input type="text" size="42" name="itemDescription" value="${descrip}" /></td>
      </tr>
      <tr>
        <td>Item Format:</td>
        <td>${itemFormatDisplay}</td>
      </tr>   
      <tr>
        <td><span style="color:red;">Difficulty:</span></td>
    <td>${difficultyDisplay}</td>
      </tr>
      ${charDisplay}
   </table>
   </td>
   <td style="width:8px;">&#160;</td>
   <td style="align:right; vertical-align:top;">
    <table class="no-style" border="0" cellspacing="3" cellpadding="3">
      <tr>
        <td>Publication Status:</td>
    <td>${publicationStatusDisplay}</td>
      </tr>
      <tr>
        <td>Dev State:</td>
    <td>$display{itemDevState}</td>
      </tr>
      <tr>
        <td><span style="color:red;">Assigned Writer:</span></td>
    <td>$display{assignedEditor}</td>
      </tr>
            <tr>
              <td>Source Document:</td>
                <td><input type="text" name="sourceDocument" size="30" value="${sourceDocument}" /></td>
            </tr>   
      <tr>
        <td>Language:</td>
    <td>${languageDisplay}</td>
      </tr>
      <tr>
        <td>Due Date:</td>
    <td>
       <input type="text" id="dueDate" name="dueDate" size="11" value="$due_date" />
           &#160;<a href="javascript:showCal('calendar1')">Select Date</a>
       <div id="calendar1"></div>
    </td>
      </tr>
      <tr>
        <td>Readability Index:</td>
    <td><input type="text" name="readability_index" size="30" value="${readability_index}" /></td>
      </tr>
            ${rejectionReport1Row}
            ${rejectionReport9Row}
            ${artRequestRow}
            <tr><td colspan="2">&#160;</td></tr>
            <tr><td colspan="2"><span style="color:red;">Red label</span> = required field</td></tr>
    </table> 
   </td>
   </tr></table>
      </div>
            <div class="tabbertab" title="Imported Data">
              <iframe name="importedDataFrame" id="importedDataFrame" width="97%" height="600" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Item Notes</iframe>
            </div>
            <div class="tabbertab" title="Notes">
              <iframe name="notesFrame" id="notesFrame" width="97%" height="390" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Item Notes</iframe>
            </div>
            <div class="tabbertab" title="History">
              <iframe name="historyFrame" id="historyFrame" width="97%" height="390" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Item History</iframe>
            </div>
            <div class="tabbertab" title="Publication History">
              <iframe name="publicationFrame" id="publicationFrame" width="97%" height="390" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Publication History</iframe>
            </div>
      <div class="tabbertab" title="Rendering">
       <iframe name="renderingFrame" id="renderingFrame" width="97%" height="600" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Rendering</iframe>
      </div>
      <div class="tabbertab" title="Preview">
       <iframe name="previewFrame" id="previewFrame" width="97%" height="600" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Item Preview</iframe>
      </div>
    </div>
    <script type="text/javascript">
    <!--
      tabberAutomatic(tabberOptions); 

      window.onload = function () {

        ${onLoadFunction}
      }
    //-->
    </script>
     <input type="hidden" name="itemId" value="${itemId}" />
     <input type="hidden" name="furl" value="${furl}" />
   </form>
  </body>
</html>         
END_HERE

  my $diff = Time::HiRes::tv_interval($start_time);
  warn "Edit Item loaded in $diff\n";

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
