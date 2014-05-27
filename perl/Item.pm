package Item;

use URI::Escape;
use DBI;
use Digest::SHA;
use UrlConstants;
use ItemConstants;
use Program;
use File::Glob ':glob';
use File::Copy 'cp';
use MIME::Lite;

use constant {
	MAX_LENGTH_ITEM_NAME => 256,
};

#
# Constructor has 2 options
# 1) DB handle
# 2) Item ID
#
# OR
# 1) DB handle
# 2) Item Bank ID
# 3) Item Name
sub new {

    my ($type) = shift;
    my ($self) = {};
    $self->{dbh}     = shift;
    $self->{id}      = shift || 0;
    $self->{name}    = shift || '';
    $self->{version} = shift;
    $self->{version} = -1 unless defined $self->{version};

    my $loadDefaults = 1;

    if ( $self->{id} > 0 ) {
        my $sql = 'SELECT * FROM item WHERE '
          . (
            $self->{name} eq '' ? "i_id=$self->{id}"
            : 'i_external_id='
              . $self->{dbh}->quote( $self->{name} )
              . " AND ib_id=$self->{id}"
              . (
                $self->{version} == -1 ? " ORDER BY i_version DESC LIMIT 1"
                : " AND i_version=$self->{version}"
              )
          );
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute();

        if ( my $row = $sth->fetchrow_hashref ) {

            #$self->{bank} = new Program($self->{dbh},$row->{ib_id});

            $self->{bankId} = $row->{ib_id};
            $sql = qq| 	SELECT * FROM item_bank ib, organization o 
			WHERE ib_id=? AND ib.o_id = o.o_id
		     |;
            my $sth2 = $self->{dbh}->prepare($sql);
            $sth2->execute($row->{ib_id});
            if ( my $row2 = $sth2->fetchrow_hashref ) {
                $self->{bankName} = $row2->{ib_external_id};
                $self->{org_id}   = $row2->{o_id};
                $self->{org_name} = $row2->{o_name};
            }

            $self->{id}           = $row->{i_id};
            $self->{version}      = $row->{i_version};
            $self->{name}         = $row->{i_external_id};
            $self->{type}         = $row->{i_type} || 1;
            $self->{format}       = $row->{i_format} || 1;
            $self->{description}  = $row->{i_description};
            $self->{devState}     = $row->{i_dev_state};
            $self->{devStateName} = $dev_states{$row->{i_dev_state}};
            $self->{difficulty}   = $row->{i_difficulty};
            $self->{notes}        = $row->{i_notes};
            $self->{sourceDoc}    = $row->{i_source_document};
            $self->{author}       = $row->{i_author};
            $self->{lastUser}     = $row->{i_last_save_user_id};
            $self->{lang}    	  = $row->{i_lang};

            if ( $self->{author} ) {
                $sql =
                  'SELECT * FROM user WHERE u_id=' . $row->{i_author};
                $sth2 = $self->{dbh}->prepare($sql);
                $sth2->execute();
                if ( my $row2 = $sth2->fetchrow_hashref ) {
                    $self->{authorName}  = "$row2->{u_last_name}, $row2->{u_first_name}";
                    $self->{authorEmail} = $row2->{u_email};
                }
            }

            $self->{correct}           = $row->{i_correct_response};
            $self->{reviewLock}        = $row->{i_review_lock};
            $self->{reviewLifetime}    = $row->{i_review_lifetime};
            $self->{project}           = $row->{ip_id} || 0;
            $self->{publicationStatus} = $row->{i_publication_status} || 0;
            $self->{imsID}             = $row->{i_ims_id};
            $self->{version}           = $row->{i_version};
            $self->{readOnly}          = $row->{i_read_only};
            $self->{exportOk}          = $row->{i_export_ok};
            $self->{handle}            = $row->{i_handle};
            $self->{rawXML}            = $row->{i_xml_data};
            $self->{formName}          = $row->{i_form_name};
            $self->{formSession}       = $row->{i_form_session};
            $self->{formSequence}      = $row->{i_form_sequence};
	    $self->{due_date}	       = (defined $row->{i_due_date} && $row->{i_due_date} ne '0000-00-00') 
	                                  ? $row->{i_due_date} : '';
            $self->{readability_index} = $row->{i_readability_index};
	    $self->{max_content_id} = $row->{i_max_content_id};
            $self->{documentReadyFunction} = '';
	    $self->{stylesheet} = $row->{i_stylesheet_url};
	    $self->{qtiXml} = $row->{i_qti_xml_data};
	    $self->{metadataXml} = $row->{i_metadata_xml};

            $self->{standards} = [];
            for ( 1 .. 3 ) {
                my $standard = {
                    'gle'             => 0,
                    'gleNumber'       => 0,
                    'benchmark'       => 0,
                    'category'        => 0,
                    'contentStandard' => 0
                };
                push @{ $self->{standards} }, $standard;
            }

            $self->{passages}     = [];
            $self->{rubrics}      = [];
            $self->{stems}        = [];
            $self->{choices}      = [];
            $self->{distractors}  = [];
            $self->{shortAnswers} = [];
	    $self->{prompt} = {};
	    $self->{enemies} = [];

            $self->{hasNotes} = 0;

            $sql =
"SELECT i_id FROM item_status WHERE i_id=$self->{id} AND i_notes != '' LIMIT 1";
            $sth = $self->{dbh}->prepare($sql);
            $sth->execute();
            if ( $row = $sth->fetchrow_hashref ) {
                $self->{hasNotes} = 1;
            }

            $sql = "SELECT * FROM item_characterization WHERE i_id=$self->{id}";
            $sth = $self->{dbh}->prepare($sql);
            $sth->execute();
            while ( $row = $sth->fetchrow_hashref ) {
                next
                  unless defined( $row->{ic_type} )
                      && (   defined( $row->{ic_value} )
                          || defined( $row->{ic_value_str} ) );

                if ( $row->{ic_type} == $OC_CONTENT_AREA ) {
                    $self->{$OC_CONTENT_AREA} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_GRADE_LEVEL ) {
                    $self->{$OC_GRADE_LEVEL} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_GRADE_SPAN_START ) {
                    $self->{$OC_GRADE_SPAN_START} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_GRADE_SPAN_END ) {
                    $self->{$OC_GRADE_SPAN_END} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_SCORING_METHOD ) {
                    $self->{$OC_SCORING_METHOD} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_ITEM_FORMAT ) {
                    $self->{$OC_ITEM_FORMAT} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_SCALE_VALUE ) {
                    $self->{$OC_SCALE_VALUE} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_MAP_VALUE ) {
                    $self->{$OC_MAP_VALUE} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_POINTS ) {
                    $self->{$OC_POINTS} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_DOK ) {
                    $self->{$OC_DOK} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_PROTRACTOR ) {
                    $self->{$OC_PROTRACTOR} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_RULER ) {
                    $self->{$OC_RULER} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_CALCULATOR ) {
                    $self->{$OC_CALCULATOR} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_COMPASS ) {
                    $self->{$OC_COMPASS} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_MINOR_EDIT ) {
                    $self->{$OC_MINOR_EDIT} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_COMP_CURRICULUM ) {
                    $self->{$OC_COMP_CURRICULUM} = $row->{ic_value_str};
                }
                elsif ( $row->{ic_type} == $OC_DEFAULT_ANSWER ) {
                    $self->{$OC_DEFAULT_ANSWER} = $row->{ic_value_str};
                }
                elsif ( $row->{ic_type} == $OC_LAYOUT ) {
                    $self->{$OC_LAYOUT} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_FORM_GROUP ) {
                    $self->{$OC_FORM_GROUP} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_ANSWER_FORMAT ) {
                    $self->{$OC_ANSWER_FORMAT} = $row->{ic_value_str};
                }
                elsif ( $row->{ic_type} == $OC_ITEM_STANDARD ) {
                    $self->{standards}[0]{gle} = $row->{ic_value};
                    $self->{standards}[0]{gleNumber} =
                      &getGLENumber( $self->{dbh}, $row->{ic_value} );
                }
                elsif ( $row->{ic_type} == $OC_SECONDARY_STANDARD ) {
                    $self->{standards}[1]{gle} = $row->{ic_value};
                    $self->{standards}[1]{gleNumber} =
                      &getGLENumber( $self->{dbh}, $row->{ic_value} );
                }
                elsif ( $row->{ic_type} == $OC_TERTIARY_STANDARD ) {
                    $self->{standards}[2]{gle} = $row->{ic_value};
                    $self->{standards}[2]{gleNumber} =
                      &getGLENumber( $self->{dbh}, $row->{ic_value} );
                }
                elsif ( $row->{ic_type} == $OC_BENCHMARK ) {
                    $self->{standards}[0]{benchmark} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_SECONDARY_BENCHMARK ) {
                    $self->{standards}[1]{benchmark} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_TERTIARY_BENCHMARK ) {
                    $self->{standards}[2]{benchmark} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_CATEGORY ) {
                    $self->{standards}[0]{category} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_SECONDARY_CATEGORY ) {
                    $self->{standards}[1]{category} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_TERTIARY_CATEGORY ) {
                    $self->{standards}[2]{category} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_CONTENT_STANDARD ) {
                    $self->{standards}[0]{contentStandard} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_SECONDARY_CONTENT_STANDARD ) {
                    $self->{standards}[1]{contentStandard} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_TERTIARY_CONTENT_STANDARD ) {
                    $self->{standards}[2]{contentStandard} = $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_PASSAGE ) {
                    push @{ $self->{passages} }, $row->{ic_value};
                }
                elsif ( $row->{ic_type} == $OC_RUBRIC ) {
                    push @{ $self->{rubrics} }, $row->{ic_value};
                } elsif ($row->{ic_type} == $OC_ITEM_ENEMY) {
		    push @{ $self->{enemies} }, $row->{ic_value};
                } elsif ($row->{ic_type} == $OC_CHOICE_SHUFFLE) {
		    $self->{$OC_CHOICE_SHUFFLE} = $row->{ic_value};
		}
            }

            $self->{rejectReason} = '';
            if (
                -e "${orcaPath}workflow/rejection-report/state-9/$self->{id}.html"
              )
            {
                open REJECT,
"<${orcaPath}workflow/rejection-report/state-9/$self->{id}.html";
                while (<REJECT>) {
                    $self->{rejectReason} .= $_;
                }
                close REJECT;
                $self->{rejectReason} =~ /<textarea[^>]+>(.+)<\/textarea>/s;
                $self->{rejectReason} = $1;
            }

            # get the item body

            $sql = 'SELECT * FROM item_fragment WHERE i_id=' . $self->{id} . ' AND if_type=' . $IF_STEM;
            $sth = $self->{dbh}->prepare($sql);
            $sth->execute();

            if ( my $row = $sth->fetchrow_hashref ) {

              my $frag = {};
	      $frag->{id} = $row->{if_id};
	      $frag->{text} = $row->{if_text};
	      $frag->{name} = $row->{if_identifier};
              $frag->{attributes} = $row->{if_attribute_list};

	      $self->{item_body}{content} = $frag;
            }

	    # get the interactions

	    $sql = 'SELECT * FROM item_interaction WHERE i_id=' . $self->{id};
            $sth = $self->{dbh}->prepare($sql);
            $sth->execute();

            while ( my $row = $sth->fetchrow_hashref ) {
 
              my $ii = {};
	      $ii->{name} = $row->{ii_name};
	      $ii->{type} = $row->{ii_type};
	      $ii->{max_score} = $row->{ii_max_score};
	      $ii->{score_type} = $row->{ii_score_type};
	      $ii->{correct} = $row->{ii_correct};
	      $ii->{correct_map} = $row->{ii_correct_map};
	      $ii->{attributes} = $row->{ii_attribute_list};
	      $ii->{content}{prompt} = {};
	      $ii->{content}{choices} = [];
	      $ii->{content}{distractorRationale} = [];
	      $ii->{content}{setChoices} = [];

              $sql = 'SELECT * FROM item_fragment WHERE ii_id=' . $row->{ii_id} . ' ORDER BY if_set_seq, if_seq';
              my $sth2 = $self->{dbh}->prepare($sql);
              $sth2->execute();

              while ( my $row2 = $sth2->fetchrow_hashref ) {

                my $frag = {};
	        $frag->{id} = $row2->{if_id};
	        $frag->{text} = $row2->{if_text};
	        $frag->{name} = $row2->{if_identifier};
                $frag->{attributes} = $row2->{if_attribute_list};

	        if($row2->{if_type} == $IF_PROMPT) {
		  $ii->{content}{prompt} = $frag;
		} 
	        elsif($row2->{if_type} == $IF_CHOICE) {
                  push (@{$ii->{content}{choices}}, $frag);  
		} 
	        elsif($row2->{if_type} == $IF_DISTRACTOR_RATIONALE) {
                  push (@{$ii->{content}{distractorRationale}}, $frag);  
		} 
		elsif($row2->{if_type} == $IF_CHOICE_MATCH) {
		  my $setIndex = $row2->{if_set_seq} - 1;
		  $ii->{content}{setChoices}[$setIndex] = [] unless exists $ii->{content}{setChoices}[$setIndex];
	          push(@{$ii->{content}{setChoices}[$setIndex]}, $frag);
		}
	      }
              
	      $self->{interactions}{$row->{ii_id}} = $ii; 
	    }

            $loadDefaults = 0;
        }

        $sth->finish;
    }

    if ($loadDefaults) {
        $self->{id}                = 0;
        $self->{bankId}            = 0;
        $self->{bankName}          = '';
        $self->{name}              = '';
        $self->{description}       = '';
        $self->{type}              = 1;
        $self->{format}              = 1;
        $self->{devState}          = 1;
        $self->{devStateName} 	   = $dev_states{$self->{devState}};
        $self->{difficulty}        = 0;
        $self->{notes}             = '';
        $self->{sourceDoc}         = '';
        $self->{author}            = 0;
        $self->{correct}           = '';
        $self->{reviewLock}        = 0;
        $self->{reviewLifetime}    = '0000-00-00 00:00:00';
        $self->{project}           = 0;
        $self->{publicationStatus} = 0;
        $self->{handle}            = '';
        $self->{imsID}             = '';
        $self->{version}           = 0;
        $self->{readOnly}          = 0;
        $self->{lastUser}          = 0;
        $self->{exportOk}          = 0;
        $self->{rawXML}            = '';
        $self->{rejectReason}      = '';
        $self->{hasNotes}          = 0;
        $self->{formName}          = '';
        $self->{formSession}       = 0;
        $self->{formSequence}      = 0;
	$self->{lang}	       	   = 1;
        $self->{documentReadyFunction} = '';
	$self->{stylesheet} = '';
	$self->{qtiXml} = '';
	$self->{metadataXml} = '';

        $self->{$OC_CONTENT_AREA}     = '';
        $self->{$OC_GRADE_LEVEL}      = '';
        $self->{$OC_GRADE_SPAN_START} = '';
        $self->{$OC_GRADE_SPAN_END}   = '';
        $self->{$OC_SCORING_METHOD}   = '';
        $self->{$OC_SCALE_VALUE}      = '';
        $self->{$OC_MAP_VALUE}        = '';
        $self->{$OC_POINTS}           = 1;
        $self->{$OC_LAYOUT}           = 1;
        $self->{$OC_DOK}              = '';
        $self->{$OC_PROTRACTOR}       = '';
        $self->{$OC_RULER}            = '';
        $self->{$OC_CALCULATOR}       = '';
        $self->{$OC_COMPASS}          = '';
        $self->{$OC_COMP_CURRICULUM}  = '';
        $self->{$OC_FORM_GROUP}       = '';
        $self->{$OC_ITEM_FORMAT}      = 1;
        $self->{$OC_CHOICE_SHUFFLE}      = 0;

        $self->{standards} = [];
        for ( 1 .. 3 ) {
            my $standard = {
                'gle'             => 0,
                'gleNumber'       => 0,
                'benchmark'       => 0,
                'category'        => 0,
                'contentStandard' => 0
            };
            push @{ $self->{standards} }, $standard;
        }
        $self->{passages} = [];
        $self->{rubrics}  = [];

        $self->{stemCount}    = 1;
        $self->{choiceCount}  = 4;
        $self->{default}      = '';
        $self->{answerFormat} = '';

        $self->{stems}                = [];
        $self->{stems}[0]             = {};
        $self->{stems}[0]->{text}     = '<div></div>';
        $self->{stems}[0]->{audioUrl} = '';

	$self->{prompt} = {};
	$self->{prompt}->{text} = '';
	$self->{prompt}->{audioUrl} = '';

	$self->{enemies} = [];

        $self->{choices}     = [];
        $self->{distractors} = [];

        for my $i ( 0 .. 3 ) {
            $self->{choices}[$i]             = {};
            $self->{choices}[$i]->{text}     = '<div></div>';
            $self->{choices}[$i]->{audioUrl} = '';

            $self->{distractors}[$i]             = {};
            $self->{distractors}[$i]->{text}     = '';
            $self->{distractors}[$i]->{audioUrl} = '';
        }

        $self->{shortAnswers} = [];

      $self->{max_content_id} = 0;

      $self->{item_body}{content}{text} = '';
      $self->{interactions} = {};
    }


    bless( $self, $type );
    return ($self);
}

