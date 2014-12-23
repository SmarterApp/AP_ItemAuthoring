package ItemsManager;

use strict;
use Cwd qw();
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use CDE;
use ItemBank;
use StandardsManager;
use JSON;
use MIME::Lite;
use Spreadsheet::ParseExcel::Simple;
use Text::CSV::Simple;
use URI::Escape;
use XML::Tidy::Tiny qw(xml_tidy);

use ItemAsset;
use Item;
use ItemConstants;
use Passage;

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
    $self->{_CDE_} = new CDE( %p );

    ##### Load Configuration ######
    my @dirs = split /\//, $INC{'ItemsManager.pm'};
    splice(@dirs, -2, 2, 'configs', $self->{_config_name} || 'items_manager.conf');
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
            warn "$_ ======>>>> $self->{cgi_params}->{$_}";
        }
    }
    $self->{_action} = $self->{action} || $self->{cgi_params}->{action};
    $self->{session} = decode_json $self->{_CDE_}->{USER}->{ss_variables} if $self->{_CDE_}->{USER}->{ss_variables};
    $self->{session}->{$self->{_action}}->{cgi_params} = $self->{cgi_params};

    $self->{_IB_} = new ItemBank( db => $self->{_CDE_}->{db}, %{$self->{cgi_params}} );
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
    $self->{_CDE_}->_saveSession( ss_variables => encode_json $self->{session}, 
				  sess_id => $self->{_CDE_}->{USER}->{sess_id},
				);
				
  return $psgi_out;
}

