package Action::itemDataUpload;

use ItemConstants;
use Item;
use Passage;
use Rubric;
use Data::Dumper;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $this_url = "${orcaUrl}cgi-bin/itemDataUpload.pl";
  
  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  our $allowImsIdUpload =
    ( $banks->{ $in{itemBankId} }{hasIMS}
        && !$banks->{ $in{itemBankId} }{assignIMSId} ) ? 1 : 0;
  
  our @fieldList =
    qw/itemId contentArea gradeLevel gradeSpanStart gradeSpanEnd itemDescription devState itemDifficulty
    itemFormat correctResponse itemDOK itemPoints passage rubric itemAuthor
    itemHandle itemScaleValue itemMapValue pubStatus calculator
    ruler protractor sourceDocument enemy readabilityIndex readOnly exportOk/;
  
  push( @fieldList, 'imsID' ) if $allowImsIdUpload;
  
  our %fieldDescriptions = (
      'itemId'                 => 'Item&nbsp;ID',
      'contentArea'            => 'Subject&nbsp;Area',
      'gradeLevel'             => 'Grade&nbsp;Level',
      'gradeSpanStart'         => 'Grade&nbsp;Span&nbsp;Start',
      'gradeSpanEnd'           => 'Grade&nbsp;Span&nbsp;End',
      'itemDescription'        => 'Description',
      'devState'               => 'Dev&nbsp;State',
      'itemDifficulty'         => 'Difficulty',
      'itemFormat'             => 'Format',
      'itemDOK'                => 'DOK',
      'itemPoints'             => 'Points',
      'project'                => 'Project',
      'gle'                    => 'GLE',
      'gleName'                => 'GLE Name',
      'passage'                => 'Passage',
      'rubric'                 => 'Rubric',
      'itemAuthor'             => 'Author',
      'correctResponse'        => 'Correct&nbsp;Answer',
      'itemBenchmark'          => 'Primary&nbsp;Benchmark',
      'itemSecondaryBenchmark' => 'Secondary&nbsp;Benchmark',
      'itemTertiaryBenchmark'  => 'Tertiary&nbsp;Benchmark',
      'itemCategory'           => 'Primary&nbsp;Category',
      'itemSecondaryCategory'  => 'Secondary&nbsp;Category',
      'itemTertiaryCategory'   => 'Tertiary&nbsp;Category',
      'itemHandle'             => 'Handle',
      'itemScaleValue'         => 'Scale&nbsp;Value',
      'itemMapValue'           => 'Map&nbsp;Value',
      'readOnly'               => 'Read&nbsp;Only',
      'exportOk'               => 'Export&nbsp;OK',
      'pubStatus'              => 'Pub&nbsp;Status',
      'calculator'             => 'Has&nbsp;Calculator',
      'ruler'                  => 'Has&nbsp;Ruler',
      'protractor'             => 'Has&nbsp;Protractor',
      'sourceDocument'         => 'Source&nbsp;Document',
      'enemy'                  => 'Item&nbsp;Enemy',
      'readabilityIndex'       => 'Readability&nbsp;Index',
      'compCurriculum'         => 'Comprehensive&nbsp;Curriculum',
  );
  
  $fieldDescriptions{imsID} = 'IMS&nbsp;ID' if $allowImsIdUpload;
  
  our %columnToField = (
      'Item ID'                  => 'itemId',
      'Subject Area'             => 'contentArea',
      'Grade Level'              => 'gradeLevel',
      'Grade Span Start'         => 'gradeSpanStart',
      'Grade Span End'           => 'gradeSpanEnd',
      'Description'              => 'itemDescription',
      'Dev State'                => 'devState',
      'Difficulty'               => 'itemDifficulty',
      'Format'                   => 'itemFormat',
      'DOK'                      => 'itemDOK',
      'Points'                   => 'itemPoints',
      'Project'                  => 'project',
      'GLE'                      => 'gle',
      'GLE Name'                 => 'gleName',
      'Passage'                  => 'passage',
      'Rubric'                   => 'rubric',
      'Author'                   => 'itemAuthor',
      'Correct Answer'           => 'correctResponse',
      'Primary Benchmark'        => 'itemBenchmark',
      'Secondary Benchmark'      => 'itemSecondaryBenchmark',
      'Tertiary Benchmark'       => 'itemTertiaryBenchmark',
      'Primary Category'         => 'itemCategory',
      'Secondary Category'       => 'itemSecondaryCategory',
      'Tertiary Category'        => 'itemTertiaryCategory',
      'Handle'                   => 'itemHandle',
      'Scale Value'              => 'itemScaleValue',
      'Map Value'                => 'itemMapValue',
      'Read Only'                => 'readOnly',
      'Export OK'                => 'exportOk',
      'Pub Status'               => 'pubStatus',
      'Has Calculator'           => 'calculator',
      'Has Ruler'                => 'ruler',
      'Has Protractor'           => 'protractor',
      'Source Document'          => 'sourceDocument',
      'Item Enemy'               => 'enemy',
      'Readability Index'        => 'readabilityIndex',
      'Comprehensive Curriculum' => 'compCurriculum',
  );
  
  $columnToField{'IMS ID'} = 'imsID' if $allowImsIdUpload;
  
  our %mutableFields = map { $_ => 1 }
    qw/itemId devState itemDifficulty itemDOK gle gleName
    itemBenchmark itemSecondaryBenchmark itemTertiaryBenchmark
    itemCategory itemSecondaryCategory itemTertiaryCategory
    itemHandle itemScaleValue itemMapValue exportOk project compCurriculum
    pubStatus sourceDocument enemy readabilityIndex/;
  
  our %fieldArrays = (
      'contentArea'    => $const[$OC_CONTENT_AREA],
      'gradeLevel'     => $const[$OC_GRADE_LEVEL],
      'gradeSpanStart' => $const[$OC_GRADE_SPAN_START],
      'gradeSpanEnd'   => $const[$OC_GRADE_SPAN_END],
      'devState'       => \%dev_states,
      'itemDifficulty' => \%difficulty_levels,
      'itemFormat'     => $const[$OC_ITEM_FORMAT],
      'itemDOK'        => $const[$OC_DOK],
      'itemPoints'     => $const[$OC_POINTS],
      'pubStatus'      => \%publication_status,
      'calculator'     => $const[$OC_CALCULATOR],
      'ruler'          => $const[$OC_RULER],
      'protractor'     => $const[$OC_PROTRACTOR],
      'exportOk'       => \%export_ok,
      'readOnly'       => \%read_only,
      'itemAuthor'     => &getEditors($dbh, $in{itemBankId}),
      'project'        => &getProjects( $dbh, $in{itemBankId})
  );
  
  our %fieldComments = (
      'itemId'      => 'The Item name (e.g. 9A12_2_MC01)',
      'contentArea' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map  { $const[$OC_CONTENT_AREA]->{$_} }
          sort { $a <=> $b } keys %{ $const[$OC_CONTENT_AREA] } )
        . '</li></ul>',
      'gradeLevel' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[$OC_GRADE_LEVEL]->{$_} }
          sort { $a <=> $b } keys %{ $const[$OC_GRADE_LEVEL] } )
        . '</li></ul>',
      'gradeSpanStart' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[56]->{$_} }
          sort { $a <=> $b } keys %{ $const[56] } )
        . '</li></ul>',
      'gradeSpanEnd' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[56]->{$_} }
          sort { $a <=> $b } keys %{ $const[56] } )
        . '</li></ul>',
      'itemDescription' => 'The text description',
      'devState'        => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map { $dev_states{$_} } grep { exists $dev_states{$_} } @dev_states_workflow_ordered_keys )
        . '</li></ul>',
      'itemDifficulty' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $difficulty_levels{$_} }
          sort { $a <=> $b } keys %difficulty_levels )
        . '</li></ul>',
      'itemFormat' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[$OC_ITEM_FORMAT]->{$_} }
          sort { $a <=> $b } keys %{ $const[$OC_ITEM_FORMAT] } )
        . '</li></ul>',
      'itemDOK' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[$OC_DOK]->{$_} }
          sort { $a <=> $b } keys %{ $const[$OC_DOK] } )
        . '</li></ul>',
      'itemPoints' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[$OC_POINTS]->{$_} }
            sort { $a <=> $b } keys %{ $const[$OC_POINTS] } )
        . '</li></ul>',
      'pubStatus' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $publication_status{$_} }
            sort { $a <=> $b } keys %publication_status )
        . '</li></ul>',
      'calculator' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[$OC_CALCULATOR]->{$_} }
            sort { $a <=> $b } keys %{ $const[$OC_CALCULATOR] } )
        . '</li></ul>',
      'ruler' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[$OC_RULER]->{$_} }
            sort { $a <=> $b } keys %{ $const[$OC_RULER] } )
        . '</li></ul>',
      'protractor' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map    { $const[$OC_PROTRACTOR]->{$_} }
            sort { $a <=> $b } keys %{ $const[$OC_PROTRACTOR] } )
        . '</li></ul>',
      'readOnly' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map { $read_only{$_} } sort { $a <=> $b } keys %read_only )
        . '</li></ul>',
      'exportOk' => 'One of:<br /><ul><li>'
        . join( '</li><li>',
          map { $export_ok{$_} } sort { $a <=> $b } keys %export_ok )
        . '</li></ul>',
      'gle' => 'The ID of the <a href="' 
        . $orcaUrl
        . 'cgi-bin/getItemsByStandard.pl" target="_blank">GLE Record</a> in the database',
      'gleName' =>
  'The GLE Subject, Grade/Course, and Name<br />',
      'passage' => 'The name of the associated Passage',
      'rubric'  => 'The name of the associated Rubric',
      'itemAuthor' =>
        'Item Writer\'s name, in the format "Last Name, First Name"',
      'project' => 'The name of a project',
      'correctResponse' =>
  "The correct response.<br />For multiple correct responses, use the '|' character as a separator",
      'itemBenchmark'          => 'The primary benchmark',
      'itemSecondaryBenchmark' => 'The secondary benchmark',
      'itemTertiaryBenchmark'  => 'The tertiary benchmark',
      'itemCategory'           => 'The primary category',
      'itemSecondaryCategory'  => 'The secondary category',
      'itemTertiaryCategory'   => 'The tertiary category',
      'itemHandle'             => 'The handle',
      'itemScaleValue'         => 'The scale value',
      'itemMapValue'           => 'The map value',
      'sourceDocument'         => 'The source documentation reference',
      'enemy'                  => 'The Item ID for an Item Enemy',
      'readabilityIndex'       => 'The readability index',
      'compCurriculum'         => 'The comprehensive curriculum',
      'imsID'                  => 'The ID assigned to this Item in the IMS system'
  );
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  our %currentItems    = ();
  our %currentPassages = ();
  our %currentRubrics  = ();
  our %readOnlyItems   = ();
  
  our %errorItems = ();
  
  our %columnMap = ();
  our %valueMap  = ();
  
  our $dataIsOkay     = 1;
  our @columnWarnings = ();
  
  our @createdItems    = ();
  our @updatedItems    = ();
  our @createdPassages = ();
  our @createdRubrics  = ();
  
  #
  # Find out which Items, Passages, Rubrics need to be updated vs. created
  #
  $sql =
      'SELECT i_id, i_external_id, i_read_only FROM item WHERE ib_id='
    . $in{itemBankId}
    . ' ORDER BY i_version DESC';
  $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {
  
      #
      # Only use the values from the latest item version
      #
      next if exists $currentItems{ $row->{i_external_id} };
  
      $currentItems{ $row->{i_external_id} } = $row->{i_id};
  
      $readOnlyItems{ $row->{i_external_id} } = 1 if $row->{i_read_only};
  }
  
  $sql = 'SELECT p_id, p_name FROM passage WHERE ib_id=' . $in{itemBankId};
  $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {
      $currentPassages{ $row->{p_name} } = $row->{p_id};
  }
  
  $sql =
    'SELECT sr_id, sr_name FROM scoring_rubric WHERE ib_id=' . $in{itemBankId};
  $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {
      $currentRubrics{ $row->{sr_name} } = $row->{sr_id};
  }
  
  #
  # Handle either the 'upload' or 'save' case
  #
  if ( $in{myAction} eq 'save' ) {
  
      &do_db_update();
      unlink( $in{uploadFile} );
  
      return [ $q->psgi_header('text/html'), [ &print_save_page() ]];
  }
  elsif ( $in{myAction} eq 'upload' ) {
  
      my $uploadHandle = $q->upload("myfile");
      $in{uploadFile} = "/tmp/itemdataupload.$$.txt";
  
      open UPLOADED, ">$in{uploadFile}";
      while (<$uploadHandle>) {
          print UPLOADED;
      }
      close UPLOADED;
 
      my $psgi_out = &print_confirm_header();
  
      open ITEMLIST, "<$in{uploadFile}";
  
      # check the header row to establish field/column mapping
      my $headerRow = <ITEMLIST>;
      $headerRow =~ s/\s+$//;
      &check_input_header($headerRow);
      $psgi_out .= &print_confirm_table_header();
  
      while (<ITEMLIST>) {
          $_ =~ s/\s+$//;
          last if $_ eq '';
  
          $psgi_out .= &check_input_record($_);
      }
  
      close ITEMLIST;
  
      unless ($dataIsOkay) {
          unlink( $in{uploadFile} );
      }
  
      $psgi_out .= &print_confirm_footer();

      return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
}
### ALL DONE! ###