BEGIN {
}

#
# GETTERS
#

sub getPrimaryContentCode {
    my ($self) = shift;

    return join(
        '.',
        $self->{standards}[0]{contentStandard},
        0,
        ( $self->{standards}[0]{category} || 0 ),
        $self->{standards}[0]{benchmark},
        (
            $self->{standards}[0]{gleNumber}
            ? sprintf( '%02d', $self->{standards}[0]{gleNumber} )
            : 0
        )
    );
}

sub getSecondaryContentCode {
    my ($self) = shift;

    return join(
        '.',
        $self->{standards}[1]{contentStandard},
        0,
        ( $self->{standards}[1]{category} || 0 ),
        $self->{standards}[1]{benchmark},
        (
            $self->{standards}[1]{gleNumber}
            ? sprintf( '%02d', $self->{standards}[1]{gleNumber} )
            : 0
        )
    );
}

sub getTertiaryContentCode {
    my ($self) = shift;

    return join(
        '.',
        $self->{standards}[2]{contentStandard},
        0,
        ( $self->{standards}[2]{category} || 0 ),
        $self->{standards}[2]{benchmark},
        (
            $self->{standards}[2]{gleNumber}
            ? sprintf( '%02d', $self->{standards}[2]{gleNumber} )
            : 0
        )
    );
}

sub getApprover {
    my ($self) = shift;
    $sql =
"SELECT CONCAT(u_last_name,', ', u_first_name) AS approver_name FROM user WHERE u_id="
      . " (SELECT is_u_id FROM item_status"
      . " WHERE i_id=$self->{id}"
      . " AND is_last_dev_state=${DS_CONTENT_REVIEW_1}"
      . " ORDER BY is_timestamp DESC LIMIT 1)";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    if ( my $row = $sth->fetchrow_hashref ) {
        return $row->{approver_name};
    }

    return '';
}

sub getGLE {
    my ($self) = shift;
    my %gle = ();

    if ( $self->{standards}[0]{gle} ) {
        my $sql = 'SELECT * FROM hierarchy_definition WHERE hd_id='
          . $self->{standards}[0]{gle};
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute()
          || return $self->error( "Failed Query:" . $self->{dbh}->err );

        if ( my $row = $sth->fetchrow_hashref ) {
            $gle{id}   = $row->{hd_id};
            $gle{name} = $row->{hd_value};
            $gle{text} = $row->{hd_std_desc};
        }

        $sth->finish;
    }
    return \%gle;
}

sub getPassages {
    my ($self) = shift;
    my %p = ();

    if ( scalar @{ $self->{passages} } > 0 ) {
        my $sql = 'SELECT * FROM passage WHERE p_id IN ('
          . join( ',', @{ $self->{passages} } ) . ')';
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute()
          || return $self->error( "Failed Query:" . $self->{dbh}->err );
        while ( my $row = $sth->fetchrow_hashref ) {
            $p{ $row->{p_id} }            = {};
            $p{ $row->{p_id} }->{name}    = $row->{p_name};
            $p{ $row->{p_id} }->{summary} = $row->{p_summary};
            $p{ $row->{p_id} }->{url} 	  = $row->{p_url};
        }

        $sth->finish;
    }

    return \%p;
}

sub getCharByType {
    my ($self)   = shift;
    my $charType = shift;
    my @chars    = ();

    my $sql =
"SELECT ic_value FROM item_characterization WHERE i_id=$self->{id} AND ic_type=${charType}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    while ( my $row = $sth->fetchrow_hashref ) {
        push( @chars, $row->{ic_value} );
    }
    $sth->finish;
    return @chars;
}

sub getRubrics {
    my ($self) = shift;
    my %r = ();

    if ( scalar @{ $self->{rubrics} } > 0 ) {
        my $sql = 'SELECT * FROM scoring_rubric WHERE sr_id IN ('
          . join( ',', @{ $self->{rubrics} } ) . ')';
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute()
          || return $self->error( "Failed Query:" . $self->{dbh}->err );
        while ( my $row = $sth->fetchrow_hashref ) {
            $r{ $row->{sr_id} }            = {};
            $r{ $row->{sr_id} }->{name}    = $row->{sr_name};
            $r{ $row->{sr_id} }->{summary} = $row->{sr_description};
            $r{ $row->{sr_id} }->{url} = $row->{sr_url};
        }

        $sth->finish;
    }

    return \%r;
}

sub getAllNotes {
    my ($self) = shift;

    my %notes = ();

    my $sql =
        "SELECT ist.*, u.* FROM item_status AS ist, user AS u"
      . " WHERE ist.i_id=$self->{id} AND ist.i_notes != '' AND ist.is_u_id=u.u_id"
      . " ORDER BY ist.is_timestamp DESC";

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{is_timestamp};
        $notes{$key}                = {};
        $notes{$key}{firstName}     = $row->{u_first_name};
        $notes{$key}{lastName}      = $row->{u_last_name};
        $notes{$key}{devState}      = $dev_states{ $row->{is_last_dev_state} };
        $notes{$key}{devStateValue} = $row->{is_last_dev_state};
	$notes{$key}{newDevStateValue} = $row->{is_new_dev_state};
        $notes{$key}{notes}         = $row->{i_notes};
    }
    $sth->finish;

    return \%notes;
}

sub getMetafiles {
    my ($self) = shift;

    my %metafiles = ();

    my $sql =
        "SELECT im.*, u.* FROM item_metafiles AS im, user AS u"
      . " WHERE im.i_id=$self->{id} AND im.u_id=u.u_id"
      . " ORDER BY im.im_timestamp DESC";

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{im_timestamp};
        $metafiles{$key}            = {};
        $metafiles{$key}{firstName} = $row->{u_first_name};
        $metafiles{$key}{lastName}  = $row->{u_last_name};
        $metafiles{$key}{devState}  = $dev_states{ $row->{i_dev_state} };
        $metafiles{$key}{comment}   = $row->{im_comment};
        $metafiles{$key}{name}      = $row->{im_filename};
        $metafiles{$key}{view} =
          "${orcaUrl}item-metafiles/$self->{id}/$row->{im_filename}";
        $metafiles{$key}{view} =~ s/\s/%20/g;
    }
    $sth->finish;

    return \%metafiles;
}

