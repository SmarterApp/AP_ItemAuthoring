package StandardsManager;

use strict;
use CDE;
use JSON;
use URI::Escape;
use XML::Tidy::Tiny qw(xml_tidy);

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
    my @dirs = split /\//, $INC{'StandardsManager.pm'};
    splice(@dirs, -2, 2, 'configs', $self->{_config_name} || 'standards_manager.conf');
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
            #warn "$_ ======>>>> $self->{cgi_params}->{$_}";
        }
    }
    $self->{_action} = $self->{action} || $self->{cgi_params}->{action};
    $self->{session} = decode_json $self->{_CDE_}->{USER}->{ss_variables} if $self->{_CDE_}->{USER}->{ss_variables};
    $self->{session}->{$self->{_action}}->{cgi_params} = $self->{cgi_params};
}

sub run {
    my ($self, %p) = @_;

    $self->{_action} = $p{action} if $p{action};
    my $action = $self->{_action} or return { error => 1, error_msg => 'No action provided!' };
    my $run    = $self->$action( %p );

    my $psgi_out = '';

    if( ref($run) =~ /^HASH/ ) {
	$psgi_out .= $run->{error};
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
sub displayEditor {
    my ( $self, %p ) = @_; 
    
    my %hierarchy_json = my %standards_json = ();

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => $self->{_action} );
    return $template if $template->{error};

    $p{standards} = $self->{_CDE_}->{db}->getDataArray( sql => $self->{_cfg}->{select_standard_hierarchy_sql}, );
    if( ref $p{standards} eq 'HASH' ) {
    	$p{standards} = [];
    }
    $standards_json{$_->{hd_id}} = $_ for @{$p{standards}};

    $p{hierarchy} = $self->{_CDE_}->{db}->getDataArray( sql => $self->{_cfg}->{select_hierarchy_sql}, );
    if( ref $p{hierarchy} eq 'HASH' ) {
    	$p{hierarchy} = [];
    }
    else {
	$hierarchy_json{$_->{hd_id}} = $_ for( @{$p{hierarchy}} );
    }

    if( $self->{cgi_params}->{hierarchy_id} ) {
    	$p{types} = $self->{_CDE_}->{db}->getDataArray( 
					sql => $self->{_cfg}->{select_qualifier_label_by_hdid_sql}, 
					values => [$self->{cgi_params}->{hierarchy_id}], 
	);
	$p{types} = [] if( ref $p{types} eq 'HASH' );

    	$p{content_area} = $self->{_CDE_}->{db}->getDataArray( 
					sql => $self->{_cfg}->{select_hd_levels_sql}, 
					values => [2, $self->{cgi_params}->{hierarchy_id}], 
	);
    	if( ref $p{content_area} eq 'HASH' ) {
	    $p{content_area} = [];
    	}
    	else {
	    for my $ca ( @{$p{content_area}} ) {
		$hierarchy_json{$ca->{hd_id}} = $ca;
    	    	$ca->{grades} = $self->{_CDE_}->{db}->getDataArray( 
					sql => $self->{_cfg}->{select_hierarchy_by_parentid_sql}, 
					values => [$ca->{hd_id}], 
					#sql => $self->{_cfg}->{select_hd_levels_sql}, 
					#values => [3, $ca->{hd_id}], 
	    	);
    	    	if( ref $ca->{grades} eq 'HASH' ) {
		    $ca->{grades} = [];
    	    	}
    	    	else {
	    	    for my $grade ( @{$ca->{grades}} ) {
			$hierarchy_json{$grade->{hd_id}} = $grade;
    	    		$grade->{strands} = $self->{_CDE_}->{db}->getDataArray( 
						sql => $self->{_cfg}->{select_hierarchy_by_parentid_sql}, 
						values => [$grade->{hd_id}], 
						#sql => $self->{_cfg}->{select_hd_levels_sql}, 
						#values => [4, $grade->{hd_id}], 
	    		);
    	    		if( ref $grade->{strands} eq 'HASH' ) {
		    	    $grade->{strands} = [];
    	    		}
    	    		else {
			    for my $strand ( @{$grade->{strands}} ) {
				$hierarchy_json{$strand->{hd_id}} = $strand;
    	    			$strand->{gle} = $self->{_CDE_}->{db}->getDataArray( 
							sql => $self->{_cfg}->{select_hierarchy_by_parentid_sql}, 
							values => [$strand->{hd_id}], 
							#sql => $self->{_cfg}->{select_hd_levels_sql}, 
							#values => [5, $strand->{hd_id}], 
	    			);
    	    			if( ref $strand->{gle} eq 'HASH' ) {
		    	    	    $strand->{gle} = [];
    	    			}
				else {
				    for my $l5 ( @{$strand->{gle}} ) {
				    	$hierarchy_json{$l5->{hd_id}} = $l5;
    	    				$l5->{level5} = $self->{_CDE_}->{db}->getDataArray( 
							sql => $self->{_cfg}->{select_hierarchy_by_parentid_sql}, 
							values => [$l5->{hd_id}], 
							#sql => $self->{_cfg}->{select_hd_levels_sql}, 
							#values => [6, $l5->{hd_id}], 
	    				);
    	    				if( ref $l5->{level5} eq 'HASH' ) {
		    	    	    	    $l5->{level5} = [];
    	    				}
					else {
					    for my $l6 ( @{$l5->{level5}} ) {
				    	    	$hierarchy_json{$l6->{hd_id}} = $l6; 
    	    					$l6->{level6} = $self->{_CDE_}->{db}->getDataArray( 
							sql => $self->{_cfg}->{select_hierarchy_by_parentid_sql}, 
							values => [$l6->{hd_id}], 
							#sql => $self->{_cfg}->{select_hd_levels_sql}, 
							#values => [6, $l6->{hd_id}], 
	    					);
    	    					if( ref $l6->{level6} eq 'HASH' ) {
		    	    	    	    	    $l6->{level6} = [];
    	    					}
						else {
					    	    for my $l7 ( @{$l6->{level6}} ) {
				    	    		$hierarchy_json{$l7->{hd_id}} = $l7; 
						    }
						}
					    }
    	    				}
				    }
				}
			    }
    	    		}
		    }
    	    	}
    	    }
	} 
    }
    else {
  	$p{hierarchy_id} = 0;
    }

    my $hierarchyjson = to_json \%hierarchy_json;
    my $standardsjson = to_json \%standards_json;
    $template->param( hierarchy_json => $hierarchyjson,
    		      standards_json => $standardsjson,
		    );
    $template->param( \%p );
    $template->param( $self->{cgi_params} );
    return $template;
}   

sub saveStandardHierarchy {
    my ( $self, %p ) = @_; 
    
    my $rv;
    my @bv = ( $self->{cgi_params}->{sh_external_id} );
    if( $self->{cgi_params}->{sh_id} == 0 ) {
	 $rv = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_hierarchy_definition1_sql}, undef, @bv);
	 $self->{cgi_params}->{hierarchy_id} = $p{hd_id} = $self->{_CDE_}->{db}->{dbh}->{mysql_insertid};

	 push @bv, ( $self->{cgi_params}->{sh_name}, $self->{cgi_params}->{sh_description},
		     $self->{cgi_params}->{sh_source}, $p{hd_id} );
	 $rv = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_standard_hierarchy_sql}, undef, @bv);
	 $p{sh_id} = $self->{_CDE_}->{db}->{dbh}->{mysql_insertid};

	 my $level_num = 1;
	 for ( @{$self->{_cfg}->{qualifier_label}} ) {
            my @bv = ( $p{sh_id}, $level_num++, $_ );
            my $rc = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_qualifier_label_sql}, undef, @bv );
    	 }

	 @bv = ( 2, 'New Test Subject', $p{hd_id}, 1, 'Default Test Subject', '', $p{hd_id}, );
    	 $rv = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_hierarchy_definition_sql}, undef, @bv);
	 $p{hd_id_2} = $self->{_CDE_}->{db}->{dbh}->{mysql_insertid};

	 $p{msg} = sprintf "Successfully Created Standard : %s", $self->{cgi_params}->{sh_external_id};
    }
    else {
	 push @bv, $self->{cgi_params}->{hd_id};
	 $rv = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{update_hierarchy_definition_sql}, undef, @bv);

	 @bv = ( $self->{cgi_params}->{sh_external_id}, $self->{cgi_params}->{sh_name}, 
		 $self->{cgi_params}->{sh_description}, $self->{cgi_params}->{sh_source}, 
		 $self->{cgi_params}->{sh_id}, 
	       );
	 $rv = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{update_standard_hierarchy_sql}, undef, @bv);

	 $p{msg} = sprintf "Successfully Updated Standard : %s", $bv[0];
    }

    $self->{_action} = 'displayEditor';
    return $self->displayEditor( %p );
}   