sub check_input_record {
  my $psgi_out = '';

    my $record = shift;
    my @data = split( /,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/, $record );
    foreach (@data) { $_ =~ s/^"(.*)"$/$1/ if $_ =~ /^"(.*)"$/; }

    return if $data[0] eq '';

    $psgi_out .= '<tr>';

    my @editingColumns = values %columnMap;

    foreach my $key ( sort { $a <=> $b } keys %columnMap ) {
        my $column = $columnMap{$key};

        my $goodRange = 1;

        # range check the input value
        if ( exists $fieldArrays{$column} ) {
            my %valueChecker = reverse %{ $fieldArrays{$column} };
            unless ( exists( $valueChecker{ $data[$key] } )
                or not( defined( $data[$key] ) )
                or $data[$key] eq '' )
            {

                #warn "${column} is out of range," . $data[$key];
                $goodRange  = 0;
                $dataIsOkay = 0;
            }
        }

        $psgi_out .= '<td>';

        if ( not( defined( $data[$key] ) ) or $data[$key] eq '' ) {
            $psgi_out .= '&nbsp;';
        }
        else {

            if ( $column eq 'itemId' ) {

                # We don't allow spaces or periods in item names
                $data[$key] =~ s/[\s]/_/g;

                if ( exists $currentItems{ $data[$key] } ) {
                    if ( exists $readOnlyItems{ $data[$key] } ) {

                        my $canEditThisItem = 1;
                        foreach ( values %columnMap ) {
                            $canEditThisItem = 0
                              unless exists $mutableFields{$_};
                        }

                        if ($canEditThisItem) {
                            $psgi_out .= $data[$key];
                        }
                        else {
                            $dataIsOkay = 0;
                            $psgi_out .= '<span style="color:red;">'
                              . $data[$key]
                              . '</span>';
                        }

                    }
                    else {
                        $psgi_out .= $data[$key];
                    }
                }
                else {
                    $psgi_out .= '<span style="color:blue;">'
                      . $data[$key]
                      . '</span>';
                }
            }
            elsif ( $column eq 'passage' ) {
                if ( exists $currentPassages{ $data[$key] } ) {
                    $psgi_out .= $data[$key];
                }
                else {
                    $psgi_out .= '<span style="color:blue;">'
                      . $data[$key]
                      . '</span>';
                }
            }
            elsif ( $column eq 'rubric' ) {
                if ( exists $currentRubrics{ $data[$key] } ) {
                    $psgi_out .= $data[$key];
                }
                else {
                    $psgi_out .= '<span style="color:blue;">'
                      . $data[$key]
                      . '</span>';
                }
            }
            elsif ( $column eq 'gleName' ) {
                $psgi_out .= '<span style="color:red;">' . $data[$key] . '</span>';
            }
            elsif ( not $goodRange ) {
                $psgi_out .= '<span style="color:red;">' . $data[$key] . '</span>';
            }
            else {
                $psgi_out .= $data[$key];
            }
        }

        $psgi_out .= '</td>';
    }

    $psgi_out .= '</tr>';

  return $psgi_out;
}