sub getHistory {
    my ($self) = shift;

    my %history = ();

    my $sql =
        "SELECT ist.*, u.* FROM item_status AS ist, user AS u"
      . " WHERE ist.i_id=$self->{id} AND ist.is_u_id=u.u_id"
      . " ORDER BY ist.is_timestamp DESC";

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          unless -e $webPath
              . "${orcaUrl}item-pdf/lib$row->{ib_id}/$self->{id}/$row->{is_id}.pdf";

        my $key = $row->{is_timestamp};
        $history{$key}            = {};
        $history{$key}{firstName} = $row->{u_first_name};
        $history{$key}{lastName}  = $row->{u_last_name};
        $history{$key}{devState}  = $dev_states{ $row->{is_last_dev_state} };
        $history{$key}{view} =
          "${orcaUrl}item-pdf/lib$row->{ib_id}/$self->{id}/$row->{is_id}.pdf";
    }
    $sth->finish;

    return \%history;

}

# return a list of assets for this item; connects to the database on each request
sub getAssets() {
  my ($self) = shift;
  
  my $assets = [];
  
  $sql = sprintf('SELECT * FROM item_asset_attribute WHERE i_id=%d AND iaa_source_url=%s ORDER BY iaa_timestamp DESC', $self->{id}, $self->{dbh}->quote($location) );
  my $sth = $self->{dbh}->prepare($sql);
  $sth->execute();

  while ( my $row = $sth->fetchrow_hashref ) {
    push(@$assets, new ItemAsset($self->{bankId}, $self->{name}, $self->{version}, $row->{iaa_filename}));
  }
  
  return $assets;
}

#
# SETTERS
#
sub setDescription             { $_[0]->{description}          = $_[1]; }
sub setType                    { $_[0]->{type}                 = $_[1]; }
sub setDifficulty              { $_[0]->{difficulty}           = $_[1]; }
sub setNotes                   { $_[0]->{notes}                = $_[1]; }
sub setSourceDoc               { $_[0]->{sourceDoc}            = $_[1]; }
sub setCorrect                 { $_[0]->{correct}              = $_[1]; }
sub setReviewLock              { $_[0]->{reviewLock}           = $_[1]; }
sub setReviewLifetime          { $_[0]->{reviewLifetime}       = $_[1] ? $_[1] : &get_ts(10800); }
sub setProject                 { $_[0]->{project}              = $_[1]; }
sub setPublicationStatus       { $_[0]->{publicationStatus}    = $_[1]; }
sub setReadOnly                { $_[0]->{readOnly}             = $_[1]; }
sub setExportOk                { $_[0]->{exportOk}             = $_[1]; }
sub setHandle                  { $_[0]->{handle}               = $_[1]; }
sub setContentArea             { $_[0]->{$OC_CONTENT_AREA}     = $_[1]; }
sub setGradeLevel              { $_[0]->{$OC_GRADE_LEVEL}      = $_[1]; }
sub setGradeSpanStart          { $_[0]->{$OC_GRADE_SPAN_START} = $_[1]; }
sub setGradeSpanEnd            { $_[0]->{$OC_GRADE_SPAN_END}   = $_[1]; }
sub setScoringMethod           { $_[0]->{$OC_SCORING_METHOD}   = $_[1]; }
sub setPoints                  { $_[0]->{$OC_POINTS}           = $_[1]; }
sub setDOK                     { $_[0]->{$OC_DOK}              = $_[1]; }
sub setProtractor              { $_[0]->{$OC_PROTRACTOR}       = $_[1]; }
sub setRuler                   { $_[0]->{$OC_RULER}            = $_[1]; }
sub setCalculator              { $_[0]->{$OC_CALCULATOR}       = $_[1]; }
sub setCompass                 { $_[0]->{$OC_COMPASS}          = $_[1]; }
sub setItemFormat              { $_[0]->{format}      = $_[1]; }
sub setScaleValue              { $_[0]->{$OC_SCALE_VALUE}      = $_[1]; }
sub setMapValue                { $_[0]->{$OC_MAP_VALUE}        = $_[1]; }
sub setComprehensiveCurriculum { $_[0]->{$OC_COMP_CURRICULUM}  = $_[1]; }
sub setFormGroup               { $_[0]->{$OC_FORM_GROUP}       = $_[1]; }
sub setDefault                 { $_[0]->{default}              = $_[1]; }
sub setAnswerLayout            { $_[0]->{$OC_LAYOUT}           = $_[1]; }
sub setAnswerFormat            { $_[0]->{answerFormat}         = $_[1]; }
sub setStemCount               { $_[0]->{stemCount}            = $_[1]; }
sub setChoiceCount             { $_[0]->{choiceCount}          = $_[1]; }
sub setFormName                { $_[0]->{formName}             = $_[1]; }
sub setFormSession             { $_[0]->{formSession}          = $_[1]; }
sub setFormSequence            { $_[0]->{formSequence}         = $_[1]; }
sub setLastUser                { $_[0]->{lastUser}             = $_[1]; }
sub setLanguage                { $_[0]->{lang}                 = $_[1]; }
sub setDueDate                 { $_[0]->{due_date}             = $_[1]; }
sub setReadabilityIndex        { $_[0]->{readability_index}    = $_[1]; }
sub setStylesheet        { $_[0]->{stylesheet}    = $_[1]; }
sub setChoiceShuffle        { $_[0]->{$OC_CHOICE_SHUFFLE}    = $_[1]; }
sub setMetadataXml { $_[0]->{metadataXml} = $_[1]; }

sub setDevState { 
    $_[0]->{devState}     = $_[1]; 
    $_[0]->{devStateName} = $dev_states{$_[1]};
}

sub setAuthor { 
    $_[0]->{author} = $_[1]; 
    if ( $_[1] ) {
    	my $sql = "SELECT * FROM user WHERE u_id = $_[1]";
        my $sth = $_[0]->{dbh}->prepare($sql);
        $sth->execute();
        if ( my $row = $sth->fetchrow_hashref ) {
             $_[0]->{authorName}  = "$row->{u_last_name}, $row->{u_first_name}";
             $_[0]->{authorEmail} = $row->{u_email};
        }
    }

}

sub setIMSId {
    my ($self) = shift;
    my $imsID = shift;
    my $sql =
        'UPDATE item SET i_ims_id='
      . $self->{dbh}->quote($imsID)
      . ' WHERE i_id='
      . $self->{id};
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub setStems {
    my ($self) = shift;
    @{ $self->{stems} } = @_;
    $self->{stemCount} = scalar @{ $self->{stems} };
}

sub setChoices {
    my ($self) = shift;
    @{ $self->{choices} } = @_;
    $self->{choiceCount} = scalar @{ $self->{choices} } || 4;
}

sub setDistractors {
    my ($self) = shift;
    @{ $self->{distractors} } = @_;
}

sub setPrompt {

  my ($self) = shift;
  $self->{prompt} = shift;
}


#
# Save the Item
#
sub save {
    my ($self) = shift;
    my $save_process = shift || 'System';
    my $save_user_id = shift || 0;
    my $save_detail = shift || '';

    $self->rebuildXml();

    $self->{publicationStatus} ||= 0;

    my $sql =
        "UPDATE item SET "
      . "i_format="
      . $self->{format}
      . ", i_description="
      . $self->{dbh}->quote( $self->{description} )
      . ", i_difficulty="
      . $self->{dbh}->quote( $self->{difficulty} )
      . ", i_dev_state="
      . $self->{devState}
      . ", i_xml_data="
      . $self->{dbh}->quote( $self->{rawXML} )
      . ", i_notes="
      . $self->{dbh}->quote( $self->{notes} )
      . ", i_review_lock="
      . $self->{reviewLock}
      . ", i_review_lifetime="
      . $self->{dbh}->quote( $self->{reviewLifetime} )
      . ", i_author="
      . $self->{dbh}->quote( $self->{author} )
      . ", i_export_ok="
      . $self->{exportOk}
      . ", i_source_document="
      . $self->{dbh}->quote( $self->{sourceDoc} )
      . ", ip_id="
      . $self->{project}
      . ", i_publication_status="
      . $self->{publicationStatus}
      . ", i_read_only="
      . $self->{readOnly}
      . ", i_handle="
      . $self->{dbh}->quote( $self->{handle} )
      . ", i_last_save_user_id="
      . $self->{lastUser}
      . ", i_lang="
      . $self->{dbh}->quote( $self->{lang} )
      . ", i_due_date="
      . $self->{dbh}->quote( $self->{due_date} )
      . ", i_readability_index="
      . $self->{dbh}->quote( $self->{readability_index} )
      . ", i_max_content_id="
      . $self->{dbh}->quote( $self->{max_content_id} )
      . ", i_stylesheet_url="
      . $self->{dbh}->quote( $self->{stylesheet} )
      . ", i_metadata_xml="
      . $self->{dbh}->quote( $self->{metadataXml} )
      . " WHERE i_id="
      . $self->{id};

    #print STDERR $sql;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error(
        "Failed Query:" . $self->{dbh}->err . "," . $self->{dbh}->errstr );
    $sth->finish;

    #Insert/Update Item Characteristics
    foreach (
        @ctypes,             @tools,
        $OC_SCALE_VALUE,    $OC_MAP_VALUE, $OC_POINTS,
        $OC_COMP_CURRICULUM
      )
    {
        $self->updateChar( $_, $self->{$_} );
    }


    # insert/update the 'item_fragment' and 'item_interaction' data
    $self->_updateItemFragment($IF_STEM, 0, 0, 0, $self->{item_body}{content});

    foreach my $ii_key (keys %{$self->{interactions}}) {

      my $ii = $self->{interactions}{$ii_key};

      my $ii_name_quoted = $self->{dbh}->quote($ii->{name});
      my $ii_correct_quoted = $self->{dbh}->quote($ii->{correct});
      my $ii_correct_map_quoted = $self->{dbh}->quote($ii->{correct_map});
      my $ii_att_list_quoted = $self->{dbh}->quote($ii->{attributes});

      $sql = <<SQL;
      UPDATE item_interaction 
        SET i_id=$self->{id},
	    ii_name=$ii_name_quoted,
	    ii_type=$ii->{type},
	    ii_max_score=$ii->{max_score},
	    ii_score_type=$ii->{score_type},
	    ii_correct=$ii_correct_quoted,
	    ii_correct_map=$ii_correct_map_quoted,
	    ii_attribute_list=$ii_att_list_quoted
        WHERE ii_id=$ii_key
SQL
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();

      if( $ii->{content}{prompt} 
          && (   $ii->{type} == $IT_CHOICE 
	      || $ii->{type} == $IT_EXTENDED_TEXT
	      || $ii->{type} == $IT_MATCH)
	) {
        $self->_updateItemFragment($IF_PROMPT, $ii_key, 0, 0, $ii->{content}{prompt});
      }

      if($ii->{content}{choices}) {

        my $seq = 1;
       
        foreach my $choice (@{$ii->{content}{choices}}) {

	  $self->_updateItemFragment($IF_CHOICE, $ii_key, 0, $seq, $choice);
	  $seq++;
	}
      }

      if($ii->{content}{distractorRationale}) {

        my $seq = 1;
       
        foreach my $dis_rat (@{$ii->{content}{distractorRationale}}) {

	  $self->_updateItemFragment($IF_DISTRACTOR_RATIONALE, $ii_key, 0, $seq, $dis_rat);
	  $seq++;
	}
      }

      if($ii->{content}{setChoices}) {

        foreach (my $set_seq = 0; $set_seq < scalar(@{$ii->{content}{setChoices}}); $set_seq++) {
        
	  my $seq = 1;

          foreach my $choice (@{$ii->{content}{setChoices}[$set_seq]}) {

	    $self->_updateItemFragment($IF_CHOICE_MATCH, $ii_key, $set_seq + 1, $seq, $choice);
	    $seq++;
	  }
	}
      }
    }

    if($save_user_id) {

      $sql = sprintf('INSERT INTO user_action_item SET i_id=%d, u_id=%d, uai_process=%s, uai_detail=%s',
                   $self->{id},
		   $save_user_id,
		   $self->{dbh}->quote($save_process),
		   $self->{dbh}->quote($save_detail));
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
    }

    return 1;
}

