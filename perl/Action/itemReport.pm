package Action::itemReport;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use IO::File;
use URI::Escape;
use ItemConstants;
use Item;
use HTTP::Date;
use File::Copy 'cp';
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  
  our $thisUrl = "${orcaUrl}cgi-bin/itemReport.pl";

  our $ib_all = '1000000';

  our %reportTypes = (
    '1' => 'Standard',
    '2' => 'Progress',
    '3' => 'Pivot',
  #  '4' => 'Work Summary'
    '5' => 'Quality',
    '6' => 'Timeliness'
  );

  our %userTypes = (
    '1' => 'Item Writer',
    '2' => 'Content Reviewer',
    '3' => 'Copy Editor',
    '4' => 'Art Editor'
  );

  our %filtered_dev_states =  map { $_ => $dev_states{$_} } grep { exists $dev_states{$_} } 
                              @dev_states_workflow_ordered_keys;

  our %has_copyright = ( '1' => 'Yes',
                         '2' => 'No' ); 

  our %userTypeDevStates = (
    '1' => [$DS_DEVELOPMENT],
    '2' => [
        $DS_CONTENT_REVIEW,    $DS_CONTENT_REVIEW_2, $DS_CONTENT_APPROVED,
        $DS_SUPERVISOR_REVIEW, $DS_CLIENT_PREVIEW,   $DS_CLIENT_APPROVED,
        $DS_CLIENT_APPROVED_2, $DS_CLIENT_APPROVED_3
    ],
    '3' => [
        $DS_COPY_REVIEW,    $DS_COPY_REVIEW_2,       $DS_COPY_APPROVED,
        $DS_CUSTOMER_PROOF, $DS_COPY_TEACHER_REVIEW, $DS_COPY_F2F_REVIEW,
        $DS_COPY_FINAL_REVIEW
    ],
    '4' => [ $DS_NEW_ART, $DS_FIX_ART ]
  );

  our $sth;
  our $sql;

  our $user = Session::getUser($q->env, $dbh);
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  our %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

  if($user->{adminType} == $UA_ORG || $user->{adminType} == $UA_SUPER) {
    $itemBanks{$ib_all} = 'All';
  }

  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};

  our $currentWorkGroups = &getUserWorkGroupsForBank($user->{workGroups}, $in{itemBankId});
  if(scalar(keys %{$currentWorkGroups}) && ! $in{workGroupId}) {
    $in{workGroupId} = (keys %{$currentWorkGroups})[0];
  }

  our $useWorkgroupFilter = 0;

  if($user->{adminType}) {
    $currentWorkGroups = &getWorkgroups($dbh, $in{itemBankId});
    %$currentWorkGroups = map { $_ => $currentWorkGroups->{$_}{name} } keys %$currentWorkGroups;
  } else {

    if(  scalar(keys %{$user->{workGroups}}) 
      && defined($user->{workGroups}{$in{workGroupId}})
      && scalar(keys %{$user->{workGroups}{$in{workGroupId}}{filters}}) ) {
     
      $useWorkgroupFilter = 1;
    }
  }

  our $editors   = &getEditors($dbh, $in{itemBankId});

  $in{reportType} = '1' unless exists $in{reportType};
  $in{myaction}   = '' unless exists $in{myaction};

  unless ( $in{myaction} eq '1' or $in{myaction} eq '2' or $in{myaction} eq '3' )
  {
    my $psgi_out;

    #$in{message} = "Please Select an Program.";
    if ( $in{reportType} eq '3' ) {
        $psgi_out = &print_pivot_welcome( \%in );
    }
    elsif ( $in{reportType} eq '4' ) {
        $psgi_out = &print_work_summary_welcome( \%in );
    }
    else {
        $psgi_out = &print_welcome( \%in );
    }

    return [ $q->psgi_header('text/html'), [ $psgi_out  ] ];
  }

  our %fieldMap = (
    'content_area'    => $const[$OC_CONTENT_AREA],
    'grade_level'     => $const[$OC_GRADE_LEVEL],
    'item_format'       => \%item_formats,
    'dev_state'       => \%filtered_dev_states,
    'difficulty'      => \%difficulty_levels,
    'item_writer'     => $editors,
    'standard_strand' => {},
    'standard_gle'    => {}
  );

  our %dbMap = (
    'content_area'    => 'content_area',
    'grade_level'     => 'grade_level',
    'item_format'       => 'i_format',
    'dev_state'       => 'i_dev_state',
    'difficulty'      => 'i_difficulty',
    'item_writer'     => 'i_author',
    'standard_strand' => 'standard_strand',
    'standard_gle'    => 'standard_gle'
  );

  our %labelMap = (
    'content_area'    => 'Content Area',
    'grade_level'     => 'Grade Level',
    'item_format'       => 'Format',
    'dev_state'       => 'Dev State',
    'difficulty'      => 'Difficulty',
    'item_writer'     => 'Item Writer',
    'standard_strand' => 'Strand',
    'standard_gle'    => 'Expectation'
  );

  $in{items} = [];
  our $data         = {};
  our @reportFields = ();
  our @itemIds;

  $in{contentArea} = '' unless defined $in{contentArea};
  $in{gradeLevel}  = '' unless defined $in{gradeLevel};

  if ( $in{reportType} eq '1' ) {

    my %filterFields = (
        'contentArea'     => {},
        'gradeLevel'      => {},
        'itemFormat'      => {},
        'devState'        => {},
        'editor'          => {},
        'difficultyLevel' => {},
        'language'        => {},
	'hasCopyright'    => {},
    );

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    $sql =
        "SELECT t1.*,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_CONTENT_AREA} LIMIT 1) AS content_area,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_GRADE_LEVEL} LIMIT 1) AS grade_level,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_DOK} LIMIT 1) AS knowledge_depth,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_POINTS} LIMIT 1) AS num_points,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_CALCULATOR} LIMIT 1) AS calculator,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_SCORING_METHOD} LIMIT 1) AS scoring_method,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_PASSAGE} LIMIT 1) AS passage_id,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_RUBRIC} LIMIT 1) AS rubric_id,"
      . " metafiles_count(t1.i_id) AS mf_count,"
      . " has_outdated_metafiles(t1.i_id) AS mf_outdated"
      . " FROM /*cde-filter*/ item AS t1"
      . " WHERE /*cde-filter*/ "
      . ($in{itemBankId} eq $ib_all ? ' t1.ib_id IN (' . join(',', keys %itemBanks) . ')' 
                                    : " t1.ib_id=$in{itemBankId}");

    if ( $in{myfile} ne '' ) {
        my $uploadHandle = $q->upload("myfile");

        open UPLOADED, ">/tmp/itemlist.$$.txt";
        while (<$uploadHandle>) { print UPLOADED; }
        close UPLOADED;

        open ITEMLIST, "</tmp/itemlist.$$.txt";

        while (<ITEMLIST>) {

            $_ =~ s/\s+$//;

            my @fields = split /,/, $_;
            push( @itemIds, $fields[0] ) if $_ ne '';
        }
        close ITEMLIST;

        unlink("/tmp/itemlist.$$.txt");

        $sql .= " AND t1.i_external_id IN ("
          . join( ',', map { "'$_'" } @itemIds ) . ')';
    }
    elsif ( $in{passageId} eq '' ) {
        $sql .= ''
          #. ( $in{projectId} eq '' ? '' : " AND t1.ip_id=$in{projectId}" )
          . (
            scalar( keys %{ $filterFields{itemFormat} } ) == 0 ? ''
            : " AND t1.i_format IN ("
              . join( ',', keys %{ $filterFields{itemFormat} } )
              . ")" )
          . (
            scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
            : " AND t1.i_dev_state IN ("
              . join( ',', keys %{ $filterFields{devState} } )
              . ")" )
          . (
            scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
            : " AND t1.i_author IN ("
              . join( ',', keys %{ $filterFields{editor} } )
              . ")" )
          . (
            scalar( keys %{ $filterFields{difficultyLevel} } ) == 0 ? ''
            : " AND t1.i_difficulty IN ("
              . join( ',', keys %{ $filterFields{difficultyLevel} } )
              . ")" )
          . (
            scalar( keys %{ $filterFields{language} } ) == 0 ? ''
            : " AND t1.i_lang IN ("
              . join( ',', keys %{ $filterFields{language} } )
              . ")" );
    }
    else {
        $sql .=
" AND t1.i_id IN (SELECT i_id FROM item_characterization WHERE ic_type=${OC_PASSAGE} AND ic_value=$in{passageId})";
    }
    $sql .= " ORDER BY t1.i_external_id ASC, t1.i_version DESC LIMIT 1000";

    my @sorted_items = ();
    my %foundIDs = ();

    if($useWorkgroupFilter && $in{workGroupId} eq '') {
      # no items if you don't have a workgroup and you need one
    } else {

      $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_ITEM, 't1')
        if $useWorkgroupFilter;

      $sth = $dbh->prepare($sql);
      $sth->execute();

      @sorted_items = sortItems( sth => $sth, items => \@itemIds );
    }

    for my $row ( @sorted_items ) {
    #while(my $row = $sth->fetchrow_hashref) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };

        #next if exists $foundIDs{ $row->{i_external_id} };
        #$foundIDs{ $row->{i_external_id} } = 1;

        my $copyrightFiles = getBankMetafilesForItem($dbh, $row->{i_id}, $IB_METAFILE_COPYRIGHT);

        unless(exists $filterFields{hasCopyright}{1} && exists $filterFields{hasCopyright}{2}) {

	  next if scalar(keys %{$copyrightFiles}) && exists $filterFields{hasCopyright}{2};
	  next if scalar(keys %{$copyrightFiles}) == 0 && exists $filterFields{hasCopyright}{1};
        }

        my %newItem = ();
        $newItem{id}              = $row->{i_id};
	$newItem{version} = $row->{i_version};
        $newItem{external_id}     = $row->{i_external_id};
        $newItem{ims_id}          = $row->{i_ims_id};
        $newItem{format}            = $item_formats{ $row->{i_format} };
        $newItem{description}     = $row->{i_description};
        $newItem{editor}          = $row->{i_author};
        $newItem{knowledge_depth} = $row->{knowledge_depth};
        $newItem{num_points}      = $row->{num_points};
        $newItem{pub_status} =
          $publication_status{ $row->{i_publication_status} };
        $newItem{dev_state}  = $dev_states{ $row->{i_dev_state} };
        $newItem{language}   = $languages{ $row->{i_lang} };
        $newItem{correct}    = $row->{i_correct_response};
        $newItem{read_only}  = $row->{i_read_only};
        $newItem{difficulty} = $difficulty_levels{ $row->{i_difficulty} };
	$newItem{source_document} = $row->{i_source_document} || '';
        $newItem{grade_level} =
          $const[$OC_GRADE_LEVEL]->{ $row->{grade_level} };
        $newItem{content_area} =
          $const[$OC_CONTENT_AREA]->{ $row->{content_area} };
        $newItem{calculator} =
          $const[$OC_CALCULATOR]->{ $row->{calculator} || 0 };
        $newItem{passage_id}     = $row->{passage_id} || 0;
        $newItem{passage_name}   = '';
        $newItem{rubric_id}      = $row->{rubric_id} || 0;
        $newItem{rubric_name}    = '';
        $newItem{gle0_name}      = '';
        $newItem{gle1_name}      = '';
        $newItem{gle2_name}      = '';
        $newItem{gle0_text}      = '';
        $newItem{gle1_text}      = '';
        $newItem{gle2_text}      = '';
        $newItem{strand_name}    = '';
        $newItem{gle_sort_order} = '99_99';
        $newItem{standards}      = [];
        $newItem{mf_count}       = $row->{mf_count};
        $newItem{mf_outdated}    = $row->{mf_outdated};
	$newItem{enemies} = [];
	$newItem{copyrightFiles} = {};
        $newItem{alternatives} = '';

        for ( 0 .. 2 ) {
            my $standard = {
                'gle'             => 0,
                'gleNumber'       => 0,
                'benchmark'       => 0,
                'category'        => 0,
                'contentStandard' => 0
            };
            push @{ $newItem{standards} }, $standard;
        }

	# get extra attributes

        $sql = "SELECT * FROM item_characterization WHERE i_id=$row->{i_id}";
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute();
        while ( my $row2 = $sth2->fetchrow_hashref ) {
            if ( $row2->{ic_type} == $OC_ITEM_STANDARD ) {
                $newItem{standards}[0]{gle} = $row2->{ic_value};
                $newItem{standards}[0]{gleNumber} =
                  &getGLENumber( $dbh, $row2->{ic_value} );
            }
            elsif ( $row2->{ic_type} == $OC_SECONDARY_STANDARD ) {
                $newItem{standards}[1]{gle} = $row2->{ic_value};
                $newItem{standards}[1]{gleNumber} =
                  &getGLENumber( $dbh, $row2->{ic_value} );
            }
            elsif ( $row2->{ic_type} == $OC_TERTIARY_STANDARD ) {
                $newItem{standards}[2]{gle} = $row2->{ic_value};
                $newItem{standards}[2]{gleNumber} =
                  &getGLENumber( $dbh, $row2->{ic_value} );
            }
            elsif ( $row2->{ic_type} == $OC_BENCHMARK ) {
                $newItem{standards}[0]{benchmark} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_SECONDARY_BENCHMARK ) {
                $newItem{standards}[1]{benchmark} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_TERTIARY_BENCHMARK ) {
                $newItem{standards}[2]{benchmark} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_CATEGORY ) {
                $newItem{standards}[0]{category} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_SECONDARY_CATEGORY ) {
                $newItem{standards}[1]{category} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_TERTIARY_CATEGORY ) {
                $newItem{standards}[2]{category} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_CONTENT_STANDARD ) {
                $newItem{standards}[0]{contentStandard} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_SECONDARY_CONTENT_STANDARD ) {
                $newItem{standards}[1]{contentStandard} = $row2->{ic_value};
            }
            elsif ( $row2->{ic_type} == $OC_TERTIARY_CONTENT_STANDARD ) {
                $newItem{standards}[2]{contentStandard} = $row2->{ic_value};
            }
	    elsif ( $row2->{ic_type} == $OC_ITEM_ENEMY ) {
	    
	      $sql = "SELECT i_external_id FROM item WHERE i_id=" . $row2->{ic_value};
	      my $sth3 = $dbh->prepare($sql);
	      $sth3->execute();
	      if(my $row3 = $sth3->fetchrow_hashref) {
	        push @{$newItem{enemies}}, $row3->{i_external_id};
	      }
	      $sth3->finish;
	    }
        }

	$newItem{copyrightFiles} = getBankMetafilesForItem($dbh, $row->{i_id}, $IB_METAFILE_COPYRIGHT); 

        $sql = <<ITEM_ALTERNATES;
SELECT GROUP_CONCAT(i_external_id) 
FROM item 
WHERE i_id IN (SELECT ia_alternate_i_id FROM item_alternate WHERE i_id=$row->{i_id})
GROUP BY i_external_id;
ITEM_ALTERNATES
        $newItem{alternatives} = $dbh->selectrow_array($sql);

        for ( 0 .. 2 ) {

            if ( $newItem{standards}[$_]{gle} ) {
                my $std = &getStandard( $dbh, $newItem{standards}[$_]{gle} );

                $newItem{ 'gle' . $_ . '_text' } =
                  substr( $std->{$HD_LEAF}->{text}, 0, 70 );
                $newItem{ 'gle' . $_ . '_name' } = $std->{$HD_LEAF}->{value};

                if ( $_ == 0 ) {

                    $sql =
"SELECT t1.hd_posn_in_parent, t1.hd_parent_id, (SELECT hd_posn_in_parent FROM hierarchy_definition WHERE hd_id=t1.hd_parent_id) AS parent_posn FROM hierarchy_definition AS t1 WHERE hd_id="
                      . $newItem{standards}[$_]{gle};
                    my $sth2 = $dbh->prepare($sql);
                    $sth2->execute();

                    if ( my $row2 = $sth2->fetchrow_hashref ) {
                        $newItem{gle_sort_order} = sprintf( '%02d_%02d',
                            $row2->{parent_posn}, $row2->{hd_posn_in_parent} );
                    }

                    $newItem{strand_name} =
                      $std->{$HD_STANDARD_STRAND}->{value};
                }
            }
        }

        if ( $newItem{passage_id} != 0 ) {

            # passage info
            my $sql2 = "SELECT * FROM passage WHERE p_id=$newItem{passage_id}";
            my $sth2 = $dbh->prepare($sql2);
            $sth2->execute();

            if ( my $row2 = $sth2->fetchrow_hashref ) {

                # Found passage
                $newItem{passage_name}  = $row2->{p_name};
                $newItem{passage_genre} = $genres{ $row2->{p_genre} };
            }
        }

        if ( $newItem{rubric_id} != 0 ) {

            # rubric info
            my $sql2 =
              "SELECT * FROM scoring_rubric WHERE sr_id=$newItem{rubric_id}";
            my $sth2 = $dbh->prepare($sql2);
            $sth2->execute();

            if ( my $row2 = $sth2->fetchrow_hashref ) {

                # Found rubric
                $newItem{rubric_name} = $row2->{sr_name};
            }
        }

        push @{ $in{items} }, \%newItem;
    }
  }
  elsif ( $in{reportType} eq '2' ) {

    my %filterFields = (
        'contentArea'     => {},
        'gradeLevel'      => {},
        'itemFormat'      => {},
        'devState'        => {},
        'editor'          => {},
        'difficultyLevel' => {},
        'language'        => {}
    );

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    my $users = &getUsers($dbh);

    $sql =
        "SELECT t1.*,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_CONTENT_AREA} LIMIT 1) AS content_area,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_GRADE_LEVEL} LIMIT 1) AS grade_level,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_DOK} LIMIT 1) AS knowledge_depth,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_POINTS} LIMIT 1) AS num_points,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_ITEM_STANDARD} LIMIT 1) AS gle_id"
      . " FROM /*cde-filter*/ item AS t1"
      . " WHERE /*cde-filter*/ "
      . ($in{itemBankId} eq $ib_all ? ' t1.ib_id IN (' . join(',', keys %itemBanks) . ')' 
                                    : " t1.ib_id=$in{itemBankId}")
      #. ( $in{projectId} eq '' ? '' : " AND t1.ip_id=$in{projectId}" )
      . (
        scalar( keys %{ $filterFields{itemFormat} } ) == 0 ? ''
        : " AND t1.i_format IN ("
          . join( ',', keys %{ $filterFields{itemFormat} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND t1.i_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND t1.i_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{difficultyLevel} } ) == 0 ? ''
        : " AND t1.i_difficulty IN ("
          . join( ',', keys %{ $filterFields{difficultyLevel} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND t1.i_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" )
      . " ORDER BY t1.i_external_id ASC, t1.i_version DESC LIMIT 1000";

    my %foundIDs = ();

    if($useWorkgroupFilter && $in{workGroupId} eq '') {
      # no items if you don't have a workgroup and you need one
      $sql = 'SELECT i_id FROM item WHERE 1=0';
    } else {
      if($user->{adminType}) {
        if($in{workGroupId}) {
          my $wgf = {};
	  $wgf->{filters} = &getWorkgroupFilters($dbh, $in{workGroupId});
          $sql = &makeQueryWithWorkgroupFilter($sql,$wgf, $OT_ITEM, 't1');
        }
      } else {
        $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_ITEM, 't1')
          if $useWorkgroupFilter;
      }
    }

    $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };
        next
          if scalar( keys %{ $filterFields{itemFormat} } ) > 0
              and not exists $filterFields{itemFormat}{ $row->{item_format} };

        next if exists $foundIDs{ $row->{i_external_id} };
        $foundIDs{ $row->{i_external_id} } = 1;

        my %newItem = ();
        $newItem{id}              = $row->{i_id};
        $newItem{external_id}     = $row->{i_external_id};
        $newItem{format}            = $item_formats{ $row->{i_format} };
        $newItem{description}     = $row->{i_description};
        $newItem{editor}          = $row->{i_author};
        $newItem{knowledge_depth} = $row->{knowledge_depth};
        $newItem{num_points}      = $row->{num_points};
        $newItem{dev_state}       = $dev_states{ $row->{i_dev_state} };
        $newItem{language}        = $languages{ $row->{i_lang} };
        $newItem{correct}         = $row->{i_correct_response};
        $newItem{difficulty}      = $difficulty_levels{ $row->{i_difficulty} };
	$newItem{source_document} = $row->{i_source_document} || '';
        $newItem{grade_level} =
          $const[$OC_GRADE_LEVEL]->{ $row->{grade_level} };
        $newItem{content_area} =
          $const[$OC_CONTENT_AREA]->{ $row->{content_area} };
        $newItem{gle_id}         = $row->{gle_id} || 0;
        $newItem{gle_sort_order} = '99_99';
        $newItem{gle_name}       = '';
        $newItem{strand_name}    = '';

        if ( $newItem{gle_id} != 0 ) {
            my $std = &getStandard( $dbh, $newItem{gle_id} );
            $sql =
"SELECT t1.hd_posn_in_parent, t1.hd_parent_id, (SELECT hd_posn_in_parent FROM hierarchy_definition WHERE hd_id=t1.hd_parent_id) AS parent_posn FROM hierarchy_definition AS t1 WHERE hd_id=$newItem{gle_id}";
            my $sth2 = $dbh->prepare($sql);
            $sth2->execute();
            if ( my $row2 = $sth2->fetchrow_hashref ) {
                $newItem{gle_sort_order} = sprintf( "%02d_%02d",
                    $row2->{parent_posn}, $row2->{hd_posn_in_parent} );
            }

            $newItem{gle_text}    = substr( $std->{$HD_LEAF}->{text}, 0, 70 );
            $newItem{gle_name}    = $std->{$HD_LEAF}->{value};
            $newItem{strand_name} = $std->{$HD_STANDARD_STRAND}->{value};
        }

        my %ts = ();
        $sql =
"SELECT * FROM item_status WHERE i_id=$row->{i_id} ORDER BY is_timestamp DESC";
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute();
        while ( my $row2 = $sth2->fetchrow_hashref ) {
            my $key = $row2->{is_last_dev_state};

            unless ( exists $ts{$key} ) {
                $ts{$key}            = {};
                $ts{$key}{nextState} = $row2->{is_next_dev_state};
                $ts{$key}{sent}      = $row2->{is_timestamp};
                $ts{$key}{user}      = $users->{ $row2->{is_u_id} };
                $ts{$key}{elapsed}   = 0;
            }

            unless ( $row2->{is_accepted_timestamp} eq '0000-00-00 00:00:00' ) {
                $ts{$key}{elapsed} +=
                  ( str2time( $row2->{is_timestamp} ) -
                      str2time( $row2->{is_accepted_timestamp} ) );
            }
        }

        $newItem{ts} = \%ts;

        push @{ $in{items} }, \%newItem;
    }

  }
  elsif ( $in{reportType} eq '3' ) {

    my %filterFields = (
        'contentArea'     => {},
        'gradeLevel'      => {},
        'itemFormat'        => {},
        'devState'        => {},
        'editor'          => {},
        'difficultyLevel' => {},
        'language'        => {}
    );

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    foreach my $key ( keys %fieldMap ) {
        if ( exists $in{"report_${key}"} ) {
            push( @reportFields, $key );
        }
    }

    foreach my $key ( keys %{ $fieldMap{ $in{pivotField} } } ) {
        $data->{$key} = {};

        foreach my $field (@reportFields) {
            $data->{$key}->{$field} = {};

            #foreach my $fieldKey ( keys %{$fieldMap{$field}} ) {
            #  $data->{$key}->{$field}->{$fieldKey} = 0;
            #}
        }
    }

    $sql =
        "SELECT t1.*,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_CONTENT_AREA}) AS content_area,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_GRADE_LEVEL}) AS grade_level,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_DOK}) AS knowledge_depth,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_POINTS}) AS num_points,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_ITEM_STANDARD} LIMIT 1) AS gle_id,"
      . " (SELECT hd_parent_path FROM hierarchy_definition WHERE hd_id=(SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_ITEM_STANDARD} LIMIT 1)) AS gle_path,"
      . " (SELECT hd_value FROM hierarchy_definition WHERE hd_id=(SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_ITEM_STANDARD} LIMIT 1)) AS standard_gle"
      . " FROM /*cde-filter*/ item AS t1"
      . " WHERE /*cde-filter*/ t1.ib_id=$in{itemBankId}"
      #. ( $in{projectId} eq '' ? '' : " AND t1.ip_id=$in{projectId}" )
      . (
        scalar( keys %{ $filterFields{itemFormat} } ) == 0 ? ''
        : " AND t1.i_format IN ("
          . join( ',', keys %{ $filterFields{itemFormat} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND t1.i_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND t1.i_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{difficultyLevel} } ) == 0 ? ''
        : " AND t1.i_difficulty IN ("
          . join( ',', keys %{ $filterFields{difficultyLevel} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND t1.i_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" )
      . " ORDER BY t1.i_external_id";

    if($useWorkgroupFilter && $in{workGroupId} eq '') {
      # no items if you don't have a workgroup and you need one
      $sql = 'SELECT i_id FROM item WHERE 1=0';
    } else {

      $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_ITEM, 't1')
        if $useWorkgroupFilter;
    }

    #print STDERR $sql;
    $sth = $dbh->prepare($sql);
    $sth->execute();

    my %strandId = ();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };
        next
          if scalar( keys %{ $filterFields{itemFormat} } ) > 0
              and not exists $filterFields{itemFormat}{ $row->{item_format} };
        #next
        #  if exists( $in{itemContentHasImages} )
        #      && not( containsImages( $row->{i_xml_data} ) );

        $row->{standard_gle} = 'GLE ' . $row->{standard_gle};

        # load the $fieldMap{'standard_strand'} array
        if ( scalar( keys %{ $fieldMap{'standard_strand'} } ) == 0
            and $row->{gle_path} )
        {
            $sql =
"SELECT hd_id,hd_value FROM hierarchy_definition WHERE hd_parent_id=(SELECT hd_parent_id FROM hierarchy_definition WHERE hd_type=${HD_STANDARD_STRAND} AND hd_id IN ($row->{gle_path}) LIMIT 1)";
            my $sth2 = $dbh->prepare($sql);
            $sth2->execute();
            while ( my $row2 = $sth2->fetchrow_hashref ) {
                $fieldMap{'standard_strand'}{ $row2->{hd_value} } =
                  $row2->{hd_value};
                $strandId{ $row2->{hd_id} } = 1;
            }
        }

        if ( $row->{gle_path} ) {
            $sql =
"SELECT hd_value FROM hierarchy_definition WHERE hd_type=${HD_STANDARD_STRAND} AND hd_id IN ($row->{gle_path})";
            my $sth2 = $dbh->prepare($sql);
            $sth2->execute();
            if ( my $row2 = $sth2->fetchrow_hashref ) {
                $row->{standard_strand} = $row2->{hd_value};
            }
        }

        # load the $fieldMap{'standard_gle'} array
        unless ( scalar( keys %{ $fieldMap{'standard_gle'} } ) > 0 ) {
            foreach ( keys %strandId ) {
                $sql =
"SELECT hd_id,hd_value FROM hierarchy_definition WHERE hd_type=${HD_LEAF} AND (hd_parent_path LIKE '\%,$_,\%' OR hd_parent_id=$_)";
                my $sth2 = $dbh->prepare($sql);
                $sth2->execute();
                while ( my $row2 = $sth2->fetchrow_hashref ) {
                    $fieldMap{'standard_gle'}{ 'GLE ' . $row2->{hd_value} } =
                      'GLE ' . $row2->{hd_value};
                }
            }
        }

        # It passes the filters, so add it to the count
        foreach my $key ( keys %{ $fieldMap{ $in{pivotField} } } ) {
            foreach my $field (@reportFields) {
                foreach my $fieldKey ( keys %{ $fieldMap{$field} } ) {
                    if (    $row->{ $dbMap{ $in{pivotField} } } eq $key
                        and $row->{ $dbMap{$field} } eq $fieldKey )
                    {
                        if ( exists $data->{$key}->{$field}->{$fieldKey} ) {
                            $data->{$key}->{$field}->{$fieldKey}++;
                        }
                        else {
                            $data->{$key}->{$field}->{$fieldKey} = 1;
                        }    #end if/else
                    }    #end if
                }    #end foreach my $fieldKey
            }    # end foreach my $field
        }    # end foreach my $key
    }    # end while

  }
  elsif ( $in{reportType} eq '4' ) {

    my %filterFields = (
        'contentArea'     => {},
        'gradeLevel'      => {},
        'itemFormat'      => {},
        'devState'        => {},
        'editor'          => {},
        'difficultyLevel' => {},
        'language'        => {}
    );

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    $sql =
        "SELECT t1.*,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_CONTENT_AREA}) AS content_area,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_GRADE_LEVEL}) AS grade_level"
      . " FROM /*cde-filter*/ item AS t1"
      . " WHERE /*cde-filter*/ t1.ib_id=$in{itemBankId}"
      #. ( $in{projectId} eq '' ? '' : " AND t1.ip_id=$in{projectId}" )
      . (
        scalar( keys %{ $filterFields{itemFormat} } ) == 0 ? ''
        : " AND t1.i_format IN ("
          . join( ',', keys %{ $filterFields{itemFormat} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND t1.i_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND t1.i_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{difficultyLevel} } ) == 0 ? ''
        : " AND t1.i_difficulty IN ("
          . join( ',', keys %{ $filterFields{difficultyLevel} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND t1.i_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" )
      . " ORDER BY t1.i_id";

    if($useWorkgroupFilter && $in{workGroupId} eq '') {
      # no items if you don't have a workgroup and you need one
      $sql = 'SELECT i_id FROM item WHERE 1=0';
    } else {

      $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_ITEM, 't1')
        if $useWorkgroupFilter;
    }

    #print STDERR $sql;
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };

        $sql =
"SELECT t1.*, t2.* FROM item_status AS t1, user AS t2 WHERE t1.i_id=$row->{i_id} AND t1.is_u_id=t2.u_id"
          . " AND t1.is_last_dev_state IN ("
          . join( ',', @{ $userTypeDevStates{ $in{userType} } } ) . ")";
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute();
        while ( my $row2 = $sth2->fetchrow_hashref ) {
            my %newItem = ();
            $newItem{id} = $row->{i_id};
            $newItem{user} =
              $row2->{u_first_name} . ' ' . $row2->{u_last_name};
            $newItem{state}              = $row2->{is_last_dev_state};
            $newItem{timestamp}          = $row2->{is_timestamp};
            $newItem{accepted_timestamp} = $row2->{is_accepted_timestamp};
            $newItem{elapsed} =
              $row2->{is_accepted_timestamp} eq '0000-00-00 00:00:00'
              ? 300
              : str2time( $row2->{is_timestamp} ) -
              str2time( $row2->{is_accepted_timestamp} );

            $newItem{item_format}  = $item_formats{$row->{i_format}};
            push @{ $in{items} }, \%newItem;
        }
        $sth2->finish;
    }
  }
  elsif ( $in{reportType} eq '5' ) {

    my %filterFields = (
        'contentArea'     => {},
        'gradeLevel'      => {},
        'itemFormat'      => {},
        'devState'        => {},
        'editor'          => {},
        'difficultyLevel' => {},
        'language'        => {}
    );

    my $count_map = {};

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    $sql =
        "SELECT t1.*,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_CONTENT_AREA} LIMIT 1) AS content_area,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_GRADE_LEVEL} LIMIT 1) AS grade_level"
      . " FROM /*cde-filter*/ item AS t1"
      . " WHERE /*cde-filter*/ "
      . ($in{itemBankId} eq $ib_all ? ' t1.ib_id IN (' . join(',', keys %itemBanks) . ')' 
                                    : " t1.ib_id=$in{itemBankId}")
      #. ( $in{projectId} eq '' ? '' : " AND t1.ip_id=$in{projectId}" )
      . (
        scalar( keys %{ $filterFields{itemFormat} } ) == 0 ? ''
        : " AND t1.i_format IN ("
          . join( ',', keys %{ $filterFields{itemFormat} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND t1.i_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND t1.i_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{difficultyLevel} } ) == 0 ? ''
        : " AND t1.i_difficulty IN ("
          . join( ',', keys %{ $filterFields{difficultyLevel} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND t1.i_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" )
      . "";

    my %foundIDs = ();

    if($useWorkgroupFilter && $in{workGroupId} eq '') {
      # no items if you don't have a workgroup and you need one
      $sql = 'SELECT i_id FROM item WHERE 1=0';
    } else {
      if($user->{adminType}) {
        if($in{workGroupId}) {
          my $wgf = {};
	  $wgf->{filters} = &getWorkgroupFilters($dbh, $in{workGroupId});
          $sql = &makeQueryWithWorkgroupFilter($sql,$wgf, $OT_ITEM, 't1');
        }
      } else {

        $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_ITEM, 't1')
          if $useWorkgroupFilter;
      }
    }

    $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };
        next
          if scalar( keys %{ $filterFields{itemFormat} } ) > 0
              and not exists $filterFields{itemFormat}{ $row->{item_format} };

        next if exists $foundIDs{ $row->{i_external_id} };
        $foundIDs{ $row->{i_external_id} } = 1;

        my $writerId = $row->{i_author};
	my $metric = ($row->{i_dev_state} == $DS_REJECTED || $row->{i_dev_state} == $DS_DNU_ITEM_POOL) ? 'dnu' : 'total';
	my $category = $row->{content_area} . '_' . $row->{grade_level};

	if(exists $count_map->{$writerId}{$metric}{$category}) {
          $count_map->{$writerId}{$metric}{$category}++;
	} else {
          $count_map->{$writerId}{$metric}{$category} = 1;
	}

        #  $const[$OC_GRADE_LEVEL]->{ $row->{grade_level} };
        #  $const[$OC_CONTENT_AREA]->{ $row->{content_area} };
    }

    $in{count_map} = $count_map;
  }
  elsif ( $in{reportType} eq '6' ) {

    my %filterFields = (
        'contentArea'     => {},
        'gradeLevel'      => {},
        'itemFormat'      => {},
        'devState'        => {},
        'editor'          => {},
        'difficultyLevel' => {},
        'language'        => {}
    );

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    $sql =
        "SELECT t1.*,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_CONTENT_AREA} LIMIT 1) AS content_area,"
      . " (SELECT ic_value FROM item_characterization AS t2 WHERE t2.i_id=t1.i_id AND t2.ic_type=${OC_GRADE_LEVEL} LIMIT 1) AS grade_level"
      . " FROM /*cde-filter*/ item AS t1"
      . " WHERE /*cde-filter*/ "
      . ($in{itemBankId} eq $ib_all ? ' t1.ib_id IN (' . join(',', keys %itemBanks) . ')' 
                                    : " t1.ib_id=$in{itemBankId}")
      #. ( $in{projectId} eq '' ? '' : " AND t1.ip_id=$in{projectId}" )
      . ' AND t1.i_due_date >= ' . $dbh->quote($in{startDate} eq '' ? '0000-00-00' : $in{startDate})
      . ' AND t1.i_due_date <= ' . $dbh->quote($in{endDate} eq '' ? '9999-01-01' : $in{endDate})
      . (
        scalar( keys %{ $filterFields{itemFormat} } ) == 0 ? ''
        : " AND t1.i_format IN ("
          . join( ',', keys %{ $filterFields{itemFormat} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND t1.i_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND t1.i_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{difficultyLevel} } ) == 0 ? ''
        : " AND t1.i_difficulty IN ("
          . join( ',', keys %{ $filterFields{difficultyLevel} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND t1.i_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" )
      . " ORDER BY t1.i_external_id ASC, t1.i_version";

    my %foundIDs = ();

    if($useWorkgroupFilter && $in{workGroupId} eq '') {
      # no items if you don't have a workgroup and you need one
      $sql = 'SELECT i_id FROM item WHERE 1=0';
    } else {

      if($user->{adminType}) {
        if($in{workGroupId}) {
          my $wgf = {};
	  $wgf->{filters} = &getWorkgroupFilters($dbh, $in{workGroupId});
          $sql = &makeQueryWithWorkgroupFilter($sql,$wgf, $OT_ITEM, 't1');
        }
      } else {
        $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_ITEM, 't1')
          if $useWorkgroupFilter;
      }
    }

    $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };
        next
          if scalar( keys %{ $filterFields{itemFormat} } ) > 0
              and not exists $filterFields{itemFormat}{ $row->{item_format} };

        next if exists $foundIDs{ $row->{i_external_id} };
        $foundIDs{ $row->{i_external_id} } = 1;

        my %newItem = ();
        $newItem{id}              = $row->{i_id};
        $newItem{name}     = $row->{i_external_id};
	$newItem{program} = $banks->{$row->{ib_id}}{name};
        $newItem{editor}          = $row->{i_author} ? $editors->{$row->{i_author}} : 'Unassigned, Unassigned';
        $newItem{dev_state}  = $dev_states{ $row->{i_dev_state} };
	$newItem{due_date} = $row->{i_due_date};

        push @{ $in{items} }, \%newItem;
    }

  }

  if ( $in{myaction} eq '1' ) {

    if ( $in{reportType} eq '1' ) {
      
        return [ $q->psgi_header('text/html'),
                 [ &print_standard_html_report( \%in ) ] ];
    }
    elsif ( $in{reportType} eq '2' ) {

        return [ $q->psgi_header('text/html'),
                 [ &print_progress_html_report( \%in ) ] ];
    }
  }
  elsif ( $in{myaction} eq '2' ) {

    if ( $in{reportType} eq '1' ) {

        return [ $q->psgi_header( -type => 'text/csv',
	                          -attachment => 'item_report.csv' ),
                 [ &print_standard_csv_report( \%in ) ] ];
    }
    elsif ( $in{reportType} eq '2' ) {

      return [ $q->psgi_header( -type => 'text/csv',
                                -attachment => 'item_progress_report.csv' ),
               [ &print_progress_csv_report( \%in ) ] ];
    }
    elsif ( $in{reportType} eq '3' ) {

      return [ $q->psgi_header( -type => 'text/csv',
                                -attachment => "item_pivot_$in{pivotField}_report.csv"),
               [ &print_pivot_csv_report( \%in, $data ) ] ];
    }
    elsif ( $in{reportType} eq '4' ) {
  
      return [ $q->psgi_header( -type => 'text/csv',
                                -attachment => 'item_work_summary_report.csv' ),

               [ &print_work_summary_csv_report( \%in ) ] ];
    }
    elsif ( $in{reportType} eq '5' ) {
  
      return [ $q->psgi_header( -type => 'text/csv',
                                -attachment => 'item_quality_report.csv' ),

               [ &print_quality_csv_report( \%in ) ] ];
    }
    elsif ( $in{reportType} eq '6' ) {
  
      return [ $q->psgi_header( -type => 'text/csv',
                                -attachment => 'item_timeliness_report.csv' ),

               [ &print_timeliness_csv_report( \%in ) ] ];
    }
  }
  elsif ( $in{myaction} eq '3' ) {
    return [ $q->psgi_header( -type => 'multipart/x-zip',
                              -attachment => 'item_xml.zip' ),
             [ &print_xml_report( \%in ) ] ];
  }
}

