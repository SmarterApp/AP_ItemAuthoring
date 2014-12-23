package Authz;

use warnings;
use strict;
use Session;
use ItemConstants;

# the authz cache per app
our %authz_app;

$authz_app{itemApproveMain} = 
  sub { 
    my ($user, $q) = @_;
    return $user->{reviewType}
        && $user->{reviewType} != $UR_DATA_MANAGER
        && $user->{reviewType} != $UR_PSYCHOMETRICIAN
        && hasItemBank(@_); 
  };
$authz_app{passageApproveMenu} = $authz_app{itemApproveMain};
$authz_app{itemPassageCreate} = $authz_app{itemApproveMain};
$authz_app{itemRubricCreate} = $authz_app{itemApproveMain};

$authz_app{itemPrintList} = 
  sub { 
    my ($user, $q) = @_;
    return (  isCommittee(@_) 
           || $user->{reviewType} == $UR_CONTENT_SPECIALIST
           || $user->{adminType})
	 && hasItemBank(@_); 
  };
$authz_app{passagePrintList} = $authz_app{itemPrintList};

$authz_app{itemReport} = 
  sub { 
    my ($user, $q) = @_;
    return (  $user->{reviewType} == $UR_CONTENT_SPECIALIST
           || $user->{adminType} )
	&& hasItemBank(@_);
  };
$authz_app{passageReport} = $authz_app{itemReport};

$authz_app{itemAdminMenu} = 
  sub { 
    my ($user, $q) = @_;
    return $user->{adminType};
  };

$authz_app{itemBankManage} = 
  sub { 
    my ($user, $q) = @_;
    return $user->{adminType}
        && ( $user->{adminType} == $UA_ORG
	  || $user->{adminType} == $UA_SUPER
	  || hasItemBank(@_) );
  };

$authz_app{itemUserManage} = 
  sub { 
    my ($user, $q) = @_;
    return $user->{adminType} == $UA_SUPER || $user->{adminType} == $UA_ORG; 
  };

$authz_app{cde} = 
  sub {
    my ($user, $q) = @_;

    if(defined($q->param('action')) && $q->param('action') eq 'dataManager') {

      return 0 if $user->{reviewType} != $UR_DATA_MANAGER;
    }

    return 1;
  };

# the main function, is the user authz for this app?
sub isAuthorized {

  my $appName = shift;
  my $q = shift;
  my $dbh = shift;

  return 1 unless exists $authz_app{$appName};

  my $user = Session::getUser($q->env, $dbh);

  return $authz_app{$appName}->($user, $q); 
}

# the authz helper functions below here

# authz: is the user authz for this item bank?
sub hasItemBank {

  my($user, $q) = @_;

  return 0 unless scalar keys %{$user->{banks}};
  return 0 if defined($q->param('itemBankId')) 
                && $q->param('itemBankId') ne '1000000'
                && ! exists $user->{banks}{$q->param('itemBankId')};
  return 1;
}

sub isCommittee {

  my($user, $q) = @_;

  return 1 if $user->{reviewType} == $UR_COMMITTEE_REVIEWER 
           || $user->{reviewType} == $UR_COMMITTEE_FACILITATOR;
  return 0;
}
 
1;

