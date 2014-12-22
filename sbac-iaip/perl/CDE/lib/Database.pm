package Database;

use strict;
use Config::General;

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
    $self->{_config_file} = '/etc/httpd/conf/cde_clients.conf';
    my $cge    = new Config::General( -ConfigFile => $self->{_config_file}, 
                                      -IncludeRelative => 1, 
                                      -InterPolateVars => 1 );
    my %config = $cge->getall;
    $self->{_cfg}->{$_} = $config{$_} foreach( keys %config );

    $p{instance_name} ||= 'cde';
    $self->{instance} = $self->{_cfg}->{$p{instance_name}};
}


##########
#
##########
sub getDataArray {
    my ( $self, %p ) = @_;

    return { _error_msg => "No sql passed" } unless $p{sql};

    $p{dbh}    ||= $self->{dbh}; 
    $p{values} ||= [];
    my $sth      = $p{dbh}->prepare( $p{sql} );
    $sth->execute( @{$p{values}} );
    my @dataset  = (); 
    while(my $hr = $sth->fetchrow_hashref( 'NAME_lc' )) {
    	push @dataset, $hr;
    }
    $sth->finish();
    return @dataset ? \@dataset : { _error_msg => "No Data To Return From getDataArray($p{sql})" };
}

##########
#
##########
sub getDataHash {
    my ( $self, %p ) = @_;

    return { _error_msg => "No sql passed" } unless $p{sql};
    
    $p{dbh}    ||= $self->{dbh}; 
    $p{values} ||= [];
    my $sth      = $p{dbh}->prepare( $p{sql} );
    $sth->execute( @{$p{values}} ) || warn "Unable to execute $p{sql}";
    my $hr = $sth->fetchrow_hashref( 'NAME_lc' );
    $sth->finish();
    return $hr ? $hr : { _error_msg => "No Data To Return From getDataHash($p{sql})" };
}

##########
#
##########
sub getDataHashByKey {
    my ( $self, %p ) = @_;

    return { _error_msg => "No sql passed" } unless $p{sql};
    return { _error_msg => "No KEY passed" } unless $p{key};

    $p{dbh}    ||= $self->{dbh};
    $p{values} ||= [];
    my $sth      = $p{dbh}->prepare( $p{sql} );
    $sth->execute( @{$p{values}} );
    my $dataset;
    while(my $hr = $sth->fetchrow_hashref( 'NAME_lc' )) {
        $dataset->{$hr->{$p{key}}} = $hr;
    }
    $sth->finish();
    return $dataset ? $dataset : { _error_msg => "No Data To Return From getDataHashByKey($p{sql})" };
}

1;