### ALL DONE! ###

sub print_welcome {

    my $params = shift;
    my $msg    = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;'>" . $params->{message} . "</div>"
        : "" );

    my $itemBankId =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : "1" );
    my $itemBankHtml =
      &hashToSelect( 'itemBankId', \%itemBanks, $itemBankId, 'doBankChange();',
        '', '', );

    #my $projectId =
    #  ( defined $params->{projectId} ? $params->{projectId} : '' );
    #my $projectHtml =
    #  &hashToSelect( 'projectId', &getProjects( $dbh, $itemBankId ),
    #    $projectId, '', 'null:All', '', );

    my $workGroupId = ( defined $params->{workGroupId} ? $params->{workGroupId} : "" );
    my $workGroupHtml = &hashToSelect('workGroupId', $currentWorkGroups,
                                      $workGroupId, '', '', 'value', ); 
    if($user->{adminType}) {
      $workGroupHtml = &hashToSelect('workGroupId', $currentWorkGroups,
                                      $workGroupId, '', 'null:All', 'value', ); 
    }

    my $contentAreaHtml =
      &hashToCheckbox( 'contentArea', $const[$OC_CONTENT_AREA], 5 );
    my $gradeLevelHtml =
      &hashToCheckbox( 'gradeLevel', $const[$OC_GRADE_LEVEL], 14 );
    my $itemFormatHtml = &hashToCheckbox( 'itemFormat', \%item_formats, 5 );
    my $devStateHtml = &hashToCheckbox( 'devState', \%filtered_dev_states, 5 );
    my $editorHtml   = &hashToCheckbox( 'editor',   $editors,     5 );
    my $difficultyLevelHtml =
      &hashToCheckbox( 'difficultyLevel', \%difficulty_levels, 6 );
    my $languageHtml = &hashToCheckbox( 'language', \%languages, 6 );
    my $copyrightHtml = &hashToCheckbox( 'hasCopyright', \%has_copyright );

    my $reportType =
      ( defined $params->{reportType} ? $params->{reportType} : "" );
    my $typeHtml = &hashToSelect( 'reportType', \%reportTypes, $reportType,
        'doTypeChange();', '', '', );

    my $passageHtml =
      &hashToSelect( 'passageId', &getPassageList( $dbh, $itemBankId ),
        '', '', 'null', 'value', );

    unless ( defined $params->{items} ) {
        $params->{items} = [];
    }

    my $startDate = defined($in{startDate}) ? $in{startDate} : ''; 
    my $endDate = defined($in{endDate}) ? $in{endDate} : ''; 

    my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Report</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/footer.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      function myOpen(name,url,w,h)
      {
    var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(370,180);
    return true;
      }
   
     function doTypeChange() {
        document.location.href='${thisUrl}?reportType=' + document.form1.reportType.options[document.form1.reportType.selectedIndex].value;
     }
      
            function doBankChange() {
            document.location.href='${thisUrl}?reportType=${reportType}&itemBankId='
                                      + document.form1.itemBankId.options[document.form1.itemBankId.selectedIndex].value;
            }

      function doHtmlSubmit(f) {
	if( f.reportType.selectedIndex == 0 ) {
	    alert('Please SELECT a Report Type to continue.');
	    return false;
   	}
        document.form1.myaction.value = '1';
    document.form1.submit();
    return true;
      }
      
      function doCsvSubmit(f) {
	if( f.reportType.selectedIndex == 0 ) {
	    alert('Please SELECT a Report Type to continue.');
	    return false;
   	}
        document.form1.myaction.value = '2';
    document.form1.submit();
    return true;
      }

      function doXmlSubmit(f) {
	if( f.reportType.selectedIndex == 0 ) {
	    alert('Please SELECT a Report Type to continue.');
	    return false;
   	}
        document.form1.myaction.value = '3';
    document.form1.submit();
    return true;
      }

    //-->
    </script>
  </head>
  <body>
    ${msg}
    <form name="form1" action="${thisUrl}" method="POST" enctype="multipart/form-data" target="_blank">
      
      <input type="hidden" name="myaction" value="" />
      <input type="hidden" name="instance_name" value="$instance_name" />
    <div class="title">View Item Report</div> 
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr><td>Report Type:</td><td>${typeHtml}</td></tr>
      <tr><td>Program:</td><td>${itemBankHtml}</td></tr>
