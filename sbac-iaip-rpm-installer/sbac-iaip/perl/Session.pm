package Session;

use warnings;
use strict;
use ItemConstants;
use UrlConstants;

sub getUser {
        my $env = shift;
        my $dbh  = shift;
        my $userId= $env->{'HTTP_REMOTE_USER'};
        my $user = {};

        # if we're using session cache and have 'user' cached, return it
	if ( defined($env->{'psgix.session'})
	  && defined($env->{'psgix.session'}{user})
	  && $env->{'psgix.session'}{user}{userName} eq $userId) {
          return $env->{'psgix.session'}{user};
        } 

        my $sql  = qq|SELECT * FROM user
                 WHERE u_username = ?
                 LIMIT 1
                |;
        my $sth = $dbh->prepare($sql);
        $sth->execute($userId);
        if ( my $row = $sth->fetchrow_hashref ) {
                $user->{type}           = $row->{u_type};
                $user->{id}             = $row->{u_id};
                $user->{adminType}      = $row->{u_admin_type};
                $user->{reviewType}     = $row->{u_review_type};
                $user->{organizationId} = $row->{o_id};
                $user->{writerCode} = $row->{u_writer_code};
		$user->{userName} = $userId;
		$user->{firstName} = $row->{u_first_name};
		$user->{lastName} = $row->{u_last_name};
		$user->{eMail} = $row->{u_email};
                $user->{banks} = ItemConstants::getItemBanks($dbh, $row->{u_id});
		$user->{workGroups} = ItemConstants::getWorkgroupsByUser($dbh, $row->{u_id});
        }
        else {
                $user->{type}           = 0;
                $user->{id}             = 0;
                $user->{adminType}      = 0;
                $user->{reviewType}     = 0;
                $user->{organizationId} = 0;
                $user->{writerCode} = 0;
		$user->{userName} = '';
		$user->{firstName} = '';
		$user->{lastName} = '';
		$user->{eMail} = '';
		$user->{banks} = {};
        }

        # if we're using session cache, set the 'user' key
	if($env->{'psgix.session'}) {
	  $env->{'psgix.session'}{user} = $user;
	}

        return $user;
}

1;
