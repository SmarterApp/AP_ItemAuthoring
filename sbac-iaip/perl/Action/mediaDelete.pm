package Action::mediaDelete;

use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $IF_STEM = 1;
  our $IF_CHOICE = 2;


  our ($filename, $title, $media_description) = &get_media_info();

  my $psgi_out = '';

  if ( defined $in{action} && $in{action} eq 'delete' ) {
    eval { &delete_media(); };
  
    if ($@) {
      $psgi_out .= &print_delete_error($@);
    } else {
      $psgi_out .= &print_delete();
    }
  } else {
    $psgi_out .= &print_preview();
  }

  return [ $q->psgi_header(
              -type          => 'text/html',
              -pragma        => 'nocache',
              -cache_control => 'no-cache, must-revalidate'),
           [ $psgi_out ]];
}

### ALL DONE! ###

sub print_preview {

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
  <meta charset=utf-8 />
    <title>SBAC CDE Delete Media</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
  <body>
    <form name="actionForm" action="${orcaUrl}cgi-bin/mediaDelete.pl" method="POST">
      <input type="hidden" name="i_id" value="$in{i_id}" />
      <input type="hidden" name="i_version" value="$in{i_version}" />
      <input type="hidden" name="iaa_id" value="$in{iaa_id}" />
      <input type="hidden" name="interaction_id" value="$in{interaction_id}" />
      <input type="hidden" name="action" value="delete" />
    </form>
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
        <td>
          <div class="title">Delete Media</div>
          <span>Confirm deletion of media file and any item part associations:</span>
          <p />
          <span><b>Filename:</b>&nbsp;$title</span><br />
          <span><b>Description:</b>&nbsp;$media_description</span>
          <p />
          <span>Warning: This action is immediate and cannot be undone.</span>
        </td>
      </tr>
    </table>
    <input type="button" value="Delete" onClick="document.actionForm.submit(); return true;" /> 
    <input type="button" value="Cancel" onClick="window.close(); return true;" /> 
  </body>
</html>
END_HERE

}

sub print_delete() {

  # get the list of item fragments to remove media content from eong instances
  my $eong_js_array = "var eongArray = [";

  # TBD: the list and type of item parts may change based on item type or item format
  my $stem_cnt = ($in{interaction_id}) ? 0 : 1;

  for (my $i = 0; $i < $stem_cnt; $i++) {
     $eong_js_array .= "eval(\"window.opener.oEdit\"),";
  }

  my $choice_cnt = ($in{interaction_id}) ? &get_item_part_count($IF_CHOICE) : 0;
  
  for (my $i = 0; $i < $choice_cnt; $i++) {
     $eong_js_array .= "eval(\"window.opener.oEditC$i\"),";
  }

  chop($eong_js_array);
  $eong_js_array .= "];";

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
  <meta charset=utf-8 />
    <title>SBAC CDE Delete Media</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript">
    <!--
      \$(document).ready(function() {
         deleteMediaContent();
         deleteMediaRowFromAssetTable();
      });

     function deleteMediaContent() {
      // remove media tag from all item parts
      $eong_js_array
      
      for (var i = 0; i < eongArray.length; i++) {
         var eong = eongArray[i];
         var content = eong.getBodyFragment();
         var contentChanged = false;
         
         // use jQuery to select only DOM content that is not the media file

         var elementMedia = \$(content).filter("div[class=orca:media:$filename]").length;
         if (elementMedia) {
           content = \$(content).not("div[class=orca:media:$filename]");
           contentChanged = true;
         }

         // look for media div inside other elements
         var decendentMedia = \$(content).find("div[class=orca:media:$filename]").length;
         if (decendentMedia) {
           content = \$(content).not(":has(div[class=orca:media:$filename])");
           contentChanged = true;
         }

         if (contentChanged) {
           // little trick to get the html from jQuery selection
           var html = \$("<div>").append(\$(content).clone()).remove().html();
           eong.invokeAction("select-all");
           eong.invokeAction("delete-forward");
           eong.setBodyFragment(html);
         }
       }
     }
     
     function deleteMediaRowFromAssetTable() {
       // delete row from media assets table
       var mediaAssetRow = window.opener.document.getElementById("$filename");
       \$(mediaAssetRow).remove();
         
       // if no more rows display no media footer
       var mediaAssetTable = window.opener.document.getElementById("mediaAssetTable");
       
       if (\$(mediaAssetTable).find("tbody>tr").size() == 0) {
         var noMediaMessage = window.opener.document.getElementById("noMediaMessage");        
         \$(noMediaMessage).show();
       }
     }

    //-->
    </script>
  </head>
  <body>
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
        <td>
          <div class="title">Media Deleted</div>
          <p />
          <span><b>Filename:</b>&nbsp;$title</span><br />
          <span><b>Description:</b>&nbsp;$media_description</span>
          <p />
        </td>
      </tr>
    </table>
    <input type="button" value="Close" onClick="window.close(); return true;" /> 
  </body>
</html>
END_HERE

}