sub moveToBank {
    my ($self) = shift;
    my $newBank = shift;
    my $save_process = shift || 'System';
    my $save_user_id = shift || 0;
    my $save_detail = shift || '';

    my $sql =
"SELECT i_external_id, i_xml_data, ib_id FROM item WHERE i_id=$self->{id}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    if ( my $row = $sth->fetchrow_hashref ) {

        my $xml      = $row->{i_xml_data};
        my $bank     = $row->{ib_id};
        my $itemName = $row->{i_external_id};

        # Make sure an item doesn't exist with that name in the target bank
        $sql = "SELECT i_id FROM item WHERE ib_id=${newBank} AND i_external_id="
          . $self->{dbh}->quote($itemName);
        $sth = $self->{dbh}->prepare($sql);
        $sth->execute();

        if ( my $row = $sth->fetchrow_hashref ) {
            $sth->finish;
            return "Item '${itemName}' already exists in Bank ${newBank}";
        }

        # Fix Item XML references (image URLs)
        my $fromLib = "lib${bank}";
        my $toLib   = "lib${newBank}";
        $xml =~ s/\/$fromLib\/$itemName\//\/$toLib\/$itemName\//gs;

        # Move the item data to right directory
        rename(
            "${imagesDir}/${fromLib}/${itemName}",
            "${imagesDir}/${toLib}/${itemName}"
        );

      # Update DB, also set Item Project = 0, since those are item-bank specific
        $sql =
            "UPDATE item SET ib_id=${newBank}, ip_id=0, i_xml_data="
          . $self->{dbh}->quote($xml)
          . " WHERE i_id=$self->{id}";
        $sth = $self->{dbh}->prepare($sql);
        $sth->execute();
        $sth->finish;

        # Don't retain Passage, Rubric links, since they are item-bank specific
        $self->deleteChar($OC_PASSAGE);
        $self->deleteChar($OC_RUBRIC);

    	#$self->setGUID(prg_name => $newBank, save => 1); # Set GUID & Save

        if($save_user_id) {

          $sql = sprintf('INSERT INTO user_action_item SET i_id=%d, u_id=%d, uai_process=%s, uai_detail=%s',
                   $self->{id},
		   $save_user_id,
		   $self->{dbh}->quote($save_process),
		   $self->{dbh}->quote($save_detail));
          $sth = $self->{dbh}->prepare($sql);
          $sth->execute();
        }

        return "Moved Item '${itemName}' from Bank ${bank} to Bank ${newBank}";
    }
    else {
        $sth->finish;
        return "Item not initialized";
    }
}

sub getCompareContent {
    my ($self) = shift;
    my $lastDevState = shift || 0;

    my %c = ();

    my $sql;

    if ($lastDevState) {
        $sql = <<SQL;
        SELECT is_id 
	  FROM item_status 
	  WHERE i_id=$self->{id} 
	    AND is_new_dev_state=${lastDevState} 
	    ORDER BY is_timestamp DESC LIMIT 1
SQL
    }
    else {
        $sql = <<SQL;
        SELECT is_id 
	  FROM item_status 
	  WHERE i_id=$self->{id} 
	    AND is_new_dev_state NOT IN ($DS_FIX_ART, $DS_NEW_ART, $DS_FIX_MEDIA, $DS_NEW_MEDIA, $DS_FIX_ACCESSIBILITY, $DS_NEW_ACCESSIBILITY)
	    ORDER BY is_timestamp DESC LIMIT 1, 1
SQL
    }
    #printf STDERR "[sql:$sql]\n";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    if ( my $row = $sth->fetchrow_hashref ) {

      $sql = 'SELECT * FROM item_status_fragment WHERE is_id=' . $row->{is_id};
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
      while(my $row2 = $sth->fetchrow_hashref) {
        $c{$row2->{if_id}} = $row2->{isf_text};
      }

    }
    #printf STDERR '[success:' . scalar(keys %c) . "]\n";
    $sth->finish;
    return \%c;
}

sub getDefaultMetadataXml {

  my ($self) = shift;

  return <<XML;
<metadata>
  <SB_ContentTargetLink />
  <SB_LinkToScoringTable />
  <SB_Braille />
  <SB_App>N</SB_App>
  <SB_PTWritingType />
  <SB_TechnologyEnabled>N</SB_TechnologyEnabled>
  <SB_TechnologyEnhanced>Y</SB_TechnologyEnhanced>
  <SB_Target-SpecificAttributes />
  <SB_SecondaryClaims />
  <SB_Item-TaskNotes />
  <SB_EnemyItem />
  <SB_PassageLength>S</SB_PassageLength>
  <SB_StimulusType>T</SB_StimulusType>
  <SB_StimulusID />
  <SB_Acknowledgements />
  <SB_Stimulus-Passages></SB_Stimulus-Passages>
  <SB_AI-Scored>N</SB_AI-Scored>
  <SB_HumanScored>N</SB_HumanScored>
  <SB_MaxPoints>1</SB_MaxPoints>
  <SB_ScorePoints>0,1</SB_ScorePoints>
  <SB_Key />
  <SB_MaximumGrade>5</SB_MaximumGrade>
  <SB_MinimumGrade>4</SB_MinimumGrade>
  <SB_Difficulty>M</SB_Difficulty>
  <SB_DOK>2</SB_DOK>
  <SB_SuffEvdncOfClaim>None</SB_SuffEvdncOfClaim>
  <SB_PrimaryContentDomain>RI</SB_PrimaryContentDomain>
  <SB_Standards>RI-1, RI-3</SB_Standards>
  <SB_Brief_Write_or_Revision />
  <SB_Claim2_Category />
  <SB_AssessmentTargets>8</SB_AssessmentTargets>
  <SB_PrimaryClaim>1</SB_PrimaryClaim>
  <SB_ItemID>$self->{name}</SB_ItemID>
  <SYSTEM_ItemID>apipitem_$self->{name}</SYSTEM_ItemID>
  <SYSTEM_ItemType>$item_formats{$self->{format}}</SYSTEM_ItemType>
  <SYSTEM_ItemVersion>0</SYSTEM_ItemVersion>
  <SYSTEM_Subject>ELA</SYSTEM_Subject>
  <SYSTEM_ItemSubcategory>Reading</SYSTEM_ItemSubcategory>
  <SYSTEM_Grade>4</SYSTEM_Grade>
  <SYSTEM_Workflow>SBE_ItemWrtng/Rev</SYSTEM_Workflow>
  <SYSTEM_Status>OT</SYSTEM_Status>
  <SYSTEM_ItemKeywords></SYSTEM_ItemKeywords>
  <SYSTEM_DateCreated>2012-12-10T02:15:50.233</SYSTEM_DateCreated>
  <SYSTEM_LastApprovedDate>2012-12-15T08:26:38.040</SYSTEM_LastApprovedDate>
  <SYSTEM_LinkedPassageID></SYSTEM_LinkedPassageID>
  <SYSTEM_PerformanceTaskID />
  <SYSTEM_Author>None</SYSTEM_Author>
  <SYSTEM_Source></SYSTEM_Source>
  <SYSTEM_Copyright></SYSTEM_Copyright>
</metadata>
XML
}

sub toHTML {
    my ($self) = shift;
    my $seq = shift || 1;
    my $c = $self->getDisplayContent();

    return <<END_HERE;
<html>
  <head>
	</head>
	<body>
	$c->{itemBody};
	<br />
	$c->{metadata} 
	</body>
</html>	
END_HERE
}

#
# The returned data structure will have the following keys:
# itemBody, distractorRationale, metadata, correctResponse 
#   Which are ready for display in an HTML page
sub getDisplayContent {

    my ($self) = shift;
    my $print_only = shift || 0;
    my $c = {};

    $self->{documentReadyFunction} = '';

    # These are deprecated, so empty
    $c->{prompt} = '';
    $c->{stem} = '';
    $c->{choice} = '';
    $c->{distractor} = '';
    $c->{correct} = '';

    $c->{itemBody} = $self->{item_body}{content}{text};
    $c->{distractorRationale} = '';
    $c->{metadata} = '';
    $c->{correctResponse} = '';

    # replace the interaction tags in the item body with proper display html
    $c->{itemBody} =~ s/<(?:span|div) class="orca:interaction" id="interaction_(\d+)"[^>]*>.*?<\/(?:span|div)>/$self->_getInteractionDisplay($1)/egs; 

    # strip media from content, this will be handled by media table
    $c->{itemBody} =~ s/<div class="orca:media:([^"]+)"[^>]*><a [^>]+>Media File<\/a><\/div>//eg;

    # build display of distractor rationale, if item has MC interactions 
    foreach my $ii_id (keys %{$self->{interactions}}) {

      my $ii = $self->{interactions}{$ii_id};
      if($ii->{type} == $IT_CHOICE) {
        $c->{distractorRationale} .= <<HTML;
	<div class="distractor-rationale">
	  <table border="1" cellpadding="3" cellspacing="3">
	    <tr>
	      <td colspan="2">Distractor Rationale: $ii->{name}</td>
            </tr>
HTML

        my $dr_ord = 0;
	foreach my $dr (@{$ii->{content}{distractorRationale}}) {

	  my $dr_letter = $choice_chars[$dr_ord];

	  if($dr->{text} ne '') {

	    $c->{distractorRationale} .= <<HTML;
	    <tr>
	      <td>$dr_letter</td>
	      <td>$dr->{text}</td>
            </tr>
HTML
          }

	  $dr_ord++;
	}

	if($dr_ord == 0) {
	  $c->{distractorRationale} .= '<tr><td colspan="2">None</td></tr>';
	}

	$c->{distractorRationale} .= '</table></div>';
      }
    }



    # build display of correct responses, if item has match response interactions 
    $c->{correctResponse} .= '<table class="no-style" border="0" cellspacing="2" cellpadding="2">';

    foreach my $ii_id (keys %{$self->{interactions}}) {

      my $ii = $self->{interactions}{$ii_id};
      my $correctDisplay = '';

      if($ii->{type} == $IT_TEXT_ENTRY) {
        $correctDisplay = $ii->{correct};
      } 
      elsif($ii->{type} == $IT_MATCH) {
        my %correct_map = map { $_ => 1 } split(/ /, $ii->{correct});

	foreach my $source ( @{$ii->{content}{setChoices}[0]} ) {
	  foreach my $target ( @{$ii->{content}{setChoices}[1]} ) {
	    if(exists $correct_map{$source->{name} . ':' . $target->{name}}) {
	      $correctDisplay .= '<div>' . $source->{text} . ' =&gt; ' . $target->{text} . '</div>';
	    }
	  }
	}
      }
      elsif($ii->{type} == $IT_INLINE_CHOICE) {
        if( exists($reverse_choice_chars{$ii->{correct}}) ) {
          $correctDisplay = $ii->{content}{choices}[$reverse_choice_chars{$ii->{correct}}]{text};
        }
      }
      elsif($ii->{type} == $IT_CHOICE) {

        # translate between QTI identifiers for choices and letter choices, since we store id and display letters
        my %correct_map = map { $_ => 1 } split(/ /, $ii->{correct});
	$correctDisplay = join (' ', map { $choice_chars[$_] } 
	                             grep { exists $correct_map{$ii->{content}{choices}[$_]{name}} }
				     (0 .. scalar @{$ii->{content}{choices}}));
      }

      if(  $ii->{type} == $IT_CHOICE 
        || $ii->{type} == $IT_TEXT_ENTRY 
	|| $ii->{type} == $IT_INLINE_CHOICE
	|| $ii->{type} == $IT_MATCH ) {
        $c->{correctResponse} .= <<HTML;
	<tr>
	  <td>Correct ($ii->{name}) = </td>
	  <td>$correctDisplay</td>
        </tr>
HTML
      }
    }
    $c->{correctResponse} .= '</table>';

    my @hierarchy_id = ();
    my $sth = $self->{dbh}->prepare('SELECT * FROM hierarchy_definition WHERE hd_id=?');
    for( map {$_->{gle} } @{$self->{standards}} ) {
        next unless $_;
        $sth->execute($_);
        if ( my $row = $sth->fetchrow_hashref ) {
            push @hierarchy_id, $row->{hd_value};
            for( split(/,/, $row->{hd_parent_path}) ) {
                $sth->execute($_);
                if ( my $row2 = $sth->fetchrow_hashref ) {
                    unshift @hierarchy_id, $row2->{hd_value};
                }
            }
        }
    }

    $c->{metadata} = sprintf
                        qq| <br/>
                         <table border="1" cellspacing="2" cellpadding="2">
                            <tr><td width="150px">Hierarchy</td><td>%s</td></tr>
                            <tr><td width="150px">Description</td><td>%s</td></tr>
                            <tr><td width="150px">Difficulty</td><td>%s</td></tr>
                            <tr><td width="150px">Publication Status</td><td>%s</td></tr>
                          |,
                        join('<br/>', @hierarchy_id),
                        ($self->{description}||''),
                        ($self->{difficulty}||''),
                        ($self->{publicationStatus} ? $publication_status{$self->{publicationStatus}} : ''),

    my @requests = (); 

    my $sql = sprintf('SELECT wsi_work_type FROM work_supplemental_info WHERE wsi_object_type=%d AND wsi_object_id=%d',
                      $OT_ITEM, $self->{id});   
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while(my $row = $sth->fetchrow_hashref) {
       if($row->{wsi_work_type} == 1) {
         push @requests, 'Art';
       } elsif ($row->{wsi_work_type} == 2) {
         push @requests, 'Media';
       } elsif ($row->{wsi_work_type} == 3) {
         push @requests, 'Accessibility';
       }
    }
    $sth->finish;

    if(scalar @requests) {
      $c->{metadata} .= '<tr><td width="150px">Request Forms</td><td>' . join(', ', @requests) . '</td></tr>';
    }

    $c->{metadata} .= '</table>';

    return $c;
}