sub saveHierarchyDefinition {
    my ( $self, %p ) = @_; 
    
    my $rv;
    my @bv;
    if( $self->{cgi_params}->{hd_id} == 0 ) {
	 @bv = ( $self->{cgi_params}->{hd_type}, $self->{cgi_params}->{hd_value}, 
		 $self->{cgi_params}->{hierarchy_id},
		 $self->{cgi_params}->{hd_posn_in_parent},
		     $self->{cgi_params}->{hd_std_desc}, 
		     $self->{cgi_params}->{hd_extended_desc}, 
	       );
	 $rv = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_standard_hierarchy_sql}, undef, @bv);
	 $p{sh_id} = $self->{_CDE_}->{db}->{dbh}->{mysql_insertid};

	 $p{msg} = sprintf "Successfully Created Standard : %s", $self->{cgi_params}->{hd_value};
    }
    else {
	 @bv = ( $self->{cgi_params}->{hd_value}, $self->{cgi_params}->{hd_std_desc}, 
		 $self->{cgi_params}->{hd_extended_desc}, $self->{cgi_params}->{hd_type}, 
		 $self->{cgi_params}->{hd_id}, 
	       );
	 $rv = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{update_hierarchy_definition_all_sql}, undef, @bv);
	printf STDERR "%s\t=$rv\n", join('~',@bv);

	 $p{msg} = sprintf "Successfully Updated Node : %s", $self->{cgi_params}->{hd_value};
    }

    $self->{_action} = 'displayEditor';
    return $self->displayEditor( %p );
}   
    
