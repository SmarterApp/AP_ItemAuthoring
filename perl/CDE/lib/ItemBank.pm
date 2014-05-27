package ItemBank;

use strict;
use Config::General;
use JSON;
use Params::Validate qw(:all);
use Spreadsheet::ParseExcel::Simple;

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
    my @dirs = split /\//, $INC{'ItemBank.pm'};
    splice(@dirs, -2, 2, 'configs', $self->{_config_name} || 'item_bank.conf');
    $self->{_config_file} ||= sprintf "%s", join('/', @dirs);
    my $cge    = new Config::General( -ConfigFile => $self->{_config_file}, 
                                      -IncludeRelative => 1, 
                                      -InterPolateVars => 1 );
    my %config = $cge->getall;
    $self->{_cfg}->{$_} = $config{$_} foreach( keys %config );

    $self->{item_bank} = $self->{db}->getDataHash( 
		sql => $self->{_cfg}->{select_item_bank_byid_sql}, values => [$self->{ib_id}], 
    );
}

sub getItemByMetadataFields {
    my ($self, %p) = @_;

    $p{ib_id} ||= $self->{ib_id} || 0;
    $p{ip_id} ||= $self->{ip_id} || undef;
    my @bv = ( $p{ib_id} );
    my @where_clause = ();
    for( keys %{$self->{_cfg}->{search_items_by_metadata_fields}} ) {
	$p{$_} = defined $p{$_} ? $p{$_} : defined $self->{$_} ? $self->{$_} : undef;
        if( defined $p{$_} ) {
	    if( $self->{_cfg}->{search_items_by_metadata_fields}->{$_} eq 'str' ) {
                # escape _ to make sure it is treated as a literal
                $p{$_} =~ s/\_/\\_/g;
	    	push @where_clause, sprintf("%s LIKE %s", $_, $self->{db}->{dbh}->quote('%' . $p{$_} . '%') );
	    }
	    elsif( $self->{_cfg}->{search_items_by_metadata_fields}->{$_} eq 'int' ) {
	    	push @bv, $p{$_};
	    	push @where_clause, "$_ = ?";
	    }
	    elsif( $self->{_cfg}->{search_items_by_metadata_fields}->{$_} eq 'daterange' ) {
	      if($p{$_} ne '') {
	        if($_ =~ /^(.*)\_(start|end)$/) {
	          my $field = $1;
	          my $range_part = $2;
	          push @where_clause, ($field . ($range_part eq 'start' ? ' >= ' : ' <= ') 
		                              .$self->{db}->{dbh}->quote($p{$_}));
                }
              }
	    }
	    else {
		$p{ic}++;
	    }
	}
    }

    my $sql = $self->{_cfg}->{select_items_sql};
    $sql .= sprintf " AND %s", join(' AND ', @where_clause) if @where_clause;
    if( $p{ip_id} ) {
	$sql .= " AND ip_id=?";
	push @bv, $p{ip_id};
    }
    $sql .= " ORDER BY i_external_id";
    my $items = $self->{db}->getDataArray( sql => $sql, values => \@bv, );
    $items = ref $items eq 'ARRAY' ? $items : [];

    my @tmp_items = ();

    if( $p{need_art} ) {
        @tmp_items = ();
        for( @$items ) {
            my $art_request = sprintf "%s%sworkflow/art-request/%s.html",
                                $self->{db}->{instance}->{web_path},
                                $self->{db}->{instance}->{orca_url},
                                $_->{i_id};
            push @tmp_items, $_ if -e $art_request;
        }
        $items = \@tmp_items;
    }

    if( $p{ic} ) {
	my @tmp_ary = ();
    	for( @$items ) {
	    my @ic_type = my @ic_value = ();
	    if( $p{subject_area} ) {
	    	push @ic_type, "ic_type=2";
	    	push @ic_value, "ic_value='$p{subject_area}'";
	    }
	    if( $p{grade_level} ) {
	    	push @ic_type, "ic_type=3";
	    	push @ic_value, "ic_value='$p{grade_level}'";
	    }
	    if( $p{grade_span_start} ) {
	    	push @ic_type, "ic_type=5";
	    	push @ic_value, "ic_value='$p{grade_span_start}'";
	    }
	    if( $p{grade_span_end} ) {
	    	push @ic_type, "ic_type=6";
	    	push @ic_value, "ic_value='$p{grade_span_end}'";
	    }
	    if( $p{dok} ) {
	    	push @ic_type, "ic_type=8";
	    	push @ic_value, "ic_value='$p{dok}'";
	    }
	    $sql = sprintf qq| 	SELECT * FROM item_characterization 
		   	   	WHERE i_id=$_->{i_id} AND ( (%s) AND (%s) )
		 	     |, join(' AND ', @ic_type), join(' AND ', @ic_value);
	    my $rv = $self->{db}->{dbh}->do( $sql );
	    push @tmp_ary, $_ if( $rv > 0 );
	}
	$items = \@tmp_ary;
    }

    return $self->{limit_items} ? [splice( @$items, 0, $self->{limit_items})] : $items;
}

sub getItems {
    my ($self, %p) = @_;
    $p{ib_id} ||= $self->{ib_id} || 0;
    my @bv = ( $p{ib_id} );
    my $items = $self->{db}->getDataArray( sql => $self->{_cfg}->{select_items_sql}, values => \@bv, );
}

sub getItemsByHierarchy {
    my ($self, %p) = @_;

    $p{$_}  ||= $self->{$_} for( qw( hd_id sh_id ib_id ) );
    my @bv    = ( $p{hd_id}, $p{ib_id} );
    $self->{_cfg}->{select_items_by_hierarchy_sql} .= " LIMIT $self->{limit_items}" if $self->{limit_items};
    my $items = $self->{db}->getDataArray(
                        sql => $self->{_cfg}->{select_items_by_hierarchy_sql},
                        values => \@bv,
    );
    if( ref $items eq 'HASH' ) {
        @bv    = ( $p{ib_id}, $p{sh_id}, );
        $self->{_cfg}->{select_items_by_hierarchy_parent_sql} =~ s/<HD_ID>/$p{hd_id}/g;
        $self->{_cfg}->{select_items_by_hierarchy_parent_sql} .= " LIMIT $self->{limit_items}"
                        if $self->{limit_items};
        $items = $self->{db}->getDataArray(
                        sql => $self->{_cfg}->{select_items_by_hierarchy_parent_sql},
                        values => \@bv,
        );
    }

    if(  ref $items eq 'ARRAY' ) {
	my @hd_types = split /\|/, $self->{hd_types};
	my $level    = pop @hd_types;
    	for( @$items ) {
            my @parent_path = split /,/, $_->{hd_parent_path};
            for my $pp( @parent_path ) {
            	@bv = ( $pp, $p{sh_id}, );
            	my $hierarchy = $self->{db}->getDataHash(
                        sql => $self->{_cfg}->{select_hierarchy_parent_path_sql},
                        values => \@bv,
            	);
            	$_->{"level$hierarchy->{ql_type}"} = $hierarchy->{hd_value};
            }
            my $key = sprintf "level%d", ($_->{ql_type} ? $_->{ql_type} : $level);
            $_->{$key} = $_->{hd_value};
    	}
    }

    return $items;
}

1;
