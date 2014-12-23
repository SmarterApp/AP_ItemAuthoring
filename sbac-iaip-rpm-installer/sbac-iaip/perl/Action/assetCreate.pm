package Action::assetCreate;

use File::Copy;
use URI;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  # list of TeX names to provide buttons for
  our @templates = ('prod','integral','sum','fraction','subscript','superscript','root',
                   'nth-root','nuclide','limit','over-line','over-right-arrow',
  		 'over-double-arrow');
  
  our @spaces = ('thin','medium','thick','negative');
  
  our @styles = ('roman','sans serif','emphasis','bold','italic','slant','type');
  
  our @brackets = ('(',')','[',']','{','}','left .','right .');
  
  our @arrows = ('left','strong-left','right','strong-right','double','strong-double',
                'long-left','long-strong-left','long-right','long-strong-right',
  	      'long-double','long-strong-double');
  
  our @symbols = ('times','divide','plus-minus','less-than-equal','greater-than-equal',
                 'not-equal','congruent','approximate','equivalent','similar','degree','angle',
  	       'dollar','cent','infinity','pi','theta');
  
  our %converter = ('prod' => '\\\\prod_{}^{}',
                   'integral' => '\\\\int_{}^{}',
                   'sum' => '\\\\sum_{}^{}',
  		 'subscript' => '_{}',
  		 'superscript' => '^{}',
  		 'root' => '\\\\sqrt{}',
  		 'nth-root' => '\\\\sqrt[n]{}',
  		 'nuclide' => '\\\\nuclide[a][b]{}',
  		 'limit' => '\\\\lim_{}',
  		 'fraction' => '\\\\frac{}{}',
  		 'over-line' => '\\\\overline{}',
  		 'over-right-arrow' => '\\\\overrightarrow{\\\\textsf{ }}',
  		 'over-double-arrow' => '\\\\stackrel{\\\\longleftrightarrow}{}',
  		 'left' => '\\\\leftarrow',
  		 'strong-left' => '\\\\Leftarrow',
  		 'right' => '\\\\rightarrow',
  		 'strong-right' => '\\\\Rightarrow',
  		 'double' => '\\\\leftrightarrow',
  		 'strong-double' => '\\\\Leftrightarrow',
  		 'long-left' => '\\\\longleftarrow',
  		 'long-strong-left' => '\\\\Longleftarrow',
  		 'long-right' => '\\\\longrightarrow',
  		 'long-strong-right' => '\\\\Longrightarrow',
  		 'long-double' => '\\\\longleftrightarrow',
  		 'long-strong-double' => '\\\\Longleftrightarrow',
  		 'times' => '\\\\times',
  		 'divide' => '\\\\div',
  		 'plus-minus' => '\\\\pm',
  		 'less-than-equal' => '\\\\leq',
  		 'greater-than-equal' => '\\\\geq',
  		 'not-equal' => '\\\\neq',
  		 'congruent' => '\\\\cong',
  		 'approximate' => '\\\\approx',
  		 'equivalent' => '\\\\equiv',
  		 'similar' => '\\\\sim',
  		 'degree' => '^\\\\circ',
  		 'angle' => '\\\\angle',
  		 'dollar' => '\\\\textrm{\\\\textdollar}',
  		 'cent' => '\\\\textrm{\\\\textcent}',
  		 'infinity' => '\\\\infty',
  		 'pi' => '\\\\pi',
  		 'theta' => '\\\\theta',
  		 'thin' => '\\,',
  		 'medium' => '\\:',
  		 'thick' => '\\;',
  		 'negative' => '\\!',
  		 'roman' => '\\textrm{}',
  		 'sans serif' => '\\textsf{}',
  		 'emphasis' => '\\emph{}',
  		 'bold' => '\\textbf{}',
  		 'italic' => '\\textit{}',
  		 'slant' => '\\textsl{}',
  		 'type' => '\\texttt{}',
  		 '(' => '\\left(',
  		 ')' => '\\right)',
  		 '[' => '\\left[',
  		 ']' => '\\right]',
  		 '{' => '\\left\\{',
  		 '}' => '\\right\\}',
  		 'left .' => '\\left.',
  		 'right .' => '\\right.');
  
  our $asset_root = "${imagesDir}lib$in{itemBankId}/$in{itemId}/";
  
  if(defined $in{assetId}) {
    $in{assetId} =~ tr/ /_/;
    $in{assetId} =~ s/^V\d+\.//;
    $in{assetId} =~ tr/./_/;
    $in{assetId} = ($in{version} eq '0' ? $in{assetId} : "V$in{version}.$in{assetId}");
  }
  
  unless(defined $in{myAction})
  {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }  
  
  if($in{myAction} eq 'Retrieve')
  {
    
    my $id = $in{assetId}; 
   
    $in{assetBody} = ""; 
    my $infile_name = "${asset_root}${id}.tex";
    open INFILE, "<${infile_name}";
    while(<INFILE>)
    {
      $in{assetBody} .= $_;
    }
    close INFILE;
   
    $in{assetBody} =~ s/\r//g;
  
    if($in{assetBody} =~ m/\\begin\{displaymath\}\n+(.*)\n+\\end\{displaymath\}/s)
    {
      $in{assetBody} = $1;
      if($in{assetBody} =~ m/^\\math\w+\{(.*)\}$/s) {
        $in{assetBody} = $1;
      }  
    }

    return [ $q->psgi_header(-type => 'text/html',
                             -pragma => 'nocache',
  		             -cache_control => 'no-cache, must-revalidate'),
             [ &print_welcome(\%in) ]];
  }
  elsif($in{myAction} eq 'Create')
  {
    if($in{assetId} eq '')
    {
      $in{message} = 'Please enter a Graphic Title.'; 
      return [ $q->psgi_header('text/html'), [ &print_error(\%in) ]];
    }
    
    # assetId is used to generate file name. Limit for names is 100
    if (length($in{assetId}) > 100) {
      $in{message} = "Graphic Title must be less than 100 characters. Please enter a shorter Title."; 
      return [ $q->psgi_header('text/html'), [ &print_error(\%in) ]];
    }
  
    if ($in{assetId} =~ m/[^a-zA-Z0-9\-_]/){
      $in{message} = "Graphic Title may only contain alphanumeric characters, underscore, or dash.";
      return [ $q->psgi_header('text/html'), [ &print_error(\%in) ]];
    }
  
    if(-e $asset_root . $in{assetId} . '.gif'
    || -e $asset_root . $in{assetId} . '.swf')
    {
      $in{message} = "Graphic '" . $in{assetId} 
                   . "' already exists."
                   . "<br />Please choose another Title.";
      return [ $q->psgi_header('text/html'), [ &print_error(\%in) ]];
    }
  
    &make_asset_file(\%in);
    
    my $uri = URI->new($textogif_url);
    $uri->query_form( 'assetId' => $in{assetId}, 'size' => $in{fontSize}, 'itemBankId' => $in{itemBankId}, 'itemId' => $in{itemId}, 'type' => 'tex');
  
    return [ $q->psgi_redirect($uri->as_string), ['' ]];
  }  
  elsif($in{myAction} eq 'Update')
  {
    if($in{assetId} eq '')
    {
      $in{message} = 'Please enter a Graphic Title.'; 
      return [ $q->psgi_header('text/html'), [ &print_error(\%in) ]];
    }
  
    unless(-e $asset_root . $in{assetId} . '.' . 'tex')
    {
      $in{message} = "Graphic '" . $in{assetId} 
                   . "' Not Found."
                   . "<br />Unable to Update.";
      return [ $q->psgi_header('text/html'), [ &print_error(\%in) ]];
    }
  
    &make_asset_file(\%in);
  
    my $uri = URI->new($textogif_url);
    $uri->query_form( 'assetId' => $in{assetId}, 'size' => $in{fontSize}, 'itemBankId' => $in{itemBankId}, 'itemId' => $in{itemId}, 'type' => 'tex', 'quick' => $in{quick});
  
    return [ $q->psgi_redirect( -location => $uri->as_string,
                               -pragma => 'nocache',
                               -cache_control => 'no-cache, must-revalidate'), ['' ]];
  }  
}

