package Action::passageMediaView;

use PassageMedia;
use UrlConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;


  my $passage_media = from_db PassageMedia($in{pm_id});

  my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>SBAC CDE Media View</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    @{[$passage_media->get_style_library_includes()]}
    @{[$passage_media->get_js_library_includes()]}
    <script type="text/javascript">  
    <!--
      \$(document).ready(function() {
        @{[$passage_media->get_jquery_ready_function()]}
      });
    //-->
    </script>
  </head>
  <body>
   <div class="title">@{[$passage_media->get_client_filename()]}</div>
   @{[$passage_media->draw()]}
  </body>
</html>
END_HERE

  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
};
1;