#
# Special functions
#

sub getCssLink {
  my ($self) = shift;

  return ($self->{stylesheet} eq '' ? '<!-- No item-specific stylesheet -->'
       : '<link href="' . $self->{stylesheet} . '" rel="stylesheet" type="text/css">');
}

sub getNamePrefix {
  my ($self) = shift;
  my $bank = shift;
  my $year = shift || 1;
  my $writer_code = shift || 'WCNONE';

  #####
  # Item names are auto generated
  # Program(3)Year(4)-WriterCode(5)-Sequence
  #####
  my $sql = "SELECT * FROM item_bank WHERE ib_id=$bank";
  my $sth = $self->{dbh}->prepare($sql);
  $sth->execute();
  my $program = 'NONE';
  if ( my $row = $sth->fetchrow_hashref ) {
    $program  = sprintf "%-3s", $row->{ib_external_id};
  }
  $sth->finish;

  return sprintf "%s%s-%s-", substr($program,0,3), $year, $writer_code;
}


sub create {
    my ($self) = shift;
    my $bank   = shift || 0;
    my $name   = shift;
    my $year   = shift || (localtime(time))[5] + 1900;
    my $writer_code = shift || 'WCNONE';

    if( $name =~ /^\s*$/ ) {
      
        my $prefix = $self->getNamePrefix($bank, $year, $writer_code);
	my $sequence = &getNextItemSequence($self->{dbh}, $bank, $prefix);
	$name = $prefix . sprintf('%04d', $sequence);
    }
    $name =~ s/\s+//g;

    #
    # Make sure name is available in the item bank
    #
    $sql =
        "SELECT i_id, ib_id FROM item WHERE i_external_id="
      . $self->{dbh}->quote($name)
      . " AND ib_id=${bank}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute() || return 0;

    if ( defined $sth->fetchrow_arrayref ) {
        $sth->finish;
        return 0;
    }

    my $xml .=
      "<item stems='$self->{stemCount}' choices='$self->{choiceCount}'>\n";
    for ( my $i = 1 ; $i <= $self->{stemCount} ; $i++ ) {
        $xml .= "<question sequence='${i}'><div></div></question>\n";
    }
    for ( my $j = 1 ; $j <= $self->{choiceCount} ; $j++ ) {
        $xml .=
          "<choice sequence='${j}' distractor=''><div></div></choice>\n";
    }
    $xml .= "</item>";

    $sql =
"INSERT INTO item (ib_id, i_external_id, i_dev_state, i_xml_data, i_created) "
      . "VALUES (${bank},"
      . $self->{dbh}->quote($name) . ",1,"
      . $self->{dbh}->quote($xml)
      . ",NOW())";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute() || return 0;

    # Get the ID and close result handle
    $self->{id}     = $self->{dbh}->{mysql_insertid};
    $self->{name}   = $name;
    $self->{bankId} = $bank;
    $sql            = 'SELECT * FROM item_bank WHERE ib_id=' . $bank;
    my $sth2 = $self->{dbh}->prepare($sql);
    $sth2->execute();
    if ( my $row2 = $sth2->fetchrow_hashref ) {
        $self->{bankName} = $row2->{ib_external_id};
    }
    $self->{rawXML} = $xml;

    $sth->finish;

    my $new_dir = "${asset_path}lib${bank}/${name}";
    mkdir( $new_dir, 0777 );
    system( "chmod", "a+rw", $new_dir );

    # Set GUID
    $self->setGUID(save => 1);

    return 1;
}

# create an interaction and return the record ID
# takes an interaction data structure as input
sub createInteraction {

  my ($self) = shift;
  my $i_obj = shift;

  my $ii_att_quote = $self->{dbh}->quote($i_obj->{attributes});
  my $correct_quoted = $self->{dbh}->quote($i_obj->{correct});

  my $sql = <<SQL;
  INSERT INTO item_interaction
    SET i_id=$self->{id},
        ii_name='$i_obj->{name}',
	ii_type=$i_obj->{type},
	ii_max_score=$i_obj->{max_score},
	ii_score_type=$i_obj->{score_type},
	ii_correct=$correct_quoted,
	ii_attribute_list=$ii_att_quote
SQL

  my $sth = $self->{dbh}->prepare($sql);
  $sth->execute();
  $sth->finish;

  my $ii_id = $self->{dbh}->{mysql_insertid};

  $self->{interactions}{$ii_id} = $i_obj;

  return $ii_id;
}

sub getInteractionByName {
  my ($self) = shift;
  my $ii_name = shift || '';

  foreach my $ii_id (keys %{$self->{interactions}}) {
    return $self->{interactions}{$ii_id}
      if $self->{interactions}{$ii_id}{name} == $ii_name;
  }
  
  return 0;
}

#
# Returns a string success/error message
#
sub rename {
    my ($self) = shift;
    my $newName = shift;

    $newName =~ s/[\\\/\s]/_/g;
    if ( length($newName) > MAX_LENGTH_ITEM_NAME ) {
        return "Item Name is limited to ".MAX_LENGTH_ITEM_NAME." characters";
    }

    return "Item is Versioned and cannot be renamed" if $self->{version} > 0;
    return "Item is Read Only and cannot be renamed" if $self->{readOnly};

    # Make sure there are no duplicates
    my $sql =
        "SELECT i_id FROM item WHERE ib_id=$self->{bankId}"
      . " AND i_external_id="
      . $self->{dbh}->quote($newName);
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $sth->finish;
        return
"Cannot Rename Item, the name '${newName}' is already in the $self->{bankName} Bank.";
    }

    # Proceed with the rename if we made it this far
    $xml = $self->{rawXML};
    my $myLib   = "lib$self->{bankId}";
    my $oldName = $self->{name};
    $xml =~ s/\/$myLib\/$oldName\//\/$myLib\/$newName\//gs;

    rename(
        "${imagesDir}/${myLib}/$self->{name}",
        "${imagesDir}/${myLib}/${newName}"
    );

    $sql =
        "UPDATE item SET i_external_id="
      . $self->{dbh}->quote($newName)
      . ", i_xml_data="
      . $self->{dbh}->quote($xml)
      . " WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    $sth->finish;

    $self->{rawXML} = $xml;
    $self->{name}   = $newName;

    # Set GUID
    $self->setGUID(save => 1);

    return "Renamed '${oldName}' to '${newName}'";
}

#
# Returns a string success/error message
#
sub copy {
    my ($self) = shift;
    my $newName = shift;

    $newName =~ s/[\\\/\s]/_/g;
    if ( length($newName) > MAX_LENGTH_ITEM_NAME ) {
        return "Item Name is limited to ".MAX_LENGTH_ITEM_NAME." characters";
    }

    return "Item is Versioned and cannot be copied" if $self->{version} > 0;

    # Make sure there are no duplicates
    my $sql =
        "SELECT i_id FROM item WHERE ib_id=$self->{bankId}"
      . " AND i_external_id="
      . $self->{dbh}->quote($newName);
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $sth->finish;
        return
"Cannot Copy Item, the name '${newName}' is already in the $self->{bankName} Bank.";
    }

    # Proceed with the copy if we made it this far
    my $oldName = $self->{name};
    my $myLib   = "lib$self->{bankId}";
    $xml = $self->{rawXML};
    $xml =~ s/\/$myLib\/$oldName\//\/$myLib\/$newName\//gs;

    system(
        "cp", "-r",
        "${imagesDir}${myLib}/${oldName}/",
        "${imagesDir}${myLib}/${newName}/"
    );
    system('chmod','a+rw',"${imagesDir}${myLib}/${newName}/");

    my $sprintfStr = <<'SQL'; 
    INSERT INTO item 
      SET ib_id=%d,
          i_external_id=%s,
	  i_type=%d,
	  i_description=%s,
	  i_correct_response=%s,
	  i_xml_data=%s, 
	  i_difficulty=%d,
	  i_source_document=%s,
	  i_dev_state=1,
	  i_readability_index=%s,
	  i_lang=%d,
	  i_qti_xml_data=%s,
	  i_max_content_id=%d,
	  i_stylesheet_url=%s,
	  i_metadata_xml=%s,
	  i_created=NOW()
SQL

    $sql = sprintf($sprintfStr,
        $self->{bankId},
        $self->{dbh}->quote($newName),
        $self->{type},
        $self->{dbh}->quote( $self->{description} ),
        $self->{dbh}->quote( $self->{correct} ),
        $self->{dbh}->quote($xml),
        $self->{difficulty},
        $self->{dbh}->quote( $self->{sourceDoc} ),
	$self->{dbh}->quote( $self->{readability_index} ),
	$self->{lang},
	$self->{dbh}->quote( $self->{qtiXml} ),
	$self->{max_content_id},
	$self->{dbh}->quote( $self->{stylesheet} ),
	$self->{dbh}->quote( $self->{metadataXml} )
    );
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    my $itemId = $self->{dbh}->{mysql_insertid};

    $sql = "SELECT * FROM item_characterization WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $sql =
