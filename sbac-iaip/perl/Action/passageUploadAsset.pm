package Action::passageUploadAsset;

use Cwd;
use File::Copy;
use URI;
use ItemConstants;
use PassageAsset;
use Session;


sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );

  unless ( defined $in{actionType} ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(%in) ]];
  }
  
  $in{onlineAssetName} = '' unless exists $in{onlineAssetName};
  
  our $asset_root = "${passagePath}lib$in{itemBankId}/images/p$in{passageId}/";
  our $asset_url  = "${passageUrl}lib$in{itemBankId}/images/p$in{passageId}/";
  
  our %asset_ext = map { $_ => 1 } @graphic_extensions;
  our %media_ext = map { $_ => 1 } @media_extensions;
  our %banned_ext = map { $_ => 1 } @banned_extensions;
  
  if ( $in{actionType} eq "upload" ) {
  
    my @date = localtime(time);
    my $tstamp = sprintf('%4d%02d%02d_%02d%02d%02d', $date[5] + 1900, $date[4] + 1, $date[3], $date[2], $date[1], $date[0]);
  
    $in{myfile} =~ /([^\/\\.]+)\.(.*?)$/;
    my $uploadName = $1;
    my $ext = $2;
  
    $uploadName =~ s/\s/_/g; 
    $uploadName =~ s/\./_/g; 
  
    $in{assetName} = (exists($asset_ext{$ext}) ? 'psg' : $uploadName) . "_${tstamp}.${ext}";
  
## Modified By Mithun
    my $itemAssetFile = "";
    if (${ext} ne "" && ${ext} eq "eps") {
	$itemAssetFile = substr $in{onlineAssetName}, 0, (length($in{onlineAssetName}) - 4);
	$itemAssetFile = $itemAssetFile . ".eps";
	$in{assetName} = $itemAssetFile;
    }
    else {
	$itemAssetFile = $in{assetName};
    }
#################

    if($in{onlineAssetName} eq '') {
  
        unless (exists($asset_ext{$ext})) {
          $in{message} = "Unsupported image extension: $ext<p/>To upload images you will need to convert $in{myfile} to one of the following: @graphic_extensions";
          return [ $q->psgi_header('text/html'), [ &print_welcome(%in) ]];
        }
    } else {
  
        if (exists $media_ext{$ext}) {
          $in{message} = "Media extension: $ext<p/>Media file types must be uploaded using the Media Upload function";
          return [ $q->psgi_header('text/html'), [ &print_welcome(%in) ]];
        } elsif (exists $banned_ext{$ext}) {
          $in{message} = "Prohibited extension: $ext<p>&nbsp;</p>This file type cannot be uploaded";
          return [ $q->psgi_header('text/html'), [ &print_welcome(%in) ]];
        } 
  
    }
  
    my $uploadHandle = $q->upload("myfile");
  
    my $asset = new PassageAsset( $in{itemBankId}, $in{passageId}, $in{assetName} );
  
    my $MEGABYTE = 1048576;
    my $MAX_FILE_SIZE = 5 * $MEGABYTE;
  
    my $fileSize = -s $uploadHandle;
  
    if ($fileSize > $MAX_FILE_SIZE)  {
        # file has been determined to be a large file; prompt user to resize
        my $fileSizeRoundedMB = sprintf "%.2f", $fileSize/$MEGABYTE;
        $in{message} = "The file you have selected is too large (".$fileSizeRoundedMB."MB); to proceed you must decrease file size to less than ".$MAX_FILE_SIZE/$MEGABYTE."MB";
        return [ $q->psgi_header('text/html'), [ &print_welcome(%in) ]];
    }
  
    unless ( $asset->create($uploadHandle) ) {
  
      $in{message} = "Image '$in{assetName}' already exists.<br /> Please choose another.";
      return [ $q->psgi_header('text/html'), [ &print_welcome(%in) ]];
    }
  
    if($in{onlineAssetName} ne '') {	
	#&setContentAssetPair($dbh, $OT_PASSAGE, $in{passageId}, $in{onlineAssetName}, $itemAssetFile);
      &setContentAssetPair($dbh, $OT_PASSAGE, $in{passageId}, $in{onlineAssetName}, $in{assetName});
    }
      
    $in{message} = "Upload Complete!";
 
    return [ $q->psgi_header('text/html'), [ &print_preview() ]];
  }
}
### ALL DONE! ###

sub print_welcome {

    my $params = shift;
    my $msg    = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;font-weight:bold'>"
          . $params->{message}
          . "</div>"
        : "" );

    my $dpi = ( defined $params->{dpi}        ? $params->{dpi}        : "150" );
    my $assetBody =
      ( defined $params->{assetBody} ? $params->{assetBody} : "" );

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Image Upload</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
    <script>
       function doUpload() {
	 if(!document.upload.myfile.value) {
	   alert('Please click Browse and select a file to upload.');
	   return false;
	 }
	 document.upload.submit();
       }
    </script>
  <body>
    <div class="title">Upload Image</div>
    ${msg} 
   <br />
   <form name="upload" action="passageUploadAsset.pl" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="itemBankId" value="$in{itemBankId}" />
     <input type="hidden" name="passageId" value="$in{passageId}" />
     <input type="hidden" name="actionType" value="upload" />
     <input type="hidden" name="onlineAssetName" value="$in{onlineAssetName}" />
     
   <table border=0 cellspacing=4 cellpadding=4 class="no-style">
     <tr>
       <td>
         <span class="text">File To Upload:</span></td>
	 <td><input type="file" name="myfile" />
       </td>
     </tr>
    <tr>
      <td>&nbsp;</td>
      <td>
      <input type="button" value="Upload and View" onClick="doUpload();" />
      </td>
     </tr>
   </table>             
   </form>
  </body>
</html>         
END_HERE
}

sub print_preview {
  my $psgi_out = '';

    my $asset =
      new PassageAsset( $in{itemBankId}, $in{passageId},
        $in{assetName} );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>View Image</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
  <body>
    <div class="title">View Image</div>
    <p><a href="passageUploadAsset.pl?itemBankId=$in{itemBankId}&passageId=$in{passageId}">Upload New Image</a></p>
    <form name="assetCreate" action="" method="POST">
     <input type="hidden" name="actionType" value="doSomething" />
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
        <td><span class="text">Title:</span></td>
	<td><b>$asset->{title}</b></td>
      </tr>
    </table>
    <table id="assetContent" border="1" cellpadding="2" cellspacing="2" class="no-style">
      <tbody>
       <tr>
         <td valign="top"> 
END_HERE

    if ( $asset->{url} =~ /svg$/ ) {
        $psgi_out .= <<END_HERE;
	    <embed src="$asset->{url}" type="image/svg+xml"></object>
END_HERE
    } elsif(exists $asset_ext{$asset->{ext}}) {
       $psgi_out .= '<img src="' . $asset->{url} . '" />';
    } else {
       $psgi_out .= '<a href="' . $asset->{url} . '">Click to download</a>';
    }

    $psgi_out .= <<END_HERE;
         </td>  
       </tr>
      </tbody>
    </table>
    <br />
    <p><input type="button" onClick="window.close(); return true;" value="Close" /></p>
   </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}
1;
