package Action::assetInsert;

use Cwd;
use URI;
use URI::Escape;
use ItemConstants;
use ItemAsset;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );

  our $thisUrl = "${orcaUrl}cgi-bin/assetInsert.pl";
  push @asset_extensions, 'xml';


  # Check for copy/delete actions and carry those out first
  if ( defined $in{myAction} ) {
      my $asset = new ItemAsset( $in{itemBankId}, $in{itemExternalId}, $in{version}, $in{imageId} );
  
      if ( $in{myAction} eq 'copy' ) {
          $asset->copy();
      } elsif ( $in{myAction} eq 'delete' ) {
          unless ( $asset->delete($dbh) ) {
              warn "Could not delete " . $in{imageId};
  	    $in{message} = 'Cannot delete image, as reference to image is part of saved content.';
          }
      }
  }
  
  return [ $q->psgi_header( 
             -type          => 'text/html',
             -pragma        => 'nocache',
             -cache_control => 'no-cache, must-revalidate'
           ),
	   [ &print_preview() ] ];
}

### ALL DONE! ###

sub print_preview {

  my $filez       = shift;
  my $itemBankId = $in{itemBankId};
  my $ibankName   = $banks->{ $in{itemBankId} }{name};
  my $itemName    = $in{itemExternalId};
  my $version     = $in{version};
  my $sortBy      = $in{sortBy} || 'date';

  my $msg = defined($in{message})
          ? '<br /><span style="color:red;">' . $in{message} . '</span><br />'
	  : '';

  my $sortButton =
      $sortBy eq 'name'
      ? '<a href="#" onClick="sortBy(\'date\');">Sort By Date</a>'
      : '<a href="#" onClick="sortBy(\'name\');">Sort By Name</a>';

  my $documentReadyFunction = '';

  my $sortSub = sub { $a->{title} cmp $b->{title} };

  if ( $sortBy eq 'date' ) {
    $sortSub = sub { $b->{date} <=> $a->{date} };
  }

  my $htmlBody = '';

  foreach my $asset ( sort $sortSub &getItemAssets( $in{itemBankId}, $in{itemExternalId}, $in{version} ) ) {
    
    my $assetHtml = '';
    if ( $asset->{ext} eq 'xml' ) {
      my %vars    = ();
      my $ogtFile = $asset->{path};
      $ogtFile =~ s/xml$/ogt/;
      &readOgtFile( $ogtFile, \%vars );

      my $chartString = $charts{ $vars{chartType} };
      my $chartUrl    = $chartsUrl . $chartString;
      my $chartXmlUrl = uri_escape( $asset->{url} );

      $assetHtml =
'<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" width="' . $vars{width} . '" height="' . $vars{height} . '" id="' . $chartString . '">'
              . '<PARAM NAME="movie" VALUE="' . $chartUrl . '">'
              . '<PARAM NAME="FlashVars" VALUE="&dataUrl=' . $chartXmlUrl . '&chartWidth=' . $vars{width} . '&chartHeight=' . $vars{height} . '">'
              . '<PARAM NAME="quality" VALUE="high">'
              . '<EMBED SRC="' . $chartUrl . '" FlashVars="&dataURL=' . $chartXmlUrl . '&chartWidth=' . $vars{width} . '&chartHeight=' . $vars{height} . '" quality="high" WIDTH="' . $vars{width} . '" HEIGHT="' . $vars{height} . '" NAME="' . $chartString . '" TYPE="application/x-shockwave-flash" /></OBJECT>';

      $toolbarHtml =
'<input style="width: 50px;" type="button" value="Insert" onClick="copyChartTag(\''
              . $chartUrl . '\',\''
              . $chartXmlUrl . '\','
              . $vars{width} . ','
              . $vars{height} . ',\''
              . $chartString
              . '\'); return true;">';
    } elsif ( $asset->{ext} eq 'swf' ) {

      $assetHtml =
'<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" width="550" height="400">'
              . '<PARAM NAME="movie" VALUE="' . $asset->{url} . '">'
              . '<PARAM NAME="FlashVars" VALUE="">'
              . '<PARAM NAME="quality" VALUE="high">'
              . '<EMBED SRC="' . $asset->{url} . '" FlashVars="" quality="high" WIDTH="550" HEIGHT="400" TYPE="application-x-shockwave-flash" />'
              . '</OBJECT>';

      $toolbarHtml = '<input style="width: 50px;" type="button" value="Insert" onClick="embedFlashTag(\'' . $asset->{url} . '\'); return true">';
    } elsif ( $asset->{ext} eq 'svg' ) {

      my $asset_pair = &getContentAssetPair($dbh,$OT_ITEM,$in{itemId},$asset->{fileName});
      $asset_pair = ($asset_pair eq '') ? 0 
                                       : ItemAsset->new($itemBankId,$itemName,$version,$asset_pair);

      $assetHtml = 
                  '<object data="'.$asset->{url}
                . '" type="image/svg+xml" wmode="transparent" width="'.$asset->{width}.'" height="'.$asset->{height}.'">'
                . '</object>';

      $assetHtml = sprintf qq|<embed src="%s" wmode="transparent" type="image/svg+xml" %s %s />|, $asset->{url}, ($asset->{width} ? qq|width="$asset->{width}"| : ''), ($asset->{height} ? qq|height="$asset->{height}"| : '');

      $asset->{width}  ||= 100;
      $asset->{height} ||= 100;
      $toolbarHtml =
'<input style="width: 55px;" type="button" value="Insert" onClick="embedSVGTag(\''
              . $asset->{url} . '\',\''
              . $asset->{width} . '\',\''
              . $asset->{height}
              . '\'); return true;"><br />'
              . '<input style="width: 55px;" type="button" value="Copy" onClick="copyImage(\''
              . $asset->{name}
              . '\');"><br />'
              . '<input style="width: 55px;" type="button" value="Delete" onClick="deleteImage(\''
              . $asset->{name}
              . '\');"><br /><br />'
              . 'Print Version:<br />'
              . ($asset_pair ? '<a href="' . $asset_pair->{url} . '" />Download</a><br />' : '')
              . '<input style="width: 55px;" type="button" value="Upload" onClick="doUpload(\''.$asset->{fileName}.'\');">';

    } elsif (grep $_ eq $asset->{ext}, @media_extensions) {
      # ignore; media should be inserted from media asset table
    } else {

      my $asset_pair = &getContentAssetPair($dbh,$OT_ITEM,$in{itemId},$asset->{fileName});
      $asset_pair = ($asset_pair eq '') ? 0 
                                       : ItemAsset->new($itemBankId,$itemName,$version,$asset_pair);
      $assetHtml = 
			'<a href="#" onClick="copyImageTag(\''.$asset->{url}
                 	. '\'); return true;">'
                 	. '<img style="border:0px;" src="'.$asset->{url}.'" /></a>';
    
      $toolbarHtml = 
			'<input style="width: 55px;" type="button" value="Edit" onClick="editImage(\''.$asset->{fileName}.'\');"><br />'
                  	. '<input style="width: 55px;" type="button" value="Copy" onClick="copyImage(\''.$asset->{name}.'\');"><br />'
                  	. '<input style="width: 55px;" type="button" value="Delete" onClick="deleteImage(\''.$asset->{name}.'\');"><br /><br />'
                        . 'Print Version:<br />'
                        . ($asset_pair ? '<a href="' . $asset_pair->{url} . '" />Download</a><br />' : '')
                  	. '<input style="width: 55px;" type="button" value="Upload" onClick="doUpload(\''.$asset->{fileName}.'\');">';
    }

    unless (grep $_ eq $asset->{ext}, @media_extensions) {
      $htmlBody .= <<END_HERE;
<b>$asset->{title}</b>
<br />
<table id="assetContent" bgcolor="#fcfcfc" border="1" cellpadding="2" cellspacing="2">
  <caption>$asset->{name}</caption>
  <tbody>
    <tr>
      <td valign="top">
      ${toolbarHtml} 
      </td>
      <td valign="top">
      ${assetHtml}
      </td>
    </tr>
  </tbody>
</table>
<br />
END_HERE
    }
  }

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Insert Image</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
    <script type="text/javascript">
    <!--

      \$(document).ready(function() {

        ${documentReadyFunction}

        var resizeWindowByWidth = window.innerWidth < \$(document).width();
        var resizeWindowByHeight = window.innerHeight < \$("#assetContent").height();
 
        // resize the window to fit asset
        if ( resizeWindowByWidth || resizeWindowByHeight ) {
          // account for window offset, padding, margin in resize
          var windowWidth = resizeWindowByWidth ? \$(document).width() + window.outerWidth - \$(window).width() : window.outerWidth;
          var windowHeight = resizeWindowByHeight ? \$("#assetContent").height() + window.outerHeight - \$(window).height() : window.outerHeight;
          window.resizeTo(windowWidth, windowHeight);
        }
      });

      function alertProps(obj) {
        var output = '';
	for (var prop in obj) {
	  output += prop + ' = ' + obj[prop] + '\\n';
        }
	alert(output);
      }

      function copyImageTag (url)
      {
	 window.opener.tmpEditorObj.insertContent("<img src='"+url+"' alt='' />");
	 //window.opener.tmpEditorObj.pumpEvents(); 
	 window.close();
      }	 
      
      function copyChartTag (url,data,w,h,id)
      {
	 window.opener.tmpEditorObj.insertContent("<object classid='clsid:D27CDB6E-AE6D-11cf-96B8-444553540000' codebase='https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0' width='"+w+"' height='"+h+"' id='"+id+"'>"
	   + "<param name='movie' value='"+url+"'></param>"
	   + "<param name='FlashVars' value='&dataUrl="+data+"&chartWidth="+w+"&chartHeight="+h+"'></param>"
	   + "<param name='quality' value='high'></param>"
	   + "<embed src='"+url+"' FlashVars='&dataUrl="+data+"&chartWidth="+w+"&chartHeight="+h+"' wmode='transparent' quality='high' width='"+w+"' height='"+h+"' name='"+id+"' type='application/x-shockwave-flash'></embed></object>");
	 //window.opener.tmpEditorObj.pumpEvents(); 
	 window.close();
      }	 
      
      function embedFlashTag (url)
      {
	 window.opener.tmpEditorObj.insertContent("<object classid='clsid:D27CDB6E-AE6D-11cf-96B8-444553540000' codebase='https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,29,0' width='550' height='400'>"
	   + "<param name='movie' value='"+url+"'></param>"
	   + "<param name='FlashVars' value=''></param>"
	   + "<param name='quality' value='high'></param>"
	   + "<embed src='"+url+"' FlashVars='' wmode='transparent' width='550' height='400' type='application/x-shockwave-flash'></embed></object>");
	 //window.opener.tmpEditorObj.pumpEvents(); 
	 window.close();
      }	 

     function embedSVGTag (url,width,height)
	 {
	   window.opener.tmpEditorObj.insertContent(
                "<!--[if gte IE 9]><!--><object data='"+url+"' type='image/svg+xml' width='"+width+"' height='"+height+"'><!--<![endif]-->"
                + "<embed src='"+url+"' wmode='transparent' type='image/svg+xml' width='"+width+"' height='"+height+"'></embed>"
                + "<!--[if gte IE 9]><!--></object><!--<![endif]-->" );
	   window.close();
	 }

     function editImage(imageId) {
       var editWin = window.open('${imageEditUrl}?image='+imageId+'&item_bank_id=${itemBankId}&item_name=${itemName}','editWin','width=600,height=300,resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
       editWin.moveTo(350,150);
     }

     function copyImage(imageId) {
       document.actionForm.myAction.value = 'copy';
       document.actionForm.imageId.value = imageId;
       document.actionForm.submit();
     }
     
     function deleteImage(imageId) {
       document.actionForm.myAction.value = 'delete';
       document.actionForm.imageId.value = imageId;
       document.actionForm.submit();
     }

     function sortBy(sortField) {
        document.actionForm.myAction.value = 'sort';
	 document.actionForm.sortBy.value = sortField;
	 document.actionForm.submit();
     } 

      function doUpload(assetName) {
	   document.uploadForm.onlineAssetName.value = assetName;
           var upWin = window.open('../nopage.html','uploadWin','width=600,height=300,resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
	 document.uploadForm.submit();
      }

    //-->
    </script>
  </head>
  <body>
    <form name="actionForm" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="itemExternalId" value="${itemName}" />
      <input type="hidden" name="itemId" value="$in{itemId}" />
      <input type="hidden" name="version" value="${version}" />
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="imageId" value="" />
      <input type="hidden" name="sortBy" value="${sortBy}" />
    </form>
    <form name="uploadForm" action="assetUpload.pl" method="POST" target="uploadWin">
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="itemExternalId" value="${itemName}" />
      <input type="hidden" name="itemId" value="$in{itemId}" />
      <input type="hidden" name="version" value="${version}" />
	<input type="hidden" name="onlineAssetName" value="" />
    </form>
    <form name="userForm" action="" method="POST">
    ${msg}
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
        <td width="4px"></td>
        <td></td>
      </tr>
      <tr>
        <td></td>
        <td>

    <div class="title">Images for this Item</div>
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">	
      <tr>
        <td colspan="2">${sortButton}</td>
      </tr>
    </table> 
    <br />
    <div><span class="text">Click Image to Insert</span></div>
    <br />
    ${htmlBody}
    </td></tr></table>
    </form>
  </body>
</html>
END_HERE

}
1;
