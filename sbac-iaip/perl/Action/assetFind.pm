package Action::assetFind;

use Cwd;
use URI;
use URI::Escape;
use File::Find;
use File::Copy;
use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{type} = '' unless exists $in{type};
  
  our @asset_extensions = ( "tex", "asy", "xml" );
  
  if ( defined $in{copy} ) {
  
    if ( $in{type} eq 'asy' ) {
  	copy( "${webPath}$in{copy}.ogt",
  		"${asset_path}lib$in{itemBankId}/$in{itemId}/$in{assetId}.ogt" );
    }
    elsif ( $in{type} eq 'xml' ) {
  	copy( "${webPath}$in{copy}.xml",
  		"${asset_path}lib$in{itemBankId}/$in{itemId}/$in{assetId}.xml" );
  	copy( "${webPath}$in{copy}.ogt",
  		"${asset_path}lib$in{itemBankId}/$in{itemId}/$in{assetId}.ogt" );
  	copy( "${webPath}$in{copy}.oct",
  		"${asset_path}lib$in{itemBankId}/$in{itemId}/$in{assetId}.oct" );
    }
  
    if ( $in{type} eq 'xml' ) {
  
  	my %vars = ();
  	&readOgtFile(
  		"${asset_path}lib$in{itemBankId}/$in{itemId}/$in{assetId}.ogt",
  		\%vars );
  
  	my $psgi_out = <<ENDHTML;
    <html>
      <head>
        <script language="JavaScript">
        <!--
          function loadAndQuit()
          {
            window.opener.parent.imageOutFrame.location.href='${chartDisplayUrl}?itemBankId=$in{itemBankId}&itemId=$in{itemId}&assetId=$in{assetId}&chartType=$vars{chartType}&width=$vars{width}&height=$vars{height}'; 
  	  window.opener.parent.acFrame.location.href='${assetCreateUrl}?itemBankId=$in{itemBankId}&itemId=$in{itemId}&type=xml&myAction=Retrieve&assetId=$in{assetId}';
            window.close();
          }
        //-->
        </script>
      </head>
      <body onLoad="loadAndQuit(); return true;">
      </body>
    </html>
ENDHTML
    
      return [ $q->psgi_header('text/html'), [ $psgi_out ]];
    }
    else {
  
  	my $assetBody = "";
  
  	open INFILE, "<${webPath}$in{copy}.$in{type}";
  	while (<INFILE>) {
    	  $assetBody .= $_;
  	}
  
  	$assetBody =~ s/\r//g;
  
  	if ( $assetBody =~
  			m/\\begin\{displaymath\}\n+(.*)\n+\\end\{displaymath\}/s )
  	{
  		$assetBody = $1;
  		$assetBody =~ s/^\\[a-z]+{\s*(.+)\s*}\s*$/$1/;
  	}
  	$assetBody =~ s/\\/\\\\/g;
  	$assetBody =~ s/\"/\\\"/g;
  	$assetBody =~ s/\n/\\n/g;
  	close INFILE;
  
  	my $psgi_out = <<ENDHTML;
    
    <html>
      <head>
        <script language="JavaScript">
        <!--
          function loadAndQuit()
          {
            window.opener.document.assetCreate.assetBody.value="${assetBody}";
            window.close();
          }
        //-->
        </script>
      </head>
      <body onLoad="loadAndQuit(); return true;">
      </body>
    </html>
ENDHTML
    
      return [ $q->psgi_header('text/html'), [ $psgi_out ]];
    }
  
  }
  
  unless ( defined $in{findTerms} ) {

    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  # Find all media files starting with the findTerms
  our @filez = ();
  
  our $terms = $in{findTerms};
  our $type  = $in{type};
  
  unless ( defined $in{itemBankId} ) { $in{itemBankId} = "1"; }
  
  our $asset_path = "${imagesDir}lib$in{itemBankId}";
  
  our @directories = ($asset_path);
  
  find(
  	sub {
  		push( @filez, $File::Find::name )
  		  if &wanted_file( $_, $terms, $type ) == 1;
  	},
  	@directories
  );
  
  return [ $q->header(
  	              -type          => 'text/html',
  	              -pragma        => 'nocache',
  	              -cache_control => 'no-cache, must-revalidate'),
           [ &print_preview( \%in, \@filez ) ]];

}
### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

	my $params = shift;
	my $type   = $in{type};
	my $itemId = $in{itemId};

	my $typeASY   = $type eq 'asy' ? 'SELECTED' : '';
	my $typeTEX   = $type eq 'tex' ? 'SELECTED' : '';
	my $typeChart = $type eq 'xml' ? 'SELECTED' : '';

	my $defaultBank =
	  ( defined $params->{itemBankId} ? $params->{itemBankId} : "1" );

	my %itemBanks = map { $_ => $banks->{$_}{name} } %$banks;

	my $ibankDisplay =
	  &hashToSelect( 'itemBankId', \%itemBanks, $defaultBank, '', '', 'value' );

	my $hiddenHtml = '';

	if ( defined $params->{itemBankId} ) {
		$ibankDisplay = $itemBanks{$defaultBank};
		$hiddenHtml .=
		  '<input type="hidden" name="itemBankId" value="'
		  . $params->{itemBankId} . '" />';
	}

	$psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Graphic Finder</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
  <body onLoad="document.assetFind.findTerms.focus();">
    <div class="title">Graphic Finder</div>
    <form name="assetFind" action="assetFind.pl" method="POST">
      <input type="hidden" name="assetId" value="$params->{assetId}" />
      <input type="hidden" name="itemId" value="${itemId}" />
      
      ${hiddenHtml} 
    <table border="0" cellspacing="3" cellpadding="3">
      <tr><td><span class="text">Bank:</span></td><td>${ibankDisplay}</td></tr>
      <tr>
        <td><span class="text">Type:</span></td><td>