END_HERE

    if($user->{adminType} || $useWorkgroupFilter) {
      $psgi_out .= <<END_HERE;
      <tr><td>Workgroup:</td><td>${workGroupHtml}</td></tr>
END_HERE
    }

    if($reportType eq '6') {
      $psgi_out .= <<END_HERE;
      <tr><td>Start Date:</td>
          <td><input type="text" name="startDate" value="$startDate" maxlength="10" /> (yyyy-mm-dd)</td></tr>
      <tr><td>End Date:</td>
          <td><input type="text" name="endDate" value="$endDate" maxlength="10" /> (yyyy-mm-dd)</td></tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
      <tr><td>Passage:</td><td>${passageHtml}</td></tr>
    </table>
        <table border="1" cellpadding="1" cellspacing="1">
      <tr><td style="width:80px;">Content Area:</td><td style="width:400px;text-align:left;">${contentAreaHtml}</td></tr>
      <tr><td>Grade Level:</td><td>${gradeLevelHtml}</td></tr>
      <tr><td>Item Format:</td><td>${itemFormatHtml}</td></tr>
      <tr><td>Dev State:</td><td>${devStateHtml}</td></tr>
      <tr><td>Difficulty:</td><td>${difficultyLevelHtml}</td></tr>
      <tr><td>Item Writer:</td><td>${editorHtml}</td></tr>
      <tr><td>Language:</td><td>${languageHtml}</td></tr>
      <tr><td>Has Copyright?:</td><td>${copyrightHtml}</td></tr>
    </table>
        <br /><b>OR</b>
        <p>Upload File:&nbsp;<input type="file" name="myfile" /></p>
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
END_HERE

    if($in{reportType} eq '1' || $in{reportType} eq '2') {
      $psgi_out .= <<END_HERE;
        <td><input class="action_button_long" type="button" value="Get HTML Report" onClick="doHtmlSubmit(this.form);" /></td>
END_HERE
    }

    $psgi_out .= <<END_HERE;
        <td><input class="action_button_long" type="button" value="Get CSV Report" onClick="doCsvSubmit(this.form);" /></td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}