sub exportHierarchyXML {
    my ( $self, %p ) = @_; 

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => 'generic' );
    return $template if $template->{error};

    $template->param( data => $self->addNodeXml( hd_id => $self->{cgi_params}->{hd_id} ) );
    return $template;
}   
    
sub createHD {
    my ( $self, %p ) = @_; 

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => 'generic' );
    return $template if $template->{error};

    $p{status} = 0;
    my $hd = $self->{_CDE_}->{db}->getDataArray( sql => $self->{_cfg}->{select_parent_children_sql},
						 values => [$self->{cgi_params}->{id}],
    );
    $hd = pop @$hd if( ref $hd eq 'ARRAY' );

	$p{hd_value} 		= $self->{cgi_params}->{title};
	$p{hd_parent_id} 	= $self->{cgi_params}->{id};
	$p{hd_posn_in_parent} 	= $hd->{hd_posn_in_parent} ? $hd->{hd_posn_in_parent} + 1 : 1;
	$p{hd_std_desc} 	= $self->{cgi_params}->{title};
	$p{hd_extended_desc} 	= $self->{cgi_params}->{title};
	$p{hd_parent_path} 	= sprintf "%s,%s", $p{hd_parent_id}, $hd->{parent_path};

	my @p_p = split /\,/, $hd->{parent_path};
	$p{root_hd_id} = pop @p_p;
	$p{root_hd_id} = $hd->{parent_id} unless $p{root_hd_id};

    	my $sh = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_standard_hierarchy_by_hdid_sql},
				values => [$p{root_hd_id}],
    	);
	unless( $sh->{_error_msg} ) {
	    my $hier_cnt = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_count_hierarchy_sql},
				values => [$p{hd_parent_id}, $p{hd_value}],
    	    );
	    if( $hier_cnt->{cnt} == 0 ) {
    	    	my $ql = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_qualifier_label_sql},
				values => [$sh->{sh_id}, $hd->{type}],
    	    	);
	    	$p{hd_type} = $ql->{_error_msg} ? $hd->{type} : $ql->{ql_type};
	    	my @bv = ( $p{hd_type}, $p{hd_value}, $p{hd_parent_id}, 
			   $p{hd_posn_in_parent}, $p{hd_std_desc}, 
			   $p{hd_extended_desc}, $p{hd_parent_path},
			 );
    	    	$p{status} = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_hierarchy_definition_sql}, undef, @bv);
	    	$p{id} = $self->{_CDE_}->{db}->{dbh}->{mysql_insertid};
	    }
	    else {
    	    	$p{status} = undef;
		$p{id} = 'Duplicate Node.';
	    }
	}

    $template->param( data => to_json \%p ); 
    return $template;
}   
    