"INSERT INTO item_characterization SET i_id=${itemId}, ic_type=$row->{ic_type}, ic_value=$row->{ic_value}";
        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
        $sth2->finish;
    }
    $sth->finish;

    my $lookup = {};
    $sql = "SELECT * FROM item_interaction WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
      $sql = sprintf('INSERT INTO item_interaction SET ii_name=%s, i_id=%d, ii_type=%d, ii_max_score=%f, ii_score_type=%d, ii_correct=%s, ii_correct_map=%s, ii_attribute_list=%s',
               $self->{dbh}->quote($row->{ii_name}),
	       $itemId,
	       $row->{ii_type},
	       $row->{ii_max_score},
	       $row->{ii_score_type},
               $self->{dbh}->quote($row->{ii_correct}),
               $self->{dbh}->quote($row->{ii_correct_map}),
               $self->{dbh}->quote($row->{ii_attribute_list}));
      my $sth2 = $self->{dbh}->prepare($sql);
      $sth2->execute();
      $sth2->finish;

      $lookup->{interaction}{$row->{ii_id}} = $self->{dbh}->{mysql_insertid};
    }

    $sql = "SELECT * FROM item_fragment WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
   
        my $xml = $row->{if_text};
        $xml =~ s/\/$myLib\/$oldName\//\/$myLib\/$newName\//gs;
	$xml =~ s/id="interaction_(\d+)"/id="interaction_$lookup->{interaction}{$1}"/g;

        $sql = sprintf('INSERT INTO item_fragment SET i_id=%d, ii_id=%d, if_type=%d, if_seq=%d, if_text=%s, if_identifier=%s, if_attribute_list=%s',
	               $itemId,
		       $row->{ii_id} ? $lookup->{interaction}{$row->{ii_id}} : 0,
		       $row->{if_type},
		       $row->{if_seq},
		       $self->{dbh}->quote($xml),
		       $self->{dbh}->quote($row->{if_identifier}),
		       $self->{dbh}->quote($row->{if_attribute_list}));

        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
        $sth2->finish;
    }
    $sth->finish;

    $sql = "SELECT * FROM accessibility_element WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
      $sql = sprintf('INSERT INTO accessibility_element SET i_id=%d, ae_name=%s, ae_content_type=%d, ae_content_name=%s, ae_content_link_type=%d, ae_text_link_type=%d, ae_text_link_word=%d, ae_text_link_start_char=%d, ae_text_link_stop_char=%d',
	       $itemId,
               $self->{dbh}->quote($row->{ae_name}),
	       $row->{ae_content_type},
               $self->{dbh}->quote($row->{ae_content_name}),
	       $row->{ae_content_link_type},
	       $row->{ae_text_link_type},
	       $row->{ae_text_link_word},
	       $row->{ae_text_link_start_char},
	       $row->{ae_text_link_stop_char});
      my $sth2 = $self->{dbh}->prepare($sql);
      $sth2->execute();
      $sth2->finish;

      $lookup->{access}{$row->{ae_id}} = $self->{dbh}->{mysql_insertid};

      $sql = "SELECT * FROM accessibility_feature WHERE ae_id=$row->{ae_id}";
      $sth2 = $self->{dbh}->prepare($sql);
      $sth2->execute();
      while ( my $row2 = $sth2->fetchrow_hashref ) {
   
        $sql = sprintf('INSERT INTO accessibility_feature SET ae_id=%d, af_type=%d, af_feature=%d, af_info=%s, lang_code=%s',
		   $lookup->{access}{$row->{ae_id}},
		   $row2->{af_type},
		   $row2->{af_feature},
		   $self->{dbh}->quote($row2->{af_info}),
		   $self->{dbh}->quote($row2->{lang_code}));

        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
        $sth2->finish;
      } 
    }
    $sth->finish;

    $sql = "SELECT * FROM inclusion_order WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
      $sql = sprintf('INSERT INTO inclusion_order SET i_id=%d, io_type=%d',
	       $itemId,
	       $row->{io_type});
      my $sth2 = $self->{dbh}->prepare($sql);
      $sth2->execute();
      $sth2->finish;

      my $io_id = $self->{dbh}->{mysql_insertid};

      $sql = "SELECT * FROM inclusion_order_element WHERE io_id=$row->{io_id}";
      $sth2 = $self->{dbh}->prepare($sql);
      $sth2->execute();
      while ( my $row2 = $sth2->fetchrow_hashref ) {
   
        $sql = sprintf('INSERT INTO inclusion_order_element SET io_id=%d, ae_id=%d, ioe_sequence=%d',
		       $io_id,
		       $lookup->{access}{$row2->{ae_id}},
		       $row2->{ioe_sequence});

        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
        $sth2->finish;
      } 
    }
    $sth->finish;

    $self->setGUID(item_name => $newName); # Set GUID
    $self->saveGUID(item_id  => $itemId);  # Save GUID

    return "Copied '${oldName}' to '${newName}'";
}

sub assignIMSId {
    my ($self) = shift;

    unless ( $self->{imsID} eq '0' || $self->{imsID} eq '' ) { return 0; }

    $self->{dbh}->{RaiseError} = 1;
    $self->{dbh}->{AutoCommit} = 0;
    {
        $sql =
"SELECT i_ims_id FROM item WHERE ib_id=$self->{bankId} AND i_ims_id NOT LIKE '\%x' ORDER BY CHAR_LENGTH(i_ims_id) DESC, i_ims_id DESC LIMIT 1";
        $sth = $self->{dbh}->prepare($sql);
        $sth->execute();
        my $row   = $sth->fetchrow_hashref;
        my $imsId = int( $row->{i_ims_id} ) + 1;

        $sql = "UPDATE item SET i_ims_id='${imsId}' WHERE i_id=$self->{id}";
        $sth = $self->{dbh}->prepare($sql);
        $sth->execute();

        $self->{dbh}->commit();

        $sth->finish;
    };
    $self->{dbh}->rollback if $@;
    $self->{dbh}->{AutoCommit} = 1;

    return $@ ? 0 : 1;
}

sub version {

  my ($self) = shift;
  $self->{dbh}->{RaiseError} = 1;
  $self->{dbh}->{AutoCommit} = 0;

  {
    my $sql = "SELECT * FROM item WHERE i_id=$self->{id}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    if ( my $row = $sth->fetchrow_hashref ) {

      delete $row->{i_id};
      $row->{i_ims_id}  = 0;
      $row->{i_created} = 'NOW()';

      my $itemName   = $row->{i_external_id};
      my $itemBank   = $row->{ib_id};
      my $oldVersion = int( $row->{i_version} );
      my $newVersion = int( $row->{i_version} ) + 1;

      if ( $oldVersion == 0 ) {
        $row->{i_xml_data} =~
          s/(\/images\/lib$itemBank\/$itemName\/)/$1V$newVersion./g;
      }
      else {
        $row->{i_xml_data} =~
          s/(\/images\/lib$itemBank\/$itemName\/)V\d+\./$1V$newVersion./g;
      }

      $row->{i_version}   = $newVersion;
      $row->{i_dev_state} = 1;

      $sql = sprintf(
             "INSERT INTO item SET %s",
                join( ',',
                    map { $_ . ' = ' . $self->{dbh}->quote( $row->{$_} ) }
                      keys %{$row} )
            );
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute() || return 0;

      my $newItemId = $self->{dbh}->{mysql_insertid};

      $sql = "UPDATE item SET i_created=NOW() WHERE i_id=${newItemId}";
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute() || return 0;

      $sql = "SELECT * FROM item_characterization WHERE i_id=$self->{id}";
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
   
      while ( my $row2 = $sth->fetchrow_hashref ) {

        $sql =
          "INSERT INTO item_characterization SET i_id=${newItemId}, ic_type=$row2->{ic_type}, ic_value=$row2->{ic_value}";
        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
      }

      my $lookup = {};

      $sql = "SELECT * FROM item_interaction WHERE i_id=$self->{id}";
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
      while ( my $row2 = $sth->fetchrow_hashref ) {
	$sql = sprintf('INSERT INTO item_interaction SET ii_name=%s, i_id=%d, ii_type=%d, ii_max_score=%f, ii_score_type=%d, ii_correct=%s, ii_correct_map=%s, ii_attribute_list=%s',
	         $self->{dbh}->quote($row2->{ii_name}),
	         $newItemId,
	         $row2->{ii_type},
	         $row2->{ii_max_score},
	         $row2->{score_type},
	         $self->{dbh}->quote($row2->{ii_correct}),
	         $self->{dbh}->quote($row2->{ii_correct_map}),
	         $self->{dbh}->quote($row2->{ii_attribute_list}));

        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();

	$lookup->{interaction}{$row2->{ii_id}} = $self->{dbh}->{mysql_insertid};
      }

      $sql = "SELECT * FROM item_fragment WHERE i_id=$self->{id}";
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
      while ( my $row2 = $sth->fetchrow_hashref ) {

	my $text = $row2->{if_text};

        if ( $oldVersion == 0 ) {
          $text =~  s/(\/images\/lib$itemBank\/$itemName\/)/$1V$newVersion./g;
        } else {
          $text =~  s/(\/images\/lib$itemBank\/$itemName\/)V\d+\./$1V$newVersion./g;
        }

	$text =~ s/id="interaction_(\d+)"/id="interaction_$lookup->{interaction}{$1}"/g;

        $sql = sprintf('INSERT INTO item_fragment SET i_id=%d, ii_id=%d, if_type=%d, if_seq=%d, if_identifier=%s, if_text=%s, if_attribute_list=%s', 
                $newItemId,
		$row2->{ii_id} ? $lookup->{interaction}{$row2->{ii_id}} : 0,
		$row2->{if_type},
		$row2->{if_seq},
		$self->{dbh}->quote($row2->{if_identifier}),
                $self->{dbh}->quote($text),
		$self->{dbh}->quote($row2->{if_attribute_list}));

        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
      }

      $sql = "SELECT * FROM accessibility_element WHERE i_id=$self->{id}";
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
      while ( my $row2 = $sth->fetchrow_hashref ) {
        $sql = sprintf('INSERT INTO accessibility_element SET i_id=%d, ae_name=%s, ae_content_type=%d, ae_content_name=%s, ae_content_link_type=%d, ae_text_link_type=%d, ae_text_link_word=%d, ae_text_link_start_char=%d, ae_text_link_stop_char=%d',
          $newItemId,
          $self->{dbh}->quote($row2->{ae_name}),
          $row2->{ae_content_type},
          $self->{dbh}->quote($row2->{ae_content_name}),
          $row2->{ae_content_link_type},
          $row2->{ae_text_link_type},
          $row2->{ae_text_link_word},
	  $row2->{ae_text_link_start_char},
	  $row2->{ae_text_link_stop_char});

        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();

        $lookup->{access}{$row2->{ae_id}} = $self->{dbh}->{mysql_insertid};

        $sql = "SELECT * FROM accessibility_feature WHERE ae_id=$row2->{ae_id}";
        $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
        while ( my $row3 = $sth2->fetchrow_hashref ) {
   
          $sql = sprintf('INSERT INTO accessibility_feature SET ae_id=%d, af_type=%d, af_feature=%d, af_info=%s, lang_code=%s',
		   $lookup->{access}{$row2->{ae_id}},
		   $row3->{af_type},
		   $row3->{af_feature},
		   $self->{dbh}->quote($row3->{af_info}),
		   $self->{dbh}->quote($row3->{lang_code}));

          my $sth3 = $self->{dbh}->prepare($sql);
          $sth3->execute();
          $sth3->finish;
        }
      }

      $sql = "SELECT * FROM inclusion_order WHERE i_id=$self->{id}";
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
      while ( my $row2 = $sth->fetchrow_hashref ) {

        $sql = sprintf('INSERT INTO inclusion_order SET i_id=%d, io_type=%d',
	       $newItemId,
	       $row2->{io_type});
        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();

	my $io_id = $self->{dbh}->{mysql_insertid};

        $sql = "SELECT * FROM inclusion_order_element WHERE io_id=$row2->{io_id}";
        $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();

        while ( my $row3 = $sth2->fetchrow_hashref ) {
   
          $sql = sprintf('INSERT INTO inclusion_order_element SET io_id=%d, ae_id=%d, ioe_sequence=%d',
		       $io_id,
		       $lookup->{access}{$row3->{ae_id}},
		       $row3->{ioe_sequence});

          my $sth3 = $self->{dbh}->prepare($sql);
          $sth3->execute();
        }
      }

      if ( $oldVersion == 0 ) {

        foreach my $file (
          bsd_glob("${imagesDir}/lib${itemBank}/${itemName}/*"))
        {
          my $newFile = $file;
          $newFile =~ s/(\/${itemName}\/)/$1V$newVersion./g;
          cp( $file, $newFile );
	  system('chmod','a+rw',$newFile);
        }
      }
      else {

        foreach my $file (
          bsd_glob("${imagesDir}/lib${itemBank}/${itemName}/V${oldVersion}.*"))
        {
          my $newFile = $file;
          $newFile =~ s/(\/${itemName}\/)V\d+\./$1V$newVersion./g;
          cp( $file, $newFile );
	  system('chmod','a+rw',$newFile);
        }
      }

      $sql = "UPDATE item SET i_is_old_version=1 WHERE i_id=$self->{id}";
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();

      $self->{dbh}->commit();
    }
    $sth->finish;

  }
  $self->{dbh}->rollback if $@;
  $self->{dbh}->{AutoCommit} = 1;


  return $@ ? 0 : 1;
}

