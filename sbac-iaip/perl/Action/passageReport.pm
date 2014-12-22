package Action::passageReport;

use URI::Escape;
use ItemConstants;
use HTTP::Date;
use Data::Dumper;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $thisUrl = "${orcaUrl}cgi-bin/passageReport.pl";

  our %reportTypes = ( '1' => 'Standard' );

  our $sth;
  our $sql;

  our $user = Session::getUser($q->env, $dbh);
  our $editors   = &getEditors($dbh);
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  our %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

  $in{reportType} = '' unless exists $in{reportType};
  $in{myaction}   = '' unless exists $in{myaction};

  unless ( $in{myaction} eq '1' or $in{myaction} eq '2' ) {

    my $psgi_out;

    if ( $in{reportType} eq '3' ) {
        $psgi_out = &print_pivot_welcome( \%in );
    }
    elsif ( $in{reportType} eq '4' ) {
        $psgi_out = &print_completion_welcome( \%in );
    }
    else {
        $psgi_out = &print_welcome( \%in );
    }

    return [ $q->psgi_header('text/html'), [ $psgi_out  ] ];
  }

  our %fieldMap = (
    'content_area'    => $const[$OC_CONTENT_AREA],
    'grade_level'     => $const[$OC_GRADE_LEVEL],
    'dev_state'       => \%dev_states,
    'passage_writer'  => $editors,
    'standard_strand' => {},
    'standard_gle'    => {}
  );

  our %dbMap = (
    'content_area'   => 'content_area',
    'grade_level'    => 'grade_level',
    'dev_state'      => 'p_dev_state',
    'passage_writer' => 'p_author'
  );

  our %labelMap = (
    'content_area'   => 'Content Area',
    'grade_level'    => 'Grade Level',
    'dev_state'      => 'Dev State',
    'difficulty'     => 'Difficulty',
    'passage_writer' => 'Passage Writer'
  );

  $in{passages} = [];
  our $data         = {};
  our @reportFields = ();

  $in{contentArea} = '' unless defined $in{contentArea};
  $in{gradeLevel}  = '' unless defined $in{gradeLevel};

  if ( $in{reportType} eq '1' ) {

    my %filterFields = (
        'contentArea' => {},
        'gradeLevel'  => {},
        'devState'    => {},
        'editor'      => {},
        'language'    => {}
    );

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    $sql =
        "SELECT t1.*,"
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_CONTENT_AREA}) AS content_area,"
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_GRADE_LEVEL}) AS grade_level,"
      . " passage_metafiles_count(t1.p_id) AS mf_count,"
      . " passage_has_outdated_metafiles(t1.p_id) AS mf_outdated"
      . " FROM passage AS t1"
      . " WHERE ib_id=$in{itemBankId}"
      . ( $in{projectId} eq '' ? '' : " AND ip_id=$in{projectId}" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND p_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND p_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND p_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" );
    $sql .= " ORDER BY p_name";
    $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };
        my %psg = ();
        $psg{id}           = $row->{p_id};
        $psg{external_id}  = $row->{p_name};
        $psg{description}  = $row->{p_summary};
        $psg{editor}       = $row->{p_author};
        $psg{dev_state}    = $dev_states{ $row->{p_dev_state} };
        $psg{language}     = $languages{ $row->{p_lang} };
        $psg{genre}        = $genres{ $row->{p_genre} };
        $psg{grade_level}  = $const[$OC_GRADE_LEVEL]->{ $row->{grade_level} };
        $psg{content_area} = $const[$OC_CONTENT_AREA]->{ $row->{content_area} };
        $psg{code}         = $row->{p_code};
        $psg{mf_count}	   = $row->{mf_count};
        $psg{mf_outdated}  = $row->{mf_outdated};

        push @{ $in{passages} }, \%psg;
    }
  }
  elsif ( $in{reportType} eq '2' ) {

    my %filterFields = (
        'contentArea' => {},
        'gradeLevel'  => {},
        'devState'    => {},
        'editor'      => {},
        'language'    => {}
    );

    foreach my $filterKey ( keys %filterFields ) {
        foreach ( grep /^${filterKey}_/, keys %in ) {
            $filterFields{$filterKey}{ substr( $_, length($filterKey) + 1 ) } =
              1;
        }
    }

    my $getNameSql =
'(SELECT CONCAT(u_last_name,\', \',u_first_name) FROM user WHERE u_id=';

    $sql =
        "SELECT t1.*,"
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_CONTENT_AREA}) AS content_area,"
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_GRADE_LEVEL}) AS grade_level,"
      . " ${getNameSql}t1.p_author) AS passage_writer_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_DEVELOPMENT} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS passage_writer_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_DEVELOPMENT} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS passage_writer_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_REVIEW} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW_2} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS content_review_1_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_REVIEW} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW_2} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS content_review_1_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_REVIEW} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW_2} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS content_review_1_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_REVIEW_2} AND t3.ps_new_dev_state=${DS_COPY_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS content_review_2_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_REVIEW_2} AND t3.ps_new_dev_state=${DS_COPY_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS content_review_2_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_REVIEW_2} AND t3.ps_new_dev_state=${DS_COPY_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS content_review_2_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_COPY_REVIEW} AND t3.ps_new_dev_state=${DS_CONTENT_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS style_review_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_COPY_REVIEW} AND t3.ps_new_dev_state=${DS_CONTENT_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS style_review_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_COPY_REVIEW} AND t3.ps_new_dev_state=${DS_CONTENT_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS style_review_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_APPROVED} AND t3.ps_new_dev_state=${DS_COPY_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS content_approved_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_APPROVED} AND t3.ps_new_dev_state=${DS_COPY_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS content_approved_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CONTENT_APPROVED} AND t3.ps_new_dev_state=${DS_COPY_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS content_approved_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_COPY_APPROVED} AND t3.ps_new_dev_state=${DS_CLIENT_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS copy_approved_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_COPY_APPROVED} AND t3.ps_new_dev_state=${DS_CLIENT_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS copy_approved_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_COPY_APPROVED} AND t3.ps_new_dev_state=${DS_CLIENT_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS copy_approved_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CLIENT_APPROVED} AND t3.ps_new_dev_state=${DS_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS client_approved_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CLIENT_APPROVED} AND t3.ps_new_dev_state=${DS_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS client_approved_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_CLIENT_APPROVED} AND t3.ps_new_dev_state=${DS_APPROVED} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS client_approved_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_NEW_ART} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS new_art_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_NEW_ART} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS new_art_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_NEW_ART} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS new_art_accepted_timestamp,"
      . " ${getNameSql}(SELECT t3.ps_u_id FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_FIX_ART} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1)) AS fix_art_user,"
      . " (SELECT t3.ps_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_FIX_ART} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS fix_art_timestamp,"
      . " (SELECT t3.ps_accepted_timestamp FROM passage_status AS t3 WHERE t3.p_id=t1.p_id AND t3.ps_last_dev_state=${DS_FIX_ART} AND t3.ps_new_dev_state=${DS_CONTENT_REVIEW} ORDER BY t3.ps_timestamp DESC LIMIT 1) AS fix_art_accepted_timestamp"
      . " FROM item AS t1"
      . " WHERE ib_id=$in{itemBankId}"
      . ( $in{projectId} eq '' ? '' : " AND ip_id=$in{projectId}" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND p_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND p_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND p_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" )
      . " ORDER BY p_name";

    $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if scalar( keys %{ $filterFields{contentArea} } ) > 0
              and not exists $filterFields{contentArea}{ $row->{content_area} };
        next
          if scalar( keys %{ $filterFields{gradeLevel} } ) > 0
              and not exists $filterFields{gradeLevel}{ $row->{grade_level} };
        my %newPassage = ();
        $newPassage{id}          = $row->{p_id};
        $newPassage{external_id} = $row->{p_name};
        $newPassage{description} = $row->{p_summary};
        $newPassage{editor}      = $row->{p_author};
        $newPassage{dev_state}   = $dev_states{ $row->{p_dev_state} };
        $newPassage{genre}       = $genres{ $row->{p_genre} };
        $newPassage{language}    = $languages{ $row->{p_lang} };
        $newPassage{grade_level} =
          $const[$OC_GRADE_LEVEL]->{ $row->{grade_level} };
        $newPassage{content_area} =
          $const[$OC_CONTENT_AREA]->{ $row->{content_area} };

        # Add progress info
        $newPassage{passage_writer_user}    = $row->{passage_writer_user};
        $newPassage{passage_writer_ts}      = $row->{passage_writer_timestamp};
        $newPassage{passage_writer_elapsed} = (
            $row->{passage_writer_accepted_timestamp} eq '0000-00-00 00:00:00'
            ? ''
            : &time2string(
                str2time( $newPassage{passage_writer_ts} ) -
                  str2time( $row->{passage_writer_accepted_timestamp} )
            )
        );
        $newPassage{content_review_1_user} = $row->{content_review_1_user};
        $newPassage{content_review_1_ts}   = $row->{content_review_1_timestamp};
        $newPassage{content_review_1_elapsed} = (
            $row->{content_review_1_accepted_timestamp} eq '0000-00-00 00:00:00'
            ? ''
            : &time2string(
                str2time( $newPassage{content_review_1_ts} ) -
                  str2time( $row->{content_review_1_accepted_timestamp} )
            )
        );
        $newPassage{content_review_2_user} = $row->{content_review_2_user};
        $newPassage{content_review_2_ts}   = $row->{content_review_2_timestamp};
        $newPassage{content_review_2_elapsed} = (
            $row->{content_review_2_accepted_timestamp} eq '0000-00-00 00:00:00'
            ? ''
            : &time2string(
                str2time( $newPassage{content_review_2_ts} ) -
                  str2time( $row->{content_review_2_accepted_timestamp} )
            )
        );
        $newPassage{style_review_user}    = $row->{style_review_user};
        $newPassage{style_review_ts}      = $row->{style_review_timestamp};
        $newPassage{style_review_elapsed} = (
            $row->{style_review_accepted_timestamp} eq '0000-00-00 00:00:00'
            ? ''
            : &time2string(
                str2time( $newPassage{style_review_ts} ) -
                  str2time( $row->{style_review_accepted_timestamp} )
            )
        );
        $newPassage{content_approved_user} = $row->{content_approved_user};
        $newPassage{content_approved_ts}   = $row->{content_approved_timestamp};
        $newPassage{content_approved_elapsed} = (
            $row->{content_approved_accepted_timestamp} eq '0000-00-00 00:00:00'
            ? ''
            : &time2string(
                str2time( $newPassage{content_approved_ts} ) -
                  str2time( $row->{content_approved_accepted_timestamp} )
            )
        );
        $newPassage{copy_approved_user}    = $row->{copy_approved_user};
        $newPassage{copy_approved_ts}      = $row->{copy_approved_timestamp};
        $newPassage{copy_approved_elapsed} = (
            $row->{copy_approved_accepted_timestamp} eq '0000-00-00 00:00:00'
            ? ''
            : &time2string(
                str2time( $newPassage{copy_approved_ts} ) -
                  str2time( $row->{copy_approved_accepted_timestamp} )
            )
        );
        $newPassage{client_approved_user} = $row->{client_approved_user};
        $newPassage{client_approved_ts}   = $row->{client_approved_timestamp};
        $newPassage{client_approved_elapsed} = (
            $row->{client_approved_accepted_timestamp} eq '0000-00-00 00:00:00'
            ? ''
            : &time2string(
                str2time( $newPassage{client_approved_ts} ) -
                  str2time( $row->{client_approved_accepted_timestamp} )
            )
        );
        $newPassage{new_art_user} = $row->{new_art_user};
        $newPassage{new_art_ts}   = $row->{new_art_timestamp};
        $newPassage{fix_art_user} = $row->{fix_art_user};
        $newPassage{fix_art_ts}   = $row->{fix_art_timestamp};

        push @{ $in{passages} }, \%newPassage;
    }

  }
  elsif ( $in{reportType} eq '3' ) {

    my %filterFields = (
        'contentArea' => {},
        'gradeLevel'  => {},
        'devState'    => {},
        'editor'      => {},
        'language'    => {}
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
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_CONTENT_AREA}) AS content_area,"
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_GRADE_LEVEL}) AS grade_level"
      . " FROM passage AS t1"
      . " WHERE ib_id=$in{itemBankId}"
      . ( $in{projectId} eq '' ? '' : " AND ip_id=$in{projectId}" )
      . (
        scalar( keys %{ $filterFields{devState} } ) == 0 ? ''
        : " AND p_dev_state IN ("
          . join( ',', keys %{ $filterFields{devState} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{editor} } ) == 0 ? ''
        : " AND p_author IN ("
          . join( ',', keys %{ $filterFields{editor} } )
          . ")" )
      . (
        scalar( keys %{ $filterFields{language} } ) == 0 ? ''
        : " AND p_lang IN ("
          . join( ',', keys %{ $filterFields{language} } )
          . ")" )
      . " ORDER BY p_name";

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

    my %usedDevStates = ();
    foreach ( keys %workStates ) {
        $usedDevStates{ $workStates{$_} } = $_;
    }

    $sql =
        "SELECT t1.*,"
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_CONTENT_AREA}) AS content_area,"
      . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=t1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_GRADE_LEVEL}) AS grade_level"
      . " FROM passage AS t1"
      . " WHERE ib_id=$in{itemBankId}"
      . " AND ip_id=$in{projectId}"
      . ( $in{language} eq '' ? '' : " AND p_lang=$in{language}" )
      . " ORDER BY p_name";

    #print STDERR $sql;
    $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          if $in{contentArea} ne ''
              and $in{contentArea} ne $row->{content_area};
        next
          if $in{gradeLevel} ne '' and $in{gradeLevel} ne $row->{grade_level};
        next unless exists $usedDevStates{ $row->{p_dev_state} };

        $data->{ $row->{grade_level} } = {}
          unless exists $data->{ $row->{grade_level} };

        if ( exists $data->{ $row->{grade_level} }->{ $row->{p_dev_state} } ) {
            $data->{ $row->{grade_level} }->{ $row->{p_dev_state} }++;
        }
        else {
            $data->{ $row->{grade_level} }->{ $row->{p_dev_state} } = 1;
        }
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
                                -attachment => 'passage_report.csv' ),
               [ &print_standard_csv_report( \%in ) ] ];
    }
    elsif ( $in{reportType} eq '2' ) {

      return [ $q->psgi_header( -type => 'text/csv',
                                -attachment => 'passage_progress_report.csv' ),
               [ &print_progress_csv_report( \%in ) ] ];
    }
    elsif ( $in{reportType} eq '3' ) {

        return [ $q->psgi_header( -type => 'text/csv',
	                          -attachment => "passage_pivot_$in{pivotField}_report.csv" ),
                 [ &print_pivot_csv_report( \%in, $data ) ] ];
    }
    elsif ( $in{reportType} eq '4' ) {

        return [ $q->psgi_header( -type => 'text/csv', 
                                  -attachment => "passage_completion_report.csv"),
                 [ &print_completion_csv_report( \%in, $data ) ] ];
    }
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
        '', '', 'font-size:11px;' );

    my $projectId =
      ( defined $params->{projectId} ? $params->{projectId} : '' );
    my $projectHtml =
      &hashToSelect( 'projectId', &getProjects( $dbh, $itemBankId ),
        $projectId, '', 'null:All', '', 'font-size:11px;' );

    my $contentAreaHtml =
      &hashToCheckbox( 'contentArea', $const[$OC_CONTENT_AREA], 5 );
    my $gradeLevelHtml =
      &hashToCheckbox( 'gradeLevel', $const[$OC_GRADE_LEVEL], 14 );
    my %filteredDevStates =  map { $_ => $dev_states{$_} } grep { exists $dev_states{$_} } @dev_states_workflow_ordered_keys;
    my $devStateHtml = &hashToCheckbox( 'devState', \%filteredDevStates, 6 );
    my $editorHtml   = &hashToCheckbox( 'editor',   $editors,     5 );
    my $languageHtml = &hashToCheckbox( 'language', \%languages,  6 );

    my $reportType =
      ( defined $params->{reportType} ? $params->{reportType} : "" );
    my $typeHtml = &hashToSelect( 'reportType', \%reportTypes, $reportType,
        'doTypeChange();', '', '', 'font-size:11px;' );

    unless ( defined $params->{items} ) {
        $params->{items} = [];
    }

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Report</title>
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
        document.location.href='${thisUrl}?reportType=' + document.form1.reportType.options[document.form1.reportType.selectedIndex].value;
     }
      
			function doBankChange() {
		    document.location.href='${thisUrl}?reportType=${reportType}&itemBankId='
				                      + document.form1.itemBankId.options[document.form1.itemBankId.selectedIndex].value;
			}

      function doHtmlSubmit() {
        document.form1.myaction.value = '1';
	document.form1.submit();
	return true;
      }
      
      function doCsvSubmit() {
        document.form1.myaction.value = '2';
	document.form1.submit();
	return true;
      }
    //-->
    </script>
  </head>
  <body>
    ${msg}
    <form name="form1" action="${thisUrl}" method="POST" target="_blank">
      
      <input type="hidden" name="myaction" value="" />
    <div class="title">View Passage Report</div> 
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr><td>Report Type:</td><td>${typeHtml}</td></tr>
      <tr><td>Program:</td><td>${itemBankHtml}</td></tr>
    </table>
		<table border="1" cellpadding="1" cellspacing="1">
      <tr><td style="width:80px;">Content Area:</td><td style="width:400px;text-align:left;">${contentAreaHtml}</td></tr>
      <tr><td>Grade Level:</td><td>${gradeLevelHtml}</td></tr>
      <tr><td>Dev State:</td><td>${devStateHtml}</td></tr>
      <tr><td>Passage Writer:</td><td>${editorHtml}</td></tr>
      <tr><td>Language:</td><td>${languageHtml}</td></tr>
    </table>
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr>
        <td><input type="button" value="Get HTML Report" onClick="doHtmlSubmit();" /></td>
        <td><input type="button" value="Get CSV Report" onClick="doCsvSubmit();" /></td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE
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

    my $projectId =
      ( defined $params->{projectId} ? $params->{projectId} : '' );
    my $projectHtml =
      &hashToSelect( 'projectId', &getProjects( $dbh, $itemBankId ),
        $projectId, '', 'null:All' );

    my $contentAreaHtml =
      &hashToCheckbox( 'contentArea', $const[$OC_CONTENT_AREA], 5 );
    my $gradeLevelHtml =
      &hashToCheckbox( 'gradeLevel', $const[$OC_GRADE_LEVEL], 14 );
    my $devStateHtml = &hashToCheckbox( 'devState', \%dev_states, 6 );
    my $editorHtml   = &hashToCheckbox( 'editor',   $editors,     5 );
    my $languageHtml = &hashToCheckbox( 'language', \%languages,  6 );

    my $reportType =
      ( defined $params->{reportType} ? $params->{reportType} : "" );
    my $typeHtml = &hashToSelect( 'reportType', \%reportTypes, $reportType,
        'doTypeChange();', '' );

    unless ( defined $params->{items} ) {
        $params->{items} = [];
    }

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Report -- Pivot</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
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
      function doHtmlSubmit() {
        document.form1.myaction.value = '1';
	document.form1.submit();
	return true;
      }
      */
      
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
    <div class="title">View Passage Report</div> 
    <table style="margin-left:10px;" border="0" cellspacing="1" cellpadding="1">
      <tr><td>Report Type:</td><td>${typeHtml}</td></tr>
      <tr><td>Program:</td><td>${itemBankHtml}</td></tr>
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
			  <td>Dev State:</td><td>${devStateHtml}</td>
			</tr>
			<tr>
			  <td>Item Writer:</td><td>${editorHtml}</td>
			</tr>
      <tr><td>Language:</td><td>${languageHtml}</td></tr>
    </table>
    <br />
    <div class="title">2) Select Pivot Field <small>(Not a filter field)</small></div>
    <select name="pivotField">
      <option value="content_area">Content Area</option>
      <option value="grade_level">Grade Level</option>
      <option value="dev_state">Dev State</option>
      <option value="passage_writer">Item Writer</option>
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
        <td><input type="checkbox" name="report_dev_state" value="yes" /></td>
	<td align="left">Dev State</td>
      </tr>
    </table>
		    </td>
				<td valign="top">
		<table width="170px" border="0" cellspacing="1" cellpadding="1">
      <tr>
        <td><input type="checkbox" name="report_passage_writer" value="yes" /></td>
	<td align="left">Item Writer</td>
      </tr>
    </table>
		  </td></tr></table>
    <br />
    <table border="0" cellspacing="1" cellpadding="1">
      <tr>
        <!--
        <td><input type="button" value="Get HTML Report" onClick="doHtmlSubmit();" /></td>
        --> 
	<td colspan="2"><input type="button" class="button" value="Get CSV Report" onClick="doCsvSubmit();" /></td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE
}

