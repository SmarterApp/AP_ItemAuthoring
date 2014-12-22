package Action::getPassageGraphicUrl;

use Cwd;
use URI;
use File::Find;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/getPassageGraphicUrl.pl";
  
  our $psg = new Passage( $dbh, $in{passageId} );
  $in{itemBankId}  = $psg->{bank};
  $in{itemBank}    = $psg->{bankName};
  $in{passageName} = $psg->{name};
  
  # Find all media files for this itemBankId, this passageId
  our @filez = ();
  
  our $asset_path = "${passagePath}lib$in{itemBankId}/images/p$in{passageId}/";
  
  our @directories = ($asset_path);
  
  find( sub { push( @filez, $File::Find::name ) if &wanted_file($_) == 1; },
      @directories );
  
  @filez = sort(@filez);
  
  return [ $q->psgi_header(
                 -type          => 'text/html',
                 -pragma        => 'nocache',
                 -cache_control => 'no-cache, must-revalidate'),
           [ &print_preview( \%in, \@filez ) ]];
}
### ALL DONE! ###

sub print_preview {
  my $psgi_out = '';

    my $params      = shift;
    my $filez       = shift;
    my $ibankNumber = $params->{itemBankId};
    my $ibankName   = $params->{itemBank};

    $psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Find Passage Graphic</title>
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script type="text/javascript">
    <!--
      function alertProps(obj) {
        var output = '';
	for (var prop in obj) {
	  output += prop + ' = ' + obj[prop] + '\\n';
        }
	alert(output);
      }

      function copyImageTag (url)
      {
	 window.opener.document.artRequest.attachImageUrl.value = url; 
	 window.opener.document.artRequest.attachedImageName.value = url; 
	 window.close();
      }	 
      
    //-->
    </script>
  </head>
  <body>
    <table border="0" cellspacing="2" cellpadding="2">
    <tr><td width="4px"></td><td></td></tr>
    <tr><td></td><td>
    <h3><span class="text">Graphics for this Passage</span></h3>
    <br />
    <div><span class="text">Click Image to Select</span></div>
    <br />
END_HERE

    foreach my $file ( @{$filez} ) {
        my $file_id   = $file;
        my $file_url  = $file;
        my $path      = $file;
        my $full_path = $file_url;
        $file_url =~ s/^${webPath}//;
        $path     =~ s/^$asset_path//;
        $path     =~ s/\/[^\/]*$//;
        $file_id  =~ s/^.*\/([^\/]*)$/$1/;
        my $image_id = $file_id;
        $file_id =~ s/\.[^.]*$//;

        my $assetHtml = '';
        $assetHtml =
            '<a href="#" onClick="copyImageTag(\''
          . $file_url
          . '\'); return true;">'
          . '<img style="border:0px;" src="'
          . $file_url
          . '" /></a>';

        $psgi_out .= <<END_HERE;
        <b>${file_id}</b><br />
	<table bgcolor="#fcfcfc" border="1" cellpadding="2" cellspacing="2">
          <tbody>
	    <tr>
	    <td valign="top">
	    </td>
	    <td valign="top">
	    ${assetHtml}
	             </td></tr></tbody></table><br />
END_HERE
    }

    $psgi_out .= "</td></tr></table>";
    $psgi_out .= "</body></html>\n";
  return $psgi_out;
}

sub wanted_file {
    my $fname = shift;
    foreach my $ext (@asset_extensions) {
        return 1 if $fname =~ m/\.$ext$/;
    }
    return 0;
}
1;
