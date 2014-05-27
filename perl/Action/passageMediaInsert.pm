package Action::passageMediaInsert;

use CGI;
use DBI;
use UrlConstants;
use PassageMedia;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);


  my $passage_media = from_db PassageMedia($in{pm_id});

  my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
  <meta charset=utf-8 />
    <title>SBAC CDE Edit Media Associations</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript">
    <!--

     function updateMediaContent() {
         // insert media content tag into passage content (via edit-on ng applet)
         var eong = eval("window.opener.oEdit1");
         var itemFragContent = eong.getBodyFragment();

         var title = '@{[$passage_media->get_client_filename()]}'; 
         var filename = '@{[$passage_media->get_server_filename()]}';

         // only add content once, if already exists ignore
         if (\$(itemFragContent).filter("div[class=orca:media:" + filename + "]").length == 0 &&
             \$(itemFragContent).find("div[class=orca:media:" + filename + "]".length == 0)) {
           eong.invokeAction("select-all");
           eong.invokeAction("delete-forward");
           eong.setBodyFragment(itemFragContent + "<div class=\\\"orca:media:" +  filename + "\\\">" + title + "</div>");
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
          <h3><span class="text">Associate Media</span></h3>
          <p />
          <span><b>Filename:</b>&nbsp;@{[$passage_media->get_client_filename()]}</span><br />
          <span><b>Description:</b>&nbsp;@{[$passage_media->get_description()]}</span>
          <p />
        </td>
      </tr>
    </table>
    <input type="button" value="Associate" onClick="updateMediaContent(); return true;" /> 
  </body>
</html>
END_HERE

  return [ $q->psgi_header(
    -type          => 'text/html',
    -pragma        => 'nocache',
    -cache_control => 'no-cache, must-revalidate'),
           [ $psgi_out ]];
}
1;