sub print_completion_welcome {

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

    my $projectId =
      ( defined $params->{projectId} ? $params->{projectId} : '' );
    my $projectHtml =
      &hashToSelect( 'projectId', &getProjects( $dbh, $itemBankId ),
        $projectId, '', '' );

    my $contentArea =
      ( defined $params->{contentArea} ? $params->{contentArea} : "" );
    my $contentAreaHtml =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        $contentArea, '', 'null' );

    my $gradeLevel =
      ( defined $params->{gradeLevel} ? $params->{gradeLevel} : "" );
    my $gradeLevelHtml =
      &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], $gradeLevel, '',
        'null' );

    my $language = ( defined $params->{language} ? $params->{language} : "" );
    my $languageHtml =
      &hashToSelect( 'language', \%languages, $language, '', 'null' );

    my $reportType =
      ( defined $params->{reportType} ? $params->{reportType} : "" );
    my $typeHtml = &hashToSelect( 'reportType', \%reportTypes, $reportType,
        'doTypeChange();', '' );

    unless ( defined $params->{items} ) {
        $params->{items} = [];
    }

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Report -- Completion</title>
    <script language="JavaScript">
    <!--
      function myOpen(name,url,w,h)
      {
	var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(370,180);
	return true;
      }
  
      function doBankChange() {
		    document.location.href='${thisUrl}?reportType=4&itemBankId='
				                      + document.form1.itemBankId.options[document.form1.itemBankId.selectedIndex].value;
			}

     function doTypeChange() {
       if(document.form1.reportType.options[document.form1.reportType.selectedIndex].value != '4') 
       {
         document.location.href='${thisUrl}?reportType='
	                       + document.form1.reportType.options[document.form1.reportType.selectedIndex].value;
       }	 
     }

      /*
      function doHtmlSubmit() {
        document.form1.myaction.value = '1';
	document.form1.submit();
	return true;
      }
      */
      
      function doCsvSubmit() {
        document.form1.myaction.value = '2';
	document.form1.submit();
	return true;
      }
    //-->
    </script>
    <style type="text/css">
      td { width: 160px; 
           text-align: right; 
	   font-size: 14px;
	 } 

      body { font-size: 14px; }
      
      select { font-size: 14px; }

      div.text { font-size: 16px; color: blue; margin-bottom: 7px;}

      div.title { font-size: 14px; text-align: left; margin-bottom: 8px; margin-top: 5px;} 
    
      input.button { font-size: 14px; } 
    </style>
  </head>
  <body>
    ${msg}
    <form name="form1" action="${thisUrl}" method="POST" target="_blank">
      
      <input type="hidden" name="myaction" value="" />
    <div class="text">View Passage Report</div> 
    <table border="0" cellspacing="2" cellpadding="2">
      <tr><td>Report Type:</td><td>${typeHtml}</td></tr>
      <tr><td>Program:</td><td>${itemBankHtml}</td></tr>
			<tr><td colspan="2">&nbsp;</td></tr>
              <tr><td>Content Area:</td><td align="right">${contentAreaHtml}</td></tr>
              <tr><td>Grade Level:</td><td align="right">${gradeLevelHtml}</td></tr>
              <tr><td>Language:</td><td align="right">${languageHtml}</td></tr>
    </table>
    <br />
    <table border="0" cellspacing="1" cellpadding="1">
      <tr>
	<td colspan="2"><input type="button" class="button" value="Get CSV Report" onClick="doCsvSubmit();" /></td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE
}

