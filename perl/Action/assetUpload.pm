package Action::assetUpload;

use Cwd;
use URI;
use Session;
use ItemConstants;
use ItemAsset;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  $in{onlineAssetName} = '' unless exists $in{onlineAssetName};
  
  unless(defined $in{actionType})
  {
    my $isPrintVersion = ($in{onlineAssetName} ne '');
  
    # if the user is uploading a print version for the online asset
    # check that a print version does not already exist  
    if ($isPrintVersion) {
      my $contentAssetPair = &getContentAssetPair($dbh, $OT_ITEM, $in{itemId}, $in{assetName});
      
      # if a print version exists
      # notify the user that proceeding will delete the existing print version asset
      if ($contentAssetPair ne '') {
        $in{message} = "A print version exists for this asset. If you continue, the print version will be replaced.";
      }
    }

    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
  }
  
  our %asset_ext = map { $_ => 1 } @graphic_extensions;
  our %media_ext = map { $_ => 1 } @media_extensions;
  our %banned_ext = map { $_ => 1 } @banned_extensions;
  
  
  if($in{actionType} eq "upload")
  {
    my @date = localtime(time);
    my $tstamp = sprintf('%4d%02d%02d_%02d%02d%02d', $date[5] + 1900, $date[4] + 1, $date[3], $date[2], $date[1], $date[0]);
  
    $in{myfile} =~ /([^\/\\.]+)\.(.*?)$/;
    my $uploadName = $1;
    my $ext = $2;
  
    if($in{onlineAssetName} eq '') {
  
      unless (exists($asset_ext{$ext})) {
        $in{message} = "Unsupported image extension: $ext<p/>To upload images you will need to convert $in{myfile} to one of the following: @graphic_extensions";

	return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
      } 
    } else {
  
      if (exists $media_ext{$ext}) {
        $in{message} = "Media extension: $ext<p/>Media file types must be uploaded using the Media Upload function";

	return [ $q->psgi_header('text/html'), [ &print_wecome(\%in) ] ];

      } elsif (exists $asset_ext{$ext}) {
        $in{message} = "Image extension: $ext<p/>Image file types must be uploaded using the Image Upload function";

	return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];

      } elsif (exists $banned_ext{$ext}) {
        $in{message} = "Prohibited extension: $ext<p>&nbsp;</p>This file type cannot be uploaded";

	return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
      }
    }
  
    $uploadName =~ s/\s/_/g; 
    $uploadName =~ s/\./_/g; 
  
    $in{assetName} = (exists($asset_ext{$ext}) ? $in{itemExternalId} : $uploadName) . "_${tstamp}.${ext}";
  
    my $sourceUrl = $in{myfile};
  
    my $asset = new ItemAsset($in{itemBankId},$in{itemExternalId},$in{version},$in{assetName});
    my $uploadHandle = $q->upload("myfile");
  
    my $MEGABYTE = 1048576;
    my $MAX_FILE_SIZE = 5 * $MEGABYTE;
  
    my $fileSize = -s $uploadHandle;
    my $fileSizeRoundedMB = sprintf "%.2f", $fileSize/$MEGABYTE; 
    
    $in{uploadingLargeFile} = $fileSize > $MAX_FILE_SIZE; 
    
    if ($in{uploadingLargeFile} && !$in{forceFileUpload}) {
      if ($in{resizeFileOnUpload}) {
        # to do: attempt to resize the file
        $in{message} = "Resize logic has not been implemented in this build: Must resize file yourself!";
 
        return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];

      } else {
        # file has been determined to be a large file; prompt user to resize
        my $fileSizeRoundedMB = sprintf "%.2f", $fileSize/$MEGABYTE; 
        $in{message} = "You have selected a large file (".$fileSizeRoundedMB."MB) to upload. It is recommended that you decrease file size to less than ".$MAX_FILE_SIZE/$MEGABYTE."MB. You can resize the file yourself and try again, have the server attempt to resize the file by clicking 'Resize and View' button, or upload the file as is by clicking 'Upload and View' button.";
 
        return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
      }
    }
    
    # if a print version exists delete before uploading new one.
    my $isPrintVersion = ($in{onlineAssetName} ne '');
    
    if ($isPrintVersion) {
      my $contentAssetPair = &getContentAssetPair($dbh, $OT_ITEM, $in{itemId}, $in{onlineAssetName});
      if ($contentAssetPair) {
        my $printVersion = ItemAsset->new($in{itemBankId},$in{itemExternalId},$in{version},$contentAssetPair);
        $printVersion->delete();
    	}
    }
  
    unless($asset->create($uploadHandle)) {
      $in{message} = "Image '$in{assetName}' already exists.<br /> Please choose another.";

      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
    }
  
    &setAssetAttributes($dbh, $in{itemId}, $in{assetName},$in{media_description}, $sourceUrl, $user->{id});
  
    if($in{onlineAssetName} ne '') {
       &setContentAssetPair($dbh, $OT_ITEM, $in{itemId}, $in{onlineAssetName}, $in{assetName}); 
    }
  
    $in{message} = "Upload Complete!";
 
    return [ $q->psgi_header('text/html'), [ &print_preview(\%in) ] ];
  }
}

