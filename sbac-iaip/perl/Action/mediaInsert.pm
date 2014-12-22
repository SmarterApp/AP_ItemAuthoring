package Action::mediaInsert;

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

  return [ $q->psgi_header(
              -type          => 'text/html',
              -pragma        => 'nocache',
              -cache_control => 'no-cache, must-revalidate'),
           [ &print_preview() ]];
}

### ALL DONE! ###

sub print_preview {

  # display media file name and description
  my ($filename, $title, $media_description) = &get_media_info();

  # TBD: the list and type of item parts may change based on item type or item format
  my $stem_cnt = ($in{interaction_id}) ? 0 : 1;
  my $choice_cnt = ($in{interaction_id}) ? &get_item_part_count($IF_CHOICE) : 0;

  # checkbox list item parts
  my $ip_checkbox_grp = "";

  for (my $i = 0; $i < $stem_cnt; $i++) {
    # TBD: mark item part checked when media file already associated
    $ip_checkbox_grp .= "<input type=\"checkbox\" id=\"stem$i\">&nbsp;<label>Stem</label><br />";
  }

  for (my $i = 0; $i < $choice_cnt; $i++) {
    # TBD: mark item part checked when media file already associated
    $ip_checkbox_grp .= "<input type=\"checkbox\" id=\"choice$i\">&nbsp;<label>Choice ". chr(64+$i+1) . "</label><br />";
  }
  
  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
  <meta charset=utf-8 />
    <title>SBAC CDE Edit Media Associations</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript">
    <!--

     function updateMediaContent(filename, title) {
       var elements = document.getElementsByTagName("input");

       for (var i = 0; i < elements.length; i++) {
         if (elements[i].type != "checkbox") {
           continue;
         }

         var eong;

         if (elements[i].id.indexOf("stem") != -1) {
           eong = eval("window.opener.oEdit");
         } else if (elements[i].id.indexOf("choice") != -1) {
           eong = eval("window.opener.oEditC"+elements[i].id.substr(6));
         } 

         var itemFragContent = eong.getBodyFragment();
         var newFragContent = '';
         var itemFragContentChanged = false;

         //var mediaContent = "<div class=\\\"orca:media:" +  filename + "\\\" style=\\\"-ro-editable:false;-ro-editable-inside:false;\\\">" + title + "</div>";
         var mediaContent = "<div class=\\\"orca:media:" +  filename + "\\\">" + title + "</div>";

         // only add content once, if already exists ignore
         if (elements[i].checked &&
             \$(itemFragContent).filter("div[class=orca:media:" + filename + "]").length == 0 &&
             \$(itemFragContent).find("div[class=orca:media:" + filename + "]".length == 0)) {
           newFragContent = itemFragContent + mediaContent;   
           itemFragContentChanged = true;
         } else if (!elements[i].checked &&
                    \$(itemFragContent).filter("div[class=orca:media:" + filename + "]").length) {
           itemFragContent = \$(itemFragContent).not("div[class=orca:media:" + filename + "]");
           newFragContent = \$("<div>").append(\$(itemFragContent).clone()).remove().html();
           itemFragContentChanged = true;
         } else if (!elements[i].checked &&
                    \$(itemFragContent).find("div[class=orca:media:" + filename + "]").length) {
           itemFragContent = \$(itemFragContent).not(":has(div[class=orca:media:" + filename + "])");
           newFragContent = \$("<div>").append(\$(itemFragContent).clone()).remove().html();
           itemFragContentChanged = true;
         }

         if (itemFragContentChanged) {
           eong.invokeAction("select-all");
           eong.invokeAction("delete-forward");
           eong.setBodyFragment(newFragContent);
         }
       }

       window.close();
     }

    //-->
    </script>
  </head>
  <body>
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
        <td>
          <div class="title">Edit Media Associations</div>
          <p />
          <span><b>Filename:</b>&nbsp;$title</span><br />
          <span><b>Description:</b>&nbsp;$media_description</span>
          <p />
          <span>For each item part, check or uncheck the appropriate checkboxes to assocate or disassociate media</span>
          <p />
          <span class="text">Item Parts:</span><br />
          <span>$ip_checkbox_grp</span>
        </td>
      </tr>
    </table>
    <input type="button" value="Edit Associations" onClick="updateMediaContent('$filename', '$title'); return true;" /> 
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

  my $sql = sprintf('SELECT COUNT(*) FROM item_fragment WHERE if_type = %d AND i_id = %d AND ii_id= %d;', 
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
1;