END_HERE

	if ( $type eq '' ) {
		$psgi_out .= <<END_HERE;
	  <select name="type" style="width:100px;">
	    <option value="tex" ${typeTEX}>Equation</option>
	    <option value="asy" ${typeASY}>Graph</option>
	    <option value="xml" ${typeChart}>Chart</option>
          </select>
END_HERE
	}
	else {
		$psgi_out .= '<input type="hidden" name="type" value="' . $type . '" />';
		if ( $type eq 'tex' ) { $psgi_out .= 'Equation'; }
		if ( $type eq 'asy' ) { $psgi_out .= 'Graph'; }
		if ( $type eq 'xml' ) { $psgi_out .= 'Chart'; }
	}

	$psgi_out .= <<END_HERE;
        </td>
      </tr>
      <tr>
	<td><span class="text">Graphic Title:</span></td>
        <td><input type="text" size="20" name="findTerms" />&nbsp;&nbsp;
	    <input type="submit" value="Find" />
        </td>
      </tr>
   </table>             
   </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}

sub print_preview {
  my $psgi_out = '';

	my $params      = shift;
	my $filez       = shift;
	my $foundTerms  = $params->{findTerms};
	my $ibankNumber = $in{itemBankId};
	my $itemId      = $params->{itemId};
	my $ibankName   = $banks->{ $in{itemBankId} }{name};
	my $type        = $in{type};
	my $typeASY     = $type eq 'asy' ? 'SELECTED' : '';
	my $typeTEX     = $type eq 'tex' ? 'SELECTED' : '';
	my $typeChart   = $type eq 'xml' ? 'SELECTED' : '';
	my $clicker     = 'Image';
	if ( $type eq 'xml' ) { $clicker = 'Title'; }

	my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

	my $ibankDisplay =
	  &hashToSelect( 'itemBankId', \%itemBanks, $ibankNumber, '', '' );

	$ibankDisplay = $ibankName;

	$psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Graphic Finder</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
  <body>
    <div class="title">Graphic Finder</div>
    <form name="assetFind" action="assetFind.pl" method="POST">
      <input type="hidden" name="assetId" value="$params->{assetId}" />
      <input type="hidden" name="itemId" value="${itemId}" />
      
      <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
    <table border="0" cellspacing="3" cellpadding="3">
      <tr><td><span class="text">Bank:</span></td><td>${ibankDisplay}</td></tr> 
      <tr>
        <td><span class="text">Type:</span></td>
	<td>
END_HERE

	if ( $type eq '' ) {
		$psgi_out .= <<END_HERE;
	  <select name="type">
	    <option value="tex" ${typeTEX}>Equation</option>
	    <option value="asy" ${typeASY}>Graph</option>
	    <option value="xml" ${typeChart}>Chart</option>
          </select>
END_HERE
	}
	else {
		$psgi_out .= '<input type="hidden" name="type" value="' . $type . '" />';
		if ( $type eq 'tex' ) { $psgi_out .= 'Equation'; }
		if ( $type eq 'asy' ) { $psgi_out .= 'Graph'; }
		if ( $type eq 'xml' ) { $psgi_out .= 'Chart'; }
	}

	$psgi_out .= <<END_HERE;
	</td>
      </tr>
      <tr>
        <td><span class="text">Graphic Title:</span></td>
        <td><input type="text" size="20" name="findTerms" value="${foundTerms}" />&nbsp;&nbsp;
	    <input type="submit" value="Find" />
        </td>
      </tr>
    </table>
    <p>
    <div><span class="text">Click ${clicker} to Copy Graphic</span></div>
    </p>
END_HERE

	foreach my $file ( @{$filez} ) {
		my $file_id       = $file;
		my $file_url      = $file;
		my $file_location = $file;
		my $path          = $file;
		$file_url =~ s/^${webPath}//;
		$file_url =~ s/\.$type$//;
		$path     =~ s/^$asset_path//;
		$path     =~ s/\/[^\/]*$//;
		$file_id  =~ s/^.*\/([^\/]*)$/$1/;
		$file_id  =~ s/\.[^.]*$//;
		my $filePath = $file_url;
		$filePath =~ s/\//%2F/g;
		$filePath =~ s/\.[^.]*$//;

		if ( $type eq 'xml' ) {
			my %vars    = ();
			my $ogtFile = $file_location;
			$ogtFile =~ s/xml$/ogt/;
			&readOgtFile( $ogtFile, \%vars );

			my $chartString = $charts{ $vars{chartType} };
			my $chartUrl    = $chartsUrl . $chartString;
			$file_url .= '.xml';
			my $chartXmlUrl = uri_escape($file_url);
			$psgi_out .= <<END_HERE;
        <a href="${assetFindUrl}?itemBankId=${ibankNumber}&amp;itemId=${itemId}&amp;type=xml&amp;copy=${filePath}&amp;assetId=$params->{assetId}"><b>${file_id}</b></a>
	  <br />
	  <table bgcolor="#fcfcfc" border="1" cellpadding="2" cellspacing="2">
            <tbody><tr><td valign="top">
        <OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" 
	      width="$vars{width}" height="$vars{height}" id="${chartString}">
           <PARAM NAME="movie" VALUE="${chartUrl}">
           <PARAM NAME="FlashVars" VALUE="&dataUrl=${chartXmlUrl}&chartWidth=$vars{width}&chartHeight=$vars{height}">
	   <PARAM NAME="quality" VALUE="high">
	   <EMBED SRC="${chartUrl}" FlashVars="&dataURL=${chartXmlUrl}&chartWidth=$vars{width}&chartHeight=$vars{height}" quality="high" WIDTH="$vars{width}" HEIGHT="$vars{height}" NAME="${chartString}" TYPE="application/x-shockwave-flash" PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer" /></OBJECT>
	     </td></tr></tbody></table><br />
END_HERE
		}
		else {

			$file_url .= '.gif';

			$psgi_out .= <<END_HERE;
        <b>${file_id}</b>
	  <br />
	  <table bgcolor="#fcfcfc" border="1" cellpadding="2" cellspacing="2">
            <tbody><tr><td valign="top">
	      <a href="${assetFindUrl}?itemBankId=${ibankNumber}&amp;itemId=${itemId}&amp;type=${type}&amp;copy=${filePath}&amp;assetId=$params->{assetId}"><img style="border:0px;" src="$file_url" /></a>
	     </td></tr></tbody></table><br />
END_HERE
		}
	}

	$psgi_out .= "</form></body></html>\n";
  return $psgi_out;
}

sub wanted_file {
	my $fname = shift;
	my $term  = shift;
	my $type  = shift;
	if ( $term ne "" ) { return 0 unless $fname =~ m/^$term/; }
	return 1 if $fname =~ m/\.$type$/;
	return 0;
}
1;