sub print_pivot_welcome {

    my $params = shift;
    my $msg    = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;'>" . $params->{message} . "</div>"
        : "" );

    my $itemBankId =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : "1" );
    my $itemBankHtml =
      &hashToSelect( 'itemBankId', \%itemBanks, $itemBankId, 'doBankChange();',
        '' );

    #my $projectId =
    #  ( defined $params->{projectId} ? $params->{projectId} : '' );
    #my $projectHtml =
    #  &hashToSelect( 'projectId', &getProjects( $dbh, $itemBankId ),
    #    $projectId, '', 'null:All' );

    my $workGroupId = ( defined $params->{workGroupId} ? $params->{workGroupId} : "" );
    my $workGroupHtml = &hashToSelect('workGroupId', $currentWorkGroups,
                                      $workGroupId, '', '', 'value', ); 

    my $contentAreaHtml =
      &hashToCheckbox( 'contentArea', $const[$OC_CONTENT_AREA], 5 );
    my $gradeLevelHtml =
      &hashToCheckbox( 'gradeLevel', $const[$OC_GRADE_LEVEL], 14 );
    my $itemFormatHtml = &hashToCheckbox( 'itemFormat', \%item_formats, 5 );
    my $devStateHtml = &hashToCheckbox( 'devState', \%filtered_dev_states, 6 );
    my $editorHtml   = &hashToCheckbox( 'editor',   $editors,     5 );
    my $difficultyLevelHtml =
      &hashToCheckbox( 'difficultyLevel', \%difficulty_levels, 6 );
    my $languageHtml = &hashToCheckbox( 'language', \%languages, 6 );

    my $reportType =
      ( defined $params->{reportType} ? $params->{reportType} : "" );
    my $typeHtml = &hashToSelect( 'reportType', \%reportTypes, $reportType,
        'doTypeChange();', '' );

    unless ( defined $params->{items} ) {
        $params->{items} = [];
    }

    my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Report -- Pivot</title>
    <link rel="stylesheet" type="text/css" src="${orcaUrl}style/text.css" />
    <script language="JavaScript">
    <!--
      function myOpen(name,url,w,h)
      {
    var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(370,180);
    return true;
      }
   
     function doTypeChange() {
       if(document.form1.reportType.options[document.form1.reportType.selectedIndex].value != '3') 
       {
         document.location.href='${thisUrl}?reportType='
                           + document.form1.reportType.options[document.form1.reportType.selectedIndex].value;
       }     
     }
            
            function doBankChange() {
            document.location.href='${thisUrl}?reportType=${reportType}&itemBankId='
                                      + document.form1.itemBankId.options[document.form1.itemBankId.selectedIndex].value;
            }

      /*
      function doHtmlSubmit(f) {
	if( f.reportType.selectedIndex == 0 ) {
	    alert('Please SELECT a Report Type to continue.');
	    return false;
   	}
        document.form1.myaction.value = '1';
    document.form1.submit();
    return true;
      }
      */
      
      function doCsvSubmit(f) {
	if( f.reportType.selectedIndex == 0 ) {
	    alert('Please SELECT a Report Type to continue.');
	    return false;
   	}
        document.form1.myaction.value = '2';
    document.form1.submit();
    return true;
      }
    //-->
    </script>
    <style type="text/css">
      
      select { font-size: 12px; }

      div.text { font-size: 16px; color: blue; margin-bottom: 7px;}

      div.title { font-size: 14px; text-align: left; margin-bottom: 8px; margin-top: 5px;} 
    
      input.button { font-size: 12px; } 
    </style>
  </head>
  <body>
    ${msg}
    <form name="form1" action="${thisUrl}" method="POST" target="_blank">
      
      <input type="hidden" name="myaction" value="" />
    <div class="text">View Item Report</div> 
    <table style="margin-left:10px;" border="0" cellspacing="1" cellpadding="1">
      <tr><td>Report Type:</td><td>${typeHtml}</td></tr>
      <tr><td>Program:</td><td>${itemBankHtml}</td></tr>
