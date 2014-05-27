package PassageMediaTable;
require Exporter;

use CGI::Carp;
use Passage;
use PassageMedia;
use UrlConstants;

@ISA = qw(Exporter);
@EXPORT_OK = qw(View_Mode Edit_Mode);

use constant View_Mode => 0;
use constant Edit_Mode => 1;

our $Table_Id = "passageMediaTable";
our $Table_Title = "Media Assets";

our $Table_No_Media_Message_Id = "passageNoMediaMessage";
our $Table_No_Media_Message = "No Media Assets";

our $Delete_Action_Title = "Delete";
our $Delete_Action_Url = "${orcaUrl}cgi-bin/passageMediaDelete.pl";
our $Delete_Action_Window_Name = "passageMediaDeleteWin";

our $Insert_Action_Title = "Associate";
our $Insert_Action_Url = "${orcaUrl}cgi-bin/passageMediaInsert.pl";
our $Insert_Action_Window_Name = "passageMediaInsertWin";

our $Upload_Action_Title = "Upload";
our $Upload_Action_Url = "${orcaUrl}cgi-bin/passageMediaUpload.pl";
our $Upload_Action_Window_Name = "passageMediaUploadWin";

our $View_Action_Title = "View";
our $View_Action_Url = "${orcaUrl}cgi-bin/passageMediaView.pl";
our $View_Action_Window_Name = "passageMediaViewWin";

sub new {
  my $class = shift;

  my $self = {};

  bless($self, $class);

  return $self;
}

sub get_style_library_includes {
  return <<CSS_INCLUDES;
<link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
CSS_INCLUDES
}

sub get_js_library_includes {
  my $self = shift();
  my $include_jquery_js = shift() || 0;

  my $js_library_includes = "";

  if ($include_jquery_js) {
    $js_library_includes .= "<script type=\"text/javascript\" src=\"${commonUrl}js/jquery-1.4.2.min.js\"></script>"; 
  }
  
  $js_library_includes .= "<script type=\"text/javascript\" src=\"${commonUrl}js/jquery.tablesorter.min.js\"></script>";
  return $js_library_includes;
}

sub get_js_inline_includes {
return <<JS_INCLUDES;
function myOpen(name,url,w,h)
{
    var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
    return true; 
}
JS_INCLUDES
}

sub get_jquery_ready_function {
  my $self = shift();

  # turn off sort for action column
  my $jquery_ready = <<JQUERY_READY;
jQuery("#$Table_Id").tablesorter({headers:{3:{sorter:false}}});
JQUERY_READY
  return $jquery_ready;
}

sub get_add_table_row_jquery_ready_function {
  my $self = shift();
  my $passage_media = shift();
  my $jquery = shift() || "jQuery";
  my $sess_id = shift() || '';

  my $content_media_row = <<MEDIA_ROW;
  "<tr id=\\\"@{[$passage_media->get_server_filename()]}\\\">" +
    "<td>@{[$passage_media->get_client_filename()]}</td>" +
    "<td>@{[$passage_media->get_description()]}</td>" +
    "<td>@{[$passage_media->get_filesize()]} kb</td>" +
    "<td>" +
      "<a href=\\\"#\\\" onClick=\\\"myOpen('${View_Action_Window_Name}','${View_Action_Url}?sess_id=$sess_id&pm_id=@{[$passage_media->get_id()]}',700,500);\\\">${View_Action_Title}</a>" +
      "&nbsp;|&nbsp;" +
      "<a href=\\\"#\\\" onClick=\\\"myOpen('${Insert_Action_Window_Name}','${Insert_Action_Url}?sess_id=$sess_id&pm_id=@{[$passage_media->get_id()]}',700,500);\\\">${Insert_Action_Title}</a>" +
      "&nbsp;|&nbsp;" +
      "<a href=\\\"#\\\" onClick=\\\"myOpen('${Delete_Action_Window_Name}','${Delete_Action_Url}?sess_id=$sess_id&pm_id=@{[$passage_media->get_id()]}',400,350);\\\">${Delete_Action_Title}</a>" +
    "</td>" +
  "</tr>"
MEDIA_ROW

my $preview_media_row = <<MEDIA_ROW;
  "<tr id=\\\"@{[$passage_media->get_server_filename()]}\\\">" +
    "<td>@{[$passage_media->get_client_filename()]}</td>" +
    "<td>@{[$passage_media->get_description()]}</td>" +
    "<td>@{[$passage_media->get_filesize()]} kb</td>" +
    "<td>" +
      "<a href=\\\"#\\\" onClick=\\\"myOpen('${View_Action_Window_Name}','${View_Action_Url}?sess_id=$sess_id&pm_id=@{[$passage_media->get_id()]}',700,500);\\\">${View_Action_Title}</a>" +
    "</td>" +
  "</tr>"
MEDIA_ROW

  $jquery_add = <<JQUERY_ADD;
  // if the no media message is still displayed hide it
  if ($jquery("[id=$Table_No_Media_Message_Id]").is(':visible')) {
    $jquery("[id=$Table_No_Media_Message_Id]").hide();
  }

  // upate the media table with the new asset
    var contentDiv = $jquery(".tabbertab").get(0);
    \$(contentDiv).find("[id=$Table_Id]").append($content_media_row);

    var previewDiv = $jquery(".tabbertab").get(-1);
    \$(previewDiv).find("[id=$Table_Id]").append($preview_media_row);
JQUERY_ADD

  return $jquery_add;
}

