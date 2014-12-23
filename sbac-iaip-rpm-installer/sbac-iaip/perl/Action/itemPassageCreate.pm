package Action::itemPassageCreate;

use URI;
use ItemConstants;
use Passage;
use PassageMedia;
use PassageMediaTable qw(View_Mode Edit_Mode);
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/itemPassageCreate.pl";
  
  our %cross_ccs = (
      '0' => 'None',
      '1' => 'Science/Technology/Math',
      '2' => 'Social Studies',
      '3' => 'Fine Arts',
      '4' => 'Health/Physical Education'
  );
  
  our %char_ethnicities = (
      '0' => 'None',
      '1' => 'White',
      '2' => 'African-American',
      '3' => 'Native American',
      '4' => 'Asian-American',
      '5' => 'Mexican-American/Latino',
      '6' => 'Foreign'
  );
  
  our %char_genders = (
      '0' => 'None',
      '1' => 'Male',
      '2' => 'Female'
  );
  
  our %pd_templates = &preDefinedTemplates();
  
  our @flags = ();
  
  our $doCompare = ( exists( $in{doCompare} ) ? 1 : 0 );
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};
  
  our $editors = &getEditors($dbh, $in{itemBankId});
  
  our %editFieldPermission = (
      'developmentState'   => 1,
      'assignedWriter' => 1,
  );
  
  our %filteredDevStates =  map { $_ => $dev_states{$_} } grep { exists $dev_states{$_} } @dev_states_workflow_ordered_keys;
  
  our %fieldHash = (
      'developmentState'   => \%filteredDevStates,
      'assignedWriter' => $editors,
  );
  
  unless ( defined( $in{pname} ) && $in{pname} ne '' ) {
  
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  if ( $in{myAction} eq "create" ) {
 
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  elsif ( $in{myAction} eq "edit" ) {
  
    my $sql = "SELECT passage_has_outdated_metafiles(p_id) flag FROM passage WHERE p_id= (select p_id from passage where ib_id=$in{itemBankId} AND p_name = "
      . $dbh->quote( $in{pname} )
      . ")";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
  
    if ( my $row = $sth->fetchrow_hashref ) {
  
      $in{outdated} = $row->{flag};
    }
    else {
      $in{outdated} = '';
    }
 
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  elsif ( $in{myAction} eq 'save' ) {
  
    $in{code} = uc( $in{code} );
    
  
    my $psg = new Passage( $dbh, $in{pid} );
    $psg->setGenre( $in{genre} );
    $psg->setSubGenre( $in{subgenre} );
    $psg->setTopic( $in{topic} );
    $psg->setReadingLevel( $in{readingLevel} );
    $psg->setSummary( $in{summary} );
    $psg->setCrossCurriculum( $in{crossCurriculum} );
    $psg->setCharEthnicity( $in{charEthnicity} );
    $psg->setCharGender( $in{charGender} );
    if($in{passageNotes} eq ''){
    $psg->setNotes( $in{passageNote} );  
    }else{
    $psg->setNotes( $in{passageNotes} );    
    }
    $psg->setContentArea( $in{contentArea} );
    $psg->setGradeLevel( $in{gradeLevel} );
    $psg->setGradeSpanStart( $in{gradeSpanStart} );
    $psg->setGradeSpanEnd( $in{gradeSpanEnd} );
    $psg->setBody( $in{passageText} );
    $psg->setLanguage( $in{language} );
    $psg->setPublicationStatus( $in{publicationStatus} );
    $psg->setAuthor( $in{assignedWriter} );
    $psg->setDevState( $in{developmentState} );
    $psg->setReadabilityIndex( $in{readabilityIndex} );
    $psg->save('Create/Edit Passage', $user->{id}, 'Content Update' );
  
    $in{message} = "Passage Saved.";
    my $psgi_out = '';
  
    if ( $in{furl} eq '' or $in{message} =~ /Unable to Save/ ) {

      $psgi_out = &print_welcome( \%in );
    }
    else {
     &setPassageReviewState( $dbh, $in{pid}, $psg->{devState},
              $psg->{devState}, $user->{id});    
    
      $psgi_out = <<END_HERE;
    <html>
      <head><title>Passage Saved</title></head>
      <body onLoad="document.location.href='$in{furl}';">
      Passage Saved!
      </body>
     </html>
END_HERE
    }

    return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
}
### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    my $params = shift;
    my %value = ();
    my $hiddenFields = '';

    my $pname = exists( $params->{pname} ) ? $params->{pname} : '';
    my $itemBankName = $banks->{$in{itemBankId}}{name};

    my $psg;
#check iformat define or not
#if define use as it is otherwise assign  0
my $format=(defined( $in{iformat}))?$in{iformat}:0;

   
    if($in{myAction} eq 'create') {

      $psg = new Passage($dbh);

      unless ( $psg->create( $in{itemBankId}, $in{pname} ) ) {
        $in{message} = "Passage '$in{pname}' exists. Please choose a new name.";
      }
    } else {

      if( $pname ne '' ) {
        $psg = new Passage( $dbh, $in{itemBankId}, $pname );
      } else {
        $psg = new Passage($dbh);
      }

      if ( $pname ne '' && $psg->{name} eq '' ) {
        $in{message} = "Passage '${pname}' not found.";
      }
    }

    my $passageText = $q->escapeHTML( $psg->getBody() );
    my $compareText =
      $doCompare ? $q->escapeHTML( $psg->getCompareBody() ) : '';
    $doCompare = 0 if $compareText eq '';

    my $msg = (!defined( $params->{message} ) || $params->{message} eq '')
        ? ''
        : '<br /><span style="margin-top:3px;font-size:13pt;color:red;">'
          . $in{message}
          . '</span><br />';

    my $title =
        '<span class="title">Create Passage:&#160;&#160;' 
      . '<b>' . $psg->{name} . '</b>&#160;&#160;&lt;' . $itemBankName . '&gt;'
      . '</span>' . '&#160;&#160;' . $msg;
      
      if($in{iformat} == 5) {
$title .= <<END_HERE;        
	    	<input type="button" name="save" value="Save Passage" onClick="doSaveSubmit(this.form);" />
END_HERE
}

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $gradeLevelList =
      &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], $psg->{gradeLevel},
        '', '' );
    my $contentAreaList =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        $psg->{contentArea}, '', '0' );
    my $gradeSpanStartList = hashToSelect( 'gradeSpanStart', $const[$OC_GRADE_SPAN_START], $psg->{gradeSpanStart}, '', '');	
    my $gradeSpanEndList = hashToSelect( 'gradeSpanEnd', $const[$OC_GRADE_SPAN_END], $psg->{gradeSpanEnd}, '', '');	
    my $genreList = &hashToSelect( 'genre', \%genres, $psg->{genre}, '', '' );
    my $crossCurriculumList =
      &hashToSelect( 'crossCurriculum', \%cross_ccs, $psg->{crossCurriculum},
        '', '' );
    my $charEthnicityList =
      &hashToSelect( 'charEthnicity', \%char_ethnicities, $psg->{charEthnicity},
        '', '0' );
    my $charGenderList =
      &hashToSelect( 'charGender', \%char_genders, $psg->{charGender}, '', '' );
    my $itemBankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $psg->{bank} || $in{itemBankId}, '', '' );
    my $publicationStatusList =
      &hashToSelect( 'publicationStatus', \%publication_status,
        $psg->{publicationStatus}, '', 'null' );
    my $furl = ( defined $params->{furl} ? $params->{furl} : '' );
    my $readabilityIndex = $q->escapeHTML($psg->{readabilityIndex} || '');

    my $languageDisplay = &hashToSelect('language',\%languages, $psg->{language},'','');
    my $locale_code = $psg->{language} == 2 ? 'es-ES' : 'en-US';
    
    
    $value{assignedWriter} = $psg->{author} || 0;
    $value{developmentState} = $psg->{devState} || 1;

    # Use display (and editFieldPermission) hash to determine if field should be displayed read-only
    my %display = (
        'assignedWriter' => &hashToSelect(
            'assignedWriter',
            $fieldHash{'assignedWriter'},
            $value{'assignedWriter'},
            '', '0', 'value', 'width:205px;'
        ),
        'developmentState' => &hashToSelect(
            'developmentState', $fieldHash{'developmentState'},
            $value{'developmentState'}, '', '', 'value', 'width:205px;',
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


    my $mediaTable = new PassageMediaTable();
    my $passage_media = $mediaTable->find_media_for_passage($psg);

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Create Passage</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
    <link href="${commonUrl}style/tabber.css" rel="stylesheet" type="text/css" />
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css" />
    @{[$mediaTable->get_style_library_includes()]}
    <style>
	.action_button {
        	font-family: Verdana;
        	font-size: 12px;
        	height:22px;
        	width:125px;
        	text-align:center;
     		padding: 0 0 3px 0;
	}
    </style>
    <!-- pid=$psg->{id} action=$in{myAction} pname=$params->{pname} -->
	<script language="JavaScript" src="${commonUrl}eong3/lib/js/jquery/jquery.min.js"></script>
        @{[$mediaTable->get_js_library_includes()]}
	<script language="JavaScript" src="${commonUrl}eong3/lib/js/edit-on-ng.js"></script>
    <link rel="stylesheet" type="text/css" media="screen" href="${commonUrl}eong3/lib/css/edit-on-ng.css" />
    <link rel="stylesheet" type="text/css" media="screen" href="${commonUrl}style/modal.css" />
    <script language="JavaScript">
    <!--
      var Popup_Wind = new Array();
      \$(document).ready(function() {
          @{[$mediaTable->get_jquery_ready_function()]}
            
          // create prompt for passage name if needed
          if(document.createPassage.pid.value == '0') {
            modalToggle();
          } 
      });
      
      function myOpenPreview(name, url, w, h) {
    var myWin = window
    .open(url,name,'width=' + w + ',height=' + h
        + ',resizable=no,dialog=yes,minimizable=no,maximizable=no,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.focus();
        Popup_Wind[Popup_Wind.length] = myWin;
        return false;
      }
      
      function CloseChildWindow() {
           if (Popup_Wind.length != 0) {
               for (var i = 0; i < Popup_Wind.length; i++) {
                   Popup_Wind[0].close();
               }
           } 
       }
 
function replaceByOcr(strData, strTextToReplace, strReplaceWith, replaceAt) {
    var index = strData.indexOf(strTextToReplace);
    for (var i = 1; i < replaceAt; i++)
        index = strData.indexOf(strTextToReplace, index + 1);
    if (index >= 0)
        return strData.substr(0, index) + strReplaceWith + strData.substr(index + strTextToReplace.length, strData.length);
    return strData;
}

function sortByKey(array, key, asc) {
    return array.sort(function(a, b) {
        var x = a[key];
        var y = b[key];

        if (asc) {
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        } else {
            return ((x > y) ? -1 : ((x < y) ? 1 : 0));
        }

    });
}

function showData() {
    var s = jQuery('#itemAccessibility').html();
    var hybridJson = {},
        sortJson = {};
    jQuery.each(JSON.parse(s), function(idx, myObject) {

        var name = myObject.name;
        var linkType = myObject.linkType;
        var textType = myObject.textType;
        var word = myObject.word;
        var info = myObject.info;
        var startChar = myObject.startChar;
        var endChar = myObject.endChar
        var wordid = myObject.name + '' + myObject.word;
        var parentElement = jQuery('#' + myObject.name);

        if (linkType == 2 || (linkType == 1 && textType == 1)) {
            parentElement.css('cursor', 'pointer');
            parentElement.click(function() {
                myOpenPreview('TTSPreview', '/orca-sbac/TextToSpeechPreview.jsf?text=' + info, 450, 100);
            });
        } else if (linkType == 1 && textType == 3) {
            var textu = parentElement.text().replace(/\\s+/g, " ").trim();
            var text = textu.split(' ');

            for (var w = 1; w <= text.length; w++) {
                if (w == word) {
                    var a = textu.indexOf(text[w - 1]);
                    var b = a + (text[w - 1].length - 1);
                    if (typeof hybridJson[name] == 'undefined') {
                        hybridJson[name] = [];
                    };
                    var node = {};
                    node['textType'] = textType;
                    node['startChar'] = a;
                    node['endChar'] = b;
                    node['info'] = info;
                    node['word'] = word;

                    hybridJson[name].push(node);
                }
            }
        } else if (linkType == 1 && textType == 2) {
            if (typeof hybridJson[name] == 'undefined') {
                hybridJson[name] = [];
            };
            var node = {};
            node['textType'] = textType;
            node['startChar'] = startChar;
            node['endChar'] = endChar;
            node['info'] = info;
            node['word'] = word;

            hybridJson[name].push(node);
        }


    });

    //Sorting Initiate
    jQuery.each(hybridJson, function(idy, myObj) {
        sortJson[idy] = sortByKey(myObj, 'startChar', false);
    });
    //Plotting Initiate

    jQuery.each(sortJson, function(idy, myObj) {
        var name = idy;
        var parentElement = jQuery('#' + name);
        var tag = [];
        tag = jQuery('#' + name + ' > :not(".myOpen")');

        jQuery.each(myObj, function(idyC, myObjC) {
            parentElement = jQuery('#' + name);
            var text = parentElement.html();
            var textType = myObjC.textType;
            var word = myObjC.word;
            var info = myObjC.info;
            var startChar = myObjC.startChar;
            var endChar = myObjC.endChar
            var wordid = name + '' + myObjC.word;
            var ntext = '';


            if (jQuery(tag).size() > 0) {
                jQuery.each(tag, function(index) {
                    if (!jQuery.isEmptyObject(tag[index])) {
                        text = replaceByOcr(text, tag[index].outerHTML, '~', 1);

                    }
                });
            }

            if (text.indexOf('~') !== -1) {
                var logicalBlocks = text.split("~");
                var block = 0,
                    blockSum = 0,
                    active = true;
                jQuery.each(logicalBlocks, function(ind, obj) {
                    blockSum += obj.length;
                    if (blockSum > startChar && active) {
                        block = ind;
                        active = false;

                    }
                });
                var newStartChar = startChar + block;
                var newEndChar = endChar + block;
                if (typeof newStartChar != 'undefined') {
                    ntext = text.substring(0, newStartChar) + '<a data-id="' + wordid + '" data-info="' + info + '" class="myOpen" style="text-decoration:none;cursor:pointer;">' + text.substring(newStartChar, newEndChar + 1) + '</a>' + text.substring(newEndChar + 1);
                }
            } else {
                ntext = text.substring(0, startChar) + '<a data-id="' + wordid + '" data-info="' + info + '" class="myOpen" style="text-decoration:none;cursor:pointer;">' + text.substring(startChar, endChar + 1) + '</a>' + text.substring(endChar + 1);
            }

            jQuery.each(tag, function(index) {
                if (!jQuery.isEmptyObject(tag[index])) {
                    ntext = replaceByOcr(ntext, '~', tag[index].outerHTML, tag.length - (index + 1));
                }
            });
            jQuery('#' + name).html(ntext);
        });
    });
    jQuery('.myOpen').click(function() {
        var info = jQuery(this).attr('data-info');
        var wordid = jQuery(this).attr('data-wordid');
        myOpenPreview('TTSPreview', '/orca-sbac/TextToSpeechPreview.jsf?text=' + info, 450, 100);
    });
}

      function modalToggle() {
        el = document.getElementById("modal");
	el.style.visibility = (el.style.visibility == "visible") ? "hidden" : "visible";
      }
 
      var tmpEditorObj;

      var compareHeader = "<html><head><title>title</title></head><body>";
      var compareFooter = "</body></html>";

    
	function applyTemplate(f, template_num) {
		var template = document.getElementById('template_'+template_num).value;
		if( f.passageText.value.match(/^\\s*\$/) ) {
		    f.passageText.value = template;
		    oEdit1.setBodyFragment(f.passageText.value);
		}
		else {
		    if( confirm('Applying this Template will overwrite existing Content!\\nProceed?') ) {
		        f.passageText.value = template;
		        oEdit1.setBodyFragment(f.passageText.value);
		    }
		    else {
			f.pd_template.selectedIndex = 0;
		    }
		}
	}
      function mySubmit()
      {
	document.createPassage.submit();
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
	myOpen('insertGraphicWin','${passageInsertAssetUrl}?itemBankId=$psg->{bank}&passageId=$psg->{id}',400,500);
      }	

      function doCreateSubmit(itemBank, passageName) {
        document.createPassage.itemBankId.value = itemBank;
        document.createPassage.pname.value = passageName;
        document.createPassage.myAction.value = 'create';
	document.createPassage.submit();
      }
      function doEditSubmit(itemBank, passageName) {
        document.createPassage.itemBankId.value = itemBank;
        document.createPassage.pname.value = passageName;
        document.createPassage.myAction.value = 'edit';
	document.createPassage.submit();
      }
      function doSaveSubmit(f) {
		//alert(f.language.value);
		//alert(oEdit1.getDocumentLanguage());
			  /*if(document.createPassage.code.value.length > 4) {
				  alert('Passage Code is limited to 4 characters.');
					return false;
				}*/	
        document.createPassage.myAction.value = 'save';
       
        
        if( $format !=  5) {
        
          document.createPassage.passageText.value = convertEntities(oEdit1.getBodyFragment());
        }
	      document.createPassage.submit();
	      return true;
      }

      var tabberOptions = {
     
         'manualStartup':true,
	       'addLinkId':true,
     
         'onClick': function(argsObj) {

  if($format != 5) {
	 
	         var t = argsObj.tabber;
	         var id = t.id;
	         var i = argsObj.index;

           if(id=='tabMain') {
	           if(document.createPassage.pid.value == '0') {
	             return false;
             }
	       }

           if(id == 'tabMain' && i != 2) {
	      parent.rightFrame.footnoteFrame.location.href='${orcaUrl}blankPage.html';
	   }

           if(id == 'tabMain' && i == 2) {
		           document.footnote.htmlContent.value = convertEntities(oEdit1.getBodyFragment());
			       document.footnote.submit();
		       }	 

           if(id == 'tabMain' && i==3) {
					   parent.rightFrame.notesFrame.location.href='${orcaUrl}cgi-bin/passageNotes.pl?passageId=$psg->{id}';
					 }
		
		       if(id == 'tabMain' && i==4) {
	           // User clicked the History tab
	           // so load the 'history' in the iframe
	          parent.rightFrame.historyFrame.location.href='${orcaUrl}cgi-bin/passageHistory.pl?passageId=$psg->{id}'; 
	         }

	         if(id=='tabMain' && i==5) {
	           
      	       document.getElementById('prepassage').innerHTML = oEdit1.getBodyFragment() != '' ? convertEntities(oEdit1.getBodyFragment()) : document.createPassage.passageText.value;
	         }
	 }else{
	 
  var t = argsObj.tabber;
	         var id = t.id;
	         var i = argsObj.index;

           if(id=='tabMain') {
	           if(document.createPassage.pid.value == '0') {
	             return false;
             }
	       }

           if(id == 'tabMain' && i == 1) {
           
		         parent.rightFrame.notesFrame.location.href='${orcaUrl}cgi-bin/passageNotes.pl?passageId=$psg->{id}';
		       }
		
		       if(id == 'tabMain' && i==2) {
	           // User clicked the History tab
	           // so load the 'history' in the iframe
	          parent.rightFrame.historyFrame.location.href='${orcaUrl}cgi-bin/passageHistory.pl?passageId=$psg->{id}'; 
	         }

	         if(id=='tabMain' && i==4) {
	           
	           document.getElementById('prepassage').innerHTML = oEdit1.getBodyFragment() != '' ? convertEntities(oEdit1.getBodyFragment()) : document.createPassage.passageText.value; 
	         }

          }
	       }

      };
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
  <body onunload="CloseChildWindow();">
    <div id="modal">
      <div>
        ${msg}
        <p>Enter a Passage name to Create or Edit:</p>
        <form name="modalForm">
	  <table class="no-style" border="0" cellspacing="2" cellpadding="2">
	    <tr>
	      <td>Program:</td>
	        <td align="left">${itemBankDisplay}</td>
	        <td><input style="width:60px;" type="button" name="create" value="Create" 
		           onClick="doCreateSubmit(document.modalForm.itemBankId.options[document.modalForm.itemBankId.selectedIndex].value, document.modalForm.pname.value);" /></td>
             </tr>
	     <tr>
	       <td>Name:</td>
	       <td align="left"><input type="text" name="pname" value="$psg->{name}" size="25" /></td>
               <td><input style="width:60px;" type="button" name="edit" value="Edit" 
	                  onClick="doEditSubmit(document.modalForm.itemBankId.options[document.modalForm.itemBankId.selectedIndex].value, document.modalForm.pname.value);" /></td> 
	     </tr>
	  </table>
	</form>
      </div>
    </div>
    <form name="footnote" action="${orcaUrl}cgi-bin/passageFootnote.pl" method="POST" target="footnoteFrame">
      <input type="hidden" name="itemBankId" value="$psg->{bank}" />
      <input type="hidden" name="passageId" value="$psg->{id}" />
	<input type="hidden" name="htmlContent" value="" />
	<input type="hidden" name="doCompare" value="${doCompare}" />
    </form>
    <form name="createPassage" action="${thisUrl}" method="POST">
      <input type="hidden" name="pid" value="$psg->{id}" />
      <input type="hidden" name="furl" value="${furl}" />
      <input type="hidden" name="passageNote" value="" />
      <input type="hidden" name="myAction" value="" /> 
      <input type="hidden" name="pname" value="$psg->{name}" />
      <input type="hidden" name="itemBankId" value="$psg->{bank}" />
      ${hiddenFields}
    <table class="no-style" width="98%" border="0" cellpadding="3" cellspacing="3">
      <tr>
        <td width="98%">
	  <table class="no-style" width="100%" border="0" cellpadding="2" cellspacing="2">
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
END_HERE
#added for unsupported passage
if($in{iformat} != 5) {
 $psgi_out .= <<END_HERE;
	    <div class="tabbertab" title="Content">
	    <table class="no-style" border="0" cellspacing="3" cellpadding="3"><tr><td valign="top">
	    <input type="hidden" id="hdnEditor" name="hdnEditor" value=" "/>
    <textarea style="display:none;" id="passageText" name="passageText" rows="6" cols="30">${passageText}</textarea>
    <textarea style="display:none;" id="passageTextCompare" name="passageTextCompare" rows="6" cols="30">${compareText}</textarea>
    <script language="JavaScript">
    <!--
    
        function convertEntities (str_in) {
        if(str_in != null){
          /*[\\u00A0-\\u00FF\\u2022-\\u2135] */
          var str_out = str_in.replace(/[\\u00A0-\\u2900]/g, function (c) {
                                     return '&#' + c.charCodeAt(0) + ';';
                        });
          //alert(str_out);
          }
          return str_out;
        }

	var oEdit1;

        if(document.createPassage.pid.value > '0') {        
           oEdit1 = new eongApplication(650, 460, "myEditor1", "myEditor1","oEdit1");
           oEdit1.setCodebase("${commonUrl}eong3/lib/bin");
	   oEdit1.clearUserPreferences();
	   oEdit1.clearUserStyles();
	   oEdit1.setUIConfigURL("${commonUrl}eong3/lib/config/uiconfig.json");
	   oEdit1.setConfigURL("${commonUrl}eong3/lib/config/config.json");
	   oEdit1.setActionExtensionURL("${commonUrl}eong3/extension/actionmap.ext.json");
	   oEdit1.setContentCaching(false);
	   oEdit1.addUserStylesFromURL("${orcaUrl}style/item-style.css");
	   oEdit1.addUserStylesFromURL("${commonUrl}eong3/lib/css/custom.css");
	   oEdit1.invokeAction("live-document-language", "$locale_code");
           oEdit1.setUserAttributes("Username","$user->{userName}");
           oEdit1.registerEventHandler('ONEDITORLOADED', 'showEditor');              
        }

	function showEditor() {	
	     jQuery("#myEditor1").css("position", "").css("left", "");
	     jQuery("#spinner1").css("display", "none");	     
	}
	function editorChangedEvent(editorRef, charCount) {
	
       
   
     }
	

        function localCompareDocuments1() {

		   document.createPassage.passageText.value = oEdit1.getBodyFragment();

           if(document.createPassage.passageTextCompare.value == document.createPassage.passageText.value) {
           
             alert('Content matches original.');

           } else if(document.createPassage.passageTextCompare.value != '' &&
                   document.createPassage.passageText.value != '') {

		     oEdit1.compareDocumentsFromContent(
		        compareHeader + document.createPassage.passageTextCompare.value + compareFooter,
			    compareHeader + document.createPassage.passageText.value + compareFooter);

	         oEdit1.invokeAction("show-changes-inline-diff");

           } else {

             alert('Comparison content not available.');
           }

        }

        if(document.createPassage.pid.value > '0') {
          oEdit1.Helper.jsObj.localCompareDocuments = localCompareDocuments1;

END_HERE

    if ($doCompare) {
        $psgi_out .= <<END_HERE;
        oEdit1.registerEventHandler('ONEDITORLOADED', 'localCompareDocuments1');
END_HERE
    }
    #else {
        $psgi_out .= <<END_HERE;
	    oEdit1.setBodyFragment(document.createPassage.passageText.value);
	    oEdit1.registerEventHandler('ONCHARACTERCOUNTCHANGED', 'editorChangedEvent');
END_HERE
    #}

    $psgi_out .= <<END_HERE;
        }
    //-->
    </script>
   <div id="spinner1"><img src="${commonUrl}images/LoadingProgressBar.gif" /></div>
    <div id="myEditor1" style="position: absolute; left: -10000px;"></div>
    </td>
    <td style="width:10px;">&#160;</td>
    <td style="vertical-align:top;">
      <table class="no-style" border="0" cellpadding="3" cellspacing="3">
        <tr><td>Files:</td><td>
	        <input type="button" onClick="myOpen('assetUploadWindow','${passageUploadAssetUrl}?itemBankId=$psg->{bank}&passageId=$psg->{id}',400,450);" value="Upload Images" class="action_button" />&#160;&#160;
	    </td></tr>
	    <tr><td/><td><input type="button" onClick="myOpen('itemMetafileWindow','${orcaUrl}cgi-bin/passageMetafiles.pl?passageId=$psg->{id}',600,550);" value="View Metafiles" class="action_button" />&#160;&#160;</td></tr>
	    <tr><td/><td><input type="button" onClick="myOpen('programMetafilesWindow','/orca-sbac/IBMetafilesView.jsf?passage=$psg->{id}',750,450);" value="Program Metafiles" class="action_button" /></td></tr>
	    <tr><td colspan="2">@{[$mediaTable->draw($psg, $passage_media, Edit_Mode)]}</td></tr> 
END_HERE

	    if ( $in{outdated} eq "Y" ) {
    	    $psgi_out .= <<END_HERE;
		<tr><td>Note:</td><td><span style="color: red">This Passage has outdated Program Metafiles</span>
END_HERE
	    }

    	$psgi_out .= <<END_HERE;
	    
	    
        <tr><td colspan="2">&#160;</td></tr> 
        <tr><td>Template:</td><td><select name="pd_template" style="width:100px" onChange="applyTemplate(this.form, this.value)"><option value="0">---Select---</option><option value="1">Basic</option><option value="2">Advance</option></td></tr> 
        <tr><td colspan="2">&#160;</td></tr> 
        <tr><td>Notes:</td><td><textarea name="passageNotes" rows="9" cols="29">$psg->{notes}</textarea></td></tr>
      </table>
    </td></tr></table>
	    </div>
END_HERE
}
#end here unsupported item
$psgi_out .= <<END_HERE;
	    <div class="tabbertab" title="Metadata">
    <table class="no-style" border="0" cellpadding="2" cellspacing="2">
    <tr><td style="align:left; vertical-align:top;">
    <table class="no-style" border="0" cellpadding="3" cellspacing="3">
			<tr><td><span>Subject:</span></td><td>${contentAreaList}</td></tr>
			<tr><td><span>Grade Level:</span></td><td>${gradeLevelList}</td></tr>
      <tr><td><span>$labels[$OC_GRADE_SPAN_START]</span></td><td>${gradeSpanStartList}</td></tr> 
      <tr><td><span>$labels[$OC_GRADE_SPAN_END]</span></td><td>${gradeSpanEndList}</td></tr> 
      <tr><td><span>Summary:</span></td><td><textarea name="summary" rows="3" cols="35">$psg->{summary}</textarea></td></tr>
      <tr><td><span>Genre:</span></td><td>${genreList}</td></tr>
      <tr><td><span>Sub-Genre:</span></td><td><input type="text" name="subgenre" value="$psg->{subGenre}" size="35" /></td></tr>
      <tr><td><span>Topic:</span></td><td><input type="text" name="topic" value="$psg->{topic}" size="35" /></td></tr>
      <tr><td><span>Readability Index:</span></td><td><input type="text" name="readabilityIndex" value="${readabilityIndex}" size="35" /></td></tr>
    </table>
    </td>
    <td style="width:10px;">&#160;</td>
    <td style="align:right; vertical-align:top;">
      <table class="no-style" border="0" cellpadding="3" cellspacing="3">
        <tr><td><span >Reading<br />Level Notes:</span></td><td><textarea name="readingLevel" rows="3" cols="35">$psg->{readingLevel}</textarea></td></tr>
        <tr><td><span>Cross Curriculum:</span></td><td>${crossCurriculumList}</td></tr>
        <tr><td><span>Character Ethnicity:</span></td><td>${charEthnicityList}</td></tr>
        <tr><td><span>Character Gender:</span></td><td>${charGenderList}</td></tr>
	<tr><td><span>Language:</span></td><td>${languageDisplay}</td></tr>
	<tr><td><span>Publication Status:</span></td><td>${publicationStatusList}</td></tr>
	<tr><td><span>Assigned Writer:</span></td><td>$display{assignedWriter}</td></tr>
	<tr><td><span>Development State:</span></td><td>$display{developmentState}</td></tr>
        <tr><td colspan="2">&#160;</td></tr>
END_HERE
if($in{iformat} != 5) {
$psgi_out .= <<END_HERE;
<tr><td><a href="#" onClick="myOpen('printwin','${orcaUrl}cgi-bin/passageView.pl?passageId=$psg->{id}&print',650,500);">Open Print Window</a>
        </td>
        <td>
END_HERE
}
        

#added for unsupported passage
#if($in{iformat} == 5) {
#$psgi_out .= <<END_HERE;        
#	    	<input type="button" name="save" value="Save Passage" onClick="doSaveSubmit(this.form);" />
#END_HERE
#}
#ened here unsupported passage
$psgi_out .= <<END_HERE;	    	
	  	</td>
        </tr> 
			</table>
    </td></tr></table>
	    </div>
END_HERE
	   
if($in{iformat} != 5) {
$psgi_out .= <<END_HERE;    
	    <div class="tabbertab" title="Footnotes">
       <iframe name="footnoteFrame" id="footnoteFrame" width="97%" height="390" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Create Graphic</iframe> 
			</div>
END_HERE
}

#added for unsupported passage

 $psgi_out .= <<END_HERE;			
			<div class="tabbertab" title="Notes">
			  <iframe name="notesFrame" id="notesFrame" width="97%" height="390" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Passage Notes</iframe>
			</div>			
			<div class="tabbertab" title="History">
			  <iframe name="historyFrame" id="historyFrame" width="97%" height="390" frameborder="0" scrolling="auto" src="${orcaUrl}blankPage.html">Passage History</iframe>
			</div>
END_HERE
#added for unsupported passage
if($in{iformat} != 5) {
my $accessibilityData = '[';
    
my $accessibilitySQL = 'SELECT ae.i_id, ae.ae_content_name, ae.ae_content_link_type, 
            ae.ae_text_link_type, ae.ae_text_link_word, ae.ae_text_link_start_char, 
            ae.ae_text_link_stop_char,af.af_info 
            FROM cdesbac.accessibility_element as ae 
            inner join cdesbac.accessibility_feature as af on ae.ae_id = af.ae_id
            where ae.p_id = (SELECT p_id FROM cdesbac.passage where p_name = \'' . $in{pname} .  '\' limit 1) and af.af_type = 1 and af.af_feature = 2';
    
my $sth = $dbh->prepare($accessibilitySQL);
$sth->execute(); 
my $rowcount = 0;
    
while(my $row = $sth->fetchrow_hashref){
   $accessibilityData .=  '{"name":"'.$row->{ae_content_name}.'","linkType":'.$row->{ae_content_link_type}.','
       .'"textType":'.$row->{ae_text_link_type}.',"word":'.$row->{ae_text_link_word}.','
       .'"startChar":'.$row->{ae_text_link_start_char}.',"endChar":'.$row->{ae_text_link_stop_char}.','
       .'"info":"'.$row->{af_info}.'"}';        
$rowcount++;
if($rowcount != $sth->rows) {
  $accessibilityData .= ',';
 }
}
$accessibilityData .= ']';
$sth->finish;

$psgi_out .= <<END_HERE;
	    <div class="tabbertab" title="Preview">
	    <table class="no-style" border="0" cellspacing="3" cellpadding="3"><tr><td>
	     <div style="width:500px;" id="prepassage"></div> 
             @{[$mediaTable->draw($psg, $passage_media, View_Mode)]}
         <div id="itemAccessibility" style="display:none;"> 
            ${accessibilityData}
         </div>
	    </td> 
    <td style="width:10px;">&#160;</td>
    <td style="vertical-align:top;">
      <table class="no-style" border="0" cellpadding="3" cellspacing="3">
	<tr>
	<td>&#160;</td>
	</tr>
	<tr>
	  <td>
	    <input type="button" name="save" value="Save Passage" onClick="doSaveSubmit(this.form);" /> 
	  </td>
	</tr>
      </table>
    </td></tr></table>
         </div>
END_HERE
}
#ened here unsupported passage
$psgi_out .= <<END_HERE;
	  </div>
	</td>
      </tr>
    </table>
    <textarea style="display:none;" id="template_1" name="template_1" rows="6" cols="30">$pd_templates{1}</textarea>
    <textarea style="display:none;" id="template_2" name="template_2" rows="6" cols="30">$pd_templates{2}</textarea>
    <input type="hidden" name="template_0" id="template_0" value=" " />
    </form>
    <script type="text/javascript">
    <!--
      tabberAutomatic(tabberOptions); 

      window.onload = function () {

        if(document.createPassage.pid.value > '0') {
          if($format != 5) {	
            oEdit1.loadEditor();
          }
        }
      }
    //--> 
    </script>
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub preDefinedTemplates {

    my %templates = ( 
	1 => qq|
<table border="0" cellspacing="0" width="500" align="left">
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;&#160;&#160;&#160;&#160;&#160;</td>
        <td valign="top" width="448">Title Goes Here</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
    <tr>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="25">&#160;</td>
        <td valign="top" width="448">&#160;</td>
    </tr>
</table>
	|,
	2 => qq|
<table border="0" width="500" cellspacing="0" cellpadding="0">
    <tr>
        <td valign="top" width="12">#</td>
        <td valign="top" width="13">---------</td>
        <td valign="top" width="776">
            <p align="left"></p>
        </td></tr>

<tr>
        <td valign="top">&#160;&#160;1</td>
        <td valign="top">&#160;</td>
        <td valign="top">
            <p></p>
        </td>
    </tr>
<tr>
        <td valign="top">&#160;&#160;2</td>
        <td valign="top">&#160;</td>
        <td valign="top">
            <p></p>
        </td>
    </tr>
<tr>
        <td valign="top">&#160;&#160;3</td>
        <td valign="top">&#160;</td>
        <td valign="top">
            <p></p>
        </td>
    </tr>
</table>
	|,
	3 => qq|
	|,
    );
}
1;
