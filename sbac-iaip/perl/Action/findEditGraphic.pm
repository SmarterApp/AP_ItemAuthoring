package Action::findEditGraphic;

use Cwd;
use URI;
use URI::Escape;
use File::Find;
use File::Glob ':glob';
use File::Copy "cp";
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/findEditGraphic.pl";
  
  @asset_extensions = ('tex');
  
  $in{type} = 'tex' unless exists( $in{type} );
  
  if ( $in{type} eq 'asy' ) {
      @asset_extensions = ('asy');
  }
  
  if ( $in{type} eq 'xml' ) {
      @asset_extensions = ('xml');
  }
  
  # Find all media files for this itemBankId, this itemId
  our @filez = ();
  
  our $asset_path = "${imagesDir}lib$in{itemBankId}/$in{itemId}/";
  our $asset_url  = "${imagesUrl}lib$in{itemBankId}/$in{itemId}/";
  
  our @directories = ($asset_path);
  
  find( sub { push( @filez, $File::Find::name ) if (&wanted_file($_) == 1 and &image_file_exists($_, $in{type})); },
      @directories );
  
  @filez = sort(@filez);
  
  return [ $q->psgi_header(
               -type          => 'text/html',
               -pragma        => 'nocache',
               -cache_control => 'no-cache, must-revalidate'),
           [ &print_preview( \%in, \@filez ) ]];
  
  exit 0;
}
### ALL DONE! ###

