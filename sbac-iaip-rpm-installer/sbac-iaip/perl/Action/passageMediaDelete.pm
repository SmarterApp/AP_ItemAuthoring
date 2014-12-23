package Action::passageMediaDelete;

use UrlConstants;
use PassageMedia;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;


  local $passage_media = from_db PassageMedia($in{pm_id});
  
  my $psgi_out = '';
  
  if ( defined $in{action} && $in{action} eq 'delete' ) {
    # TODO consider removing tag from html file in case user does not select save
    eval { $passage_media->delete(); };
  
    if ($@) {
      $psgi_out = &print_delete_error($@);
    } else {
      $psgi_out = &print_delete();
    }
  } else {
    $psgi_out = &print_preview();
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
    <title>Delete Media</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
  <body>
    <form name="actionForm" action="${orcaUrl}cgi-bin/passageMediaDelete.pl" method="POST">
      <input type="hidden" name="pm_id" value="$in{pm_id}" />
      <input type="hidden" name="action" value="delete" />
    </form>
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
        <td>
          <div class="title">Delete Media</div>
          <span>Confirm deletion of media file:</span>
          <p />
          <span><b>Filename:</b>&nbsp;@{[$passage_media->get_client_filename()]}</span><br />
          <span><b>Description:</b>&nbsp;@{[$passage_media->get_description()]}</span>
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
  use PassageMediaTable;
  my $passage_media_table = new PassageMediaTable();

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
        var eong = eval("window.opener.oEdit1");
        var content = eong.getBodyFragment();
        var contentChanged = false;
         
        // use jQuery to select only DOM content that is not the media file

        var elementMedia = \$(content).filter("div[class=orca:media:@{[$passage_media->get_server_filename()]}]").length;
        if (elementMedia) {
          content = \$(content).not("div[class=orca:media:@{[$passage_media->get_server_filename()]}]");
          contentChanged = true;
        }

        // look for media div inside other elements
        var decendentMedia = \$(content).find("div[class=orca:media:@{[$passage_media->get_server_filename()]}]").length;
        if (decendentMedia) {
          content = \$(content).not(":has(div[class=orca:media:@{[$passage_media->get_server_filename()]}])");
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
     
      function deleteMediaRowFromAssetTable() {
        @{[$passage_media_table->get_delete_table_row_jquery_ready_function($passage_media, "window.opener.jQuery")]}
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
          <span><b>Filename:</b>&nbsp;@{[$passage_media->get_client_filename()]}</span><br />
          <span><b>Description:</b>&nbsp;@{[$passage_media->get_description()]}</span>
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
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/c
  <body>
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
        <td>
          <div class="title">Delete Media</div>
          <span style="color:#ff0000;font-weight:bold;">$message</span>
          <p />
          <span><b>Filename:</b>&nbsp;@{[$passage_media->get_client_filename()]}</span><br />
          <span><b>Description:</b>&nbsp;@{[$passage_media->get_description()]}</span>
          <p />
        </td>
      </tr>
    </table>
    <input type="button" value="Close" onClick="window.close(); return true;" /> 
  </body>
</html>
END_HERE
}
1;
