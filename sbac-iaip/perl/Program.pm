package Program;

use DBI;
use UrlConstants;
use File::Copy;

#
# Constructor takes 2 params
# 1) DB handle
# 2) Item Bank ID
#
sub new {

    my ($type) = shift;
    my ($self) = {};
    $self->{dbh} = shift;
    $self->{id} = shift || 0;

    my $loadDefaults = 1;

    if ( $self->{id} > 0 ) {

        my %val_map = (
            name        => 'ib_external_id',
            description => 'ib_description',
            owner       => 'ib_owner',
            base        => 'ib_host_base',
            hasIms      => 'ib_has_ims',
            assignImsId => 'ib_assign_ims_id'
        );

        my $sql = "SELECT * FROM item_bank WHERE ib_id=$self->{id}";
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute();

        if ( my $row = $sth->fetchrow_hashref ) {

            $self->{$_} = $row->{ $val_map{$_} } foreach keys %val_map;

            $self->{itemImgUrl}  = $orcaUrl . 'images/lib' . $self->{id} . '/';
            $self->{itemImgPath} = $webPath . $self->{itemImgUrl};

            $self->{passageUrl} = $orcaUrl . 'passages/lib' . $self->{id} . '/';
            $self->{passagePath} = $webPath . $self->{passageUrl};

            $self->{passageImgUrl}  = $self->{passageUrl} . 'images/';
            $self->{passageImgPath} = $orcaUrl . $self->{passageImgPath};

            $self->{rubricUrl}  = $orcaUrl . 'rubrics/lib' . $self->{id} . '/';
            $self->{rubricPath} = $webPath . $self->{rubricUrl};

            $self->{rubricImgUrl}  = $self->{rubricUrl} . 'images/';
            $self->{rubricImgPath} = $orcaUrl . $self->{rubricImgPath};

            $loadDefaults = 0;
        }

        $sth->finish;
    }

    if ($loadDefaults) {

        $self->{$_} = 0 foreach qw/id hasIms assignImsId/;
        $self->{$_} = ''
          foreach
          qw/name description owner base itemImgUrl itemImgPath passageUrl passagePath
          passageImgUrl passageImgPath rubricUrl rubricPath rubricImgUrl rubricImgPath/;
    }

    bless( $self, $type );
    return ($self);
}

#
# GETTERS
#
sub getName        { return $_[0]->{name}; }
sub getDescription { return $_[0]->{description}; }
sub getUrl         { return $_[0]->{url}; }
sub getPath        { return $_[0]->{path}; }
sub getHasIms      { return $_[0]->{hasIms}; }
sub getAssignImsId { return $_[0]->{assignImsId}; }

sub getItems {
    my ($self) = shift;
    my @items = ();

    $sql = "SELECT i_id FROM item WHERE ib_id=$self->{id}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        push( @items, $row->{i_id} );
    }
    $sth->finish;
    return @items;
}

sub getPassages {
    my ($self) = shift;
    my @passages = ();

    $sql = "SELECT p_id FROM passage WHERE ib_id=$self->{id}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        push( @passages, $row->{i_id} );
    }
    $sth->finish;
    return @passages;
}

#
# SETTERS
#
sub setName        { $_[0]->{name}        = $_[1]; }
sub setDescription { $_[0]->{description} = $_[1]; }
sub setOwner       { $_[0]->{owner}       = $_[1]; }
sub setHasIms      { $_[0]->{hasIms}      = $_[1]; }
sub setAssignImsId { $_[0]->{assignImsId} = $_[1]; }

#
# Create a new Rubric
#
sub create {
    my ($self) = shift;

    return 0 if $self->{name} eq '';

    my $sql = 'INSERT INTO item_bank SET ib_external_id='
      . $self->{dbh}->quote( $self->{name} );
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute() || return 0;
    $sth->finish;

    $self->{id} = $self->{dbh}->{mysql_insertid};

    $self->{itemImgUrl}  = $orcaUrl . 'images/lib' . $self->{id} . '/';
    $self->{itemImgPath} = $webPath . $self->{itemImgUrl};

    $self->{passageUrl}  = $orcaUrl . 'passages/lib' . $self->{id} . '/';
    $self->{passagePath} = $webPath . $self->{passageUrl};

    $self->{passageImgUrl}  = $self->{passageUrl} . 'images/';
    $self->{passageImgPath} = $orcaUrl . $self->{passageImgPath};

    $self->{rubricUrl}  = $orcaUrl . 'rubrics/lib' . $self->{id} . '/';
    $self->{rubricPath} = $webPath . $self->{rubricUrl};

    $self->{rubricImgUrl}  = $self->{rubricUrl} . 'images/';
    $self->{rubricImgPath} = $orcaUrl . $self->{rubricImgPath};

    foreach (
        qw/itemImgPath passagePath passageImgPath rubricPath rubricImgPath/)
    {

        mkdir $self->{$_};
        system( "chmod", "a+rw", $self->{$_} );
    }

    copy "${commonPath}editpro/eopro/config.xml",
      "${commonPath}editpro/eopro/config-$self->{name}.xml";

    foreach (qw/uiconfig uiconfig-passage uiconfig-passage-footnotes/) {
        copy "${commonPath}editpro/eopro/uiconfig.xml",
          "${commonPath}editpro/eopro/$_-$self->{name}.xml";
    }

    $self->save() || return 0;

    return 1;
}

#
# Save this Item Bank
#
sub save {
    my ($self) = shift;

    return 0 if ( $self->{id} == 0 );

    $sql = sprintf(
'UPDATE item_bank SET ib_external_id=%s, ib_description=%s, ib_owner=%s, ib_has_ims=%d,'
          . ' ib_assign_ims_id=%d WHERE ib_id=%d',
        $self->{dbh}->quote( $self->{name} ),
        $self->{dbh}->quote( $self->{description} ),
        $self->{dbh}->quote( $self->{owner} ),
        $self->{hasIms},
        $self->{assignImsId},
        $self->{id}
    );

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sth->finish;

    return 1;
}

BEGIN {
}

1;
