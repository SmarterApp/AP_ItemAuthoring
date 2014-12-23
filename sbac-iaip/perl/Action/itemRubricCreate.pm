package Action::itemRubricCreate;

use URI;
use ItemConstants;
use Rubric;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/itemRubricCreate.pl";
  
  our @flags = ();
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};
  
  $in{myAction} = '' unless exists $in{myAction};
  
  unless ( defined( $in{rname} ) && $in{rname} ne '' ) {

    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  if ( $in{myAction} eq 'create' ) {
  
  }
  elsif ( $in{myAction} eq 'save' ) {
  
      my $rubric = new Rubric( $dbh, $in{rid} );
      $rubric->setSummary( $in{description} );
      $rubric->setContentArea( $in{contentArea} );
      $rubric->setGradeLevel( $in{gradeLevel} );
  
      $in{rubricText} =~ s/&amp;#/&#/g;
      $rubric->setContent( $in{rubricText} );
  
      if ( $rubric->save() ) {
          $in{message} = "Rubric '$in{rname}' Saved.";
      }
      else {
          $in{message} = "Rubric '$in{rname}' does not exist. Unable to Save.";
      }
  
      if ( $in{furl} ne '' ) {

        my $psgi_out = <<END_HERE;
                            <!DOCTYPE HTML>
                            <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
                            <head>
                                    <script language="JavaScript">
                                            function loadUrl() {
                                                    document.location.href='$in{furl}';
                                                  }
                                          </script>
                                  </head>
                                  <body onLoad="loadUrl();">
                                  </body>
                          </html>
END_HERE
        return [ $q->psgi_header('text/html'), [ $psgi_out ]]; 
      }
  }

  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
}
### ALL DONE! ###