sub createLevel {
    my ( $self, %p ) = @_; 

    $self->{cgi_params}->{hierarchy_id} = $self->{cgi_params}->{hd_id};
    my @bv = ( $self->{cgi_params}->{hd_id} );
    my $hd = $self->{_CDE_}->{db}->getDataHash( 
				sql => $self->{_cfg}->{select_hierarchy_by_hdid_sql},
				values => \@bv,
    );
    if( $hd->{hd_type} == 1 ) {
    	my $hd_children = $self->{_CDE_}->{db}->getDataArray( 
				sql => $self->{_cfg}->{select_hierarchy_by_parentid_sql},
				values => \@bv,
    	);
	$p{hd_posn_in_parent} = ref $hd_children eq 'HASH' ? 1 : scalar @{$hd_children} + 1;

	@bv = ( 2, $self->{cgi_params}->{hd_data}, $self->{cgi_params}->{hd_id}, 
		$p{hd_posn_in_parent}, $self->{cgi_params}->{hd_data},
		'', $self->{cgi_params}->{hd_data},
	      );
    	$p{rv} = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_hierarchy_definition_sql}, undef, @bv);
    }
    else {
	@bv = ( $hd->{hd_parent_id} );
    	my $hd_children = $self->{_CDE_}->{db}->getDataArray( 
				sql => $self->{_cfg}->{select_hierarchy_by_parentid_sql},
				values => \@bv,
    	);
	$p{hd_posn_in_parent} = ref $hd_children eq 'HASH' ? 1 : scalar @{$hd_children} + 1;

	@bv = ( $hd_children->[0]->{hd_type}, $self->{cgi_params}->{hd_data}, $hd->{hd_parent_id}, 
		$p{hd_posn_in_parent}, $self->{cgi_params}->{hd_data},
		'', $hd_children->[0]->{hd_parent_path},
	      );
    	$p{rv} = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{insert_hierarchy_definition_sql}, undef, @bv);

	my @pp = split /,/, $hd_children->[0]->{hd_parent_path};
    	$self->{cgi_params}->{hierarchy_id} = pop @pp;
    	$self->{cgi_params}->{hierarchy_id} = pop @pp if($self->{cgi_params}->{hierarchy_id} == 0);
    }

    $self->{_action} = 'displayEditor';
    return $self->displayEditor( %p );
}   