sub print_standard_html_report {

    my $params = shift;
    my ( $header, $body, $footer, $viewPassageLink, $printPassageLink );
    my @viewIds = ();

    $header = <<END_HERE;
<html>
  <head>
    <title>Passage Report</title>
    <script language="JavaScript">
    <!--
      function myOpen(name,url,w,h)
      {
	var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(370,180);
	return true;
      }
    //-->
    </script>
  </head>
  <body>
END_HERE

    my @titles = ( 'Passage ID', 'Grade', 'Subject' );
    push @titles, 'Code';
    push( @titles, 'Language' ) unless $in{language} eq '';
    push( @titles, 'Genre' );
    push( @titles, 'Description' );
    push( @titles, 'Dev State' );
    push( @titles, 'Program <br>Metafiles' );
    push( @titles, 'Outdated<br> Program <br>Metafiles' );
    push( @titles, 'View' );

    $body =
        '<table border="1" cellpadding="3" cellspacing="3" style="border-collapse: collapse; empty-cells: show;">'
      . '<tr><th>'
      . join( '</th><th>', @titles )
      . '</th></tr>';

    foreach my $passage ( sort { $a cmp $b } @{ $params->{passages} } ) {
        my @fields = (
            $passage->{external_id},
            $passage->{grade_level},
            $passage->{content_area}
        );
        push @fields, $passage->{code};
        push( @fields, $passage->{language} ) unless $in{language} eq '';
        push( @fields, $passage->{genre} );
        push( @fields, $passage->{description} );
        push( @fields, $passage->{dev_state} );
        push( @fields, $passage->{mf_count} == '0' ? 'No' : 'Yes' );
        push( @fields, $passage->{mf_count} == '0' ? '' : ( $passage->{mf_outdated} eq 'Y' ? 'Yes' : 'No' )  );
        push @fields,
          '<input type="button" value="View" onClick="myOpen(\'passageWin\',\''
          . $orcaUrl
          . 'cgi-bin/passageView.pl?passageId='
          . $passage->{id}
          . '\',800,600);" />';

        $body .= '<tr><td>' . join( '</td><td>', @fields ) . '</td></tr>';
        push @viewIds, $passage->{external_id};
    }

    $body .= '</table>';

    my $passageList = join( ' ', @viewIds );

    $viewPassageLink =
'<p><a href="#" onClick="document.viewForm.submit();">Open in Item Viewer</a></p>';
    $printPassageLink =
'<p><a href="#" onClick="document.printForm.submit();">Open in Item Printer</a></p>';

    $footer = <<END_HERE;
	  <form name="viewForm" action="${orcaUrl}cgi-bin/itemView.pl" method="POST" target="_blank">
	    
			<input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
	    <input type="hidden" name="itemExternalId" value="${passageList}" />	
		</form>
	  <form name="printForm" action="${orcaUrl}cgi-bin/itemPrintList.pl" method="POST" target="_blank">
	    
			<input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
	    <input type="hidden" name="itemExternalId" value="${passageList}" />	
	    <input type="hidden" name="myAction" value="print" />	
		</form>
  </body>
</html>
END_HERE

    return $header . $body;

}

