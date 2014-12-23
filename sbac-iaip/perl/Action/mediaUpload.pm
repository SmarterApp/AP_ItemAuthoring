package Action::mediaUpload;

use Cwd;
use URI;
use ItemConstants;
use ItemAsset;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  unless(defined $in{actionType})
  {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }  


  our %media_ext = map { $_ => 1 } @media_extensions;
  our %graphic_ext = map { $_ => 1 } @graphic_extensions;
  
  if($in{actionType} eq "upload")
  {
    $in{myfile} =~ /([^\/\\.]+)\.(.*?)$/;
    my $uploadName = $1;
    my $ext = $2;
  
    # check to see that file extension is supported
    unless (exists($media_ext{$ext})) {
  
      if(exists $graphic_ext{$ext}) {
        $in{message} = "The Upload Media feature is for audio or video files only. Please use the Upload Images feature to upload files with the '$ext' extension.";
      } else {
        $in{message} = "Unsupported media extension: $ext<p/>To upload audio or video files you will need to convert $in{myfile} to one of the following: @media_extensions";
      }
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
    }
  
    # rename file based on timestamp
    $uploadName =~ s/\s/_/g; 
    $uploadName =~ s/\./_/g; 
  
    my @date = localtime(time);
    my $tstamp = sprintf('%4d%02d%02d_%02d%02d%02d', $date[5] + 1900, $date[4] + 1, $date[3], $date[2], $date[1], $date[0]);
    $in{assetName} = (exists($media_ext{$ext}) ? $in{itemExternalId} : $uploadName) . "_${tstamp}.${ext}";
  
    # given above code this will always succeed
    if($in{assetName} eq "")
    {
      $in{message} = "Please enter a Media Title."; 
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
    }
  
    my $sourceUrl = $in{myfile};
  
    my $asset = new ItemAsset($in{itemBankId},$in{itemExternalId},$in{version},$in{assetName});
    my $uploadHandle = $q->upload("myfile");
  
    # check that file does not exceed the maximum file size
    my $MEGABYTE = 1048576;
    my $MAX_FILE_SIZE = 5 * $MEGABYTE;
  
    my $fileSize = -s $uploadHandle;
    
    $in{uploadingLargeFile} = $fileSize > $MAX_FILE_SIZE; 
    
    if ($in{uploadingLargeFile} && !$in{forceFileUpload}) {
      if ($in{resizeFileOnUpload}) {
        # to do: attempt to resize the file
        $in{message} = "Resize logic has not been implemented in this build: Must resize file yourself!";
  
        return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
      } else {
        # file has been determined to be a large file; prompt user to resize
        my $fileSizeRoundedMB = sprintf "%.2f", $fileSize/$MEGABYTE; 
        $in{message} = "You have selected a large file (".$fileSizeRoundedMB."MB) to upload. It is recommended that you decrease file size to less than ".$MAX_FILE_SIZE/$MEGABYTE."MB. You can resize the file yourself and try again, have the server attempt to resize the file by clicking 'Resize and View' button, or upload the file as is by clicking 'Upload and View' button.";
  
        return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
      }
    }
  
    # check that not overwriting file; again given the naming convention above this check will always succeed
    unless($asset->create($uploadHandle)) {
      $in{message} = "Media '$in{assetName}' already exists.<br /> Please choose another.";
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
    }
  
    # check to see that file doesn't already exits for this item
    my @files = <$asset-\>{basePath}*>;
  
    foreach my $file (@files) {
      if ($file ne $asset->{path}) {
        if (system("cmp", "-s", $asset->{path}, $file) == 0) {
          $asset->delete($dbh);
          $in{message} = "Cannot upload: The file you are attempting to upload already exists for this item.";
	  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
        }
      }
    }
  
    # check that mp4 files are in supported codec
    if ($ext eq "mp4") {
      use XML::XPath;
      my $media_metadata_xml = `/usr/local/bin/ffprobe -v 0 $asset->{path} -show_streams -of xml`;
  
      my $xp = new XML::XPath( xml => $media_metadata_xml);
      my $node_set = $xp->find("//stream[\@codec_type='video']/\@codec_name");
      my @video_codecs;
      if (my @node_list = $node_set->get_nodelist) { 
        @video_codecs = map($_->string_value, @node_list);
      }
  
      if ($video_codecs[0] ne "h264") {
        $asset->delete($dbh);
        $in{message} = "The system does not support $video_codecs[0] video codec for mp4 files, please convert the file $in{myfile} to H.264 video codec and reupload.";
	return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
      }
    }
  
    # add record to the item asset attribute and complete the upload
    &setAssetAttributes($dbh, $in{itemId}, $in{assetName}, $in{media_description}, $sourceUrl, $user->{id});
    my $sql = sprintf("SELECT iaa_id FROM item_asset_attribute WHERE iaa_filename='%s';", $in{assetName});
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my @row = $sth->fetchrow_array();
    $in{iaa_id} = $row[0];
  
    $in{message} = "Upload Complete!";
  
    return [ $q->psgi_header('text/html'), [ &print_preview(\%in) ]];
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
    <title>Media Upload</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script>
	function sleep(delay) {
    	    var start = new Date().getTime();
    	    while (new Date().getTime() < start + delay);
	}

	function showSpinner(f) {
	    document.getElementById('progress_spinner').innerHTML = '<img src="/common/images/spinner.gif" />';
	    sleep(1000);
	    f.submit();
	}
    </script>
  </head>
  <body>
    <div class="title">Media Upload</div>
    ${msg} 
   <br />
   <form name="upload" action="mediaUpload.pl" method="POST" enctype="multipart/form-data">
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
       <td>
         <span class="text">Media Description:</span></td>
         <td><textarea name="media_description" rows="4" cols="40"></textarea>
       </td>
     </tr>
    <tr>
      <td>&nbsp;</td>
      <td>
        ${uploadActions}
      </td>
     </tr>
     <tr>
      <td>&nbsp;</td>
      <td>
        Note: It is not recommended to upload files larger than 5MB, the system will display a warning
      </td>
     </tr>
   </table>             
   </form>
  </body>
</html>         
END_HERE
}          

