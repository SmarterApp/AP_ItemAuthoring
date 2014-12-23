package Admin;

use strict;
use Config::General;
use HTML::Template::Expr;

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

    ##### Load Configuration ######
    $self->{_config_file} ||= sprintf "%s", 'configs/cde_admin.conf';
    my $cge    = new Config::General( -ConfigFile => $self->{_config_file}, 
                                      -IncludeRelative => 1, 
                                      -InterPolateVars => 1 );
    my %config = $cge->getall;
    $self->{_cfg}->{$_} = $config{$_} foreach( keys %config );

    $cge = new Config::General( -ConfigFile => $config{cde_clients_conf}, 
                                -IncludeRelative => 1, 
                                -InterPolateVars => 1 );
    %config = $cge->getall;
    $self->{_cde_clients_cfg}->{$_} = $config{$_} foreach( keys %config );
    
    ##### Save CGI parameters
    if( $self->{cgi} ) {
        my %input;
        push @{$input{$_}}, $self->{cgi}->param( $_ ) foreach( $self->{cgi}->param );
        for(keys %input) {
            $self->{cgi_params}->{$_} = join "|", @{$input{$_}};
            $self->{cgi_params}->{$_} =~ s/^\|//;
            $self->{cgi_params}->{$_} =~ s/\s+$//;
            $self->{cgi_params}->{$_} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        }
    }
    $self->{_action} = $self->{action} || $self->{cgi_params}->{action};
}

sub run {
    my ($self, %p) = @_;

    $self->{_action} = $p{action} if $p{action};
    my $action = $self->{_action} or return { error => 1, error_msg => 'No action provided!' };
warn "action: ".$action;
    my $run    = $self->$action( %p );
    if( $run->{error} ) {
warn $run->{error};
    }
    else {
	print $run->output;
    }
}

########## 
# 
########## 
sub displayMainPage {
    my ($self, %p) = @_;

    my $template = $self->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
warn $template->{error_msg} if $template->{error};
    unless( $template->{error} ) {
    	$template->param( clients => $self->getClients );
    }

    return $template;
}

sub manageClient {
    my ($self, %p) = @_;

    my $template = $self->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    unless( $template->{error} ) {
    	$template->param( clients => $self->getClients );
    }

    return $template;
}

sub modifyClient {
    my ($self, %p) = @_;

    my $iclient;
    my $clients = $self->getClients;
    for my $client ( @$clients ) {
	next unless( $client->{short_name} eq $self->{cgi_params}->{short_name} );
	for( qw( client_name db_name db_host db_user db_pass web_path orca_url common_url ) ) {
	     $client->{$_} = $self->{cgi_params}->{$_};
	}
	$iclient = $client;
    } 

    my $template = $self->_getTemplate( _cfg => $self->{_cfg}, template_name => 'ajax_output' );
    unless( $template->{error} ) {
        $template->param( msg  => "Modified $iclient->{client_name}!", );
    }

    return $template;
}

sub buildCDE {
    my ($self, %p) = @_;

    my @a = map { {label => (split /\//)[0]} } `$self->{_cfg}->{svn_list_cmd}`;
    my $template = $self->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    unless( $template->{error} ) {
        $template->param( clients  => $self->getClients,
			  branches => \@a,
			);
    }

    return $template;
}

sub buildOutCDE {
    my ($self, %p) = @_;

    my $rc = `$self->{_cfg}->{build_cde_cmd} --client_name=$self->{cgi_params}->{client_name} --branch_name=$self->{cgi_params}->{branch_name} --build_num=$self->{cgi_params}->{build_num}`;
    $rc =~ s/\n+/<br>/go;

    my $template = $self->_getTemplate( _cfg => $self->{_cfg}, template_name => 'ajax_output' );
    unless( $template->{error} ) {
        $template->param( msg  => $rc,
			);
    }

    return $template;
}

sub getClients {
    my ($self, %p) = @_;

    my @clients = ();
    for( @{$self->{_cde_clients_cfg}->{short_name}} ) {
	my @build_label;
	unless( -e "/www/$_" ) {
	    @build_label = ( 'trunk', 0, 'never' );
	}
	else {
	    @build_label    = split /\//, `ls -l /www/$_`;
	    @build_label    = split /-/, pop @build_label;
	    $build_label[1] = substr $build_label[1], 5;
	    chomp $build_label[2];
	}
    	push @clients, { short_name   => $_,
			 comma        => ',',
			 client_name  => $self->{_cde_clients_cfg}->{$_}->{client_name},
			 db_host      => $self->{_cde_clients_cfg}->{$_}->{db_host},
			 db_name      => $self->{_cde_clients_cfg}->{$_}->{db_name},
			 db_user      => $self->{_cde_clients_cfg}->{$_}->{db_user},
			 db_pass      => $self->{_cde_clients_cfg}->{$_}->{db_pass},
			 web_path     => $self->{_cde_clients_cfg}->{$_}->{web_path},
			 orca_url     => $self->{_cde_clients_cfg}->{$_}->{orca_url},
			 common_url   => $self->{_cde_clients_cfg}->{$_}->{common_url},
			 build_branch => $build_label[0],
			 build_num    => $build_label[1],
			 build_time   => $build_label[2],
			 build_label  => join '-', @build_label,
		       };
    }
    $clients[$#clients]->{comma} = '';
    return \@clients;
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

1;