sub get_delete_table_row_jquery_ready_function {
  my $self = shift();
  my $passage_media = shift();
  my $jquery = shift() || "jQuery";
  
  my $jquery_delete = <<JQUERY_DELETE;
  // delete row from media assets table
  $jquery("[id=@{[$passage_media->get_server_filename()]}]").remove();
         
  // if no more rows display no media footer
  if ($jquery("#$Table_Id tbody>tr").size() == 0) {
         $jquery("[id=$Table_No_Media_Message_Id]").show();
  }

JQUERY_DELETE

  return $jquery_delete;
}

sub draw {
  use HTML::Template;

  my $self = shift();
  my $passage = shift();
  my $passage_media = shift() || [];
  my $table_mode = shift() || View_Mode;
  my $sess_id = shift() || ''; # only needs to be set when Edit_Mode

  my $upload_action_url_params = "?sess_id=$sess_id&passage_id=$passage->{id}";
  my $media_tmplt = HTML::Template->new(scalarref => \ <<TEMPLATE
  <div>
    <table id="$Table_Id" class="tablesorter" border="1" cellspacing="2" cellpadding="2" align="left"> 
      <caption>$Table_Title<TMPL_IF NAME=SHOWUPLOAD><span style="float:right;"><input type="button" value="$Upload_Action_Title" onClick="myOpen('$Upload_Action_Window_Name', '$Upload_Action_Url$upload_action_url_params',550,450);"></span></TMPL_IF></caption>
      <thead>
      <tr>
        <th style="padding-right:20px;">Filename</th>
        <th style="padding-right:20px;">Description</th>
        <th style="padding-right:20px;">File Size</th>
        <th>Actions</th>
      </tr>
      </thead>
      <tbody>
      <TMPL_LOOP NAME=MEDIA>
        <tr id="<TMPL_VAR NAME=SRVR_FILENAME>">
          <td><TMPL_VAR NAME=CLNT_FILENAME></td>
          <td><TMPL_VAR NAME=DESCRIPTION></td>
          <td><TMPL_VAR NAME=FILESIZE></td>
          <td><TMPL_VAR NAME=VIEWLINK><TMPL_IF NAME=SHOWEDITOPTS>&nbsp;|&nbsp;<TMPL_VAR NAME=INSERTLINK>&nbsp;|&nbsp;<TMPL_VAR NAME=DELETELINK></TMPL_IF></td>
        </tr>
      </TMPL_LOOP>
      </tbody>
      <tfoot id="$Table_No_Media_Message_Id"<TMPL_IF NAME=MEDIA> style="display:none;"</TMPL_IF>>
      <tr>
        <td colspan="5"><span style="font-style:italic;">$Table_No_Media_Message</span></td>
      </tr>
      </tfoot>
    </table>
  </div>
TEMPLATE
);

  my $rows = [];

  foreach (@{$passage_media}) {
   my $view_link = <<VIEW_LINK;
<a href="#" onClick="myOpen('${View_Action_Window_Name}','${View_Action_Url}?sess_id=$sess_id&pm_id=@{[$_->get_id()]}',700,500);">${View_Action_Title}</a>
VIEW_LINK
   
   my $insert_link = <<INSERT_LINK;
<a href="#" onClick="myOpen('${Insert_Action_Window_Name}','${Insert_Action_Url}?sess_id=$sess_id&pm_id=@{[$_->get_id()]}',400,350);">${Insert_Action_Title}</a>
INSERT_LINK

   my $delete_link = <<DELETE_LINK;
<a href="#" onClick="myOpen('${Delete_Action_Window_Name}','${Delete_Action_Url}?sess_id=$sess_id&pm_id=@{[$_->get_id()]}',400,350);">${Delete_Action_Title}</a>
DELETE_LINK

    push(@{$rows}, {SRVR_FILENAME=>$_->get_server_filename, CLNT_FILENAME=>$_->get_client_filename, DESCRIPTION=>$_->get_description, FILESIZE=>$_->get_filesize.' kb', VIEWLINK=>$view_link, SHOWEDITOPTS=>$table_mode, INSERTLINK=>$insert_link, DELETELINK=>$delete_link});
  }

  $media_tmplt->param(MEDIA=>$rows, SHOWUPLOAD=>$table_mode);
  $media_tmplt->output();
}

sub find_media_for_passage {
  my $self = shift();
  my $passage = shift();

  my $passage_media = [];

  my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
  my $sql = sprintf( "SELECT pm_id FROM passage_media WHERE p_id = %d", $passage->{id});
  my $sth = $dbh->prepare( $sql );
  $sth->execute();

  while (my ($pm_id) = $sth->fetchrow_array()) {
carp $pm_id;
    push(@{$passage_media}, from_db PassageMedia($pm_id));
  }
  $sth->finish();
  $dbh->disconnect();

  return $passage_media;
}

1;