##########
#
##########
sub displaySearchMenu {
    my ( $self, %p ) = @_; 
    
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    #warn "cwd = " . Cwd::cwd();
    warn "template error: $template->{error_msg}" if $template->{error};
    return $template if $template->{error};

    $p{item_bank} = $self->{_CDE_}->{db}->getDataHashByKey( 
				sql => $self->{_cfg}->{select_item_bank_with_access_sql},
				values =>  [ $self->{_CDE_}->{USER}->{id} ],
				key => 'ib_id' 
    );
    if( $p{item_bank}->{_error_msg} ) {
        warn $p{item_bank}->{_error_msg} . ", u_id=" . $self->{_CDE_}->{USER}->{id};
	$p{item_bank} = {};
    }
    else {
        foreach( keys %{$p{item_bank}} ) {
	    push @{$p{programs}}, { ib_id => $_, ib_name => $p{item_bank}->{$_}->{ib_external_id}, };
    	}
    	@{$p{programs}} = sort { $a->{ib_name} cmp $b->{ib_name} } @{$p{programs}};
    	$p{item_bank} = encode_json $p{item_bank};

        # filter and order development states by states available in the SBAC item workflow
        my @dev_states_keys = @{$self->{_CDE_}->{_cfg}->{dev_states_workflow_ordered_keys}};
        my %dev_states_hash = map { $_ => $self->{_CDE_}->{_cfg}->{dev_states}{$_} } grep { exists $self->{_CDE_}->{_cfg}->{dev_states}{$_} } @dev_states_keys;

        my @dev_states_list = ();

        my $selected_dev_state = $self->{cgi_params}->{i_dev_state} || '';

        foreach(@dev_states_keys) {
    	  push @dev_states_list, { _value => $_, _label => $dev_states_hash{$_}, _selected => $selected_dev_state eq $_ ? 'selected' : '' }; 
        }

    	$p{dev_states} = \@dev_states_list;
  
      my $item = new Item( $self->{_CDE_}->{db}->{dbh},);
	  my $adminList = $item->getAdmin(); 
	  $p{i_admin_list} = $self->{_CDE_}->_hashToSelectList(hash =>  $adminList, 
							s => $self->{cgi_params}->{i_publication_status} || '' 
    	);

      my $pubStatus = $item->getPubStatus();     
    	$p{i_pub_stats} = $self->{_CDE_}->_hashToSelectList(hash =>  $pubStatus, 
							s => $self->{cgi_params}->{i_publication_status} || '' 
    	);
    	$p{authors} = $self->{_CDE_}->{db}->getDataArray( sql => $self->{_CDE_}->{_cfg}->{select_editors_sql}, );
    	if( ref $p{authors} eq 'HASH' ) {
            $p{authors} = [];
    	}


    	$p{standards} = $self->{_CDE_}->{db}->getDataArray( sql => $self->{_cfg}->{select_standard_hierarchy_sql}, );
    	if( ref $p{standards} eq 'HASH' ) {
            $p{standards} = [];
	    $p{hierarchy_json} = '{}';
    	}
    	else {
	    my $hierarchy = $self->{_CDE_}->{db}->getDataHashByKey(
                        sql => $self->{_cfg}->{select_standard_hierarchy_sql},
                        key => 'sh_id',
            );
            $hierarchy = {} if $hierarchy->{_error};
            foreach( keys %{$hierarchy} ) {
                $hierarchy->{$_}->{ql} = $self->{_CDE_}->{db}->getDataHashByKey(
                                        sql => $self->{_cfg}->{select_qualifier_label_sql},
                                        values => [$_],
                                        key => 'ql_type',
                );
                $hierarchy->{$_}->{num_ql} = scalar keys %{$hierarchy->{$_}->{ql}};
                push @{$p{hierarchy}}, $hierarchy->{$_};
            }
            @{$p{hierarchy}} = sort { $a->{sh_external_id} cmp $b->{sh_external_id} } @{$p{hierarchy}} if $p{hierarchy};
            $p{hierarchy_json} = to_json $hierarchy;

    	}

    	$p{item_formats} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{item_formats}, 
    	);
    	$p{subject_areas} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const2}, 
    	);
    	$p{grade_levels} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const3}, 
    	);
    	$p{points} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const7}, 
    	);
    	$p{difficulty_levels} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{difficulty_levels}, 
    	);
    	$p{dok} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const8}, 
    	);
    	$p{grade_span} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const5}, 
    	);

        $p{java_url} = $self->{_CDE_}->{db}->{instance}->{java_url};

        $p{web_host} = $self->{_CDE_}->{db}->{instance}->{web_host};

        $p{tib_url} = $self->{_CDE_}->{db}->{instance}->{tib_url};

    	$template->param( \%p );
    }

    $template->param( metadata_headers => $self->{_cfg}->{metadata_headers},
		      metadata_keys => $self->{_cfg}->{metadata_keys},
		      hierarchy_headers => $self->{_cfg}->{hierarchy_headers},
		      hierarchy_keys => $self->{_cfg}->{hierarchy_keys},
    );

     $template->param( $self->{cgi_params} );
    return $template;
}   

