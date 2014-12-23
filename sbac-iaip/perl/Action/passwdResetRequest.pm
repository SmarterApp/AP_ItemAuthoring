package Action::passwdResetRequest;

use UrlConstants;
use Auth;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  my $psgi_out = '';

  if ( defined $in{username} ) {
    # per DE1096 intentionally ignore error cases, so as to not inform users about .
    &passwdResetRequest( $dbh, $in{username}, "https://${webHost}${orcaUrl}" );
   $psgi_out = 
qq|<html><head><link rel="stylesheet" href="/login.css" /></head><body style="background-color:#999999;"><div id="main"><div id="login_panel"><p style="font-size:12pt;text-align:left;color:#666666;font-weight:bold;">Your request has been submitted successfully.</p></div></div></body></html>|;
  }
  else {
    $psgi_out = <<END_HERE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="/login.css" />
<title>Password Reset Request</title>
<script>
function doSubmit(f) {
        if( f.username.value.match(/^\\s*\$/) ) {
            alert( 'Username Required');
            f.username.focus();
            return false;
        }

        f.submit();
}
</script>

</head>

<body style="background-color:#999999;">
<form action="" method="post" name="cde" id="cde">
<input type="hidden" name="instance_name" value="$instance_name" />
<input type="hidden" name="action" value="reset_pswd" />
<div id="main">
  <div id="login_panel">
        <p style="font-size:14pt;text-align:left;color:#666666;font-weight:bold;">Password Reset Request</p>
        <p><label for="username">Username:</label><input name="username" type="text" size="30" maxlength="30" /></p>
        <p><input type="button" name="reset_pswd" value="Reset" onClick="doSubmit(this.form)" /></p>
        <span class="enable">Enter your 'username' and click the Reset button.</span>
	<p><br/><br/><a href="/login.html"/>Login Page</a></p>
  </div>
</div>
</form>
</body>
<script>
document.onmousedown = disableRightClick;
function disableRightClick() {
        // Set the message for the alert box
        am = "Right clicking the mouse is disabled!";

        // do not edit below this line
        // ===========================
        bV  = parseInt(navigator.appVersion)
        bNS = navigator.appName=="Netscape"
        bIE = navigator.appName=="Microsoft Internet Explorer"

        document.onmousedown = nrc;
        if (document.layers) window.captureEvents(Event.MOUSEDOWN);
        if (bNS && bV<5) window.onmousedown = nrc;
    }

function nrc(e) {
   if (bNS && e.which > 1){
      alert(am)
      return false
   } else if (bIE && (event.button >1)) {
     alert(am)
     return false;
   }
}
var user = <TMPL_VAR NAME="json_user" DEFAULT="{}">;
</script>
</html>
END_HERE
  }
  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
}
1;