sub addNodeXml {
    my ( $self, %p ) = @_; 

    my $out = '';
    my %hd_types = ( 	1 => 'Program',
                	2 => 'TestSubject',
                	3 => 'Area',
                	4 => 'GeneralContent',
                	5 => 'SpecificContent',
                	6 => 'SubSpecificContent',
              	   );

    my $sql = "SELECT * FROM hierarchy_definition WHERE hd_id = $p{hd_id}";

    my $sth = $self->{_CDE_}->{db}->{dbh}->prepare($sql);
    $sth->execute();

    if(my $row = $sth->fetchrow_hashref) { 
    	$row->{hd_std_desc}      ||= '';
    	$row->{hd_extended_desc} ||= '';

    	my @desc  = split //, $row->{hd_std_desc};
    	my @edesc = split //, $row->{hd_extended_desc};

    	foreach(@desc)  { if (ord($_) > 127) { $_ = sprintf "&#%s;", ord($_); } };
    	foreach(@edesc) { if (ord($_) > 127) { $_ = sprintf "&#%s;", ord($_); } };

        # encode certain characters to we have valid XML
	$row->{hd_value} =~ s/&(?![0-9a-zA-Z#]+;)/&amp;/g;
	$row->{hd_value} =~ s/</&lt;/g;
	$row->{hd_value} =~ s/>/&gt;/g;

	$out .= sprintf "<%s><name>%s</name><description><![CDATA[%s]]>\n</description><extendedDescription><![CDATA[%s]]>\n</extendedDescription>", $hd_types{$row->{hd_type}}, $row->{hd_value}, join('', @desc), join('', @edesc);

    	if($row->{hd_type} == 6) {
    	} 
	else {
      	    $out .= '<children>';

      	    $sql = "SELECT * FROM hierarchy_definition WHERE hd_parent_id = $p{hd_id} ORDER BY hd_posn_in_parent";
      	    my $sth2 = $self->{_CDE_}->{db}->{dbh}->prepare($sql);
      	    $sth2->execute();
      	    while(my $row2 = $sth2->fetchrow_hashref) {
        	$out .= $self->addNodeXml( hd_id => $row2->{hd_id} );
      	    }
      	    $sth2->finish;

      	    $out .= '</children>';
    	}

    	$out .= sprintf "</%s>", $hd_types{$row->{hd_type}};
    }
    $sth->finish;

    return $out;
}

sub getStandards {
    my ( $self, %p ) = @_; 
    $p{standards} = $self->{_CDE_}->{db}->getDataArray( sql => $self->{_cfg}->{select_standard_hierarchy_sql}, );
    return \%p;
}

sub deleteLevel {
    my ( $self, %p ) = @_; 

    $self->{_action} = 'displayEditor';
    $p{level_name} = $self->{cgi_params}->{hd_data} == 1 ? $self->{cgi_params}->{sh_external_id} : $self->{cgi_params}->{hd_value}; 

    my $sql = qq| SELECT COUNT(i_id) cnt FROM item_characterization
		  WHERE ic_type=$self->{cgi_params}->{hd_data}
		  AND ic_value IN
    		  	( SELECT hd_id FROM hierarchy_definition
      		    	  WHERE hd_parent_path LIKE '%,$self->{cgi_params}->{hd_id}'
      		    	  OR hd_parent_path LIKE '%,$self->{cgi_params}->{hd_id},0'
      		    	  OR hd_parent_id=$self->{cgi_params}->{hd_id}
    		  	)
		|;
    my $hd_items = $self->{_CDE_}->{db}->getDataHash( sql => $sql );
    if( $hd_items->{cnt} > 0 ) {
    	$p{msg} = "Unable to Delete: $p{level_name}<br/>Items are linked to this Standard Level!";
    	return $self->displayEditor( %p );
    }

    $sql = qq| 	DELETE FROM hierarchy_definition
		WHERE hd_id = $self->{cgi_params}->{hd_id}
		OR hd_parent_path LIKE '$self->{cgi_params}->{hd_id},%'
 		OR hd_parent_path LIKE '%,$self->{cgi_params}->{hd_id},%'
 		OR hd_parent_path LIKE '%,$self->{cgi_params}->{hd_id}'
	     |;
    $p{rv}  = $self->{_CDE_}->{db}->{dbh}->do( $sql );
    $p{msg} = "Deleted: $p{level_name}";    
    if( $self->{cgi_params}->{hd_data} eq '' || $self->{cgi_params}->{hd_data} == 1 ) {
    	$sql   = "DELETE FROM standard_hierarchy WHERE sh_id = $self->{cgi_params}->{sh_id}";
        $p{rv} = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{delete_standard_hierarchy_sql}, undef, $self->{cgi_params}->{sh_id} );
        $p{rv} = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{delete_qualifier_label_sql}, undef, $self->{cgi_params}->{sh_id} );
	undef $self->{cgi_params}->{hierarchy_id};
    }
    
    undef $self->{cgi_params}->{hd_id};
    return $self->displayEditor( %p );
}