sub getItems {
    my ( $self, %p ) = @_; 
    
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    my $items; my %item_json;
    $p{item_cnt} = 0;
    SUBACTION: {
	if( $self->{cgi_params}->{subaction} eq 'search_standards' ) {
            $items = $self->{_IB_}->getItemsByHierarchy(
                                        hd_id => $self->{cgi_params}->{hd_id},
                                        sh_id => $self->{cgi_params}->{sh_id},
                                        ib_id => $self->{cgi_params}->{ib_id},
            );
	    $self->{cgi_params}->{subaction} = 'search_standards_msie' if( $self->{cgi}->user_agent() =~ /$self->{_cfg}->{sc_browsers}/ );
            last SUBACTION;
        }
        if( $self->{cgi_params}->{subaction} eq 'search_metadata' ) {
            $items = $self->{_IB_}->getItemByMetadataFields( need_art => ($self->{cgi_params}->{need_art} ? 1 : 0) );
	    $self->{cgi_params}->{subaction} = 'search_metadata_msie' if( $self->{cgi}->user_agent() =~ /$self->{_cfg}->{sc_browsers}/ );
            last SUBACTION;
        }
#
         if( $self->{cgi_params}->{subaction} eq 'search_statistics' ) {
            $items = $self->{_IB_}->getItemByStatisticsFields( need_art => ($self->{cgi_params}->{need_art} ? 1 : 0) );
	    $self->{cgi_params}->{subaction} = 'search_statistics_msie' if( $self->{cgi}->user_agent() =~ /$self->{_cfg}->{sc_browsers}/ );
            last SUBACTION;
        }
#
    	$items = $self->{_IB_}->getItems;
    }

    unless( ref $items eq 'HASH' ) {
	$p{item_cnt} = scalar @$items; 
	for( @$items ) {
	    $_->{i_xml_data} = '';
            $_->{i_dev_state} ||= 1;
            $_->{i_dev_state} = $self->{_CDE_}->{_cfg}->{dev_states}->{$_->{i_dev_state}};
            $_->{i_format} = $self->{_CDE_}->{_cfg}->{item_formats}->{$_->{i_format}};
	    $_->{i_id} = $_->{i_id} ? $_->{i_id} : $_->{id};
	    $_->{editor_name} = "$_->{u_last_name}, $_->{u_first_name}";
	    $item_json{$_->{i_id}} = $_;
	}
    }
    else {
	$items = [];
    }


    $template->param( items => $items, item_json => encode_json \%item_json );
    $template->param( \%p );
    $template->param( $self->{cgi_params} );

    return $template;
}   

sub deleteItems {
    my ( $self, %p ) = @_; 
    
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};
    
    my $deleted_cnt = 0;
    my @item_list = map { 'i_id' => $_ }, split /\|/, $self->{cgi_params}->{item_list};
    for ( @item_list ) {
    	my $mutable = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_item_readonly_sql},
				values => [$_->{i_id}],
	);
    	my $versioned = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_item_versioned_sql},
				values => [$_->{i_id}],
	);
	if( $mutable->{cnt} == 0 && $versioned->{cnt} == 0 ) {
	    my $item = new Item( $self->{_CDE_}->{db}->{dbh}, $_->{i_id} );
            $item->remove('Item Admin', $self->{_CDE_}->{USER}->{id},'Delete Item');
    	    $deleted_cnt++;
	}
    }
    $p{item_json} = encode_json \@item_list;
    $p{msg} 	  = sprintf "%d Item(s) Successfully Deleted!", $deleted_cnt;

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub moveItems {
    my ( $self, %p ) = @_;

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    my $move_cnt = 0;
    my @item_list = map { 'i_id' => $_ }, split /\|/, $self->{cgi_params}->{item_list};
    for ( @item_list ) {
        my $mutable = $self->{_CDE_}->{db}->getDataHash(
                                sql => $self->{_cfg}->{select_item_readonly_sql},
                                values => [$_->{i_id}],
        );
        if( $mutable->{cnt} == 0 ) {
            my $item_exist = $self->{_CDE_}->{db}->getDataHash(
                                sql => $self->{_CDE_}->{_cfg}->{select_item_exist_sql},
                                values => [$self->{cgi_params}->{t_ib_id}, $_->{i_id}],
            );
	    if( $item_exist->{cnt} == 0 ) {
            	my $item = new Item( $self->{_CDE_}->{db}->{dbh}, $_->{i_id} );
            	$item->moveToBank($self->{cgi_params}->{t_ib_id},'Item Admin', $self->{_CDE_}->{USER}->{id}, 'Moved between Programs');
            	$move_cnt++;
	    }
        }
    }
    $p{item_json} = encode_json \@item_list;
    $p{msg}       = sprintf "%d Item(s) Successfully Moved!", $move_cnt;

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}