sub do_db_update {

    open ITEMLIST, "<$in{uploadFile}";

    # check the header row to establish field/column mapping
    my $headerRow = <ITEMLIST>;
    $headerRow =~ s/\s+$//;
    &check_input_header($headerRow);

    while (<ITEMLIST>) {
        $_ =~ s/\s+$//;
        &save_input_record($_);
    }

    close ITEMLIST;
}

sub save_input_record {
    my $record = shift;
    my @data = split( /,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/, $record );
    foreach (@data) { $_ =~ s/^"(.*)"$/$1/ if $_ =~ /^"(.*)"$/; }

    return if ( not( defined( $data[0] ) ) or $data[0] eq '' );

    my $item;
    my $itemName = '';

    #
    # First, cycle through the data to get the item ID
    #
    foreach my $key ( sort { $a <=> $b } keys %columnMap ) {
        my $field = $columnMap{$key};
        if ( $field eq 'itemId' ) {
            $itemName = $data[$key];
            $itemName =~ s/\s+$//;
            $itemName =~ s/[\s]/_/g;
        }
    }

    #
    # Next, create the item if needed
    #
    if ( exists $currentItems{$itemName} ) {
        $item = new Item( $dbh, $currentItems{$itemName} );
        push @updatedItems, $itemName;
    }
    else {
        $item = new Item($dbh);
        $item->create( $in{itemBankId}, $itemName, undef, $user->{writer_code} );
	$itemName = $item->{name};
        push @createdItems, $itemName;
    }

    #
    # Next, update the item object as appropriate
    #
    foreach my $key ( sort { $a <=> $b } keys %columnMap ) {

        next if ( not( defined( $data[$key] ) ) or $data[$key] eq '' );

        my $field = $columnMap{$key};

        # Do a value lookup if needed
        if ( exists $fieldArrays{$field} ) {
            my %valArray = reverse %{ $fieldArrays{$field} };
            $data[$key] = $valArray{ $data[$key] };
        }

        if ( $field eq 'itemDescription' ) {
            $item->setDescription( $data[$key] );
        }
        elsif ( $field eq 'devState' ) {
            $item->setDevState( $data[$key] );
        }
        elsif ( $field eq 'itemDifficulty' ) {
            $item->setDifficulty( $data[$key] );
        }
        elsif ( $field eq 'correctResponse' ) {
            $item->setCorrect( $data[$key] );
        }
        elsif ( $field eq 'contentArea' ) {
            $item->setContentArea( $data[$key] );
        }
        elsif ( $field eq 'gradeLevel' ) {
            $item->setGradeLevel( $data[$key] );
        }
        elsif ( $field eq 'gradeSpanStart' ) {
            $item->setGradeSpanStart( $data[$key] );
        }
        elsif ( $field eq 'gradeSpanEnd' ) {
            $item->setGradeSpanEnd( $data[$key] );
        }
        elsif ( $field eq 'itemDOK' ) {
            $item->setDOK( $data[$key] );
        }
        elsif ( $field eq 'itemBenchmark' ) {
            $data[$key] =~ /(\d+)/;
            $item->updateChar( $OC_BENCHMARK, $1 || 0 );
        }
        elsif ( $field eq 'itemSecondaryBenchmark' ) {
            $data[$key] =~ /(\d+)/;
            $item->updateChar( $OC_SECONDARY_BENCHMARK, $1 || 0 );
        }
        elsif ( $field eq 'itemTertiaryBenchmark' ) {
            $data[$key] =~ /(\d+)/;
            $item->updateChar( $OC_TERTIARY_BENCHMARK, $1 || 0 );
        }
        elsif ( $field eq 'itemCategory' ) {
            $data[$key] =~ /(\d+)/;
            $item->updateChar( $OC_CATEGORY, $1 || 0 );
        }
        elsif ( $field eq 'itemSecondaryCategory' ) {
            $data[$key] =~ /(\d+)/;
            $item->updateChar( $OC_SECONDARY_CATEGORY, $1 || 0 );
        }
        elsif ( $field eq 'itemTertiaryCategory' ) {
            $data[$key] =~ /(\d+)/;
            $item->updateChar( $OC_TERTIARY_CATEGORY, $1 || 0 );
        }
        elsif ( $field eq 'itemHandle' ) {
            $item->setHandle( $data[$key] );
        }
        elsif ( $field eq 'itemScaleValue' ) {
            $item->setScaleValue( $data[$key] );
        }
        elsif ( $field eq 'itemMapValue' ) {
            $item->setMapValue( $data[$key] );
        }
        elsif ( $field eq 'itemFormat' ) {
            $item->setItemFormat( $data[$key] );
        }
        elsif ( $field eq 'itemPoints' ) {
            $item->setPoints( $data[$key] );
        }
        elsif ( $field eq 'pubStatus' ) {
            $item->setPublicationStatus( $data[$key] );
        }
        elsif ( $field eq 'calculator' ) {
            $item->setCalculator( $data[$key] );
        }
        elsif ( $field eq 'ruler' ) {
            $item->setRuler( $data[$key] );
        }
        elsif ( $field eq 'protractor' ) {
            $item->setProtractor( $data[$key] );
        }
        elsif ( $field eq 'sourceDocument' ) {
            $item->setSourceDoc( $data[$key] );
        }
        elsif ( $field eq 'compCurriculum' ) {
            $item->setComprehensiveCurriculum( $data[$key] );
        }
        elsif ( $field eq 'readOnly' ) {
            $item->setReadOnly( $data[$key] );
        }
        elsif ( $field eq 'exportOk' ) {
            $item->setExportOk( $data[$key] );
        }
        elsif ( $field eq 'imsID' ) {
            $item->setIMSId( $data[$key] );
        }
        elsif ( $field eq 'itemAuthor' ) {
            $item->setAuthor( $data[$key] );
        }
        elsif ( $field eq 'project' ) {
            $item->setProject( $data[$key] );
        }
	elsif ( $field eq 'readabilityIndex') {
	  $item->setReadabilityIndex( $data[$key] );
	}
        elsif ( $field eq 'gle' ) {
            $item->updateChar( $OC_ITEM_STANDARD, $data[$key] );
            $item->updateChar(
                $OC_CONTENT_STANDARD,
                &getContentStandard(
                    $dbh, $data[$key], $item->{$OC_CONTENT_AREA} || 1
                )
            );
        }
        elsif ( $field eq 'passage' ) {
            my $passageId;

            if ( exists $currentPassages{ $data[$key] } ) {
                $passageId = $currentPassages{ $data[$key] };
            }
            else {
                my $passage = new Passage($dbh);
                $passage->create( $in{itemBankId}, $data[$key] );
                $passageId = $passage->{id};
                $currentPassages{ $data[$key] } = $passageId;
                push @createdPassages, $data[$key];

                unless ( $item->{$OC_CONTENT_AREA} eq '' ) {
                    $passage->setContentArea( $item->{$OC_CONTENT_AREA} );
                }
                unless ( $item->{$OC_GRADE_LEVEL} eq '' ) {
                    $passage->setGradeLevel( $item->{$OC_GRADE_LEVEL} );
                }

                $passage->save();
            }

            $item->insertChar( $OC_PASSAGE, $passageId );

        }
        elsif ( $field eq 'rubric' ) {
            my $rubricId;

            if ( exists $currentRubrics{ $data[$key] } ) {
                $rubricId = $currentRubrics{ $data[$key] };
            }
            else {
                my $rubric = new Rubric($dbh);
                $rubric->create( $in{itemBankId}, $data[$key] );
                $rubricId = $rubric->{id};
                $currentRubrics{ $data[$key] } = $rubricId;
                push @createdRubrics, $data[$key];

                unless ( $item->{$OC_CONTENT_AREA} eq '' ) {
                    $rubric->setContentArea( $item->{$OC_CONTENT_AREA} );
                }
                unless ( $item->{$OC_GRADE_LEVEL} eq '' ) {
                    $rubric->setGradeLevel( $item->{$OC_GRADE_LEVEL} );
                }

                $rubric->save();
            }

            $item->insertChar( $OC_RUBRIC, $rubricId );
        }
	elsif ( $field eq 'enemy' ) {

          my $itemEnemyId = &getCurrentItemIdByName($dbh, $item->{bankId}, $data[$key]); 

	  $sql = <<SQL;
	  SELECT * FROM item_characterization WHERE i_id=$item->{id} AND ic_type=$OC_ITEM_ENEMY AND ic_value=$itemEnemyId
SQL
          $sth = $dbh->prepare($sql);
          $sth->execute();

          unless($sth->fetchrow_hashref) {

            $sql = <<SQL;
            INSERT INTO item_characterization SET i_id=$item->{id}, ic_type=$OC_ITEM_ENEMY, ic_value=$itemEnemyId
SQL
            $sth = $dbh->prepare($sql);
            $sth->execute();

            $sql = <<SQL;
            INSERT INTO item_characterization SET i_id=$itemEnemyId, ic_type=$OC_ITEM_ENEMY, ic_value=$item->{id}
SQL
            $sth = $dbh->prepare($sql);
            $sth->execute();
          }	
	}
    }

    $item->save('Item Data Upload', $user->{id}, 'Metadata Update');
}

