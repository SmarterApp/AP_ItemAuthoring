package Action::passageMediaUpload;

use Cwd;
use URI;
use UrlConstants;
use ItemConstants;
use Passage;
use PassageMedia qw(Media_Extensions);
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  unless(defined $in{action})
  {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }  

  our %media_ext = map { $_ => 1 } Media_Extensions;
  
  if($in{action} eq "upload")
  {
    my $passage = new Passage($dbh, $in{passage_id});
  
    if($in{media_file} eq "")
    {
      $in{message} = "Please enter a media file to upload."; 
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
    }
  
    local $passage_media = new PassageMedia($passage, $in{media_file}, $in{media_description});
  
    unless (exists($media_ext{$passage_media->get_extension()})) {
      $in{message} = "Unsupported media extension: ".$passage_media->get_extension()."<p/>To upload audio or video files you will need to convert $in{media_file} to one of the following: @{[Media_Extensions]}";
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
    }
  
    my $uploadHandle = $q->upload("media_file");
  
    # TODO large file size logic
  
    unless($passage_media->create($uploadHandle, $user{id})) {
      $in{message} = "Media '$in{media_file}' already exists.<br /> Please choose another.";
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
    }
  
    my @files = <$passage_media-\>{BASE_PATH}*>;
  
    foreach my $file (@files) {
      if ($file ne $passage_media->{PATH}) {
        if (system("cmp", "-s", $passage_media->{PATH}, $file) == 0) {
          $passage_media->delete();
          $in{message} = "Cannot upload: The file you are attempting to upload already exists for this passage.";
	  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
        }
      }
    }
  
    if ($passage_media->get_extension() eq "mp4") {
      use XML::XPath;
      my $media_metadata_xml = `/usr/local/bin/ffprobe -v 0 $passage_media->{PATH} -show_streams -of xml`;
  
      my $xp = new XML::XPath( xml => $media_metadata_xml);
      my $node_set = $xp->find("//stream[\@codec_type='video']/\@codec_name");
      my @video_codecs;
      if (my @node_list = $node_set->get_nodelist) { 
        @video_codecs = map($_->string_value, @node_list);
      }
  
      if ($video_codecs[0] ne "h264") {
        $passage_media->delete();
        $in{message} = "The system does not support $video_codecs[0] video codec for mp4 files, please convert the file @{[$passage_media->get_client_filename()]} to H.264 video codec and reupload.";
	return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
      }
    }
  
    $in{message} = "Upload Complete!";
    return [ $q->psgi_header('text/html'), [ &print_preview(\%in) ]];
  }
}
### ALL DONE! ###

sub print_welcome {

  my $params = shift;

  my $msg = ( defined($params->{message}) ? "<div style='color:#ff0000;font-weight:bold'>" . $params->{message} . "</div>" : "");
  
  my $uploadActions = <<UPLOAD_ACTIONS;
<input type="button" value="Upload and View" onClick="showSpinner(this.form)" />&nbsp;<span id="progress_spinner"></span>
UPLOAD_ACTIONS

#carp "orcaUrl:".(defined($orcaUrl));
#carp "msg:".(defined($msg));
#carp "passage_id:".(defined $params->{passage_id});
#carp "passage_name:".(defined $params->{passage_name});
#carp "uploadActions:".(defined $uploadActions);

# TODO large file size logic
  
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
   <form name="upload" action="passageMediaUpload.pl" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="action" value="upload" />
     
     <input type="hidden" name="passage_id" value="$params->{passage_id}" />
     <input type="hidden" name="passage_name" calue="$params->{passage_name}" />
   <table border=0 cellspacing=4 cellpadding=4 class="no-style">
     <tr>
       <td>
         <span class="text">File To Upload:</span></td>
	 <td><input type="file" name="media_file" />
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
  use PassageMediaTable;
  my $params = shift;

  my $passage_media_table = new PassageMediaTable();

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>SBAC CDE Media View</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    @{[$passage_media->get_style_library_includes()]}
    @{[$passage_media->get_js_library_includes()]}
    <script type="text/javascript">  

      \$(document).ready(function() {
        @{[$passage_media->get_jquery_ready_function()]}

        var resizeWindowByWidth = window.innerWidth < \$(document).width();
        var resizeWindowByHeight = window.innerHeight < \$("#content").height();

        // resize the window to fit asset
        if ( resizeWindowByWidth || resizeWindowByHeight ) {
          var windowWidth = resizeWindowByWidth ? \$(document).width() + window.outerWidth - \$(window).width() : window.outerWidth;
          var windowHeight = resizeWindowByHeight ? \$("#content").height() + window.outerHeight - \$(window).height() : window.outerHeight;
          window.resizeTo(windowWidth, windowHeight);
        }

         // insert media content tag into passage content (via edit-on ng applet)
         var eong = eval("window.opener.oEdit1");
         var itemFragContent = eong.getBodyFragment();
         eong.invokeAction("select-all");
         eong.invokeAction("delete-forward");
         eong.setBodyFragment(itemFragContent + "<div class=\\\"orca:media:@{[$passage_media->get_server_filename()]}\\\">@{[$passage_media->get_client_filename()]}</div>");
         // update the media asset table with new row
         @{[$passage_media_table->get_add_table_row_jquery_ready_function($passage_media, "window.opener.jQuery")]}
      });

    </script>
  </head>
  <body>
    <div class="title">Media View</div>
    <p><a href="passageMediaUpload.pl?passage_id=$params->{passage_id}&$params->{passage_name}">Upload New Media</a></p>
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
        <td><span class="text">Title:</span></td>
	<td><b>$params->{media_file}</b></td>
      </tr>
      <tr>
        <td><span class="text">Media Description:</span></td>
        <td>$params->{media_description}</td>
      </tr>
    </table>  
    <br />
    <table id="content" border="1" cellpadding="2" cellspacing="2" class="no-style">
      <tbody>
       <tr>
         <td valign="top">
           @{[$passage_media->draw()]}
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