sub getLists {
    my ( $self, %p ) = @_; 
    
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

	$p{item_json} = '{}';
    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub groupProcessItem {
    my ( $self, %p ) = @_; 

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    my $save_reason = '';

    my $sql = 'UPDATE item SET ';
    for( split(/\|/, $self->{cgi_params}->{item_chk}) ) {

    	my $mutable = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_item_readonly_sql},
				values => [$_],
	);
	my $isMutable = $mutable->{cnt} ? 0 : 1;

        my $item = new Item($self->{_CDE_}->{db}->{dbh}, $_);
	my $msg;
	SUBACTION: {
	    if( $self->{cgi_params}->{subaction} eq 'renameItem' ) {
	        if($isMutable) {
		  $msg = $item->rename( $self->{cgi_params}->{rename_name} );
                } else {
		  $msg = "Cannot be modified.";
		}
	    	last SUBACTION;
	    }
	    if( $self->{cgi_params}->{subaction} eq 'copyItem' ) {
		$msg = $item->copy( $self->{cgi_params}->{copy_name} );
	    	last SUBACTION;
	    }
	    if( $self->{cgi_params}->{subaction} eq 'assignAuthor' ) {
	        if($isMutable) {
		  $item->setAuthor( $self->{cgi_params}->{new_author} );
		  $msg = 'save';
		  $save_reason = 'Set Author';
                } else {
		  $msg = "Cannot be modified.";
		}
	    	last SUBACTION;
	    }
	    if( $self->{cgi_params}->{subaction} eq 'assignDevState' ) {
	        if($isMutable) {
		  $item->setDevState( $self->{cgi_params}->{new_dev_state} );
		  $msg = 'save';
		  $save_reason = 'Set Development State';
                } else {
		  $msg = "Cannot be modified.";
		}
	    	last SUBACTION;
	    }
	    if( $self->{cgi_params}->{subaction} eq 'assignPubStatus' ) {
	        if($isMutable) {
		  $item->setPublicationStatus( $self->{cgi_params}->{new_pub_status} );
		  $msg = 'save';
		  $save_reason = 'Set Publication Status';
                } else {
		  $msg = "Cannot be modified.";
		}
	    	last SUBACTION;
	    }
	    if( $self->{cgi_params}->{subaction} eq 'lock_review' ) {
                $item->setReviewLock(1);
                $item->setReviewLifetime;
                $msg = $item->save ? 'Locking Successful' : 'Locking Unsuccessful';
                last SUBACTION;
            }
            if( $self->{cgi_params}->{subaction} eq 'unlock_review' ) {
                $item->setReviewLock(0);
                $msg = $item->save ? 'Unlocking Successful' : 'Unlocking Unsuccessful';
                last SUBACTION;
            }
	    $msg = 'Group Processing failed! Please try again.';
	}
	if( $msg eq 'save' ) {
	    $msg = $item->save('Item Admin', $self->{_CDE_}->{USER}->{id}, $save_reason) ? 'Saved Successfully.' : 'Trouble Saving!';
	}
	push @{$p{items}}, { processed_status 	=> $msg,
			     id 	  	=> $item->{id},
			     version            => $item->{version},
			     ib_id 	  	=> $item->{bankId},
			     name 	  	=> $item->{name},
			     description 	=> $item->{description},
			     author 	  	=> $item->{authorName},
			     dev_state 	  	=> $self->{_CDE_}->{_cfg}->{dev_states}->{$item->{devState}},
			     publication_status => $self->{_CDE_}->{_cfg}->{publication_status}->{$item->{publicationStatus}},
			   };
    }

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub getHierarchyDefinition {
    my ( $self, %p ) = @_; 
    
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    my $hd = $self->{_CDE_}->{db}->getDataArray(
                                sql => $self->{_cfg}->{select_hd_bypid_sql},
                                values => [$self->{cgi_params}->{hd_id},$self->{cgi_params}->{sh_id},],
    );
    if( ref $hd eq 'HASH' ) {
	$p{msg} = 0;
	$hd 	= [];
    }
    else {
	$p{msg} = $hd->[0]->{ql_label};
    }
    $p{item_json} = encode_json $hd;

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub getHierarchyTree {
    my ( $self, %p ) = @_; 
    
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    my %json_obj;
    my @bv = ( $self->{cgi_params}->{sh_id}, $self->{cgi_params}->{hd_type}, );
    my $ql = $self->{_CDE_}->{db}->getDataArray(
                                sql => $self->{_cfg}->{select_qualifier_label_gt_type_sql},
                                values => \@bv,
    );
    if( ref $ql eq 'ARRAY' ) {
	$json_obj{lower_level_cnt} = scalar @$ql;
	push @{$json_obj{level_labels}}, 
		(map { label => $_->{ql_label} }, @$ql), 
		(map { label => $_ }, ('SR', 'CR', 'Activity Based', 'Performance') ); 

	my @joins;
	my @fields = ( 'hd_value1' );
	my @select_fields = ( 'hd1.hd_id AS hd_id1', 'hd1.hd_value AS hd_value1', );
	my $where_clause  = qq| WHERE hd1.hd_type = $ql->[0]->{ql_type} 
				  AND (hd1.hd_parent_path LIKE '%,$self->{cgi_params}->{hd_id}%'
 				  OR   hd1.hd_parent_path LIKE '%,$self->{cgi_params}->{hd_id},%'
 				  OR   hd1.hd_parent_path LIKE '$self->{cgi_params}->{hd_id},%')
			      |;
	for( 1 .. $json_obj{lower_level_cnt} - 1 ) {
	    my $l = $_ + 1;
	    push @fields, ( "hd_value$l", );
	    push @select_fields, ( "hd$l.hd_id AS hd_id$l", 
				   "hd$l.hd_value AS hd_value$l", 
				 );
	    push @joins, sprintf "LEFT JOIN hierarchy_definition hd%d ON hd%d.hd_parent_id = hd%d.hd_id",
			$l, $l, $_;
	}
	my $sql = sprintf "SELECT %s FROM hierarchy_definition hd1 %s %s ORDER BY hd_value1", 
			join(',', @select_fields), join(' ', @joins), $where_clause;
    	$json_obj{lower_levels} = $self->{_CDE_}->{db}->getDataArray( sql => $sql, );
	if( ref $json_obj{lower_levels} eq 'HASH' ) {
    	    $json_obj{lower_levels} = [];
	}
	else {
	    for my $ll ( @{$json_obj{lower_levels}} ) {
		for( @fields ) {
		    m/hd_value(\d+)/;
		    my $n = $1;
		    $ll->{hd_id} = $ll->{"hd_id$n"} if $ll->{"hd_id$n"};
		}
	    }
	}

    	$json_obj{fields} = \@fields;
	$p{msg} = scalar @{$json_obj{lower_levels}};
    	$p{item_json} = encode_json \%json_obj;
    }
    else {
	$p{msg} = 0;
    	$p{item_json} = '{}';
    }

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub displayReport {
    my ( $self, %p ) = @_; 
    
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    my $item = new Item( $self->{_CDE_}->{db}->{dbh}, $self->{cgi_params}->{i_id} );

    $template->param( $item );
    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub generateItems {

    my ( $self, %p ) = @_;

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    for( 1 .. $self->{cgi_params}->{num_items} ) {

	my $format = $self->{cgi_params}->{item_format};
	my $choices = $self->{cgi_params}->{choice_cnt};

        my $i_obj = {};
	$i_obj->{max_score} = 1.0;
	$i_obj->{attributes} = 'responseIdentifier="RESPONSE"';
	$i_obj->{correct} = '';

        if($format == 1) {
	  $i_obj->{type} = $IT_CHOICE;
	  $i_obj->{name} = 'RESPONSE';
	  $i_obj->{score_type} = $ST_MATCH_RESPONSE;
	  $i_obj->{content}{choices} = [];
	  $i_obj->{content}{distractorRationale} = [];

          for(my $i=0; $i < $choices; $i++) {

            my $choice = {};
            $choice->{id} = 0;
	    $choice->{name} = $choice_chars[$i];
            $choice->{text} = '';
            $choice->{attributes} = '';

            my $dr = {};
            $dr->{id} = 0;
	    $dr->{name} = $choice_chars[$i];
            $dr->{text} = '';
            $dr->{attributes} = '';
    
            $i_obj->{content}{choices}[$i] = $choice;
            $i_obj->{content}{distractorRationale}[$i] = $dr;
	    
	  }

	} elsif($format == 2 || $format == 3 || $format == 4) {
	  $i_obj->{type} = $IT_EXTENDED_TEXT;
	  $i_obj->{name} = 'RESPONSE';
	  $i_obj->{score_type} = $ST_RUBRIC;
	}

	$i_obj->{content}{prompt}{id} = 0;
	$i_obj->{content}{prompt}{text} = '';
	$i_obj->{content}{prompt}{name} = 'prompt';
	$i_obj->{content}{prompt}{attributes} = '';

    	my $item = new Item( $self->{_CDE_}->{db}->{dbh}, );
	$item->create( $self->{cgi_params}->{ib_id}, '', '', $self->{_CDE_}->{USER}->{u_writer_code},$self->{cgi_params}->{primarystandard} );

        $item->{item_body}{content}{id} = 0;
        $item->{item_body}{content}{text} = '';
        $item->{item_body}{content}{name} = '';
        $item->{item_body}{content}{attributes} = '';

        $item->createInteraction($i_obj);
    $item->setPrimaryStandard( $self->{cgi_params}->{primarystandard} );
	$item->setItemFormat( $format );
	$item->setPoints( $self->{cgi_params}->{points} );
	$item->setContentArea( $self->{cgi_params}->{subject_area} );
	$item->setGradeLevel( $self->{cgi_params}->{grade_level} );
	$item->setGradeSpanStart( $self->{cgi_params}->{grade_span_start} );
	$item->setGradeSpanEnd( $self->{cgi_params}->{grade_span_end} );
	$item->setDifficulty( $self->{cgi_params}->{difficulty} );
	$item->setDOK( $self->{cgi_params}->{dok} );
	$item->setPublicationStatus( $self->{cgi_params}->{publication_status} );
	$item->setAuthor( $self->{cgi_params}->{writers} );
	$item->setDueDate( $self->{cgi_params}->{due_date} );
	$item->setReadabilityIndex( $self->{cgi_params}->{readability_index} );
	$item->insertChar( $self->{_CDE_}->{_cfg}->{OC_PASSAGE}, $self->{cgi_params}->{passage} )
			if $self->{cgi_params}->{passage};
	$item->insertChar( $self->{_CDE_}->{_cfg}->{OC_ITEM_STANDARD}, $self->{cgi_params}->{hd_id} );
	$item->insertChar( 
		$self->{_CDE_}->{_cfg}->{OC_CONTENT_STANDARD},
            	&getContentStandard( $self->{_CDE_}->{db}->{dbh}, 
				     $self->{cgi_params}->{hd_id}, 
				     $item->{$self->{_CDE_}->{_cfg}->{OC_CONTENT_AREA}} 
	    	)
        );
        $item->setMetadataXml($item->getDefaultMetadataXml());

	$item->save('Item Generator', $self->{_CDE_}->{USER}->{id}, 'Created Item');

	$p{item_bank} = $item->{bankName};
	push @{$p{item_list}}, $item;
    }

    $p{item_format_name} = $self->{_CDE_}->{_cfg}->{item_formats}->{$self->{cgi_params}->{item_format}};
    $p{difficulty_level} = $self->{_CDE_}->{_cfg}->{difficulty_levels}->{$self->{cgi_params}->{difficulty}};
    $p{publication_status} = $self->{_CDE_}->{_cfg}->{publication_status}->{$self->{cgi_params}->{publication_status}};
    $p{subject_area_char} = $self->{_CDE_}->{_cfg}->{const2}->{$self->{cgi_params}->{subject_area}};
    $p{grade_span_start_char} = $self->{_CDE_}->{_cfg}->{const5}->{$self->{cgi_params}->{grade_span_start}};
    $p{grade_span_end_char} = $self->{_CDE_}->{_cfg}->{const5}->{$self->{cgi_params}->{grade_span_end}};
    
    $p{primarystandard} = $self->{_CDE_}->{_cfg}->{primarystandard}->{$self->{cgi_params}->{primarystandard}};

    if( $self->{cgi_params}->{passage} ) {
    	my $passage = new Passage( $self->{_CDE_}->{db}->{dbh}, $self->{cgi_params}->{passage} );
	$p{passage_name} = $passage->{name};
    }
    if( $self->{cgi_params}->{writers} ) {
        my $writer = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_editors_by_id_sql}, 
				values => [$self->{cgi_params}->{writers}], 
	);
	$p{writer} = sprintf "%s, %s", $writer->{u_last_name}, $writer->{u_first_name};
	$p{writer_name} = sprintf "%s %s", $writer->{u_first_name}, $writer->{u_last_name};
	$p{writer_email} = $writer->{u_email};
    }

    #if( $self->{cgi_params}->{hd_id} ) {
    #warn "hd_id**********************\n";
	#my $sm = new StandardsManager( _SERVER_ => 1, cgi => $self->{cgi}, dbh => $self->{_CDE_}->{db}->{dbh} );
	#my $std = $sm->getHierarchy( hd_id => $self->{cgi_params}->{hd_id} );
	#$p{hierarchy} = $std->{hierarchy};
    #}

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    if( $p{blueprint} ) {
	return \%p;
    }
    else {
	$self->_sendWorkflowNotification(
		name 	  => $p{writer_name},
		email	  => $p{writer_email},
	 	program	  => $p{item_bank},
		dev_state => 'Development',
	);
	return $template;
    }
}   

sub generateItemsBP {

    my ( $self, %p ) = @_;

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    for( keys %{$self->{cgi_params}} ) {
	next unless /^itemformat_\d+_\d+_cnt$/;
	next unless( $self->{cgi_params}->{$_} =~ /\d+/ );

	my @f = split /_/, $_;
	$self->{cgi_params}->{hd_id} 	   = $f[1];
	$self->{cgi_params}->{item_format} = $f[2];
	$self->{cgi_params}->{num_items}   = $self->{cgi_params}->{$_};

	$p{gi} = $self->generateItems( blueprint => 1 );
	$p{gi}->{num_items} = $self->{cgi_params}->{$_};
	push @{$p{rpt}}, $p{gi};
    }
       $self->_sendWorkflowNotification(
		name 	  => $p{gi}->{writer_name},
		email	  => $p{gi}->{writer_email},
	 	program	  => $p{gi}->{item_bank},
		dev_state => 'Development',
    );

    $p{subject_area} = $self->{_CDE_}->{_cfg}->{const2}->{$p{subject_area}} if $p{subject_area};
    $template->param( \%p );

    $self->{cgi_params}->{subject_area} = $self->{_CDE_}->{_cfg}->{const2}->{$self->{cgi_params}->{subject_area}} if $self->{cgi_params}->{subject_area};
    $template->param( $self->{cgi_params} );
    return $template;
}

sub itemGenerator {

    my ( $self, %p ) = @_;

    my $template_name = $self->{cgi_params}->{bp} ? 'itemBPGenerator' : $self->{_action};
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $template_name );
    return $template if $template->{error};

    my %programs;
    $p{programs} = $self->{_CDE_}->{db}->getDataArray( sql => $self->{_cfg}->{select_item_bank_with_access_sql},
                                                       values => [ $self->{_CDE_}->{USER}->{id} ] );
    for( @{$p{programs}} ) {
	$programs{$_->{ib_id}} = $_;
    }
    $p{programs_json} = encode_json \%programs;

    my $hierarchy = $self->{_CDE_}->{db}->getDataHashByKey( 
			sql => $self->{_cfg}->{select_standard_hierarchy_sql}, 
			key => 'sh_id',
    );
    $hierarchy = {} if $hierarchy->{_error};
    foreach( keys %{$hierarchy} ) {
    	$hierarchy->{$_}->{ql} = $self->{_CDE_}->{db}->getDataHashByKey( 
					sql => $self->{_cfg}->{select_qualifier_label_sql}, 
					values => [$_], 
					key => 'ql_type', 
	);
	$hierarchy->{$_}->{num_ql} = scalar keys %{$hierarchy->{$_}->{ql}};
	push @{$p{hierarchy}}, $hierarchy->{$_};
    }
    @{$p{hierarchy}} = sort { $a->{sh_external_id} cmp $b->{sh_external_id} } @{$p{hierarchy}} if $p{hierarchy};
    $p{hierarchy_json} = to_json $hierarchy;

    $p{publication_status} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{publication_status}, 
    );
    $p{subject_areas} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const2}, 
    );
    $p{grade_levels} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const3}, 
    );
    $p{points} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const7}, 
    );
    $p{difficulty_levels} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{difficulty_levels}, 
    );
    $p{dok} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const8}, 
    );
    $p{item_formats} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{item_formats}, 
    );
    $p{grade_span} = $self->{_CDE_}->_hashToSelectList( 
					hash => $self->{_CDE_}->{_cfg}->{const5}, 
    );

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub getIGLists {
    my ( $self, %p ) = @_;
   
    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    my %tbl;
    my $passages = $self->{_CDE_}->{db}->getDataArray(
                                sql => $self->{_cfg}->{select_passage_by_program_sql},
                                values => [$self->{cgi_params}->{ib_id}],
    );
    $passages = [ { p_name => '---', p_id => 0 } ] if( ref $passages eq 'HASH' );
    $tbl{passages} = $passages;

    my $writers = $self->{_CDE_}->{db}->getDataArray( 
				sql => $self->{_cfg}->{select_editors_by_program_sql}, 
                                values => [$self->{cgi_params}->{ib_id}],
    );
    $writers = [ { fullname => $writers->{_error_msg}, u_id => 0 } ] if( ref $writers eq 'HASH' );
    $tbl{writers} = $writers;

    $p{msg} = 1;
    $p{item_json} = encode_json \%tbl;

    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
} 

################################################################################
# Email Notification methods
################################################################################

sub _sendWorkflowNotification {
    my ( $self, %p ) = @_;

    for( qw( name email program dev_state ) ) {
        unless( $p{$_} ) {
	    $p{error} = "Missing required field : $_"; 
	    return \%p;
	}
    }

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => 'sendWorkflowNotification' );
    return $template if $template->{error};

    $p{environment} = $self->{_CDE_}->{db}->{instance}->{client_name};
    $p{app_url} =  sprintf "%s%s",
			$self->{_CDE_}->{db}->{instance}->{web_host},
			$self->{_CDE_}->{db}->{instance}->{orca_url};

    $template->param( \%p );
    # trap any errors with sending e-mail
    {
      my $message = MIME::Lite->new(
    	To      => $p{email},
        From    => $self->{_cfg}->{notifier_email},
        Subject => 'SBAC IAIP ITEMS Need Your Attention!',
        Data    => $template->output,
      );
      $message->send( 'smtp', 'localhost' );
    };

    if($@) {
      $p{error} = $p{email_sent_msg} = 'Unable to send e-mail notification';
    } else {
      $p{error} = $p{email_sent_msg} = sprintf "E-mail sent to %s", $p{email};
    }

    return \%p;
}

1;
