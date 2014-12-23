package CDE;

use strict;
use CGI::Session;
use Config::General;
use HTML::Template::Expr;
use JSON;
use Spreadsheet::ParseExcel::Simple;
use Text::CSV::Simple;
use Data::Dumper;

use Database;
use ItemBank;

sub new {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);
    $self->_init( @_ );
    return $self;
}

sub _init {
    my ($self, %p) = @_;

    ### Make any parameters passed CLASS variables
    $self->{$_} = $p{$_} foreach( keys %p );
    ### Store here for group access
    $self->{params} = \%p;

    ##### Load Configuration ######
    my @dirs = split /\//, $INC{'CDE.pm'};
    splice(@dirs, -2, 2, 'configs', $self->{_config_name} || 'cde.conf');
    $self->{_config_file} ||= sprintf "%s", join('/', @dirs);
    my $cge    = new Config::General( -ConfigFile => $self->{_config_file}, 
				      -IncludeRelative => 1,
				      -InterPolateVars => 1 );
    my %config = $cge->getall;
    $self->{_cfg}->{$_} = $config{$_} foreach( keys %config );

    ##### Save CGI parameters
    if( $self->{cgi} ) {
        my %input;
        push @{$input{$_}}, $self->{cgi}->param( $_ ) foreach( $self->{cgi}->param );
        for(keys %input) {
            $self->{cgi_params}->{$_} = join "|", @{$input{$_}};
            $self->{cgi_params}->{$_} =~ s/^\|//;
            $self->{cgi_params}->{$_} =~ s/\s+$//;
            $self->{cgi_params}->{$_} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg; 
            warn "$_ => $self->{cgi_params}->{$_}"; 
        }
      $self->{env} = $self->{cgi}->env;
      #warn Dumper($self->{env}) if $self->{env};
    }
    $self->{_action} = $self->{params}->{action} || $self->{cgi_params}->{action};

    $p{instance_name} ||= $self->{cgi_params}->{instance_name} || 'cde';

    $self->{db} = new Database( instance_name => $p{instance_name}, dbh => $self->{dbh} );

    $self->{USER} = $self->_getUser unless $self->{_SERVER_}; # Doesn't return if Session not found
    $self->{USER}->{instance_name} = $p{instance_name};

    $self->{w_id} ||= 1;
}

sub run {
    my ($self, %p) = @_;

    $self->{_action} = $p{action} if $p{action};
    my $action = $self->{_action} or return { error => 1, error_msg => 'No action provided!' };
    my $run    = $self->$action( %p );

    my $psgi_out = '';

    if( ref($run) =~ /^HASH/ ) {
	$psgi_out .= $run->{error} if $run->{error};
    }
    else {
        $run->param( $self->{_CDE_}->{USER} );
        $psgi_out .= $run->output;
    }

  return $psgi_out;
}

sub displayMainMenu {
    my ($self, %p) = @_;

    my $template = $self->_getTemplate( template_name => $self->{_action} );
    return $template if $template->{error};


    $template->param( sess_id => $self->{cgi_params}->{sess_id} );
    return $template;
}

sub displayHome {
    my ($self, %p) = @_;

    my $template = $self->_getTemplate( template_name => $self->{_action} );
    return $template if $template->{error};

    $template->param( $self->{USER} );
    return $template;
}

sub _getTemplate {
    my ( $self, %p ) = @_;

    return { error => 1, error_msg => "No template_name passed" } unless $p{template_name};
    $p{_cfg} ||= $self->{_cfg};

    my $filename = sprintf "%s/%s", $p{_cfg}->{template_dir}, $p{_cfg}->{$p{template_name}.'_tmpl'};
    return { error => 1, error_msg => "No template file : $filename found!" } unless -e $filename;

    my $template = HTML::Template::Expr->new(
                        filename          => $filename,
                        die_on_bad_params => 0,
                        cache             => 1,
                        global_vars       => 1,
    );
    return $template ? $template : { error => 1, error_msg => 'Problem Creating Template' };
}

sub _getUser {
    my ( $self, %p ) = @_;

    my $user_name= $self->{env}->{'HTTP_REMOTE_USER'} || 'no_user_name';
    my $user = $self->{db}->getDataHash( sql 	=> $self->{_cfg}->{select_user_by_username_sql}, 
					 values => [$user_name] );
    if ( $user->{_error_msg} ) {
	$user->{type}           = 0;
        $user->{id}             = 0;
        $user->{adminType}      = 0;
        $user->{reviewType}     = 0;
        $user->{organizationId} = 0;
    }
    else {
        $user->{type}           = $user->{u_type};
        $user->{id}             = $user->{u_id};
        $user->{adminType}      = $user->{u_admin_type};
        $user->{reviewType}     = $user->{u_review_type};
        $user->{organizationId} = $user->{o_id};

	my $session 	        = $self->_startSession( u_id => $user->{u_id} );
	$user->{sess_id}        = $session->{sess_id};
	$user->{ss_variables}   = $session->{ss_variables};
    }

    return $user;
}

sub _startSession {
    my ( $self, %p ) = @_;


    $p{sess_id} ||= $self->{cgi_params}->{sess_id} || undef;
    
    # If {sess_id} = undef CGI::Session will create one.
    $self->{_session} = CGI::Session->new($p{sess_id});
    $p{sess_id} = $self->{_session}->id();
    $p{ss_variables} = $self->{_session}->is_new() ? undef : $self->{_session}->param('ss_variables');

    return \%p;
}

sub _saveSession {
    my ( $self, %p ) = @_;

    #$self->{_session}->param('ss_variables', $p{ss_variables});
}

sub _hashToSelectList {
    my ( $self, %p ) = @_;

    $p{s} ||= '';
    my @list = ();
    foreach( sort {$a <=> $b} keys %{$p{hash}} ) {
    	push @list, { _value => $_, _label => $p{hash}->{$_}, _selected => $p{s} eq $_ ? 'selected' : '' }; 
    }
    return \@list;
}

sub _hashToSelectListNoSort {
    my ( $self, %p ) = @_;

    $p{s} ||= '';
    my @list = ();
    foreach( keys %{$p{hash}} ) {
    	push @list, { _value => $_, _label => $p{hash}->{$_}, _selected => $p{s} eq $_ ? 'selected' : '' }; 
    }
    return \@list;
}

sub _arrrayToSelectList {
    my ( $self, %p ) = @_;

    $p{s} ||= '';
    my @list = ();
    foreach( @{$p{list}} ) {
    	push @list, { _value => $_, _label => $_, _selected => $p{s} eq $_ ? 'selected' : '' }; 
    }
    return \@list;
}

sub displayPublicationHistory {
    my ( $self, %p ) = @_;

    my $template = $self->_getTemplate( template_name => $self->{_action} );
    return $template if $template->{error};

    return $template;
}

sub dataManager {
    my ( $self, %p ) = @_;

    my $template = $self->_getTemplate( template_name => $self->{_action} );
    return $template if $template->{error};

    $template->param( $self->{cgi_params} );
    $template->param( $self->{USER} );
    return $template;
}

1;