END_HERE

    if($useWorkgroupFilter) {
      $psgi_out .= <<END_HERE;
      <tr><td>Workgroup:</td><td>${workGroupHtml}</td></tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    </table>
    <br />
    <div class="title">1) Select Pivot Filter</div> 
        <table border="1" cellspacing="1" cellpadding="1">
      <tr>
              <td style="width:80px;">Content Area:</td><td style="width:400px;text-align:left;">${contentAreaHtml}</td>
            </tr>
            <tr>
              <td>Grade Level:</td><td>${gradeLevelHtml}</td>
            </tr>
            <tr>
              <td>Item Format:</td><td>${itemFormatHtml}</td>
            </tr>
            <tr>
              <td>Dev State:</td><td>${devStateHtml}</td>
            </tr>
            <tr>
              <td>Item Writer:</td><td>${editorHtml}</td>
            </tr>
      <tr><td>Difficulty:</td><td>${difficultyLevelHtml}</td></tr>
      <tr><td>Language:</td><td>${languageHtml}</td></tr>
      <!--
      <tr><td colspan="2">Item Content contains images?&nbsp;&nbsp;<input type="checkbox" name="itemContentHasImages" value="1" /></td></tr>
      -->
    </table>
    <br />
    <div class="title">2) Select Pivot Field <small>(Not a filter field)</small></div>
    <select name="pivotField">
      <option value="content_area">Content Area</option>
      <option value="grade_level">Grade Level</option>
      <option value="item_format">Item Format</option>
      <option value="dev_state">Dev State</option>
      <option value="difficulty">Difficulty</option>
      <option value="item_writer">Item Writer</option>
    </select>
    <br /><br />
    <div class="title">3) Select Report Fields <small>(Not a filter or pivot field)</small></div>
    <table border="0" cellspacing="1" cellpadding="1">
          <tr>
              <td valign="top">
        <table width="170px" border="0" cellspacing="1" cellpadding="1">
      <tr>
        <td><input type="checkbox" name="report_content_area" value="yes" /></td>
    <td align="left">Content Area</td>
      </tr>
      <tr>
        <td><input type="checkbox" name="report_grade_level" value="yes" /></td>
    <td align="left">Grade Level</td>
      </tr>
      <tr>
        <td><input type="checkbox" name="report_item_format" value="yes" /></td>
    <td align="left">Item Format</td>
      </tr>
      <tr>
        <td><input type="checkbox" name="report_dev_state" value="yes" /></td>
    <td align="left">Dev State</td>
      </tr>
    </table>
            </td>
                <td valign="top">
        <table width="170px" border="0" cellspacing="1" cellpadding="1">
      <tr>
        <td><input type="checkbox" name="report_difficulty" value="yes" /></td>
    <td align="left">Difficulty</td>
      </tr>
      <tr>
        <td><input type="checkbox" name="report_item_writer" value="yes" /></td>
    <td align="left">Item Writer</td>
      </tr>
      <tr>
        <td><input type="checkbox" name="report_standard_strand" value="yes" /></td>
    <td align="left">Standard: Strand</td>
      </tr>
      <tr>
        <td><input type="checkbox" name="report_standard_gle" value="yes" /></td>
    <td align="left">Standard: GLE</td>
      </tr>
    </table>
          </td></tr></table>
    <br />
    <table border="0" cellspacing="1" cellpadding="1">
      <tr>
        <!--
        <td><input type="button" value="Get HTML Report" onClick="doHtmlSubmit(this.form);" /></td>
        --> 
    <td colspan="2"><input type="button" class="button" value="Get CSV Report" onClick="doCsvSubmit(this.form);" /></td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}

sub print_work_summary_welcome {

    my $params = shift;
    my $msg    = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;'>" . $params->{message} . "</div>"
        : "" );

    my $itemBankId =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : "1" );
    my $itemBankHtml =
      &hashToSelect( 'itemBankId', \%itemBanks, $itemBankId, 'doBankChange();',
        '', '', 'font-size:11px;' );

    #my $projectId =
    #  ( defined $params->{projectId} ? $params->{projectId} : '' );
    #my $projectHtml =
    #  &hashToSelect( 'projectId', &getProjects( $dbh, $itemBankId ),
    #    $projectId, '', '', '', 'font-size:11px;' );
    my $workGroupId = ( defined $params->{workGroupId} ? $params->{workGroupId} : "" );
    my $workGroupHtml = &hashToSelect('workGroupId', $currentWorkGroups,
                                      $workGroupId, '', '', 'value', ); 

    my $userType = ( defined $params->{userType} ? $params->{userType} : '' );
    my $userTypeHtml =
      &hashToSelect( 'userType', \%userTypes, $userType, '', '', '',
        'font-size:11px;' );

    my $contentAreaHtml =
      &hashToCheckbox( 'contentArea', $const[$OC_CONTENT_AREA], 5 );
    my $gradeLevelHtml =
      &hashToCheckbox( 'gradeLevel', $const[$OC_GRADE_LEVEL], 14 );
    my $itemFormatHtml = &hashToCheckbox( 'itemFormat', \%item_formats, 5 );
    my $devStateHtml = &hashToCheckbox( 'devState', \%filtered_dev_states, 6 );
    my $editorHtml   = &hashToCheckbox( 'editor',   $editors,     5 );
    my $difficultyLevelHtml =
      &hashToCheckbox( 'difficultyLevel', \%difficulty_levels, 6 );
    my $languageHtml = &hashToCheckbox( 'language', \%languages, 6 );

    my $reportType =
      ( defined $params->{reportType} ? $params->{reportType} : "" );
    my $typeHtml = &hashToSelect( 'reportType', \%reportTypes, $reportType,
        'doTypeChange();', '', '', 'font-size:11px;' );

    unless ( defined $params->{items} ) {
        $params->{items} = [];
    }

    my $psgi_out = <<END_HERE;
