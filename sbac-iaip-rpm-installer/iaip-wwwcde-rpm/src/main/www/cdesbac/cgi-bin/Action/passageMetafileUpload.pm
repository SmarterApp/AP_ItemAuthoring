package Action::passageMetafileUpload;

use Cwd;
use URI;
use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  my $debug = 1;
  
  unless ( defined $in{actionType} ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  if ( $in{actionType} eq "upload" ) {
  
      if ( $in{myfile} eq "" ) {
          $in{message} = "The file has no name.";
	  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
      }
  
      if ( $in{myfile} =~ /(?:\/|\\)([^\/\\]+)$/ ) {
          $in{myfile} = $1;
      }
  
      my $filePath = "${orcaPath}passage-metafiles/$in{passageId}/$in{myfile}";
  
      if ( -e $filePath ) {
          $in{message} =
            "File '$in{myfile}' already exists.<br /> Please choose another.";
          return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
      }
  
      mkdir "${orcaPath}passage-metafiles/$in{passageId}"
        unless -e "${orcaPath}passage-metafiles/$in{passageId}";
  
      my $uploadHandle = $q->upload("myfile");
  
      open UPLOADED, ">${filePath}";
      binmode UPLOADED;
      while (<$uploadHandle>) {
          print UPLOADED;
      }
  
      close UPLOADED;
  
      my $sql = sprintf(
  'INSERT INTO passage_metafiles SET p_id=%d, u_id=%d, p_dev_state=(SELECT p_dev_state FROM passage WHERE p_id=%d), pm_timestamp=NOW(), pm_filename=%s, pm_comment=%s',
          $in{passageId}, $user->{id}, $in{passageId},
          $dbh->quote( $in{myfile} ),
          $dbh->quote( $in{comment} )
      );
      my $sth = $dbh->prepare($sql);
      $sth->execute();
  
      return [ $q->psgi_header('text/html'), [ &print_done(\%in) ]];
  }
}
### ALL DONE! ###

sub print_welcome {

    my $params = shift;
    my $msg    = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;font-weight:bold'>"
          . $params->{message}
          . "</div>"
        : "" );

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Metafile Upload</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
  </head>
  <body>
    <div class="title">Passage Metafile Upload</div>
    ${msg} 
   <br />
   <form name="upload" action="passageMetafileUpload.pl" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="passageId" value="$params->{passageId}" />
     
     <input type="hidden" name="actionType" value="upload" />
   <table class="no-style" border=0 cellspacing=4 cellpadding=4>
     <tr>
       <td>
         <span class="text">File To Upload:</span></td>
	 <td><input type="file" name="myfile" />
       </td>
     </tr>
     <tr>
       <td>
       <span class="text">Comment:</span>
       </td>
       <td><textarea name="comment" rows="3" cols="50"></textarea></td>
    </tr>
    <tr>
      <td>&nbsp;</td>
      <td>
      <input type="submit" value="Upload" />
      </td>
     </tr>
   </table>             
   </form>
  </body>
</html>         
END_HERE
}

sub print_done {

    my $params = shift;

    return <<END_HERE;
<html>
  <head>
  </head>
  <body>
	  <script language="JavaScript">
		  window.opener.location.reload(true);
		  window.close();
    </script>
  </body>
</html>
END_HERE
}
1;
