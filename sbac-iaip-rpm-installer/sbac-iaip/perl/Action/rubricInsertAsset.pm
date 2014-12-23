package Action::rubricInsertAsset;

use Cwd;
use File::Copy "cp";
use File::Glob ':glob';
use URI;
use File::Find;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $debug = 1;
  
  unless ( defined $in{itemBankId} ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  #
  # Check for copy/delete actions and carry those out first
  #
  if ( defined $in{myAction} ) {
  
      my $assetDir = "${rubricPath}lib$in{itemBankId}/images/r$in{rubricId}/";
  
      if ( $in{myAction} eq 'copy' ) {
          my $fileCounter = 0;
          my $newFileName = $in{imageId};
          while ( -e $assetDir . $newFileName ) {
              $newFileName = $in{imageId};
              $newFileName =~ s/\.(\w+)$/_$fileCounter\.$1/;
              $fileCounter++;
          }
          cp( $assetDir . $in{imageId}, $assetDir . $newFileName );
  
      }
      elsif ( $in{myAction} eq 'delete' ) {
  
          #
          # Before deleting Image, make sure it isn't part of the HTML
          #
          my $rubricHtml = '';
          open INFILE, "<${rubricPath}lib$in{itemBankId}/r$in{rubricId}.htm";
          while (<INFILE>) {
              $rubricHtml .= $_;
          }
  
          if ( $rubricHtml =~ m/\/r$in{rubricId}\/$in{imageId}/ ) {
            warn "Could not delete " . $in{imageId};
  	    $in{message} = 'Cannot delete image, as reference to image is part of saved content.';
          }
          else {
              my $imagePrefix = $in{imageId};
              $imagePrefix =~ s/\.\w+$//;
              foreach ( bsd_glob( $assetDir . $imagePrefix . '.*' ) ) {
                  unlink($_);
              }
  
  	    # also find and delete any asset pair
  
              my $sql = sprintf('SELECT * FROM content_asset_pair WHERE cap_object_type=%d AND cap_object_id=%d AND cap_asset_name=%s',
  	                      $OT_RUBRIC,
  			      $in{rubricId},
  			      $dbh->quote($in{imageId}));
              my $sth = $dbh->prepare($sql);
  	    $sth->execute();
  	    while(my $row = $sth->fetchrow_hashref) {
  
  	      unlink($assetDir . $row->{cap_pair_name}); 
  	    }
  
              $sql = sprintf('DELETE FROM content_asset_pair WHERE cap_object_type=%d AND cap_object_id=%d AND cap_asset_name=%s',
  	                      $OT_RUBRIC,
  			      $in{rubricId},
  			      $dbh->quote($in{imageId}));
              $sth = $dbh->prepare($sql);
  	    $sth->execute();
          }
  
      }
  
  }
  
  return [ $q->psgi_header(
                 -type          => 'text/html',
                 -pragma        => 'nocache',
                 -cache_control => 'no-cache, must-revalidate'),
           [ &print_preview( \%in ) ]];
  
}
### ALL DONE! ###