<!DOCTYPE html> 
<html>
  <head>
    <title>Item Report</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      function myOpen(name,url,w,h)
      {
    var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(370,180);
    return true;
      }
   
     function doTypeChange() {
       if(document.form1.reportType.options[document.form1.reportType.selectedIndex].value != '4') 
       {
         document.location.href='${thisUrl}?reportType='
                           + document.form1.reportType.options[document.form1.reportType.selectedIndex].value;
       }     
     }
      
            function doBankChange() {
            document.location.href='${thisUrl}?reportType=5&itemBankId='
                                      + document.form1.itemBankId.options[document.form1.itemBankId.selectedIndex].value;
            }

      function doCsvSubmit() {
        document.form1.myaction.value = '2';
    document.form1.submit();
    return true;
      }
    //-->
    </script>
    <style type="text/css">
      td { 
             font-size: 12px; 
                 } 
    </style>
  </head>
  <body>
    ${msg}
    <form name="form1" action="${thisUrl}" method="POST" target="_blank">
      
      <input type="hidden" name="myaction" value="" />
    <div class="title">View Item Report</div> 
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr><td>Report Type:</td><td>${typeHtml}</td></tr>
      <tr><td>Program:</td><td>${itemBankHtml}</td></tr>
END_HERE

    if($useWorkgroupFilter) {
      $psgi_out .= <<END_HERE;
      <tr><td>Workgroup:</td><td>${workGroupHtml}</td></tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
            <tr><td>User Type:</td><td>${userTypeHtml}</td></tr>
    </table>
        <table border="1" cellpadding="1" cellspacing="1">
      <tr><td style="width:80px;">Content Area:</td><td style="width:400px;text-align:left;">${contentAreaHtml}</td></tr>
      <tr><td>Grade Level:</td><td>${gradeLevelHtml}</td></tr>
      <tr><td>Item Format:</td><td>${itemFormatHtml}</td></tr>
      <tr><td>Dev State:</td><td>${devStateHtml}</td></tr>
      <tr><td>Difficulty:</td><td>${difficultyLevelHtml}</td></tr>
      <tr><td>Item Writer:</td><td>${editorHtml}</td></tr>
      <tr><td>Language:</td><td>${languageHtml}</td></tr>
    </table>
    <table border="0" cellspacing="3" cellpadding="3">
      <tr>
        <td><input type="button" value="Get CSV Report" onClick="doCsvSubmit();" /></td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}

sub print_standard_html_report {

    my $params = shift;
    my ( $header, $body, $footer, $viewItemLink, $printItemLink );
    my @viewIds = ();

    $header = <<END_HERE;
<html>
  <head>
    <title>Item Report</title>
  </head>
  <body>
END_HERE

    my @titles = ('Item ID','Item Version');
    push( @titles, 'IMS ID' ) if $banks->{ $in{itemBankId} }{hasIMS};
    push @titles, 'Grade';
    push @titles, 'Subject';
    push @titles, 'Format';
    push @titles, 'Difficulty';
    push( @titles, 'Language' ) unless $in{language} eq '';
    push( @titles, 'Description' );
    push( @titles, 'Strand' );
    push( @titles, 'Primary GLE' );
    push( @titles, 'Primary Content Code' );
    push( @titles, 'Secondary GLE' );
    push( @titles, 'Secondary Content Code' );
    push( @titles, 'Tertiary GLE' );
    push( @titles, 'Tertiary Content Code' );
    push( @titles, 'Dev State' );
    push @titles, 'Publication Status';
    push( @titles, 'Calculator' );
    push( @titles, 'Depth of Knowledge' );
    push( @titles, 'Points' );
    push( @titles, 'Read Only' );
    push( @titles, 'Passage' );
    push( @titles, 'Passage Genre' );
    push( @titles, 'Rubric' );
    push( @titles, 'Program Metafiles' );
    push( @titles, 'Outdated Program Metafiles' );
    push( @titles, 'Item Enemies' );
    push( @titles, 'Copyright/DRM');
    push( @titles, 'Source Documentation');
    push( @titles, 'Alternates');

    $body =
        '<table border="1" cellpadding="3" cellspacing="3" style="border-collapse: collapse; empty-cells: show;">'
      . '<tr><th>'
      . join( '</th><th>', @titles )
      . '</th></tr>';

    #foreach my $item ( sort { $a->{gle_sort_order} cmp $b->{gle_sort_order} }
    foreach my $item ( 
        @{ $params->{items} } )
    {
        my @fields = ( $item->{external_id}, $item->{version} );
        push( @fields, $item->{ims_id} || '&nbsp;' )
          if $banks->{ $in{itemBankId} }{hasIMS};
        push @fields, $item->{grade_level};
        push @fields, $item->{content_area};
        push @fields, $item->{format};
        push @fields, $item->{difficulty};
        push( @fields, $item->{language} ) unless $in{language} eq '';
        push( @fields, $item->{description} );
        push( @fields, $item->{strand_name} );

        foreach my $i ( 0 .. 2 ) {
            push @fields,
              ( $item->{"gle${i}_name"} eq ''
                ? '&nbsp;'
                : $item->{"gle${i}_name"} . ': ' . $item->{"gle${i}_text"} );
            push @fields,
              (
                $item->{standards}[$i]{gle}
                ? join(
                    '.',
                    $item->{standards}[$i]{contentStandard},
                    0,
                    ( $item->{standards}[$i]{category} || 0 ),
                    $item->{standards}[$i]{benchmark},
                    (
                        $item->{standards}[$i]{gleNumber}
                        ? sprintf( '%02d', $item->{standards}[$i]{gleNumber} )
                        : 0
                    )
                  )
                : '&nbsp;'
              );
        }
        push( @fields, $item->{dev_state} );
        push( @fields, $item->{pub_status} );
        push( @fields, $item->{calculator} );
        push( @fields, $item->{knowledge_depth} );
        push( @fields, $item->{num_points} );
        push( @fields, $item->{read_only} == '0' ? 'No' : 'Yes' );
        push(
            @fields,
            (
                $item->{passage_name} eq ''
                ? ''
                : '<a href="' 
                  . $orcaUrl
                  . 'cgi-bin/passageView.pl?passageId='
                  . $item->{passage_id}
                  . '" target="_blank">'
                  . $item->{passage_name} . '</a>'
            )
        );
        push( @fields,
            ( $item->{passage_name} eq '' ? '' : $item->{passage_genre} ) );
        push(
            @fields,
            (
                $item->{rubric_name} eq ''
                ? ''
                : '<a href="' 
                  . $orcaUrl
                  . 'cgi-bin/rubricView.pl?rubricId='
                  . $item->{rubric_id}
                  . '" target="_blank">'
                  . $item->{rubric_name} . '</a>'
            )
        );

        push( @fields, $item->{mf_count} == '0' ? 'No' : 'Yes' );
        push( @fields, $item->{mf_count} == '0' ? '' : ( $item->{mf_outdated} eq 'Y' ? 'Yes' : 'No' ) );

	push (@fields, scalar(@{$item->{enemies}}) ? join(',', @{$item->{enemies}}) : '');

        push (@fields, scalar(keys %{$item->{copyrightFiles}}) ? 'Yes' : 'No');
	push (@fields, $item->{source_document});
	#push (@fields, scalar(keys %{$item->{copyrightFiles}}) 
	#               ? join(',', map { '<a href="' 
	#	                        . $item->{copyrightFiles}{$_}{view} 
	#				. '" target="_blank">' . $item->{copyrightFiles}{$_}{name} . '</a>' }
        #                          keys %{$item->{copyrightFiles}})
	#	       : '');
        push (@fields, $item->{alternatives});

        $body .= '<tr><td>' . join( '</td><td>', @fields ) . '</td></tr>';
        push @viewIds, $item->{external_id};
    }

    $body .= '</table>';

    my $itemList = join( ' ', @viewIds );

    $viewItemLink =
'<p><a href="#" onClick="document.viewForm.submit();">Open in Item Viewer</a></p>';
    $printItemLink =
'<p><a href="#" onClick="document.printForm.submit();">Open in Item Printer</a></p>';

    $footer = <<END_HERE;
      <form name="viewForm" action="${orcaUrl}cgi-bin/itemView.pl" method="POST" target="_blank">
        
            <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
        <input type="hidden" name="itemExternalId" value="${itemList}" />   
        </form>
      <form name="printForm" action="${orcaUrl}cgi-bin/itemPrintList.pl" method="POST" target="_blank">
        
            <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
        <input type="hidden" name="itemExternalId" value="${itemList}" />   
        <input type="hidden" name="myAction" value="print" />   
        </form>
  </body>
</html>
END_HERE

    return $header
      . $viewItemLink
      . $printItemLink
      . $body
      . $viewItemLink
      . $printItemLink
      . $footer;
}