sub moveToVersion {
    my ($self)   = shift;
    my $itemName = shift;
    my $version  = 0;

    my $sql =
"SELECT i_id, i_version, i_xml_data FROM item WHERE ib_id=$self->{bankId} AND i_external_id="
      . $self->{dbh}->quote($itemName);
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    if ( my $row = $sth->fetchrow_hashref ) {
        return "Item ${itemName} is already versioned."
          if $row->{i_version} > 0;

        # Move the item $itemName to the next version of this item

        $version = $self->{version} + 1;
        my $itemBank    = $self->{bankId};
        my $newItemName = $self->{name};

        $row->{i_xml_data} =~
s/(\/images\/lib$itemBank)\/$itemName\//$1\/$newItemName\/V$version./g;

        $sql =
            "UPDATE item SET i_external_id="
          . $self->{dbh}->quote( $self->{name} )
          . ", i_version=${version}"
          . ", i_xml_data="
          . $self->{dbh}->quote( $row->{i_xml_data} )
          . " WHERE i_id=$row->{i_id}";
        $sth = $self->{dbh}->prepare($sql);
        $sth->execute();

        foreach
          my $file ( bsd_glob("${imagesDir}lib$self->{bankId}/${itemName}/*") )
        {
            $file =~ /\/([^\/]+)$/;
            system( "mv", $file,
                "${imagesDir}lib$self->{bankId}/$self->{name}/V${version}.$1" );
        }
        rmdir "${imagesDir}lib$self->{bankId}/${itemName}/";
    }
    else {
        return
          "Item ${itemName} does not exist in the $self->{bankName} item bank.";
    }
    $sth->finish;

    return "Moved item ${itemName} to $self->{name}, version ${version}.";
}

sub remove {
    my ($self) = shift;
    my $save_process = shift || 'System';
    my $save_user_id = shift || 0;
    my $save_detail = shift || 'Delete Item';

    return "Item is Read Only and cannot be removed" if $self->{readOnly};

    #print STDERR "Unlinking item id $self->{id}";

    if ( $self->{version} == 0 ) {
        foreach my $file (
            bsd_glob("${imagesDir}/lib$self->{bankId}/$self->{name}/*") )
        {
            unlink($file);
        }

        rmdir("${imagesDir}/lib$self->{bankId}/$self->{name}/");
    }
    elsif ( $self->{version} > 0 ) {
        foreach my $file (
            bsd_glob(
"${imagesDir}/lib$self->{bankId}/$self->{name}/V$self->{version}*"
            )
          )
        {
            unlink($file);
        }
    }


    my $sql = "DELETE FROM item_characterization WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = "DELETE FROM item_fragment WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = "DELETE FROM item_interaction WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = "DELETE FROM item_asset_attribute WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = "DELETE FROM item_status WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = "DELETE FROM item_status_fragment WHERE i_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = <<SQL;
    DELETE FROM accessibility_feature WHERE ae_id IN 
    (SELECT ae_id FROM accessibility_element WHERE i_id=$self->{id})
SQL
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = 'DELETE FROM accessibility_element WHERE i_id=' . $self->{id};
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = <<SQL;
    DELETE FROM inclusion_order_element WHERE io_id IN 
    (SELECT io_id FROM inclusion_order WHERE i_id=$self->{id})
SQL
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = 'DELETE FROM inclusion_order WHERE i_id=' . $self->{id};
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sql = "DELETE FROM item WHERE i_id=$self->{id} LIMIT 1";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sth->finish;

    if($save_user_id) {

      $sql = sprintf('INSERT INTO user_action_item SET i_id=%d, u_id=%d, uai_process=%s, uai_detail=%s',
                   $self->{id},
		   $save_user_id,
		   $self->{dbh}->quote($save_process),
		   $self->{dbh}->quote($save_detail));
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
    }

    $sql = sprintf('INSERT INTO deleted_item SET i_id=%d, ib_id=%d, i_external_id=%s, i_dev_state=%d, i_publication_status=%d',
                   $self->{id},
		   $self->{bankId},
		   $self->{dbh}->quote($self->{name}),
		   $self->{devState},
		   $self->{publicationStatus});
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    return 1;
}