sub print_delete_error() {
  my $message = shift;

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
  <meta charset=utf-8 />
    <title>SBAC CDE Delete Media</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
  <body>
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
        <td>
          <div class="title">Delete Media</div>
          <span style="color:#ff0000;font-weight:bold;">$message</span>
          <p />
          <span><b>Filename:</b>&nbsp;$title</span><br />
          <span><b>Description:</b>&nbsp;$media_description</span>
          <p />
        </td>
      </tr>
    </table>
    <input type="button" value="Close" onClick="window.close(); return true;" /> 
  </body>
</html>
END_HERE
}

# get media filename and description for iaa_id
sub get_media_info {
  my $sql = sprintf("SELECT iaa_filename, iaa_source_url, iaa_media_description FROM item_asset_attribute WHERE iaa_id = %d;", $in{iaa_id});
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my @row = $sth->fetchrow_array();
  return @row;
}

# get count of item parts for if_type and i_id (item part and item fragment are synonmous)
sub get_item_part_count {
  my ($if_type) = shift;

  my $sql = sprintf('SELECT COUNT(*) FROM item_fragment WHERE if_type = %d AND i_id = %d AND ii_id=%d;', 
                    $if_type, $in{i_id}, $in{interaction_id});
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my @row = $sth->fetchrow_array();
  my $count = 0;
  if ($#row >= 0) {
    $count = $row[0];
  }
  return $count;
}

sub delete_media() {
  # delete file from system
  my $sql = sprintf("SELECT ib_id, i_external_id, iaa_filename FROM item i JOIN item_asset_attribute a ON i.i_id=a.i_id WHERE i.i_id=%d AND i.i_version=%d AND a.iaa_id=%d;", $in{i_id}, $in{i_version}, $in{iaa_id});
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my $row = $sth->fetchrow_hashref();

  my $media_file = sprintf ("%s/%simages/lib%d/%s/%s", ${webPath}, $orcaUrl, $row->{ib_id}, $row->{i_external_id}, $row->{iaa_filename});

  if (-e "$media_file") {
    unlink("$media_file") or die "Unable to delete media asset: $title";
  }

  # remove data from database
  $dbh->{RaiseError} = 1;
  $dbh->{AutoCommit} = 0;

  {
    # delete item_asset_attribute record
    $sql = sprintf("DELETE FROM item_asset_attribute WHERE iaa_id = %d;", $in{iaa_id});
    $sth = $dbh->prepare($sql);
    $sth->execute();

    # remove media tag from item content (item_fragment.if_text and item.i_xml_data)
    $sql = sprintf("SELECT i_xml_data FROM item WHERE i_id=%d AND i_version=%d AND i_xml_data RLIKE 'orca:media:%s';", $in{i_id}, $in{i_version}, $row->{iaa_filename});
    $sth = $dbh->prepare($sql);
    $sth->execute();
    my $hash_ref = $sth->fetchrow_hashref();

    if (defined $hash_ref) {
      my $xml_data = $hash_ref->{i_xml_data};

      # strip the media tag from item xml data content
      $xml_data =~ s/<div.*?(?=.*?id="[^"]+")(?=.*?class="orca:media:$row->{iaa_filename}").*?>.*?<\/div>//eg;

      $sql = sprintf("UPDATE item SET i_xml_data=%s WHERE i_id=%d AND i_version=%d", $dbh->quote($xml_data), $in{i_id}, $in{i_version});
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    # strip the media tag from item fragment text content
    $sql = sprintf("SELECT if_id, if_text FROM item_fragment WHERE i_id=%d AND if_text RLIKE 'orca:media:%s';", $in{i_id}, $row->{iaa_filename});
    $sth = $dbh->prepare($sql);
    $sth->execute();

    while (my $fragment_data = $sth->fetchrow_hashref()) {
      my $fragment_text = $fragment_data->{if_text}; 
      $fragment_text =~ s/<div.*?(?=.*?id="[^"]+")(?=.*?class="orca:media:$row->{iaa_filename}").*?>.*?<\/div>//eg;
      my $sql2 = sprintf("UPDATE item_fragment SET if_text=%s WHERE if_id=%d;", $dbh->quote($fragment_text), $fragment_data->{if_id});
      my $sth2 = $dbh->prepare($sql2);
      $sth2->execute();
    }
  };

  if ($@) {
    $dbh->rollback();
    die "Unable to delete media asset: $title";
  } else {
    $dbh->commit();
  }

  $dbh->{AutoCommit} = 1;
}
1;