sub print_progress_html_report {

    my $params = shift;
    my ( $header, $body, $footer, $viewItemLink, $printItemLink );
    my @viewIds = ();

    $header = <<END_HERE;
<html>
  <head>
    <title>Item Report</title>
  </head>
  <body>
END_HERE

    $body = '<table border="1" cellpadding="3" cellspacing="3" style="border-collapse: collapse; empty-cells: show;">';

    my @titles = ( 'Item ID', 'Subject', 'Grade', 'Type' );

    #push(@titles,'Description');
    push( @titles, 'Strand' );
    push( @titles, 'GLE' );
    push( @titles, 'Dev State' );
    push( @titles, 'Item Writer' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Content Review 1' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Content Review 2' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Copy Review' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Content Approved' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Copy Approved' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Client Approved' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Fix Art' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'New Art' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );

    $body .= '<tr><th>' . join( '</th><th>', @titles ) . '</th></tr>';

    foreach my $item ( sort { $a->{gle_sort_order} cmp $b->{gle_sort_order} }
        @{ $params->{items} } )
    {
        my @fields = (
            $item->{external_id}, $item->{content_area},
            $item->{grade_level}, $item->{type}
        );

        #push(@fields,$item->{description});
        push( @fields, $item->{strand_name} );
        push(
            @fields,
            (
                $item->{gle_name} eq ''
                ? ''
                : $item->{gle_name} . ': ' . $item->{gle_text}
            )
        );
        push( @fields, $item->{dev_state} );

        foreach (
            $DS_DEVELOPMENT,     $DS_CONTENT_REVIEW,   $DS_CONTENT_REVIEW_2,
            $DS_COPY_REVIEW,     $DS_CONTENT_APPROVED, $DS_COPY_APPROVED,
            $DS_CLIENT_APPROVED, $DS_FIX_ART,          $DS_NEW_ART
          )
        {

            push( @fields, $item->{ts}{$_}{user} || '' );
            push( @fields, $item->{ts}{$_}{sent} || '' );
            push( @fields,
                $item->{ts}{$_}{elapsed}
                ? int( $item->{ts}{$_}{elapsed} / 60 )
                : '' );
        }

        $body .= '<tr><td>' . join( '</td><td>', @fields ) . '</td></tr>';
        push @viewIds, $item->{external_id};
    }

    $body .= '</table>';

    my $itemList = join( ' ', @viewIds );

    $viewItemLink =
'<p><a href="#" onClick="document.viewForm.submit();">Open in Item Viewer</a></p>';
    $printItemLink =
'<p><a href="#" onClick="document.printForm.submit();">Open in Item Printer</a></p>';

    $footer = <<END_HERE;
      <form name="viewForm" action="${orcaUrl}cgi-bin/itemView.pl" method="POST" target="_blank">
        
            <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
        <input type="hidden" name="itemExternalId" value="${itemList}" />   
        </form>
      <form name="printForm" action="${orcaUrl}cgi-bin/itemPrintList.pl" method="POST" target="_blank">
        
            <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
        <input type="hidden" name="itemExternalId" value="${itemList}" />   
        <input type="hidden" name="myAction" value="print" />   
        </form>
  </body>
</html>
END_HERE

    return $header
      . $viewItemLink
      . $printItemLink
      . $body
      . $viewItemLink
      . $printItemLink
      . $footer;
}

sub print_standard_csv_report {

    my $psgi_out = '';

    my $params = shift;

    my @titles = ('Item ID','Item Version');
    push( @titles, 'IMS ID' ) if $banks->{ $in{itemBankId} }{hasIMS};
    push @titles, 'Grade';
    push @titles, 'Subject';
    push @titles, 'Format';
    push @titles, 'Difficulty';
    push( @titles, 'Language' ) unless $in{language} eq '';
    push @titles, 'Strand', 'Primary GLE', 'Primary Content Code',
      'Secondary GLE', 'Secondary Content Code', 'Tertiary GLE',
      'Tertiary Content Code', 'Dev State', 'Publication Status', 'Calculator',
      'Depth of Knowledge', 'Points', 'Read Only',
      'Passage', 'Passage Genre', 'Program Metafiles', 'Outdated Program Metafiles', 'Item Enemies', 
      'Copyright/DRM Files', 'Source Document', 'Alternates';

    $psgi_out .= join( ',', @titles ) . "\n";

    #foreach my $item ( sort { $a->{gle_sort_order} cmp $b->{gle_sort_order} }
    foreach my $item ( 
        @{ $params->{items} } )
    {
        $item->{type}        =~ s/,/./g;
        $item->{strand_name} =~ s/,/./g;
        my @fields = ( $item->{external_id}, $item->{version} );
        push( @fields, $item->{ims_id} ) if $banks->{ $in{itemBankId} }{hasIMS};
        push @fields, $item->{grade_level};
        push @fields, $item->{content_area};
        push @fields, $item->{format};
        push @fields, $item->{difficulty};
        push( @fields, $item->{language} ) unless $in{language} eq '';
        push( @fields, $item->{strand_name} );

        foreach my $i ( 0 .. 2 ) {
            $item->{"gle${i}_text"} =~ s/\s/ /g;

            push @fields,
              ( $item->{"gle${i}_name"} eq ''
                ? ''
                : '"'
                  . $item->{"gle${i}_name"} . ': '
                  . $item->{"gle${i}_text"}
                  . '"' );
            push @fields,
              (
                $item->{standards}[$i]{gle}
                ? join(
                    '.',
                    $item->{standards}[$i]{contentStandard},
                    0,
                    ( $item->{standards}[$i]{category} || 0 ),
                    $item->{standards}[$i]{benchmark},
                    (
                        $item->{standards}[$i]{gleNumber}
                        ? sprintf( '%02d', $item->{standards}[$i]{gleNumber} )
                        : 0
                    )
                  )
                : ''
              );
        }
        push( @fields, $item->{dev_state} );
        push( @fields, $item->{pub_status} );
        push( @fields, $item->{calculator} );
        push( @fields, $item->{knowledge_depth} );
        push( @fields, $item->{num_points} );
        push( @fields, $item->{read_only} == '0' ? 'No' : 'Yes' );
        push(
            @fields,
            (
                $item->{passage_name} eq ''
                ? ''
                : '"' . $item->{passage_name} . '"'
            )
        );
        push( @fields,
            ( $item->{passage_name} eq '' ? '' : $item->{passage_genre} ) );
        push( @fields, $item->{mf_count} == '0' ? 'No' : 'Yes' );
        push( @fields, $item->{mf_count} == '0' ? '' : ( $item->{mf_outdated} eq 'Y' ? 'Yes' : 'No' ) );
	push (@fields, scalar(@{$item->{enemies}}) ? join('  ', @{$item->{enemies}}) : '');

        push (@fields, scalar(keys %{$item->{copyrightFiles}}) ? 'Yes' : 'No');
	push (@fields, $item->{source_document});
        push (@fields, $item->{alternatives});
	#push (@fields, scalar(keys %{$item->{copyrightFiles}}) 
	#               ? join(' ', map { $item->{copyrightFiles}{$_}{name}  }
        #                          keys %{$item->{copyrightFiles}})
	#	       : '');

        $psgi_out .= join( ',', @fields ) . "\n";
    }

    return $psgi_out;

}

sub print_progress_csv_report {

    my $psgi_out = '';

    my $params = shift;

    my @titles = ( 'Item ID', 'Subject', 'Grade', 'Type' );

    #push(@titles,'Description');
    push( @titles, 'Strand' );
    push( @titles, 'GLE' );
    push( @titles, 'Dev State' );
    push( @titles, 'Item Writer' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Content Review 1' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Content Review 2' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Copy Review' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Content Approved' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Copy Approved' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Client Approved' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'Fix Art' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );
    push( @titles, 'New Art' );
    push( @titles, 'Date/Time' );
    push( @titles, 'Elapsed' );

    $psgi_out .= join( ',', @titles ) . "\n";

    #foreach my $item ( sort { $a->{gle_sort_order} cmp $b->{gle_sort_order} }
    foreach my $item ( 
        @{ $params->{items} } )
    {

        # Strip out commas from the data
        foreach my $key (qw/type strand_name gle_name gle_text/) {
            $item->{$key} =~ s/,/./g;
            $item->{$key} =~ s/\s/ /g;
        }

        my @fields = (
            $item->{external_id}, $item->{content_area},
            $item->{grade_level}, $item->{type}
        );

        #push(@fields,$item->{language}) unless $in{language} eq '';
        #push(@fields,$item->{description});
        push( @fields, $item->{strand_name} );
        push(
            @fields,
            (
                $item->{gle_name} eq ''
                ? ''
                : $item->{gle_name} . ': ' . $item->{gle_text}
            )
        );
        push( @fields, $item->{dev_state} );
        foreach (
            $DS_DEVELOPMENT,     $DS_CONTENT_REVIEW,   $DS_CONTENT_REVIEW_2,
            $DS_COPY_REVIEW,     $DS_CONTENT_APPROVED, $DS_COPY_APPROVED,
            $DS_CLIENT_APPROVED, $DS_FIX_ART,          $DS_NEW_ART
          )
        {

            $item->{ts}{$_}{user} =~ s/,/./g;

            push( @fields, $item->{ts}{$_}{user} || '' );
            push( @fields, $item->{ts}{$_}{sent} || '' );
            push( @fields,
                $item->{ts}{$_}{elapsed}
                ? int( $item->{ts}{$_}{elapsed} / 60 )
                : '' );
        }
        $psgi_out .= join( ',', @fields ) . "\n";
    }

    return $psgi_out;
}

sub print_pivot_csv_report {

    my $psgi_out = '';

    my $params = shift;
    my $data   = shift;

    my $pivotMap = $fieldMap{ $params->{pivotField} };

    # Print header to top row
    foreach my $pivotKey ( sort { $a <=> $b } keys %{$pivotMap} ) {
        my $pkeyString =
          "$labelMap{$params->{pivotField}} $pivotMap->{$pivotKey}";
        $pkeyString =~ tr/,/./;
        $psgi_out .= "${pkeyString},,,,";
    }
    $psgi_out .= "\n";

    foreach my $field (@reportFields) {

        # Print field headers for each pivot key
        foreach my $pivotKey ( keys %{$pivotMap} ) {
            my $fieldString = $labelMap{$field};
            $fieldString =~ tr/,/./;
            $psgi_out .= "Count of ${fieldString},Total,,,";
        }
        $psgi_out .= "\n";

        # Print field key counts for each pivot key
        foreach my $fieldKey ( sort { $a <=> $b } keys %{ $fieldMap{$field} } )
        {
            foreach my $pivotKey ( sort { $a <=> $b } keys %{$pivotMap} ) {
                my $fieldKeyString = $fieldMap{$field}->{$fieldKey};
                $fieldKeyString =~ tr/,/./;
                $psgi_out .= "${fieldKeyString},$data->{$pivotKey}->{$field}->{$fieldKey},,,";
            }
            $psgi_out .= "\n";
        }

        # Print a 'Grand Total' for each field, for each pivot key
        foreach my $pivotKey ( sort { $a <=> $b } keys %{$pivotMap} ) {
            my $fieldTotal = 0;
            foreach my $fieldKey ( keys %{ $fieldMap{$field} } ) {
                $fieldTotal += $data->{$pivotKey}->{$field}->{$fieldKey};
            }
            $psgi_out .= "Grand Total,${fieldTotal},,,";
        }
        $psgi_out .= "\n";

        #Print a separator
        $psgi_out .= ",,,\n,,,\n";
    }
    return $psgi_out;
}

sub print_work_summary_csv_report {
    my $psgi_out = '';

    my $params = shift;
    my $items  = $params->{items};

    my @days   = qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/;
    my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

    #my $projects = &getProjects( $dbh, $params->{itemBankId} );

    #my $projectConfig = &get_project_config( $params->{projectId} );
    #my $projectStart  = $projectConfig->{startDate};
    #my $projectEnd    = $projectConfig->{endDate};

    my @userDevStates = @{ $userTypeDevStates{ $in{userType} } };

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);

    my $weekStartDate = time - $wday * 86400 - $hour * 3600;
    my $weekEndDate   = time;

    my $monthStartDate = time - $mday * 86400 - $hour * 3600;
    my $monthEndDate   = time;

    #$monthStartDate = str2time($projectStart)
    #  if str2time($projectStart) > $monthStartDate;

    my %weekly = (
        'author' => {},
        'start'  => substr( time2str($weekStartDate), 0, 10 ),
        'end'    => substr( time2str($weekEndDate), 0, 10 )
    );

    my %monthly = (
        'author' => {},
        'start'  => substr( time2str($monthStartDate), 0, 10 ),
        'end'    => substr( time2str($monthEndDate), 0, 10 )
    );

    #my %project = (
    #    'author' => {},
    #    'start'  => $projectStart
    #);

    foreach (@userDevStates) {
        $weekly{$_}  = 0, $weekly{ $_ . '_elapsed' }  = 0;
        $monthly{$_} = 0, $monthly{ $_ . '_elapsed' } = 0;
    #    $project{$_} = 0, $project{ $_ . '_elapsed' } = 0;
    }

    foreach ( @{$items} ) {

        if ( str2time( $_->{accepted_timestamp} ) > $weekStartDate ) {
            unless ( exists $weekly{author}{ $_->{user} } ) {
                $weekly{author}{ $_->{user} } = {};

                foreach my $devState (@userDevStates) {
                    $weekly{author}{ $_->{user} }{$devState} = 0;
                    $weekly{author}{ $_->{user} }{ $devState . '_elapsed' } = 0;
                }
            }

            foreach my $devState (@userDevStates) {
                if ( $_->{state} == $devState ) {
                    $weekly{$devState}++;
                    $weekly{ $devState . '_elapsed' } += $_->{elapsed};
                    $weekly{author}{ $_->{user} }{$devState}++;
                    $weekly{author}{ $_->{user} }{ $devState . '_elapsed' } +=
                      $_->{elapsed};
                }
            }
        }

        if ( str2time( $_->{accepted_timestamp} ) > $monthStartDate ) {
            unless ( exists $monthly{author}{ $_->{user} } ) {
                $monthly{author}{ $_->{user} } = {};

                foreach my $devState (@userDevStates) {
                    $monthly{author}{ $_->{user} }{$devState} = 0;
                    $monthly{author}{ $_->{user} }{ $devState . '_elapsed' } =
                      0;
                }
            }

            foreach my $devState (@userDevStates) {
                if ( $_->{state} == $devState ) {
                    $monthly{$devState}++;
                    $monthly{ $devState . '_elapsed' } += $_->{elapsed};
                    $monthly{author}{ $_->{user} }{$devState}++;
                    $monthly{author}{ $_->{user} }{ $devState . '_elapsed' } +=
                      $_->{elapsed};
                }
            }
        }

        #unless ( exists $project{author}{ $_->{user} } ) {
        #    $project{author}{ $_->{user} } = {};
#
#            foreach my $devState (@userDevStates) {
#                $project{author}{ $_->{user} }{$devState} = 0;
#                $project{author}{ $_->{user} }{ $devState . '_elapsed' } = 0;
#            }
#        }

        foreach my $devState (@userDevStates) {
            if ( $_->{state} == $devState ) {
#                $project{$devState}++;
#                $project{ $devState . '_elapsed' } += $_->{elapsed};
#                $project{author}{ $_->{user} }{$devState}++;
#                $project{author}{ $_->{user} }{ $devState . '_elapsed' } +=
#                  $_->{elapsed};
            }
        }
    }

    foreach (@userDevStates) {
        $weekly{ $_ . '_elapsed' } = &time2string( $weekly{ $_ . '_elapsed' } );
        $monthly{ $_ . '_elapsed' } =
          &time2string( $monthly{ $_ . '_elapsed' } );
#        $project{ $_ . '_elapsed' } =
#          &time2string( $project{ $_ . '_elapsed' } );
    }

    $psgi_out .= ",,,\n"
      . "Weekly,,,Total Minutes\n";

    foreach my $devState (@userDevStates) {

        $psgi_out .= ",$dev_states{$devState}:,$weekly{$devState},"
          . $weekly{ $devState . '_elapsed' } . "\n";

        foreach my $author ( keys %{ $weekly{author} } ) {
            $psgi_out .= ",${author},$weekly{author}{$author}{$devState},"
              . &time2string(
                $weekly{author}{$author}{ $devState . '_elapsed' } )
              . "\n";
        }
    }

    $psgi_out .= ",,,\n" . "Monthly,,,Total Minutes\n";

    foreach my $devState (@userDevStates) {

        $psgi_out .= ",$dev_states{$devState}:,$monthly{$devState},"
          . $monthly{ $devState . '_elapsed' } . "\n";

        foreach my $author ( keys %{ $monthly{author} } ) {
            $psgi_out .= ",${author},$monthly{author}{$author}{$devState},"
              . &time2string(
                $monthly{author}{$author}{ $devState . '_elapsed' } )
              . "\n";
        }
    }

    #$project{start} =~ s/,/\./g;

    #$psgi_out .= ",,,\n" . "To Date,From $project{start},,Total Minutes\n";

    #foreach my $devState (@userDevStates) {
    #    $psgi_out .= ",$dev_states{$devState}:,$project{$devState},"
    #      . $project{ $devState . '_elapsed' } . "\n";
#
#        foreach my $author ( keys %{ $project{author} } ) {
#            $psgi_out .= ",${author},$project{author}{$author}{$devState},"
#              . &time2string(
#                $project{author}{$author}{ $devState . '_elapsed' } )
#              . "\n";
#        }
#    }

    return $psgi_out;
}

