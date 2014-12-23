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
#added for statistic serach
sub getItemByStatisticsFields { 
  my ($self, %p) = @_;
$p{ib_id} ||= $self->{ib_id} || 0;
$p{ip_id} ||= $self->{ip_id} || undef;


  my $sql="SELECT itm.* FROM item as itm WHERE 1 = 1 ";

if($self->{pub_status}){
$sql=$sql."AND itm.i_publication_status in (".$self->{pub_status}.")";
}

if($self->{multi_admin}){
$sql=$sql."AND EXISTS (SELECT 1
			FROM stat_item_value as siv,
				stat_key as sk,
				stat_administration as sa
			WHERE itm.i_id = siv.i_id
				AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id
				AND sa.sa_id in (". $self->{multi_admin}."))";
}

if($self->{dif_mvf}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" " )  ." AND sk.sk_name = 'DIFCat_Female_v_Male')";
}
if($self->{dif_bvw}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" "  )  ." AND sk.sk_name =  'DIFCat_Black_v_White')";
}
if($self->{dif_avw}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" " )  ." AND sk.sk_name = 'DIFCat_Asian_v_White')";
}
if($self->{dif_navw}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" " )  ." AND sk.sk_name =  'DIFCat_NativeA_v_White')";
}
if($self->{dif_iepvniep}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" "  )  ." AND sk.sk_name =  'DIFCat_IEP_v_NonIEP')";
}
if($self->{dif_lepvnlep}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" "  )  ." AND sk.sk_name =  'DIFCat_LEP_v_NonLEP')";
}
if($self->{dif_t1vnt1}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" "  )  ." AND sk.sk_name = 'DIFCat_Title1_v_NonTitle1')";
}
if($self->{statical_flag}) {  
$sql=$sql."AND EXISTS (SELECT 1 FROM stat_item_value as siv, stat_key as sk, stat_administration as sa WHERE itm.i_id = siv.i_id AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id" .($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" "  )  ." AND sk.sk_name in  ('Item_Flag_A','Item_Flag_B','Item_Flag_C','Item_Flag_D','Item_Flag_F','Item_Flag_H','Item_Flag_N','Item_Flag_O','Item_Flag_P','Item_Flag_R','Item_Flag_V','Item_Flag_Z'))";

warn "$sql"; 
}
if($self->{pc1} || $self->{pc2}) {  
my $key="'Percent_Choosing";
$sql=$sql.getStatisticsByValue($self->{pc1},$self->{pc2},$self->{multi_admin},$key);
}
if($self->{bi1} || $self->{bi2}) {  
my $key="'Biserial_Option";
$sql=$sql.getStatisticsByValue($self->{bi1},$self->{bi2},$self->{multi_admin},$key);
}
if($self->{pbi1} || $self->{pbi2}) {  
my $key="'Pt_biserial_Option";
$sql=$sql.getStatisticsByValue($self->{pbi1},$self->{pbi2},$self->{multi_admin},$key);
}
if($self->{po1} || $self->{po2}) {  
my $key="'Percent_Obtaining";
$sql=$sql.getStatisticsByValueOfObtain($self->{po1},$self->{po2},$self->{multi_admin},$key);
}
if($self->{itc1} || $self->{itc2}) {  
$sql=$sql."AND EXISTS (SELECT 1
			FROM stat_item_value as siv,
				stat_key as sk,
				stat_administration as sa
			WHERE itm.i_id = siv.i_id
				AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id".($self->{multi_admin}?" AND sa.sa_id in ( ".$self->{multi_admin}.")":" " ) .
				    " AND ((sk.sk_name = 'Item_Total_Correlation'"
					.($self->{itc1}?" AND siv.siv_numeric_value >= ".$self->{itc1}:" " )
					.($self->{itc2}?" AND siv.siv_numeric_value <= ".$self->{itc2}:" " ).")))"; 
}


  #warn "Query in $sql\n";
  my $items = $self->{db}->getDataArray( sql => $sql);

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


  return $self->{limit_items} ? [splice( @$items, 0, $self->{limit_items})] : $items;

}
sub getStatisticsByValueOfObtain {
my ($self, @p) = @_; 
my $sql1=" AND EXISTS (SELECT 1
			FROM stat_item_value as siv,
				stat_key as sk,
				stat_administration as sa
			WHERE itm.i_id = siv.i_id
				AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id".($_[2]?" AND sa.sa_id in ( ".$_[2].")":" "  ) .
				    " AND ((sk.sk_name = ".$_[3]."_0'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."_1'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".

					" OR
					 (sk.sk_name = ".$_[3]."_2'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."_3'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."_4'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".

					" OR
					 (sk.sk_name = ".$_[3]."_5'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."_6'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".

					" OR
					 (sk.sk_name = ".$_[3]."_7'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".

					" OR
					 (sk.sk_name = ".$_[3]."_8'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
"))";
return $sql1;
}
sub getStatisticsByValue {
my ($self, @p) = @_; 
my $sql1=" AND EXISTS (SELECT 1
			FROM stat_item_value as siv,
				stat_key as sk,
				stat_administration as sa
			WHERE itm.i_id = siv.i_id
				AND siv.sk_id = sk.sk_id
				AND	siv.sa_id = sa.sa_id".($_[2]?" AND sa.sa_id in ( ".$_[2].")":" ") .
				    " AND ((sk.sk_name = ".$_[3]."A'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."B'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".

					" OR
					 (sk.sk_name = ".$_[3]."C'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."D'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."E'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".

					" OR
					 (sk.sk_name = ".$_[3]."F'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					" OR
					 (sk.sk_name = ".$_[3]."G'"
					.($_[0]?" AND siv.siv_numeric_value >= ".$_[0]:" " )
					.($_[1]?" AND siv.siv_numeric_value <= ".$_[1]:" " ).")".
					

"))";
return $sql1;
}

#end here


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