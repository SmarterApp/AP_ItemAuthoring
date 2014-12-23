#!/usr/bin/perl -w
use strict;
use CGI;
use DBI;
use MIME::Lite;
use Crypt::PasswdMD5;
use UrlConstants;

my $cgi=new CGI;
my %in = map { $_ => $cgi->param($_) } $cgi->param;
my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );

if(defined $in{token}){
    my $userId;
    my $oobId;
    my $sth = $dbh->prepare("select oob_id,oob_u_id from user_oob_auth where oob_valid=1 and oob_key=? and oob_expires > NOW()");
    $sth->execute($in{token});
    if ( my $row = $sth->fetchrow_hashref ) {
      $userId=$row->{oob_u_id};
      $oobId=$row->{oob_id};
    }else{
        #slow down brute force attacks
      sleep(3);
      print $cgi->header(-location => "${orcaUrl}login/login.html", -status=>301);
    }
    $sth->finish;

    print $cgi->header("text/html");
    if(defined $in{password} && $in{password} =~ m/^[\\w]{6,}$/){
        &printPasswdReset();
    }elsif(defined $userId && defined $in{password}){
        my $pass=apache_md5_crypt($in{password});
        $sth=$dbh->prepare("update user set u_password=? where u_id=?");
        $sth->execute($pass,$userId); 
        $sth->finish;
        $sth=$dbh->prepare("update user_oob_auth set oob_valid=0, oob_updated=NOW() where oob_id=?");
    $sth->execute($oobId);
    $sth->finish;
        print qq|<html><head><link rel="stylesheet" href="${orcaUrl}login/login.css" /></head><body style="background-color:#999999;"><div id="main"><div id="login_panel"><p style="font-size:14pt;text-align:left;color:#666666;font-weight:bold;">Password Updated Successfully. <p><a href="${orcaUrl}login/login.html">Please click here to login.</a></p></p></div></div></body></html>|;        
    }else{
        &printPasswdReset();
    }
}
else {
    print $cgi->header(-location => "${orcaUrl}login/login.html", -status=>301);
}
exit;

sub printPasswdReset{
        print <<END_HERE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="${orcaUrl}login/login.css" />
<title>Password Reset Request</title>
<script>
function doSubmit(f) {
    var p1=document.getElementById('password');
    var p2=document.getElementById('password2');
    var valid=new RegExp("^[\\\\w]{6,}\$");
    if( p1.value != p2.value){
      alert('Passwords do not match');
    }else if(!valid.test(p1.value)){
      alert('The password must be 6 or more alpha numeric characters.');
    }else{
      f.submit();
    }
    p1.focus();
}
</script>

</head>

<body style="background-color:#999999;">
<form action="" method="post" name="cde" id="cde">
<input type="hidden" name="instance_name" value="$instance_name" />
<input type="hidden" name="action" value="reset_pswd" />
<input type="hidden" name="token" value="$in{token}"/>
<div id="main">
  <div id="login_panel">
        <p style="font-size:14pt;text-align:left;color:#666666;font-weight:bold;">Password Reset</p>
        <p><label for="password">Password:</label><input id="password" name="password" type="password" size="30" maxlength="30" /></p>
        <p><label for="password2">Password:</label><input id="password2" name="password2" type="password" size="30" maxlength="30" /></p>
        <p><input type="button" name="reset_pswd" value="Reset" onClick="doSubmit(this.form)" /></p>
        <span class="enable">Enter your 'password' and click the Reset button.</span>
    <p><br/><br/><a href="${orcaUrl}login/login.html"/>Login Page</a></p>
  </div>
</div>
</form>
</body>
<script>
document.getElementById('password').focus();
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
</script>
</html>
END_HERE
}

