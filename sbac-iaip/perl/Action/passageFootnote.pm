package Action::passageFootnote;

use ItemConstants;
use Passage;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $this_url = "${orcaUrl}cgi-bin/passageFootnote.pl";
  
  our $doCompare = ( exists( $in{doCompare} ) && $in{doCompare} ? 1 : 0 );
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  our $psg   = new Passage( $dbh, $in{passageId} );
  
  our $itemBankName = $banks->{ $psg->{bank} }{name};
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq 'save' ) {
  
      my %footnotes = ();
  
      #
      # Set up the %footnotes hash
      #
      foreach my $fkey ( grep { /footnoteText/ } keys %in ) {
          $fkey =~ m/footnoteText(\d+)/;
          next unless $1;
          my $fId = $1;
          $footnotes{$fId} = $in{$fkey};
      }
  
      $psg->setFootnotes( \%footnotes );
      $psg->save();
  
      $in{message} = 'Footnotes Saved.';
  }
  
  our $footnotes = $psg->getFootnotes();
  our %fnCompare = $psg->getCompareFootnotes();
  
  our $content = $in{htmlContent};
  
  while ( $content =~ m/<sup>\[(\d+)\]<\/sup>/ ) {
      $footnotes->{$1} = '' unless exists $footnotes->{$1};
      $content =~ s/<sup>\[\d+\]<\/sup>//s;
  }

  return [ $q->psgi_header('text/html'), [ &print_show_footnotes(\%in) ]];
}
### ALL DONE! ###

sub print_show_footnotes {
  my $psgi_out = '';

    my $params = shift;

    my $passageId = $params->{passageId};
    my $msg       = (
        exists $params->{message}
        ? '<ul><li>' . $params->{message} . '</li></ul>'
        : '' );

    my $onReadyFunction = '';

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Passage Footnotes</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
	<script language="JavaScript" src="${commonUrl}eong3/lib/js/jquery/jquery.min.js"></script>
	<script language="JavaScript" src="${commonUrl}eong3/lib/js/edit-on-ng.js"></script>
	<link rel="stylesheet" type="text/css" media="screen" href="${commonUrl}eong3/lib/css/edit-on-ng.css" />
    <script language="JavaScript">
		<!--

		  var tmpEditorObj;
          var compareHeader = "<html><head><title>title</title></head><body>";
          var compareFooter = "</body></html>";

END_HERE

    if($doCompare) {

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

    $psgi_out .= <<END_HERE;

        function convertEntities (str_in) {
          /*[\\u00A0-\\u00FF\\u2022-\\u2135] */
          var str_out = str_in.replace(/[\\u00A0-\\u2900]/g, function (c) {
                                     return '&#' + c.charCodeAt(0) + ';';
                        });
          //alert(str_out);
          return str_out;
        }

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
      
	    function doSaveSubmit() {
END_HERE

    foreach my $key ( keys %{$footnotes} ) {
        $psgi_out .=
"      document.footnotes.footnoteText${key}.value = convertEntities(oEdit${key}.getBodyFragment());\n";
    }

    $psgi_out .= <<END_HERE;
	      document.footnotes.submit();
			}
    -->
		</script>
	</head>
  <body>
    <div class="title">Passage Footnotes</div>
    ${msg} 
    <form name="footnotes" action="${this_url}" method="POST">
      <input type="hidden" name="passageId" value="${passageId}" />
      <input type="hidden" name="doCompare" value="${doCompare}" />
			<textarea name="htmlContent" style="display:none;">$params->{htmlContent}</textarea>
      <input type="hidden" name="myAction" value="save" />
    <table border="1" cellpadding="2" cellspacing="2">
		  <tr>
			  <td>Num</td><td align="center">Footnote Text</td>
			</tr>
END_HERE

    foreach my $key ( sort { $a <=> $b } keys %{$footnotes} ) {

        $fnCompare{$key} = $footnotes->{$key} unless exists $fnCompare{$key};

        $footnotes->{$key} = $q->escapeHTML( $footnotes->{$key} );
        $fnCompare{$key} = $q->escapeHTML( $fnCompare{$key} );

        $psgi_out .= <<END_HERE;
		  <tr>
			  <td>${key}</td>
			  <td>
    <textarea style="display:none;" id="footnoteText${key}" name="footnoteText${key}" rows="6" cols="30">$footnotes->{$key}</textarea>
    <textarea style="display:none;" id="footnoteTextCompare${key}" name="footnoteTextCompare${key}" rows="6" cols="30">$fnCompare{$key}</textarea>
    <script>
    <!--
	    var oEdit${key} = new eongApplication(560,360,"myEditor${key}","myEditor${key}","oEdit${key}");
      oEdit${key}.setCodebase("${commonUrl}eong3/lib/bin");
	   oEdit${key}.clearUserPreferences();
	   oEdit${key}.clearUserStyles();
	   oEdit${key}.setUIConfigURL("${commonUrl}eong3/lib/config/uiconfig.json");
	   oEdit${key}.setConfigURL("${commonUrl}eong3/lib/config/config.json");
	   oEdit${key}.setActionExtensionURL("${commonUrl}eong3/extension/actionmap.ext.json");
	   oEdit${key}.setContentCaching(false);
	   oEdit${key}.addUserStylesFromURL("${orcaUrl}style/item-style.css");
	   oEdit${key}.addUserStylesFromURL("${commonUrl}eong3/lib/css/custom.css");
           oEdit${key}.setUserAttributes("Username","$user->{userName}");

        function localCompareDocuments${key}() {

		   document.footnotes.foonteText${key}.value = oEdit${key}.getBodyFragment();

           if(document.footnotes.footnoteTextCompare${key}.value == document.footnotes.footnoteText${key}.value) {
           
             //alert('Content matches original.');

           } else if(document.footnotes.footnoteTextCompare${key}.value != '' &&
                   document.footnotes.footnoteText${key}.value != '') {

		     oEdit${key}.compareDocumentsFromContent(
		        compareHeader + document.footnotes.footnoteTextCompare${key}.value + compareFooter,
			    compareHeader + document.footnotes.footnoteText${key}.value + compareFooter);

	         oEdit${key}.invokeAction("show-changes-inline-diff");

           } else {

             //alert('Comparison content not available.');
           }

        }

        oEdit${key}.Helper.jsObj.localCompareDocuments = localCompareDocuments${key};
END_HERE

        if ( $doCompare && $footnotes->{$key} ne '' ) {
            $psgi_out .= <<END_HERE;
            oEdit${key}.registerEventHandler('ONEDITORLOADED', 'localCompareDocuments${key}');
END_HERE
        }
        else {
            $psgi_out .= <<END_HERE;
		  oEdit${key}.setBodyFragment(document.footnotes.footnoteText${key}.value);
END_HERE
        }

        $onReadyFunction .= "oEdit${key}.loadEditor();\n";

        $psgi_out .= <<END_HERE;
    //-->
    </script>
    <div id="myEditor${key}"></div>
		  </td>
		</tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    </table>
    <script type="text/javascript">
    <!--

      window.onload = function () {

        ${onReadyFunction}
      }
    //-->
    </script>
		<br />
		<input type="button" value="Save Footnotes" onClick="doSaveSubmit();" />
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