sub print_welcome {
  my $psgi_out = '';

    my $params = shift;

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $defaultBank =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : 0 );
    my $ibankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $defaultBank, 'doReload();', '',
        'value' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Item Data Upload</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">

    function doSubmit() {
            if( document.itemUpload.myfile.value.match(/^\\s*\$/) ) {
                alert( 'Please select a file to upload.' );
                document.itemUpload.myfile.focus();
                return false;
            }
	    document.itemUpload.submit();
    }	

			function doReload() {
			  document.itemUpload.myAction.value = '';
				document.itemUpload.submit();
			}

		</script>
	</head>
  <body>
    <div class="title">Item Data Upload</div>
    <form name="itemUpload" action="${this_url}" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="myAction" value="upload" />
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr><td><span class="text">Program:</span></td><td>${ibankDisplay}</td></tr>
			<tr><td><span class="text">Upload File:</span></td><td><input type="file" name="myfile" /></td></tr> 
			<tr>
        <td>&nbsp;</td>
         <td><input type="button" value="Upload Item Data" onClick="doSubmit();" />
        </td>
      </tr>
    </table>
    </form>
		<br />
		<h4><span class="text">Instructions:</span></h4>
		<p>All Items, Passages, and Rubrics will be updated if they exist or created if they do not exist. 
		   If an Item, Passage, or Rubric needs to be created, the ID will be displayed in <span style="color:blue;">
			 blue</span>. The only required field is Item ID (although it would make little sense to not include at least 
			 one other field).</p>
		<p>A field (column) may be listed multiple times. For example, if you include 2 'Passage' fields,
		   then both of the Passages will be assigned to the Item  (and created if they do not exist).
		</p>
		<p>You will receive a full listing of the potential changes to be made, so that you may correct
		   any errors before completing the update. Values which are out of range will be displayed in 
			 <span style="color:red;">red</span>. If the Item is read-only, the Item ID will be displayed
			 in <span style="color:red;">red</span>.
		</p>	 
		<p>The name of the field must be the first row of the column (they are both case- and space-sensitive).
		   Columns may appear in any order, <em>except</em> that the <b>Item ID</b> column must be first.</p>
		<br />
		<h4><span class="text">List of Valid Fields:</span></h4>
		<table border="0" cellspacing="3" cellpadding="3" class="no-style">