sub print_welcome {

    my $params = shift;

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;
    my $itemBankName = $banks->{$in{itemBankId}}{name};

    my $itemBankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $in{itemBankId}, '', '' );

    my $itemBankDisplay2 =
      &hashToSelect( 'itemBankId', \%itemBanks, $in{itemBankId}, '', '', '', ' ' );

    my $rubric;

    if($in{myAction} eq 'create') {

      $rubric = new Rubric($dbh);

      unless ( $rubric->create( $in{itemBankId}, $in{rname} ) ) {
        $params->{message} = "Rubric '$in{rname}' exists. Please choose a new name.";
      }

    } else {

      if($params->{rname} ne '' ) {
        $rubric = new Rubric( $dbh, $in{itemBankId}, $params->{rname} );
      } else {
        $rubric = new Rubric($dbh);
      }

      if ( $in{myAction} eq 'edit' && $rubric->{id} == 0 ) {
        $params->{message} = "Rubric '$params->{rname}' not found.";
      }
    }

    my $rid         = $rubric->{id}              ? $rubric->{id}      : '0';
    my $rname       = $rubric->{id}              ? $rubric->{name}    : "";
    my $furl        = defined( $params->{furl} ) ? $params->{furl}    : "";
    my $description = $rubric->{id}              ? $rubric->{summary} : "";
    my $rubricText =
      $rubric->{id} ? $q->escapeHTML( $rubric->{content} ) : "";

     
    my $msg = (!defined( $params->{message} ) || $params->{message} eq '')
        ? ''
        : '<br /><span style="margin-top:3px;font-size:13pt;color:red;">'
          . $in{message}
          . '</span><br />';

    my $title =
        '<span class="title">Create Rubric:&#160;&#160;' 
      . '<b>' . $rname . '</b>&#160;&#160;&lt;' . $itemBankName . '&gt;'
      . '</span>&#160;&#160;' . $msg;

    my $gradeLevel = $rubric->{id} ? $rubric->{gradeLevel} : '';
    my $gradeLevelList =
      &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], $gradeLevel, '',
        '' );

    my $contentArea = $rubric->{id} ? $rubric->{contentArea} : '';
    my $contentAreaList =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        $contentArea, '', '0' );

    return <<END_HERE;
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Create Rubric</title>
    <link href="${commonUrl}style/text.css" rel="stylesheet" type="text/css" />
    <link href="${commonUrl}style/tabber.css" rel="stylesheet" type="text/css" />
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css" />
    <script language="JavaScript" src="${commonUrl}eong3/lib/js/jquery/jquery.min.js"></script>
    <script language="JavaScript" src="${commonUrl}eong3/lib/js/edit-on-ng.js"></script>
    <link rel="stylesheet" type="text/css" media="screen" href="${commonUrl}eong3/lib/css/edit-on-ng.css" />
    <link rel="stylesheet" type="text/css" media="screen" href="${commonUrl}style/modal.css" />
    <script language="JavaScript">
    <!--

      \$(document).ready(function() {

          // create prompt for passage name if needed
          if(document.createRubric.rid.value == '0') {
            modalToggle();
          } 
      });

      function modalToggle() {
        el = document.getElementById("modal");
        el.style.visibility = (el.style.visibility == "visible") ? "hidden" : "visible";
      }

      var tmpEditorObj;
      
      function mySubmit()
      {
        document.createRubric.submit();
        return true; 
      }
      
      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(350,150); 
        return true; 
      }

      function openGraphicWindow(editorObj) {
        tmpEditorObj = editorObj;
        myOpen('insertGraphicWin','${rubricInsertAssetUrl}?itemBankId=$in{itemBankId}&rubricId=${rid}',400,500);
      }

      function doCreateSubmit(itemBank, rubricName) {
        document.createRubric.itemBankId.value = itemBank;
        document.createRubric.rname.value = rubricName;
        document.createRubric.myAction.value = 'create';
        document.createRubric.submit();
      }
      function doEditSubmit(itemBank, rubricName) {
        document.createRubric.itemBankId.value = itemBank;
        document.createRubric.rname.value = rubricName;
        document.createRubric.myAction.value = 'edit';
        document.createRubric.submit();
      }

      function doSaveSubmit() {
        document.createRubric.myAction.value = 'save';
        document.createRubric.rubricText.value = convertEntities(oEdit1.getBodyFragment());
        document.createRubric.submit();
        return true;
      }

      var tabberOptions = {
     
         'manualStartup':true,
         'addLinkId':true,
     
         'onClick': function(argsObj) {
         
           var t = argsObj.tabber;
           var id = t.id;
           var i = argsObj.index;

           if(id=='tabMain') {
             if(document.createRubric.rid.value == '') {
               return false;
             }
           }

     if(id=='tabMain' && i==2) {
                   document.templateFrame.location.href='${orcaUrl}cgi-bin/itemRubricTemplate.pl';
                 }       

           if(id=='tabMain' && i==3) {
             document.getElementById('prerubric').innerHTML = convertEntities(oEdit1.getBodyFragment()); 
           }


         }

      };

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
                editorObj.resizeEditor(defaultEditorWidth,largeEditorHeight);
        } else { 
                  editorObj.resizeEditor(defaultEditorWidth,defaultEditorHeight);
        }
            }



    //-->
    </script>
    <script language="JavaScript" src="${commonUrl}js/tabber.js"></script>
  </head>
  <body>
    <div id="modal">
        <div>
	  ${msg}
	  <p>Enter a Rubric name to Create or Edit:</p>
          <form name="modalForm">
          <table class="no-style" border="0" cellspacing="2" cellpadding="2">
            <tr>
              <td>Program:</td>
                <td align="left">${itemBankDisplay2}</td>
                <td><input style="width:60px;" type="button" name="create" value="Create" 
                           onClick="doCreateSubmit(this.form.itemBankId.options[this.form.itemBankId.selectedIndex].value, this.form.rname.value);" /></td>
             </tr>
             <tr>
               <td>Name:</td>
               <td align="left"><input type="text" name="rname" value="${rname}" size="25" /></td>
               <td><input style="width:60px;" type="button" name="edit" value="Edit" 
                          onClick="doEditSubmit(this.form.itemBankId.options[this.form.itemBankId.selectedIndex].value, this.form.rname.value);" /></td> 
             </tr>
          </table>
          </form>
        </div>
    </div>
    <form name="createRubric" action="${thisUrl}" method="POST">
      <input type="hidden" name="rid" value="${rid}" />
      
      <input type="hidden" name="myAction" value="" /> 
      <input type="hidden" name="furl" value="${furl}" /> 
      <input type="hidden" name="rname" value="${rname}" />
      <input type="hidden" name="itemBankId" value="$in{itemBankId}" />
    <table width="98%" border="0" cellpadding="3" cellspacing="3" class="no-style">
      <tr>
        <td width="98%">
          <table width="100%" border="0" cellpadding="2" cellspacing="2" class="no-style">
            <tr>
              <td align="left">
                ${title}
              </td>
            </tr>
          </table>  
        </td>
      </tr>
      <tr>
        <td>
          <div class="tabber" id="tabMain" style="margin-top:0px;">
            <div class="tabbertab" title="Content">
            <table border="0" cellspacing="3" cellpadding="3" class="no-style"><tr><td>
    <textarea style="display:none;" id="rubricText" name="rubricText" rows="6" cols="30">${rubricText}</textarea>
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

	var oEdit1;

          if(document.createRubric.rid.value > '0') {
           
            var oEdit1 = new eongApplication(650, 460, "myEditor1", "myEditor1","oEdit1"); 
           oEdit1.setCodebase("${commonUrl}eong3/lib/bin");
           oEdit1.clearUserPreferences();
           oEdit1.clearUserStyles();
           oEdit1.setUIConfigURL("${commonUrl}eong3/lib/config/uiconfig.json");
           oEdit1.setConfigURL("${commonUrl}eong3/lib/config/config.json");
           oEdit1.setActionExtensionURL("${commonUrl}eong3/extension/actionmap.ext.json");
           oEdit1.setContentCaching(false);
           oEdit1.addUserStylesFromURL("${orcaUrl}style/item-style.css");
           oEdit1.addUserStylesFromURL("${commonUrl}eong3/lib/css/custom.css");
           oEdit1.setUserAttributes("Username","$user->{userName}");
           oEdit1.invokeAction("live-document-language", "en-US");
            oEdit1.setBodyFragment(document.createRubric.rubricText ? document.createRubric.rubricText.value : '');
	    oEdit1.registerEventHandler('ONEDITORLOADED', 'showEditor');
          }

	function showEditor() {
             jQuery("#myEditor1").css("position", "").css("left", "");
             jQuery("#spinner1").css("display", "none");
        }

    //-->
    </script>
    <div id="spinner1"><img src="${commonUrl}images/LoadingProgressBar.gif" /></div>
    <div id="myEditor1" style="position: absolute; left: -10000px;"></div>
    </td>
    <td style="width:10px;">&#160;</td>
    <td style="vertical-align:top;">
      <table border="0" cellpadding="3" cellspacing="3" class="no-style">
        <tr>
          <td>Assets:</td><td>
            <input type="button" onClick="myOpen('assetUploadWindow','${rubricUploadAssetUrl}?itemBankId=$in{itemBankId}&rubricId=${rid}',400,450);" value="Upload" />
          </td>
        </tr>
      </table>
    </td></tr></table>
            </div>
            <div class="tabbertab" title="Metadata">
    <table border="0" cellpadding="2" cellspacing="2" class="no-style">
    <tr><td style="align:left; vertical-align:top;">
    <table border="0" cellpadding="3" cellspacing="3" class="no-style">
      <tr><td><span >Content Area:</span></td><td>${contentAreaList}</td></tr>
      <tr><td><span >Grade Level:</span></td><td>${gradeLevelList}</td></tr>
      <tr><td><span >Description:</span></td><td><input type="text" name="description" size="35" value="${description}" /></td></tr>
    </table>
    </td>
    <td style="width:10px;">&#160;</td>
    <td style="align:right; vertical-align:top;">
      <table border="0" cellpadding="3" cellspacing="3" class="no-style">
      </table>
    </td></tr></table>
            </div>
                        <div class="tabbertab" title="Template">
                          <iframe name="templateFrame" id="templateFrame" width="96%" height="410" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Template</iframe>
                        </div>
            <div class="tabbertab" title="Preview">
            <table border="0" cellspacing="3" cellpadding="3" class="no-style"><tr><td>
             <div style="width:500px;" id="prerubric"></div> 
            </td> 
    <td style="width:10px;">&#160;</td>
    <td style="vertical-align:top;">
      <table border="0" cellpadding="3" cellspacing="3" class="no-style">
        <tr>
        <td>&#160;</td>
        </tr>
        <tr>
          <td>
            <input type="button" name="save" value="Save Rubric" onClick="doSaveSubmit();" /> 
          </td>
        </tr>
      </table>
    </td></tr></table>
         </div>
          </div>
        </td>
      </tr>
    </table>
    </form>
    <script type="text/javascript">
    <!--
      tabberAutomatic(tabberOptions); 

      window.onload = function () {

        if(document.createRubric.rid.value > '0') {
          oEdit1.loadEditor(); 
        }
      }
    //--> 
    </script>
  </body>
</html>
END_HERE
}
1;