### ALL DONE! ###

sub print_error {
  my $params = shift;

  my $msg = '<div style="color:#ff0000;font-weight:bold;font-size:14pt">'
          . $params->{message} . '</div>';
  return <<END_HERE;
<html>
  <head>
    <title>Graphic Error</title>
    <body>
    $msg 
    </body>
  </head>
</html>
END_HERE
}

sub print_welcome {
  my $params = shift;

  my $msg = ( defined($params->{message})
        ? "<div style='color:#ff0000;font-weight:bold'>"
	  . $params->{message} . "</div>" : "");

  my $id = (defined $params->{assetId} ? $params->{assetId} : "");
  $id =~ s/^V\d+\.//;

  my $itemId = $params->{itemId};
  my $ibank = $params->{itemBankId};
  my $version = $params->{version};
  my $assetBody = ( defined $params->{assetBody} ? $params->{assetBody} : "");

  my $templateButtons = '<tr>';
  foreach my $key (@templates) {
    $templateButtons .= '<td style="margin-top:-5px;margin-bottom:-5px;">&nbsp;<img border="0" onClick="appendEntity(\''
                 . $converter{$key} . '\',false);" alt="' . $key 
		 . '" style="cursor:pointer;"'
		 . ' src="' . $commonUrl . 'equation-images/' . $key . '.gif" />&nbsp;</td>';
  }
  $templateButtons .= '</tr>';

  my $arrowButtons = '<tr>';
  foreach my $key (@arrows) {
    $arrowButtons .= '<td style="vertical-align:middle;">&nbsp;<img border="0" onClick="appendEntity(\''
                 . $converter{$key} . '\',false);" alt="' . $key 
		 . '" style="cursor:pointer;"'
		 . ' src="' . $commonUrl . 'equation-images/' . $key . '.gif" />&nbsp;</td>';
  }
  $arrowButtons .= '</tr>';

  my $symbolButtons = '<tr>';
  foreach my $key (@symbols) {
    $symbolButtons .= '<td>&nbsp;<img border="0" onClick="appendEntity(\''
                 . $converter{$key} . '\',false);" alt="' . $key 
		 . '" style="cursor:pointer;"'
		 . ' src="' . $commonUrl . 'equation-images/' . $key . '.gif" />&nbsp;</td>';
  }
  $symbolButtons .= '</tr>';

  my $selectSpace = '<select style="font-size:11px;" name="spaces" onChange="appendEntity(this.options[this.selectedIndex].value,false);this.selectedIndex=0;"><option value="" SELECTED>Spaces...</option>';
  foreach my $key (@spaces) {
    $selectSpace .= '<option value="' . $converter{$key} . '">' . $key . '</option>';
  }
  $selectSpace .= '</select>';

  my $selectStyle = '<select style="font-size:11px;" name="styles" onChange="appendEntity(this.options[this.selectedIndex].value,false);this.selectedIndex=0;"><option value="" SELECTED>Styles...</option>';
  foreach my $key (@styles) {
    $selectStyle .= '<option value="' . $converter{$key} . '">' . $key . '</option>';
  }
  $selectStyle .= '</select>';

  my $selectBracket = '<select style="font-size:11px;" name="brackets" onChange="appendEntity(this.options[this.selectedIndex].value,false);this.selectedIndex=0;"><option value="" SELECTED>Brackets...</option>';
  foreach my $key (@brackets) {
    $selectBracket .= '<option value="' . $converter{$key} . '">' . $key . '</option>';
  }
  $selectBracket .= '</select>';

  return <<END_HERE;
<html>
  <head>
    <title>Graphic Create</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
    <script language="JavaScript">
    <!--
      function myOpen(url,w,h)
      {
        var myWin = window.open(url,'_blank','width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(250,100); 
	return true;
      }

      function appendEntity(entity,doEscape)
      {
        var myText = entity;
	if(doEscape) {
	  myText = '\\\\' + entity;
        }
	smartInsert(document.assetCreate.assetBody,myText);
	document.assetCreate.assetBody.focus();
        return true; 
      }

      function insertArray(rows,cols) {
        var myText = '\\\\begin{array}{';
	for(var i=0; i < cols; i++) {
	  myText += 'c';
	}
	myText += '}';

        var myRow = ' ';
	for(var i=1; i < cols; i++) {
	  myRow += '& ';
	}
	
	for(var i=0; i < rows; i++) {
          if(i > 0) { myText += ' \\\\\\\\ '; } 
	  myText += myRow;	
	}

	myText += '\\\\end{array}';

	smartInsert(document.assetCreate.assetBody,myText);
	document.assetCreate.assetBody.focus();
	return true;
      }

      function smartInsert(myField, myValue)
      {
        if(document.selection)
	{
	  myField.focus();
	  var sel = document.selection.createRange();
	  sel.text = myValue;
        }
	else if(myField.selectionStart
	    ||  myField.selectionStart == '0' )
        {
	  var startPos = myField.selectionStart;
	  var endPos = myField.selectionEnd;
	  myField.value = myField.value.substring(0, startPos)
	                + myValue
			+ myField.value.substring(endPos, myField.value.length);
        }
	else
	{
	  myField.value += myValue;
        }
      }

      function doFindGraphic() {
        myOpen('${orcaUrl}cgi-bin/findEditGraphic.pl?itemId=${itemId}&itemBankId=${ibank}&version=${version}&type=tex',450,400);
      }

      function doCopyGraphic() {
        if(document.assetCreate.assetId.value=='') {
          alert('Please enter a Graphic Title first!');
        } else {
          myOpen('${assetFindUrl}?itemBankId=${ibank}&itemId=${itemId}&type=tex&assetId='+document.assetCreate.assetId.value,400,450);
        }
      }

      function checkOutputFrame() {
        if(document.assetCreate.assetId.value == '') {
	  parent.imageOutFrame.location.href='${assetBlankUrl}';
        }
      }

      function doSubmit(submitAction) {
        document.assetCreate.myAction.value = submitAction;
	document.assetCreate.submit();
      }	

    //-->
    </script>
  </head>
  <body onLoad="checkOutputFrame(); document.assetCreate.assetId.focus();">
    ${msg} 
    <form name="assetCreate" action="assetCreate.pl" method="POST" target="imageOutFrame">
     <input type="hidden" name="itemBankId" value="${ibank}" />
     <input type="hidden" name="itemId" value="${itemId}" />
     <input type="hidden" name="type" value="tex" />
     <input type="hidden" name="version" value="${version}" />
     <input type="hidden" name="myAction" value="" />
     <input type="hidden" name="quick" value="no" />
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
        <td colspan="2"><span class="text">Graphic Title:</span>&nbsp;&nbsp;
        <input type="text" size="30" maxlength="100" name="assetId" value="${id}" />&nbsp;&nbsp;
	&nbsp;<input type="button" name="button" value="Edit Existing" onClick="doFindGraphic();" /> 	
	</td> 
      </tr>
      <tr>
        <td><span class="text">Size:</span>&nbsp;&nbsp;
	  <select name="fontSize">
	    <option value="scriptsize">-3</option>
	    <option value="footnotesize" SELECTED>-2</option>
	    <option value="small">-1</option>
	    <option value="">Normal</option>
	    <option value="large">+1</option>
	    <option value="Large">+2</option>
	    <option value="LARGE">+3</option>
	</td>
	<td><span class="text">Font:</span>&nbsp;&nbsp;
          <select name="fontFamily">
	    <option value="">Default</option>
	    <option value="mathrm">Roman</option>
	    <option value="mathsf" SELECTED>Sans Serif</option>
	    <option value="mathtt">Typewriter</option>
          </select>
	</td>
      </tr>
   </table>
   <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
        <td>
          <span class="text">Paste TeX Here:</span><br />
          <textarea name="assetBody" rows="3" cols="60">${assetBody}</textarea>
	<div><table style="border: 1px solid black;" border="0" cellspacing="2" cellpadding="0">${templateButtons}</table></div>
	<div><table style="border: 1px solid black;" border="0" cellspacing="2" cellpadding="0">${symbolButtons}</table></div>
	<div><table style="border: 1px solid black;" border="0" cellspacing="2" cellpadding="0">${arrowButtons}</table></div>
<div style="margin-top:5px;">${selectSpace}&nbsp;&nbsp;${selectStyle}&nbsp;&nbsp;${selectBracket}
&nbsp;&nbsp;Array: rows=&nbsp;<input type="text" name="arrayRows" style="width:20px;" />, cols=&nbsp;<input type="text" name="arrayCols" style="width:20px;" />&nbsp;&nbsp;<input type="button" value="Insert" onClick="insertArray(document.assetCreate.arrayRows.value,document.assetCreate.arrayCols.value);" />
</div>
	</td>
      </tr>
    </table>
    <hr align="left" width="80%" />
    <table border="0" cellpadding="2" cellspacing="2" class="no-style">
      <tr>
        <td><input type="button" name="button" value="Create" onClick="doSubmit('Create');"/>
        &nbsp;&nbsp;<input type="button" name="button" value="Update" onClick="doSubmit('Update');" />	
        &nbsp;&nbsp;<input type="button" style="width:120px;" value="Copy from Graphic" onClick="doCopyGraphic()" /> 
	</td>
      </tr>
   </table>
   </form>
  </body>
</html>         
END_HERE
}

sub make_asset_file
{
  my $params = shift;

  $params->{assetId} =~ tr/ /_/;

  $params->{assetBody} =~ s/\\\[\r?\n(.*)\r?\n\\\]\r?\n?/$1/; 
  $params->{assetBody} =~ s/^[\$\r\n\s]+(.*)/$1/s;
  $params->{assetBody} =~ s/(.*)[\$\r\n\s]+$/$1/s;

  $params->{assetBody} =~ s/\r//;
  $params->{assetBody} =~ s/\s*$//;

  my $src_file_path = $asset_root . $params->{assetId} . ".tex";
  my $img_file_path = $asset_root . $params->{assetId} . '.gif'; 

  my $fontFamilyBegin = ( $params->{fontFamily} eq "" ? "" 
                          : "\\" . $params->{fontFamily} . "{\n" );

  my $fontFamilyEnd = ( $params->{fontFamily} eq "" ? "" : "}\n" );

  my $fontSize = ( $params->{fontSize} eq "" ? "\\normalsize\n"
                   : "\\" . $params->{fontSize} . "\n" );

  open(FILE, ">$src_file_path") || return 0;

  print FILE "\\documentclass[10pt]{article}\n"
             . "\\pagestyle{empty}\n"
             . "\\usepackage{textcomp}\n"
             . "\\usepackage{tensor}\n"
             . "\\begin{document}\n"
  	     . $fontSize
	     . "\\begin{displaymath}\n"
	     . $fontFamilyBegin
	     . $params->{assetBody} . "\n"
	     . $fontFamilyEnd
	     . "\\end{displaymath}\n"
	     . "\\end{document}";

  close FILE;

  my $dest_file = $textogif_dir . $params->{assetId} . ".tex";
  #warn "copy $src_file_path to $dest_file";
  copy($src_file_path,$dest_file);
}
1;