sub print_quality_csv_report {

    my $psgi_out = '';

    my $params = shift;

    my $count_map = $params->{count_map};

    my @subject_list = ();
    my @grade_list = ();
    my @category_list = ();

    # if they used subject or grade filters, go ahead and filter those

    foreach my $subjectKey ( grep /^contentArea_/, keys %in ) {
      $subjectKey =~ /_(\d+)$/;
      push @subject_list, $1;
    }

    foreach my $gradeKey ( grep /^gradeLevel_/, keys %in ) {
      $gradeKey =~ /_(\d+)$/;
      push @grade_list, $1;
    }



    # if they didn't check a subject or grade, then use them all
    @subject_list = keys %{$const[$OC_CONTENT_AREA]} unless scalar @subject_list;
    @grade_list = keys %{$const[$OC_GRADE_LEVEL]} unless scalar @grade_list;

    foreach my $s_key (sort { $a <=> $b } @subject_list) {
      foreach my $g_key (sort { $a <=> $b } @grade_list) {
        push @category_list, $s_key . '_' . $g_key;
      }
    }

    # if they specified a workgroup, then that overrides
    if($in{workGroupId}) {
      @category_list = ();
      my $filters = &getWorkgroupFilters($dbh, $in{workGroupId});

      foreach my $f_key (keys %$filters) {
        my $s_key = $filters->{$f_key}{parts}{$OC_CONTENT_AREA};
        my $g_key = $filters->{$f_key}{parts}{$OC_GRADE_LEVEL};

	push @category_list, $s_key . '_' . $g_key;
      }

      @category_list = sort @category_list;
    }

    my @titles = ( 'Program', 'Writer Last Name', 'Writer First Name', 'Metric' );

    # add remaining headers for subject/grade combos
    foreach my $c_key (@category_list) {
      my ($s_key, $g_key) = split /_/, $c_key;

      push @titles, $const[$OC_CONTENT_AREA]->{$s_key} . ' ' . $const[$OC_GRADE_LEVEL]->{$g_key};
    }

    $psgi_out .= join( ',', @titles ) . "\n";

    foreach my $writer (keys %$count_map) {

      foreach my $metric ('total', 'dnu') {

        my @fields = ( $banks->{$in{itemBankId}}{name}, 
	               ($writer ? $editors->{$writer} : 'Unassigned, Unassigned'), 
	               ($metric eq 'total' ? 'Total Items' : 'Rejected/DNU') );

	foreach my $c_key (@category_list) {
	  push @fields, ( exists($count_map->{$writer}{$metric}{$c_key}) ?  $count_map->{$writer}{$metric}{$c_key} : 0 );
	}
        $psgi_out .= join( ',', @fields ) . "\n";
      }
    }

    return $psgi_out;
}

sub print_timeliness_csv_report {

    my $psgi_out = '';

    my $params = shift;

    my $items = $params->{items};

    my @titles = ( 'Program', 'Item', 'Writer Last Name', 'Writer First Name', 'Development State', 'Due Date');

    $psgi_out .= join( ',', @titles ) . "\n";

    foreach my $item ( @{$params->{items}} ) {
      my @fields = map { $item->{$_} } qw/program name editor dev_state due_date/;
      $psgi_out .= join( ',', @fields ) . "\n";
    }

    return $psgi_out;
}

sub print_xml_report {

    my $p = shift;

    my $tmpDir = "/tmp/item_xml_$$";
    mkdir $tmpDir, 0777;

    my $zipDir = "${tmpDir}/item_xml";
    mkdir $zipDir, 0777;

    my $zipImgDir = $zipDir . "/images";
    mkdir $zipImgDir, 0777;

    my $itemRelPath = './images';

    #print STDERR "Using zip dir ${zipDir}";

    foreach my $item ( @{ $p->{items} } ) {
        my $xml = &getItemXml( $dbh, $item->{id} );

        my $itemDir = "${zipImgDir}/$item->{external_id}";
        mkdir $itemDir, 0777;

        $xml =~
s/src="([^"]+)"/&translate_img_src($1,$item->{external_id},${itemDir},${itemRelPath})/ge;

        open ITEM, '>', $zipDir . '/' . $item->{external_id} . '.xml';
        print ITEM $xml;
        close ITEM;
    }

    chdir $tmpDir;

    my $zip = Archive::Zip->new();
    my $dir_member = $zip->addTree( '.' , '' );
    unless ( $zip->writeToFileNamed( 'item_xml.zip' ) == AZ_OK ) {
       die 'write error';
    }

    my $fh = IO::File->new('item_xml.zip','r'); 
    #open ZIP, '<', "item_xml.zip";
    #binmode ZIP;
    #while (<ZIP>) { print; }
    #close ZIP;

    chdir '/tmp';
    system( 'rm', '-rf', $tmpDir );

    return $fh;

}

sub translate_img_src {

    my $url      = shift;
    my $itemId   = shift;
    my $itemPath = shift;
    my $relDir   = shift;

    my $itemUrl = "${relDir}/${itemId}/";
    my $imgUrl  = '';

    if ( $url =~ /$itemId\/(.*)/ ) {

        my $imgPath = $itemPath . '/' . $1;
        $imgUrl = $itemUrl . $1;

        #print STDERR "Copy ${webPath}${url} to ${imgPath}\n";
        cp( $webPath . $url, $imgPath );
    }
    else {

        #print STDERR "URL ${url} does not match ${itemId}\n";
    }

    return 'src="' . $imgUrl . '"';

}

sub time2string {
    my $ts = shift;
    if ( $ts < 1 ) { return ''; }

    return int( $ts / 60 );

 # Use this section if you want 'x' seconds converted into days /hours / minutes
    if ( $ts < 86400 ) {
        my $hours = int( $ts / 3600 );
        my $mins = int( ( $ts - ( $hours * 3600 ) ) / 60 );
        return "${hours}h ${mins}m";
    }
    else {
        my $days  = int( $ts / 86400 );
        my $hours = int( ( $ts - ( $days * 86400 ) ) / 3600 );
        my $mins  = int( ( $ts - ( $days * 86400 ) - ( $hours * 3600 ) ) / 60 );
        return "${days}d ${hours}h ${mins}m";
    }
}

sub containsImages {
    my $html = shift;

    return 1 if ( $html =~ /<img/ || $html =~ /<embed/ );
    return 0;
}

sub sortItems {
    my %p = @_;

    my @sorted_items = ();
    my %items;
    while(my $row = $p{sth}->fetchrow_hashref ) {
        $items{$row->{i_external_id}} = $row;
        push @sorted_items, $row;
    }
    @sorted_items = map { $items{$_} } @{$p{items}} if(scalar @{$p{items}} > 0);
    return @sorted_items;
}  


sub getUserWorkGroupsForBank {

  my $wg = shift;
  my $itemBankId = shift;

  my %out = map { $_ => $wg->{$_}{name} } grep { $wg->{$_}{bank} == $itemBankId } keys %$wg;
  return \%out;
}

 1;