sub print_preview {

  my $params = shift;

  my $asset = new ItemAsset($params->{itemBankId}, $params->{itemExternalId}, $params->{version}, $params->{assetName});

  my $cssIncludes = <<CSS_INCLUDES;
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
CSS_INCLUDES

  my $jsIncludes = <<JS_INCLUDES;
<script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
JS_INCLUDES

  my $documentReadyFunction;
  my $assetHtml;

  if(exists $media_ext{$asset->{ext}}) {
    if ($asset->{ext} eq "swf") {
      $assetHtml = <<END_HERE;
<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" width="550" height="400">
  <PARAM NAME="movie" VALUE="$asset->{url}">
  <PARAM NAME="FlashVars" VALUE="">
  <PARAM NAME="quality" VALUE="high">
  <EMBED SRC="$asset->{url}" FlashVars="" quality="high" WIDTH="550" HEIGHT="400" TYPE="application-x-shockwave-flash" />
</OBJECT>
END_HERE
    } else {
      $cssIncludes .= <<CSS_INCLUDES;
    <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
CSS_INCLUDES

      $jsIncludes .= <<JS_INCLUDES;
    <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
JS_INCLUDES

      # Print an interface for the audio/video file
      my $playerId = "orca_media_$params->{itemExternalId}_$asset->{title}";
      $assetHtml = getMediaHtml($playerId, $asset->{ext}, $asset->{title}, $asset->{path});
      $documentReadyFunction = getMediaReadyFunction( $playerId, $asset->{ext}, $asset->{url}, $asset->{path} );
    }
  } else {
    $assetHtml = '<a href="' . $asset->{url} . '">Click to download</a>';
  }

  my $filesize = sprintf("%.1f", (-s ${webPath} . ${orcaUrl} . 'images/lib' . $params->{itemBankId} . '/' . $params->{itemExternalId} . '/' . $params->{assetName})/1024).' kb';

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>SBAC CDE Media View</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    ${cssIncludes}
    ${jsIncludes}
    <script type="text/javascript">  

      \$(document).ready(function() {
        ${documentReadyFunction}

        var resizeWindowByWidth = window.innerWidth < \$(document).width();
        var resizeWindowByHeight = window.innerHeight < \$("#assetContent").height();

        // resize the window to fit asset
        if ( resizeWindowByWidth || resizeWindowByHeight ) {
          var windowWidth = resizeWindowByWidth ? \$(document).width() + window.outerWidth - \$(window).width() : window.outerWidth;
          var windowHeight = resizeWindowByHeight ? \$("#assetContent").height() + window.outerHeight - \$(window).height() : window.outerHeight;
          window.resizeTo(windowWidth, windowHeight);
        }

        // if the no media message is still displayed hide it
        var noMediaMessage = window.opener.document.getElementById("noMediaMessage");        
        if (\$(noMediaMessage).is(':visible')) {
          \$(noMediaMessage).hide();
        }

        // upate the media table with the new asset
        var mediaAssetTable = window.opener.document.getElementById("mediaAssetTable");
        \$(mediaAssetTable).append('<tr id="$params->{assetName}"><td><i>Unassigned</i></td><td>$params->{myfile}</td><td>$params->{media_description}</td><td>$filesize</td><td><a href="#" onClick="myOpen(\\'mediaViewer\\',\\'${mediaViewUrl}?itemBankId=$params->{itemBankId}&itemName=$params->{itemExternalId}&version=$params->{version}&imageId=$params->{assetName}\\',700,500);">View</a>&nbsp;|&nbsp;<a href="#" onClick="myOpen(\\'mediaInsert\\',\\'${mediaInsertUrl}?i_id=$params->{itemId}&iaa_id=$params->{iaa_id}\\',400,350);">Associations</a>&nbsp;|&nbsp;<a href="#" onClick="myOpen(\\'mediaDelete\\',\\'${mediaDeleteUrl}?i_id=$params->{itemId}&i_version=$params->{version}&iaa_id=$params->{iaa_id}\\',400,350);">Delete</a></td></tr>');
      });

    </script>
  </head>
  <body>
    <div class="title">Media View</div>
    <p><a href="mediaUpload.pl?itemBankId=$params->{itemBankId}&itemId=$params->{itemId}&itemExternalId=$params->{itemExternalId}&version=$params->{version}">Upload New Media</a></p>
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
        <td><span class="text">Title:</span></td>
	<td><b>$params->{myfile}</b></td>
      </tr>
      <tr>
        <td><span class="text">Media Description:</span></td>
        <td>$params->{media_description}</td>
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
    <p><input type="button" onClick="window.close(); return true;" value="Close" /></p>
  </body>
</html>         
END_HERE
}          
1;
