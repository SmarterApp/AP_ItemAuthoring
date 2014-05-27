package Auth;

use warnings;
use strict;
use UrlConstants;
use Crypt::Random qw(makerandom_octet);
use MIME::Lite;

sub genToken {
    my $length=shift;
    my $avoid;
    for ( 0 .. 47, 58 .. 64, 91 .. 96, 123 .. 255 ) {
        $avoid .= chr($_);
    }
    return makerandom_octet( Length => $length, Strength => 0, Skip => $avoid );
}

sub passwdResetRequest{
    my $dbh=shift;
    my $userName=shift;
    my $baseURL=shift;
    my $sth = $dbh->prepare(
                "select u_id,u_review_type,u_email from user where u_username=?");
    $sth->execute($userName);
    if ( my $row = $sth->fetchrow_hashref ) {
    	if($row->{'u_review_type'}==0){
    		$sth->finish;
            return "User does not have the correct privileges.";
        }
        my $userId=$row->{u_id};
        my $userEmail=$row->{u_email};
        my $token=&genToken(256);

        $sth->finish;
        $sth=$dbh->prepare("select oob_u_id from user_oob_auth where oob_valid=1 and oob_u_id=?");
        $sth->execute($userId);
        if($sth->fetchrow_hashref){
        	$sth->finish;
        	return "The user name already has a password reset request pending."
        }
        
        $sth->finish;
        $sth = $dbh->prepare("insert into user_oob_auth( oob_valid, oob_expires, oob_key, oob_u_id ) values(1, NOW() + INTERVAL 1 DAY, ?,? )");
        $sth->execute( $token, $userId );

        my $verify_link = sprintf '%slogin/cgi-bin/passwdReset.pl?token=%s', $baseURL, $token;
        my $messageData = <<END_HERE;

 <p>Please click the following link within 24 hours to reset your password:</p>

 <p><br/><a href="$verify_link">Verification Link</a><br/><br/></p>

 <p>If you are unable to click the link above, copy the link into your browser's address bar.</p>

 <p>If you have any questions regarding your account, please contact the administrator at SBAC7PacMetTeam\@pacificmetrics.com.<p>

<p>  Pacific Metrics Corporation<p>

END_HERE

        # Send e-mail notification
        my $message = MIME::Lite->new(
              To      => $userEmail,
              From    => '"SBAC CDE" <SBAC7PacMetTeam@pacificmetrics.com>',
              Subject => 'SBAC CDE Password Reset',
              Data    => $messageData,
              Type    => 'text/html'
        );

        $message->send( 'smtp', 'localhost' );
        return '';
    }
    return "User not found!";
}

 
1;