sub getHierarchy {
    my ( $self, %p ) = @_; 

    return { error => 1 } unless $p{hd_id};

    my $hrcy = $self->{_CDE_}->{db}->getDataHash( 
			sql => $self->{_cfg}->{select_hierarchy_by_hdid_sql},
			values => [$p{hd_id}],
    );
    return { error => 1 } if $hrcy->{_error_msg};

    push @{$p{hierarchy}}, $hrcy;

    my $std;
    if( $hrcy->{hd_type} == 1 ) {
    	$std = $self->{_CDE_}->{db}->getDataHash( 
			sql => $self->{_cfg}->{select_standard_hierarchy_by_hdid_sql},
			values => [$hrcy->{hd_id}],
    	);
    }
    else {
	for( split(/,/, $hrcy->{hd_parent_path}) ) {
    	    $hrcy = $self->{_CDE_}->{db}->getDataHash( 
			sql => $self->{_cfg}->{select_hierarchy_by_hdid_sql},
			values => [$_],
    	    );
	    unshift @{$p{hierarchy}}, $hrcy;
	 
    	    if( $hrcy->{hd_type} == 1 ) {
    		$std = $self->{_CDE_}->{db}->getDataHash( 
			sql => $self->{_cfg}->{select_standard_hierarchy_by_hdid_sql},
			values => [$hrcy->{hd_id}],
    		);
	    }
	}
    }


    my $ql = $self->{_CDE_}->{db}->getDataHashByKey( 
			sql     => $self->{_cfg}->{select_qualifier_label_all_sql},
			values 	=> [$std->{sh_id}],
			key 	=> 'ql_type',
    );
    for( @{$p{hierarchy}} ) {
	$_->{label} = $ql->{$_->{hd_type}}->{ql_label};
    }

    return \%p;
}

sub reorderSiblings {
    my ( $self, %p ) = @_; 

    my $template = $self->{_CDE_}->_getTemplate( _cfg => $self->{_cfg}, template_name => 'generic' );
    return $template if $template->{error};

    $p{status} = 0;

    my @tmp_ary = ();
    my $hd_siblings = $self->{_CDE_}->{db}->getDataArray( 
			sql     => $self->{_cfg}->{select_hierarchy_siblings_sql},
			values 	=> [$self->{cgi_params}->{hd_id}],
    );
    for( @$hd_siblings ) {
	push @tmp_ary, $_ if( $_->{hd_id} != $self->{cgi_params}->{hd_id} );
    }

    splice @tmp_ary, $self->{cgi_params}->{position} - 1, 
	   0, { hd_id => $self->{cgi_params}->{hd_id} }; 
    my $cnt = 1;
    for( @tmp_ary ) {
	my @bv = ( $cnt, $_->{hd_id} );
	$p{status} = $self->{_CDE_}->{db}->{dbh}->do( $self->{_cfg}->{update_hierarchy_sibling_position_sql}, undef, @bv);
	printf STDERR "%d == %d\n", $_->{hd_id}, $cnt;
	$cnt++;
    }

    $p{new_posn} = $self->{cgi_params}->{position};
    $template->param( data => to_json \%p ); 
    return $template;
}

1;