sub print_welcome {

    my $params = shift;

    my $defaultBank =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : "0" );

    return <<END_HERE;
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Image Finder</title>
  </head>
  <body bgcolor="#FFFFCC">
    <h3>Image Finder</h3>
    <form name="assetFind" action="assetFind.pl" method="POST">
    <table border="0" cellspacing="4" cellpadding="4" class="no-style">
      <tr><td>Bank:</td><td>${defaultBank}</td></tr>
      <tr>
        <td>ID:</td>
        <td><input type="text" size="20" name="findTerms" />&nbsp;&nbsp;
	    <input type="submit" value="Find" />
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

    my $params     = shift;
    my $itemBankId = $params->{itemBankId};
    my $rubricId        = $params->{rubricId};
    my $sortBy     = $in{sortBy} || 'name';

    my $msg = defined($in{message})
          ? '<br /><span style="color:red;">' . $in{message} . '</span><br />'
	  : '';

    my $sortButton =
      $sortBy eq 'name'
      ? '<a href="#" onClick="sortBy(\'date\');">Sort By Date</a>'
      : '<a href="#" onClick="sortBy(\'name\');">Sort By Name</a>';

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Insert Image</title>
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script type="text/javascript">
    <!--
      function copyImageTag (url)
      {
	      window.opener.tmpEditorObj.insertContent("<img src='"+url+"' alt=''/>");
	      //window.opener.tmpEditorObj.pumpEvents(); 
	      window.close();
      }	 

      function embedSVGTag (url,width,height)
      {
          window.opener.tmpEditorObj.insertContent(
           "<object data='"+url+"' type='image/svg+xml' wmode='transparent' width='"+width+"' height='"+height+"'>"
           + "</object>");
 
          window.close();
      }    

      function editImage(imageId) {
       var editWin = window.open('${orcaUrl}cgi-bin/editRubricImage.pl?image='+imageId+'&item_bank_id=${itemBankId}&rubric=${rubricId}','editWin','width=600,height=400,resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
       editWin.moveTo(200,150);
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
    <form name="actionForm" action="rubricInsertAsset.pl" method="POST">
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="rubricId" value="${rubricId}" />
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="imageId" value="" />
	<input type="hidden" name="sortBy" value="${sortBy}" />
    </form>
    <form name="uploadForm" action="rubricUploadAsset.pl" method="POST" target="uploadWin">
      
	<input type="hidden" name="itemBankId" value="${itemBankId}" />
        <input type="hidden" name="rubricId" value="${rubricId}" />
	<input type="hidden" name="onlineAssetName" value="" />
    </form>
    <form name="userForm" action="" method="POST">
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
    <tr><td width="8px"></td><td></td></tr>
    <tr><td></td><td>
    <div class="title">Rubric Images</div>
    ${msg}
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
			<tr>
				<td colspan="2">${sortButton}</td>
      </tr>
    </table> 
    <br />
    <div><span class="text">Click Image to Insert</span></div>
END_HERE

    my $sortSub = sub { $a->{title} cmp $b->{title} };

    if ( $sortBy eq 'date' ) {
        $sortSub = sub { $b->{date} <=> $a->{date} };
    }

    foreach my $asset (
        sort $sortSub &getRubricAssets( $in{itemBankId}, $in{rubricId} ) )
    {
        my $assetHtml   = '';
        my $toolbarHtml = '';

        if ( $asset->{url} =~ /svg$/ ) {
            $assetHtml = 
'<object data="'.$asset->{url}.'" type="image/svg+xml" wmode="transparent" width="'.$asset->{width}.'" height="'.$asset->{height}.'">'
              . '</object>';

            $toolbarHtml =
'<input style="width: 50px;" type="button" value="Insert" onClick="embedSVGTag(\''
              . $asset->{url} . '\',\''
              . $asset->{width} . '\',\''
              . $asset->{height}
              . '\'); return true;"><br />'
              . '<input style="width: 50px;" type="button" value="Copy" onClick="copyImage(\''
              . $asset->{name}
              . '\');"><br />'
              . '<input style="width: 50px;" type="button" value="Delete" onClick="deleteImage(\''
              . $asset->{name}
              . '\');">'
              . 'Print Version:<br />'
              . ($asset_pair ? '<a href="' . $asset_pair->{url} . '" />Download</a><br />' : '')
              . '<input style="width: 55px;" type="button" value="Upload" onClick="doUpload(\''.$asset->{name}.'\');">';
        } elsif (grep $_ eq $asset->{ext}, @media_extensions) {
          # ignore; media should be inserted from media asset table
        } else {

          my $asset_pair = &getContentAssetPair($dbh,$OT_RUBRIC,$rubricId,$asset->{name});
          $asset_pair = ($asset_pair eq '') ? 0 
                                            : RubricAsset->new($itemBankId,$rubricId,$asset_pair);
            $assetHtml =
                '<a href="#" onClick="copyImageTag(\''
              . $asset->{url}
              . '\'); return true;">'
              . '<img style="border:0px;" src="'
              . $asset->{url}
              . '" /></a>';
            $toolbarHtml =
'<input style="width: 50px;" type="button" value="Edit" onClick="editImage(\''
              . $asset->{name}
              . '\');"><br />'
              . '<input style="width: 50px;" type="button" value="Copy" onClick="copyImage(\''
              . $asset->{name}
              . '\');"><br />'
              . '<input style="width: 50px;" type="button" value="Delete" onClick="deleteImage(\''
              . $asset->{name}
              . '\');"><br /><br />'
              . 'Print Version:<br />'
              . ($asset_pair ? '<a href="' . $asset_pair->{url} . '" />Download</a><br />' : '')
              . '<input style="width: 55px;" type="button" value="Upload" onClick="doUpload(\''.$asset->{name}.'\');">';
        }

        unless (grep $_ eq $asset->{ext}, @media_extensions) {

          $psgi_out .= <<END_HERE;
          <b>$asset->{title}</b><br />
	  <table border="1" cellpadding="2" cellspacing="2" class="no-style">
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

    $psgi_out .= "</td></tr></table>";
    $psgi_out .= "</form></body></html>\n";
  return $psgi_out;
}
1;