sub print_preview {
  my $psgi_out = '';

    my $params      = shift;
    my $filez       = shift;
    my $ibankNumber = $params->{itemBankId};
    my $itemName    = $params->{itemId};
    my $title       = 'Equation';
    my $type        = $params->{type};
    if ( $type eq 'asy' ) { $title = 'Graph'; }
    if ( $type eq 'xml' ) { $title = 'Chart'; }
    my $clicker = $title;
    if ( $type eq 'xml' ) { $clicker = 'Chart title'; }

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head>
    <title>Find ${title} to Edit</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <script type="text/javascript">
    <!--

      function copyEquation (id1,id2,src)
      {
         window.opener.parent.imageOutFrame.location.href='${asset_url}' + id1 + '.gif'; 
	 window.opener.document.assetCreate.assetId.value = id2;
	 src.replace(/&quot;/,"\\""); 
	 window.opener.document.assetCreate.assetBody.value = src;
	 window.close();
      }	 

      function copyChart(id1,id2,type,width,height)
      {
        window.opener.parent.imageOutFrame.location.href='${chartDisplayUrl}?itemBankId=${ibankNumber}&itemId=${itemName}&assetId=' + id1 + '&chartType=' + type + '&width=' + width + '&height=' + height; 
	window.opener.parent.acFrame.location.href='${assetCreateUrl}?itemBankId=${ibankNumber}&itemId=${itemName}&type=xml&version=$params->{version}&myAction=Retrieve&assetId=' + id2;
	window.close();
      }	

    //-->
    </script>
  </head>
  <body>
    <form name="userForm" action="" method="POST">
    <table border="0" cellspacing="2" cellpadding="2">
    <tr><td width="4px"></td><td></td></tr>
    <tr><td>
	 <center><h2>${title} Finder</h2></center>
    <br /> 
    <div><span style="font-size:1.5em;">Click ${clicker} to Edit</span></div>
    <br />
END_HERE

    foreach my $file ( @{$filez} ) {
        if ( $type eq 'tex' or $type eq 'asy' ) {
            my $file_id   = $file;
            my $file_url  = $file;
            my $path      = $file;
            my $full_path = $file_url;
            $file_url =~ s/^${webPath}//;
            $file_url =~ s/$type$/gif/;
            $path     =~ s/^$asset_path//;
            $path     =~ s/\/[^\/]*$//;
            $file_id  =~ s/^.*\/([^\/]*)$/$1/;
            my $image_id = $file_id . '.gif';
            $file_id =~ s/\.[^.]*$//;
            my $display_id = $file_id;
            $display_id =~ s/^V\d+\.//;

            my $src = '';
            open INFILE, "<$full_path";
            while (<INFILE>) { chomp; $src .= $_; }
            close INFILE;

            if ( $src =~
                m/\\begin\{displaymath\}[\r\n]*(.*)[\r\n]*\\end\{displaymath\}/s
              )
            {
                $src = $1;
                if ( $src =~ m/^\\math\w+\{(.*)\}$/s ) {
                    $src = $1;
                }
            }

            $src =~ s/\\/\\\\/g;
            $src =~ s/'/\\'/g;
            $src =~ s/"/&quot;/g;
            $src =~ s/\r/\\r/g;
            $src =~ s/\n/\\n/g;

            my $assetHtml =
                '<a href="#" onClick="copyEquation(\'' 
              . $file_id . '\',\''
              . $display_id . '\',\''
              . $src
              . '\'); return true;">'
              . '<img style="border:0px;" src="'
              . $file_url
              . '" /></a>';

            $psgi_out .= <<END_HERE;
          <b>${display_id}</b><br />
  	    ${assetHtml}
  	             <br /><br />
END_HERE
        }
        elsif ( $type eq 'xml' ) {

            my $file_id   = $file;
            my $file_url  = $file;
            my $path      = $file;
            my $full_path = $file_url;
            $file_url =~ s/^${webPath}//;
            $file_url =~ s/$type$/swf/;
            $path     =~ s/^$asset_path//;
            $path     =~ s/\/[^\/]*$//;
            $file_id  =~ s/^.*\/([^\/]*)$/$1/;
            my $image_id = $file_id . '.swf';
            $file_id =~ s/\.[^.]*$//;
            my $display_id = $file_id;
            $display_id =~ s/^V\d+\.//;

            my $assetId = $file_id;

            &readOgtFile(
                "${imagesDir}lib$in{itemBankId}/$in{itemId}/${assetId}.ogt",
                \%in );

            my $chartXmlUrl =
              "${imagesUrl}lib$in{itemBankId}/$in{itemId}/${assetId}.xml";
            my $chartXmlPath =
              "${imagesDir}lib$in{itemBankId}/$in{itemId}/${assetId}.xml";

            my $chartXmlEscaped = uri_escape($chartXmlUrl);

            my $chartUrl = $chartsUrl . $charts{ $in{chartType} };

            my $chartString = $charts{ $in{chartType} };

            my $width  = $in{width};
            my $height = $in{height};

            $psgi_out .= <<END_HERE;
      <a href="#" onClick="copyChart('${assetId}','${display_id}','$in{chartType}','${width}','${height}');"><b>${display_id}</b></a>
      <br />
      <OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/
    flash/swflash.cab#version=6,0,0,0" WIDTH="${width}" HEIGHT="${height}" id="${chartString}">
      <PARAM NAME=movie VALUE="${chartUrl}">
      <PARAM NAME="FlashVars" VALUE="&dataURL=${chartXmlEscaped}&chartWidth=${width}&chartHeight=${height}">
      <PARAM NAME=quality VALUE=high>
      <PARAM NAME=bgcolor VALUE=#FFFFFF>
      <EMBED src="${chartUrl}" FlashVars="&dataURL=${chartXmlEscaped}&chartWidth=${width}&chartHeight=${height}" quality=high bgcolor=#FFFFFF WIDTH="${width}" HEIGHT="${height}" NAME="${chartString}" TYPE="application/x-shockwave-flash" PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer"></EMBED>
      </OBJECT>
      <br /><br />
END_HERE
        }
    }

    $psgi_out .= "</td></tr></table></form></body></html>";
  return $psgi_out;
}

sub wanted_file {
    my $fname   = shift;
    my $version = $in{version};
    return 0 if $version ne '0' and $fname !~ m/^V$version\./;
    return 0 if $version eq '0' and $fname =~ m/^V\d+\./;
    foreach my $ext (@asset_extensions) {
        return 1 if $fname =~ m/\.$ext$/;
    }
    return 0;
}

sub image_file_exists {
    my $file_name = shift;
    my $ext = shift;
    (my $image_name = $file_name) =~ s/$ext$/gif/;
    return -e $asset_path.$image_name;
}
1;