sub print_progress_html_report {

    my $params = shift;
    my ( $header, $body, $footer, $viewPassageLink, $printPassageLink );
    my @viewIds = ();

    $header = <<END_HERE;
<html>
  <head>
    <title>Item Report</title>
  </head>
  <body>
END_HERE

    $body = '<table border="1" cellpadding="3" cellspacing="3">';

    my @titles = ( 'Item ID', 'Subject', 'Grade' );

    #push(@titles,'Description');
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
    push( @titles, 'New Art' );
    push( @titles, 'Date/Time' );

    $body .= '<tr><th>' . join( '</th><th>', @titles ) . '</th></tr>';

    foreach my $item ( sort { $a cmp $b } @{ $params->{items} } ) {
        my @fields =
          ( $item->{external_id}, $item->{content_area}, $item->{grade_level} );

        #push(@fields,$item->{language}) unless $in{language} eq '';
        #push(@fields,$item->{description});
        push( @fields, $item->{dev_state} );
        push( @fields, $item->{passage_writer_user} );
        push( @fields, $item->{passage_writer_ts} );
        push( @fields, $item->{passage_writer_elapsed} );
        push( @fields, $item->{content_review_1_user} );
        push( @fields, $item->{content_review_1_ts} );
        push( @fields, $item->{content_review_1_elapsed} );
        push( @fields, $item->{content_review_2_user} );
        push( @fields, $item->{content_review_2_ts} );
        push( @fields, $item->{content_review_2_elapsed} );
        push( @fields, $item->{style_review_user} );
        push( @fields, $item->{style_review_ts} );
        push( @fields, $item->{style_review_elapsed} );
        push( @fields, $item->{content_approved_user} );
        push( @fields, $item->{content_approved_ts} );
        push( @fields, $item->{content_approved_elapsed} );
        push( @fields, $item->{copy_approved_user} );
        push( @fields, $item->{copy_approved_ts} );
        push( @fields, $item->{copy_approved_elapsed} );
        push( @fields, $item->{client_approved_user} );
        push( @fields, $item->{client_approved_ts} );
        push( @fields, $item->{client_approved_elapsed} );
        push( @fields, $item->{fix_art_user} );
        push( @fields, $item->{fix_art_ts} );
        push( @fields, $item->{new_art_user} );
        push( @fields, $item->{new_art_ts} );

        $body .= '<tr><td>' . join( '</td><td>', @fields ) . '</td></tr>';
        push @viewIds, $item->{external_id};
    }

    $body .= '</table>';

    my $itemList = join( ' ', @viewIds );

    $viewPassageLink =
'<p><a href="#" onClick="document.viewForm.submit();">Open in Item Viewer</a></p>';
    $printPassageLink =
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
      . $viewPassageLink
      . $printPassageLink
      . $body
      . $viewPassageLink
      . $printPassageLink
      . $footer;
}