END_HERE

    foreach (@fieldList) {
        $psgi_out .= <<END_HERE;
<tr>
  <td style="vertical-align:top;text-align:right;"><b>$fieldDescriptions{$_}</b></td>
	<td style="vertical-align:top;text-align:left;">$fieldComments{$_}</td>
</tr>	
END_HERE
    }

    $psgi_out .= <<END_HERE;
	  </table>
  </body>
</html>         
END_HERE

  return $psgi_out;
}

sub print_confirm_header {
    my $ibankName = $banks->{ $in{itemBankId} }{name};

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Item Data Upload</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">

      function doSubmit() {
				document.itemUpload.submit();
			}	

		</script>
	</head>
  <body>
    <div class="title">Data Upload Summary</div>
    <p><b>Program:</b>&nbsp;${ibankName}</p> 
		<form name="itemUpload" action="${this_url}" method="POST">
     <input type="hidden" name="myAction" value="save" />
     <input type="hidden" name="itemBankId" value="$in{itemBankId}" />
     <input type="hidden" name="uploadFile" value="$in{uploadFile}" />
		<table border="1" cellspacing="3" cellpadding="1">
END_HERE
}

sub check_input_header {
    my $header = shift;
    my @fieldList = split( /,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/, $header );
    foreach (@fieldList) { $_ =~ s/^"(.*)"$/$1/ if $_ =~ /^"(.*)"$/; }

    my $i = 0;
    foreach (@fieldList) {
        $columnMap{$i} = $columnToField{$_} if exists $columnToField{$_};
        push( @columnWarnings, "Column '$_' is not recognized." )
          unless exists $columnToField{$_};
        $i++;
    }
}