### ALL DONE! ###

sub print_welcome {

  my $params = shift;
  my $msg = ( defined($params->{message})
        ? "<div style='color:#ff0000;font-weight:bold'>"
	  . $params->{message} . "</div>" : "");
  
  my $uploadActions = "<input type=\"button\" value=\"Upload and View\" onClick=\"showSpinner(this.form)\" />&nbsp;<span id=\"progress_spinner\"></span>";

  # give user option to attempt to resize file or continue upload with file at its current size
  if ( defined($params->{uploadingLargeFile}) && $params->{uploadingLargeFile} ) {
    $uploadActions = "<input type=\"button\" value=\"Resize and View\" onClick=\"document.getElementById('resizeFileOnUpload').value=1;showSpinner(this.form)\" />"
                     . "<input type=\"button\" value=\"Upload and View\" onClick=\"document.getElementById('forceFileUpload').value=1;showSpinner(this.form)\" />"
                     . "&nbsp;<span id=\"progress_spinner\"></span>";
  }
  
  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Image Upload</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script>
	function sleep(delay) {
    	    var start = new Date().getTime();
    	    while (new Date().getTime() < start + delay);
	}
	function showSpinner(f) {
	    if(!document.upload.myfile.value) {
	      alert('Please click Browse and select a file to upload.');
	      return false;
	    }
	    document.getElementById('progress_spinner').innerHTML = '<img src="/common/images/spinner.gif" />';
	    sleep(1000);
	    f.submit();
	}
    </script>
  </head>
  <body>
    <div class="title">Image Upload</div>
    ${msg} 
   <br />
   <form name="upload" action="assetUpload.pl" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
     <input type="hidden" name="itemId" value="$params->{itemId}" />
     <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
     <input type="hidden" name="version" value="$params->{version}" />
     
     <input type="hidden" name="onlineAssetName" value="$params->{onlineAssetName}" />
     <input type="hidden" name="actionType" value="upload" />
     <input type="hidden" name="forceFileUpload" />
     <input type="hidden" name="resizeFileOnUpload"/>
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
        ${uploadActions}
      </td>
     </tr>
   </table>             
    <p>
        Note: It is not recommended to upload files larger than 5MB, the system will display a warning
    </p>
   </form>
  </body>
</html>         
END_HERE
}          

sub print_preview {

  my $params = shift;

  my $asset = new ItemAsset($params->{itemBankId},$params->{itemExternalId},$params->{version},$params->{assetName});

  my $assetHtml = '';

  if($asset->{ext} eq 'swf') {
    $assetHtml = <<END_HERE;
    <object name="flash" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
            codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,29,0" width="550" height="400">
      <param name="movie" value="$asset->{url}" />
      <param name="quality" value="high" />
      <param name="FlashVars" value="" />
      <embed name="flash" src="$asset->{url}" width="550" height="400" 
             quality="high" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" flashvars="" />
  
   </object>
END_HERE
  } elsif($asset->{ext} eq 'svg') {
    $assetHtml = <<END_HERE;
    <object data="$asset->{url}" type="image/svg+xml" wmode="transparent" width="$asset->{width}" height="$asset->{height}"></object>
END_HERE
  } elsif(exists $asset_ext{$asset->{ext}}) {
    $assetHtml = '<img src="' . $asset->{url} . '" />';
  } else {
    $assetHtml = '<a href="' . $asset->{url} . '">Click to download</a>';
  }

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>SBAC CDE Image View</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript">  

      \$(document).ready(function() {
        var resizeWindowByWidth = window.innerWidth < \$(document).width();
        var resizeWindowByHeight = window.innerHeight < \$("#assetContent").height();

        // resize the window to fit asset
        if ( resizeWindowByWidth || resizeWindowByHeight ) {
          var windowWidth = resizeWindowByWidth ? \$(document).width() + window.outerWidth - \$(window).width() : window.outerWidth;
          var windowHeight = resizeWindowByHeight ? \$("#assetContent").height() + window.outerHeight - \$(window).height() : window.outerHeight;
          window.resizeTo(windowWidth, windowHeight);
        }
      });

    </script>
  </head>
  <body>
    <div class="title">Image View</div>
    <p><a href="assetUpload.pl?itemBankId=$params->{itemBankId}&itemId=$params->{itemId}&itemExternalId=$params->{itemExternalId}&version=$params->{version}">Upload New Image</a></p>
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
        <td><span class="text">Title:</span></td>
	<td><b>$asset->{title}</b></td>
      </tr>
    </table>  
    <br />
    <table id="assetContent" border="1" cellpadding="2" cellspacing="2" class="no-style">
      <tbody>
       <tr>
         <td valign="top">
           ${assetHtml}
         </td>  
       </tr>
      </tbody>
    </table>
    <br />
    <p><input type="button" onClick="self.close(); return true;" value="Close" /></p>
  </body>
</html>         
END_HERE
}          
1;