sub print_standard_csv_report {

    my $psgi_out = '';

    my $params = shift;

    my @titles = ( 'Passage ID', 'Grade', 'Subject' );
    push @titles, 'Code';
    push( @titles, 'Language' ) unless $in{language} eq '';
    push( @titles, 'Genre' );
    push( @titles, 'Dev State' );
    push( @titles, 'Program Metafiles' );
    push( @titles, 'Outdated Program Metafiles' );

    $psgi_out .= join( ',', @titles ) . "\n";

    foreach my $passage ( sort { $a cmp $b } @{ $params->{passages} } ) {
        my @fields = (
            '"' . $passage->{external_id} . '"',
            $passage->{grade_level},
            $passage->{content_area}
        );
        push @fields, $passage->{code};
        push( @fields, $passage->{language} ) unless $in{language} eq '';
        push( @fields, $passage->{genre} );
        push( @fields, $passage->{dev_state} );
        push( @fields, $passage->{mf_count} == '0' ? 'No' : 'Yes' );
        push( @fields, $passage->{mf_count} == '0' ? '' : ( $passage->{mf_outdated} eq 'Y' ? 'Yes' : 'No' ) );
        $psgi_out .= join( ',', @fields ) . "\n";
    }
  return $psgi_out;
}

sub print_progress_csv_report {
    my $psgi_out = '';

    my $params = shift;

    my @titles = ( 'Item ID', 'Subject', 'Grade' );

    #push(@titles,'Description');
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
    push( @titles, 'New Art' );
    push( @titles, 'Date/Time' );

    $psgi_out .= join( ',', @titles ) . "\n";

    foreach my $item ( sort { $a cmp $b } @{ $params->{items} } ) {

        # Strip out commas from the data
        foreach my $key (
            qw/passage_writer_user
            content_review_1_user content_review_2_user style_review_user
            content_approved_user copy_approved_user client_approved_user
            fix_art_user new_art_user/
          )
        {
            $item->{$key} =~ s/,/./g;
            $item->{$key} =~ s/\s/ /g;
        }

        my @fields =
          ( $item->{external_id}, $item->{content_area}, $item->{grade_level} );

        #push(@fields,$item->{language}) unless $in{language} eq '';
        #push(@fields,$item->{description});
        push( @fields, $item->{dev_state} );
        push( @fields, $item->{passage_writer_user} );
        push( @fields, $item->{passage_writer_ts} );
        push( @fields, $item->{passage_writer_elapsed} );
        push( @fields, $item->{content_review_1_user} );
        push( @fields, $item->{content_review_1_ts} );
        push( @fields, $item->{content_review_1_elapsed} );
        push( @fields, $item->{content_review_2_user} );
        push( @fields, $item->{content_review_2_ts} );
        push( @fields, $item->{content_review_2_elapsed} );
        push( @fields, $item->{style_review_user} );
        push( @fields, $item->{style_review_ts} );
        push( @fields, $item->{style_review_elapsed} );
        push( @fields, $item->{content_approved_user} );
        push( @fields, $item->{content_approved_ts} );
        push( @fields, $item->{content_approved_elapsed} );
        push( @fields, $item->{copy_approved_user} );
        push( @fields, $item->{copy_approved_ts} );
        push( @fields, $item->{copy_approved_elapsed} );
        push( @fields, $item->{client_approved_user} );
        push( @fields, $item->{client_approved_ts} );
        push( @fields, $item->{client_approved_elapsed} );
        push( @fields, $item->{fix_art_user} );
        push( @fields, $item->{fix_art_ts} );
        push( @fields, $item->{new_art_user} );
        push( @fields, $item->{new_art_ts} );
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
                $psgi_out .=
"${fieldKeyString},$data->{$pivotKey}->{$field}->{$fieldKey},,,";
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

sub print_completion_csv_report {
  my $psgi_out = '';

    my $params              = shift;
    my $data                = shift;
    my $config              = &get_project_config( $params->{projectId} );
    my $minutesPerItemTotal = 0;
    my $remainingGrandTotal = 0;
    my $completedGrandTotal = 0;
    my $itemsTotal          = 0;

    # Print header
    $psgi_out .= "Task,Time,,,,,\n";

    foreach ( sort { $a <=> $b } keys %workStates ) {
        $psgi_out .=
"$dev_states{$workStates{$_}},$config->{workstates}{$workStates{$_}}{estimate},minutes per item,,,,\n";
        $minutesPerItemTotal +=
          $config->{workstates}{ $workStates{$_} }{estimate};
    }

    $psgi_out .= ",,,,,,\n,,,,,,\n";

    foreach my $grade ( sort { $a <=> $b } keys %$data ) {

        my $remainingTotal          = 0;
        my $remainingAggregateTotal = 0;
        my $completedTotal          = 0;

        my %completedStates = map { $_ => $workStates{$_} } keys %workStates;

        # Print section header
        $psgi_out .=
"$const[$OC_CONTENT_AREA]->{$params->{contentArea}} Grade $const[$OC_GRADE_LEVEL]->{$grade},,,Hours Remaining,Total Hours Remaining,,,Hours Completed\n";

        # Print totals by dev state
        foreach ( sort { $a <=> $b } keys %workStates ) {

            # don't include this state in the completed total
            delete $completedStates{$_};

            $itemsTotal += $data->{$grade}{ $workStates{$_} };

            my $remaining =
              $data->{$grade}{ $workStates{$_} } *
              $config->{workstates}{ $workStates{$_} }{estimate} / 60;
            my $remainingAggregate = 0;
            foreach ( my $i = 1 ; $i <= int($_) ; $i++ ) {
                $remainingAggregate +=
                  $data->{$grade}{ $workStates{$i} } *
                  $config->{workstates}{ $workStates{$_} }{estimate} / 60;
            }
            $remainingTotal          += $remaining;
            $remainingAggregateTotal += $remainingAggregate;

            my $completedItems = 0;
            foreach my $key ( keys %completedStates ) {
                next unless exists $data->{$grade}{ $workStates{$key} };
                $completedItems += $data->{$grade}{ $workStates{$key} };
            }

            my $completed =
              $completedItems *
              $config->{workstates}{ $workStates{$_} }{estimate} / 60;
            $completedTotal += $completed;

            $psgi_out .=f(
                "%s,%d,items,%d,%d,,,%d\n",
                $dev_states{ $workStates{$_} },
                $data->{$grade}{ $workStates{$_} },
                $remaining, $remainingAggregate, $completed
            );
        }

        #Print a totals and a separator
        $psgi_out .=f( ",,,%d,%d,,,%d\n,,,,,,,\n",
            $remainingTotal, $remainingAggregateTotal, $completedTotal );
        $remainingGrandTotal += $remainingTotal;
        $completedGrandTotal += $completedTotal;
    }

    #Print a separator
    $psgi_out .= ",,,,,,,\n";

    my $totalProjectHours = int( ( $itemsTotal * $minutesPerItemTotal ) / 60 );
    $psgi_out .= "Total Project Hours,${totalProjectHours},,,,,,\n";

    my $percentComplete = int(
        100 * (
            $completedGrandTotal /
              ( $remainingGrandTotal + $completedGrandTotal )
        )
    );
    $psgi_out .= "Percent Complete,${percentComplete}%,,,,,,\n";

    my $startDate = $config->{startDate};
    my $endDate   = $config->{endDate};
    $startDate =~ s/,//;
    $endDate   =~ s/,//;
    #print STDERR "Start = ${startDate}, End = ${endDate}";
    my $timeComplete = int(
        100 * (
            ( time - str2time($startDate) ) /
              ( str2time($endDate) - str2time($startDate) )
        )
    );
    $psgi_out .= "Time Complete,${timeComplete}%,,,,,,";
  return $psgi_out;
}

sub time2string {
    my $ts = shift;
    if ( $ts < 1 ) { return ''; }
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
1;