#
# Internal functions
#
sub rebuildXml {
  my ($self) = shift;

  # do some xml cleanup if needed
  $self->_renormalizeContent($self->{item_body}{content});
  foreach my $ii_key (keys %{$self->{interactions}}) {
    next if $self->{interactions}{$ii_key}{type} == $IT_INLINE_CHOICE;

    foreach my $content_obj ($self->{interactions}{$ii_key}{content}{prompt}, 
                             @{$self->{interactions}{$ii_key}{content}{choices}}) {
      $self->_renormalizeContent($content_obj) if $content_obj;
    } 
  }

  # Figure out which auto-generated tag ID sequence we have already hit in this item
  $self->_findMaxContentId($self->{item_body}{content});
  foreach my $ii_key (keys %{$self->{interactions}}) {
    next if $self->{interactions}{$ii_key}{type} == $IT_INLINE_CHOICE;

    foreach my $content_obj ($self->{interactions}{$ii_key}{content}{prompt}, 
                             @{$self->{interactions}{$ii_key}{content}{choices}}) {
      $self->_findMaxContentId($content_obj) if $content_obj;
    } 
  }

  # Now add ID attribute to any tag that misses it
  $self->_addContentIds($self->{item_body}{content});
  foreach my $ii_key (keys %{$self->{interactions}}) {
    next if $self->{interactions}{$ii_key}{type} == $IT_INLINE_CHOICE;

    foreach my $content_obj ($self->{interactions}{$ii_key}{content}{prompt}, 
                             @{$self->{interactions}{$ii_key}{content}{choices}}) {
      $self->_addContentIds($content_obj) if $content_obj;
    } 
  }

  # TODO: Get rid of this legacy stuff below, once references to it are removed in other code

  my $xml = <<XML; 
<item>
XML

  # Add the stem content  to the full XML
  for ( my $i = 0 ; $i < 1 ; $i++ ) {

        my $iplus = $i + 1;
	my $text = '';

        $xml .= <<XML;
  <question sequence="${iplus}">${text}</question>
XML

  }

  # Add the prompt content to the full XML


  $xml .= <<XML;
  <prompt></prompt>
XML

  # add the choice content to the full XML

  for ( my $j = 0 ; $j < 4 ; $j++ ) {

        my $jplus = $j + 1;
	my $letter = $choice_chars[$j];

	$xml .= <<XML;
  <choice sequence="${jplus}" value="${letter}"></choice> 
XML
  }

  $xml .= '</item>';

  # re-normalize entities
  $xml =~ s/&(?:amp;){2,}([a-z#])/&amp;$1/g;

  $self->{rawXML} = $self->strip_white_space($xml);
}

sub strip_white_space {
    my ($self) = shift;

    my $source = shift;
    $source =~ s/^\s*//;
    $source =~ s/\s*$//;
    $source =~ s/>\s+</> </g;
    $source =~ s/\s+</ </g;
    return $source;
}

sub get_tag_with_id {

 my ($self) = shift;
 my $tag = shift;
 my $attribute_string = shift || '';

 unless( exists($tags_with_no_id{$tag}) || $attribute_string =~ /id=["']/ ) {

   if(substr($attribute_string,-1,1) eq '/') {
     $attribute_string = substr($attribute_string,0,-1) . ' id="cde_' . $self->{max_content_id} . '" /'; 
   } else {
     $attribute_string = $attribute_string . ' id="cde_' . $self->{max_content_id} . '"';
   }

   $self->{max_content_id}++;
 }

 $attribute_string =~ s/\s$//;

 return '<' . $tag . ' ' . $attribute_string . '>';
}

sub deleteChar {
    my ($self) = shift;
    my $cType = shift;
    my $cValue = shift || 0;

    my $sql =
"DELETE FROM item_characterization WHERE i_id=$self->{id} AND ic_type=${cType}"
      . ( $cValue > 0 ? " AND ic_value=${cValue}" : '' );
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    $sth->finish;
    return 1;
}

sub updateChar {
    my ($self) = shift;
    my $cType  = shift;
    my $cValue = shift;

    unless ( defined $cValue ) { return 1; }

    #print STDERR "Update Item Char, type = ${cType}, value = ${cValue}";

    # First check to see if characterization already exists
    my $sql =
"SELECT ic_value, ic_value_str FROM item_characterization WHERE i_id=$self->{id} AND ic_type=${cType}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );

    # If it already exists, then update it
    if ( my $row = $sth->fetchrow_hashref ) {
        if ( not( exists $stringCharacteristics{$cType} )
            and $row->{ic_value} eq $cValue )
        {
            return 1;
        }
        if ( exists( $stringCharacteristics{$cType} )
            and $row->{ic_value_str} eq $cValue )
        {
            return 1;
        }

        # If the value is '', then delete the characterization
        if ( $cValue eq '' ) {
            $sql = sprintf(
'DELETE FROM item_characterization WHERE i_id=%d AND ic_type=%d',
                $self->{id}, $cType );
        }
        else {
            if ( exists $stringCharacteristics{$cType} ) {
                $sql = sprintf(
'UPDATE item_characterization SET ic_value_str=%s WHERE i_id=%d AND ic_type=%d',
                    $self->{dbh}->quote($cValue),
                    $self->{id}, $cType
                );
            }
            else {
                $sql = sprintf(
'UPDATE item_characterization SET ic_value=%d WHERE i_id=%d AND ic_type=%d',
                    $cValue, $self->{id}, $cType );
            }
        }
    }
    else {

        # If the value is '', then don't insert it
        return 1 if $cValue eq '';
        if ( exists $stringCharacteristics{$cType} ) {
            $sql = sprintf(
'INSERT INTO item_characterization (i_id, ic_type, ic_value_str) VALUES (%d,%d,%s)',
                $self->{id}, $cType, $self->{dbh}->quote($cValue) );
        }
        else {
            $sql = sprintf(
'INSERT INTO item_characterization (i_id, ic_type, ic_value) VALUES (%d,%d,%d)',
                $self->{id}, $cType, $cValue );
        }
    }
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    $sth->finish;
    return 1;
}

sub insertChar {
    my ($self) = shift;
    my $cType  = shift;
    my $cValue = shift;

    # First check to see if characterization already exists
    my $sql =
"SELECT ic_value, ic_value_str FROM item_characterization WHERE i_id=$self->{id} AND ic_type=${cType}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );

    # If it already exists, then do nothing
    while ( my $row = $sth->fetchrow_hashref ) {
        if ( not( exists $stringCharacteristics{$cType} )
            and $row->{ic_value} eq $cValue )
        {
            return 1;
        }
        if ( exists( $stringCharacteristics{$cType} )
            and $row->{ic_value_str} eq $cValue )
        {
            return 1;
        }
    }
    if ( exists $stringCharacteristics{$cType} ) {
        $sql = sprintf(
'INSERT INTO item_characterization (i_id, ic_type, ic_value_str) VALUES (%d,%d,%s)',
            $self->{id}, $cType, $self->{dbh}->quote($cValue) );
    }
    else {
        $sql = sprintf(
"INSERT INTO item_characterization (i_id, ic_type, ic_value) VALUES (%d,%d,%d)",
            $self->{id}, $cType, $cValue );
    }
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    $sth->finish;
    return 1;
}

sub error {
    my ($self) = shift;
    my $message = shift;

    print( STDERR $message );
    return 0;
}

sub getMediaDisplay {

  my ($self) = shift;
  my $assetName = shift;

  my $asset = new ItemAsset($self->{bankId}, $self->{name}, $self->{version}, $assetName);

  my $playerId = "orca_media_$self->{name}_$asset->{title}";

  $self->{documentReadyFunction} .= getMediaReadyFunction( $playerId, $asset->{ext}, $asset->{url}, $asset->{path} );
 
  return getMediaHtml($playerId, $asset->{ext}, $asset->{title}, $asset->{path});
  

}

################################################################################
# Email Notification methods
################################################################################
sub _sendWorkflowNotification {
    my ( $self, %p ) = @_;

    return 0 unless $self->{authorEmail};

    my $body = <<END_HERE;
Hello $self->{authorName},

SBAC CDE ITEM(s) have been placed in your queue and needs your attention:
Program   : $self->{bankName}

If you have any questions, please contact customer support.
SBAC7PacMetTeam\@pacificmetrics.com

Regards,
SBAC CDE Notifier
END_HERE

    my $message = MIME::Lite->new(
        To      => $self->{authorEmail},
        From    => '"SBAC CDE" <SBAC7PacMetTeam@pacificmetrics.com>',
        Subject => 'SBAC CDE ITEM Needs Your Attention!',
        Data    => $body,
    );
    $message->send( 'smtp', 'localhost' );
    $self->{email_sent_msg} = sprintf "Email sent to %s", $self->{authorEmail};

    return 1;
}

sub updateReviewLock {
    my $self        = shift;
    my $lock_unlock = shift || 0;

    $self->setReviewLock( $lock_unlock ) if( $lock_unlock =~ /^\d+$/ );

    my $sql = "UPDATE item SET i_review_lock=? WHERE i_id=?";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute( $self->{reviewLock}, $self->{id} );
}

#
# Set GUID
# uri://sbac:[Organization]:[Program]:[ItemName import/created]:[DD_YYYY_MM]:[UNIQUE ID GEN]
# Named params passed in: {org_name}, {prg_name}, {item_name}, {date}, {unique_id}, {save}
#
sub setGUID {
    my ( $self, %p ) = @_;

    $p{org_name}  ||= $self->{org_name};
    $p{prg_name}  ||= $self->{bankName};
    $p{item_name} ||= $self->{name};

    unless( $p{date} ) {
	my @dt = localtime time;
	$p{date} = sprintf "%02d_%4d_%02d", $dt[3], $dt[5]+1900, $dt[4]+1;
    }
    my @nodes = ( $instance_name, $p{org_name}, $p{prg_name}, $p{item_name}, $p{date}, );
    unless( $p{unique_id} ) {
    	my $sha = new Digest::SHA;
    	$sha->add(@nodes, time, int(rand($$)), );
	$p{unique_id} = $sha->hexdigest;
    }
    push @nodes, $p{unique_id};

    $self->{guid} = join ':', @nodes;
    $self->saveGUID( guid => $self->{guid} ) if $p{save};

    return $self->{guid};
}
sub getGUID {
    my ( $self, %p ) = @_;
    return $self->{guid} ? $self->{guid} : $self->setGUID;
}
sub saveGUID {
    my ( $self, %p ) = @_;

    $p{guid} 	||= $self->getGUID;
    $p{item_id} ||= $self->{id};
    my $sql = 'UPDATE item SET i_guid=? WHERE i_id=?';
    my $rv = $self->{dbh}->do($sql, undef, $p{guid}, $p{item_id} );
    return $rv;
}

# helpers

sub _updateItemFragment {

  my ($self) = shift;
  my $fragment_type = shift;
  my $interaction_id = shift;
  my $set_seq = shift;
  my $fragment_seq = shift;
  my $content_obj = shift;

  $content_obj->{attributes} =~ s/identifier="\w+"/identifier="$content_obj->{name}"/;

  my $text_quoted = $self->{dbh}->quote(defined($content_obj->{text}) ? $content_obj->{text} : '');
  my $att_quoted = $self->{dbh}->quote($content_obj->{attributes});
  my $name_quoted = $self->{dbh}->quote($content_obj->{name});
  my $sql;

  if($content_obj->{id}) {

    $sql = <<SQL;
    UPDATE item_fragment 
      SET if_text=$text_quoted,
          if_set_seq=$set_seq,
          if_seq=$fragment_seq,
          if_attribute_list=$att_quoted,
          if_identifier=$name_quoted
      WHERE if_id=$content_obj->{id}
SQL
  } else {
    $sql = <<SQL;
    INSERT INTO item_fragment
      SET i_id=$self->{id},
          ii_id=$interaction_id,
          if_type=$fragment_type,
	  if_set_seq=$set_seq,
	  if_seq=$fragment_seq,
	  if_identifier=$name_quoted,
	  if_attribute_list=$att_quoted,
	  if_text=$text_quoted
SQL
  }
  #warn "$sql\n";
  my $sth = $self->{dbh}->prepare($sql);
  $sth->execute();
  $sth->finish;

  $content_obj->{id} ||= $self->{dbh}->{mysql_insertid};
}

sub _getInteractionDisplay {

  my ($self) = shift;
  my $ii_id = shift;

  my $ii = $self->{interactions}{$ii_id};
  my $ii_atts = &attributeStringToHash($ii->{attributes});

  my $html = '';

  if(  $ii->{type} == $IT_CHOICE 
    || $ii->{type} == $IT_EXTENDED_TEXT
    || $ii->{type} == $IT_MATCH) {

    $html .= '<div id="' . $ii->{name} . '">';

    if( defined($ii->{content}{prompt}{text}) && $ii->{content}{prompt}{text} ne '' ) {
      $html .= <<HTML;
      <div id="$ii->{content}{prompt}{name}">
      $ii->{content}{prompt}{text}
      </div>
HTML
    }

  }

  if($ii->{type} == $IT_CHOICE) {

    $html .= '<div><table class="no-style" border="0" cellpadding=2" cellspacing="2">';

    my $choice_ord = 0;
    foreach my $choice (@{$ii->{content}{choices}}) {
 
      my $choice_letter = $choice_chars[$choice_ord];

      $html .= <<HTML;
      <tr>
        <td style="vertical-align:middle;"><input type="radio" /><b>$choice_letter</b>&nbsp;&nbsp;</td>
	<td align="left" style="text-align:left;">$choice->{text}</td>
      </tr>
HTML
      $choice_ord++; 
    }

    $html .= '</table></div>';
  }
  elsif($ii->{type} == $IT_TEXT_ENTRY) {

    my $size = $ii_atts->{expectedLength} || 10;

    $html .= <<HTML;
    <span id="$ii->{name}"><input type="text" size="$size" /></span>
HTML

  }
  elsif($ii->{type} == $IT_INLINE_CHOICE) {
    $html .= '<select>';
    $html .= '<option>' . $_->{text} . '</option>' foreach @{$ii->{content}{choices}};
    $html .= '</select>';
  }
  elsif($ii->{type} == $IT_EXTENDED_TEXT) {

    my $size = $ii_atts->{expectedLength} || 240;
    my $rows = $ii_atts->{expectedLines} || 4;

    my $columns = int($size / $rows);

    $html .= <<HTML;
    <div id="$ii->{name}">
      <textarea rows="$rows" cols="$columns"></textarea>
    </div>
HTML
  }
  elsif($ii->{type} == $IT_MATCH) {

    $ii->{content}{setChoices}[0] = [] unless exists $ii->{content}{setChoices}[0];
    $ii->{content}{setChoices}[1] = [] unless exists $ii->{content}{setChoices}[1];

    $html .= '<table border="1" cellpadding=2" cellspacing="2">';

    # print the header row, these are the choices in the "target set"
    $html .= '<thead><tr><th>&nbsp;</th>';

    foreach my $choice (@{$ii->{content}{setChoices}[1]}) {
      $html .= '<th>' . $choice->{text} . '</th>';    
    }

    $html .= '</tr></thead><tbody>';

    # now print a row for each of the choices in the "source set"
    foreach my $choice (@{$ii->{content}{setChoices}[0]}) {
      $html .= '<tr><th>' . $choice->{text} . '</th>';    

      for (my $i=0; $i < scalar @{$ii->{content}{setChoices}[1]}; $i++) {
        $html .= '<td><input type="checkbox" /></td>';
      }

      $html .= '</tr>';
    }

    $html .= '</tbody></table>';
  }

  $html =~ s/&amp;/&/g;

  return $html;
}

sub _renormalizeContent {

  my ($self) = shift;
  my $content_obj = shift;

  # surround content with <div> tags, unless it's already surrounded with a tag
  unless( $content_obj->{text} =~ /^\s*</) {
    $content_obj->{text} = '<div>' . $content_obj->{text} . '</div>';
  }
}

sub _findMaxContentId {

  my ($self) = shift;
  my $content_obj = shift;

  # Figure out which auto-generated tag ID sequence we have already hit in this item

  my $max_id = $self->{max_content_id};

  while($content_obj->{text} =~ / id="cde_([\d]+)"/g) {
    $max_id = int($1) if int($1) > $max_id;
  }

  $max_id++;

  $self->{max_content_id} = $max_id;
}

sub _addContentIds {

  my ($self) = shift;
  my $content_obj = shift;

  # Now add ID attribute to any tag that misses it
  $content_obj->{text} =~ s/<([^\s\/\!>]+)>/$self->get_tag_with_id($1,'')/eg;
  $content_obj->{text} =~ s/<([^\s\/\!>]+)\s+([^>]+)>/$self->get_tag_with_id($1,$2)/eg;
}

1;