sub print_confirm_table_header {
    return '<tr><th>'
      . join( '</th><th>',
        map  { $fieldDescriptions{ $columnMap{$_} } }
        sort { $a <=> $b } keys %columnMap )
      . '</th></tr>';
}

sub print_confirm_footer {
  my $psgi_out = '';

    $psgi_out .= '</table>';

    if ($dataIsOkay) {
        $psgi_out .= <<END_HERE;
		<br />
		<input type="button" value="Save These Changes" onClick="document.itemUpload.submit();" />
		<br />
END_HERE
    }
    else {
        $psgi_out .= <<END_HERE;
		<br />
		<input type="button" value="Upload New File" onClick="document.location.href='${orcaUrl}cgi-bin/itemDataUpload.pl?itemBankId=$in{itemBankId}';" />
    <br />	
END_HERE
    }

    $psgi_out .= '</form>';

    if ( scalar @columnWarnings ) {
        $psgi_out .= '<ul><li>' . join( '</li><li>', @columnWarnings ) . '</li></ul>';
    }

    $psgi_out .= '</body></html>';
  return $psgi_out;
}

sub print_save_page {
  my $psgi_out = '';

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Item Data Upload</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
	</head>
  <body>
    <div class="title">Item Data Uploaded</div>
END_HERE

    if ( scalar @createdItems ) {
        $psgi_out .= '<p><b>Created these Items:</b></p><ul><li>'
          . join( '</li><li>', @createdItems ) . '</ul>';
    }

    if ( scalar @updatedItems ) {
        $psgi_out .= '<p><b>Updated these Items:</b></p><ul><li>'
          . join( '</li><li>', @updatedItems ) . '</ul>';
    }

    if ( scalar @createdPassages ) {
        $psgi_out .= '<p><b>Created these Passages:</b></p><ul><li>'
          . join( '</li><li>', @createdPassages ) . '</ul>';
    }

    if ( scalar @createdRubrics ) {
        $psgi_out .= '<p><b>Created these Rubrics:</b></p><ul><li>'
          . join( '</li><li>', @createdRubrics ) . '</ul>';
    }

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
