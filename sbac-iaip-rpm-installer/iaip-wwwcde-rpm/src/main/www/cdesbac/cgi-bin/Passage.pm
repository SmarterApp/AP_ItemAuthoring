package Passage;

use URI::Escape;
use UrlConstants;
use ItemConstants;
use File::Glob ':glob';

#
# Constructor takes 2 params
# 1) DB handle
# 2) Item ID
#
sub new {

    my ($type) = shift;
    my ($self) = {};
    $self->{dbh}  = shift;
    $self->{id}   = shift || 0;
    $self->{name} = shift || '';

    my $loadDefaults = 1;

    if ( $self->{id} > 0 ) {
        my $sql =
          'SELECT p.* FROM passage AS p WHERE '
          . ( $self->{name} eq ''
            ? "p.p_id=$self->{id}"
            : 'p.p_name='
              . $self->{dbh}->quote( $self->{name} )
              . " AND p.ib_id=$self->{id}" );
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute();

        if ( my $row = $sth->fetchrow_hashref ) {

            $sql = 'SELECT * FROM item_bank WHERE ib_id=' . $row->{ib_id};
            my $sth2 = $self->{dbh}->prepare($sql);
            $sth2->execute();
            if ( my $row2 = $sth2->fetchrow_hashref ) {
                $self->{bankName} = $row2->{ib_external_id};
            }

            $self->{id}              = $row->{p_id};
            $self->{bank}            = $row->{ib_id};
            $self->{name}            = $row->{p_name};
            $self->{genre}           = $row->{p_genre};
            $self->{subGenre}        = $row->{p_subgenre};
            $self->{topic}           = $row->{p_topic};
            $self->{readingLevel}    = $row->{p_reading_level};
            $self->{summary}         = $row->{p_summary};
            $self->{wordCount}       = $row->{p_word_count};
            $self->{url}             = $row->{p_url};
            $self->{project}         = $row->{ip_id} || 0;
            $self->{crossCurriculum} = $row->{p_cross_curriculum};
            $self->{charEthnicity}   = $row->{p_char_ethnicity};
            $self->{charGender}      = $row->{p_char_gender};
            $self->{notes}           = $row->{p_notes};
            $self->{buttonName}      = $row->{p_button_name};
            $self->{code}            = $row->{p_code} || '';
            $self->{devState}        = $row->{p_dev_state};
            $self->{author}          = $row->{p_author};
	    $self->{publicationStatus} = $row->{p_publication_status};
	    $self->{readabilityIndex} = $row->{p_readability_index};
	    $self->{max_content_id} = $row->{p_max_content_id};

            if ( $self->{author} ) {
                $sql =
                  'SELECT * FROM user WHERE u_id=' . $row->{p_author};
                $sth2 = $self->{dbh}->prepare($sql);
                $sth2->execute();
                if ( my $row2 = $sth2->fetchrow_hashref ) {
                    $self->{authorName} =
                      "$row2->{u_last_name}, $row2->{u_first_name}";
                }
            }

            $self->{language}    = $row->{p_lang};
	    $self->{contentArea} = '';
	    $self->{gradeLevel} = '';
	    $self->{gradeSpanStart} = '';
	    $self->{gradeSpanEnd} = '';

            # get fields from the object_characteristic table

	    $sql = "SELECT * FROM object_characterization WHERE oc_object_type=${ItemConstants::OT_PASSAGE} AND oc_object_id="
	         . $self->{id};
            $sth2 = $self->{dbh}->prepare($sql);
            $sth2->execute();
            while ( my $row2 = $sth2->fetchrow_hashref ) {

              next unless defined($row2->{oc_object_type}) && defined($row2->{oc_int_value});
           
	      if($row2->{oc_characteristic} == $ItemConstants::OC_CONTENT_AREA ) { $self->{contentArea} = $row2->{oc_int_value}; }

	      if($row2->{oc_characteristic} == $ItemConstants::OC_GRADE_LEVEL ) { $self->{gradeLevel} = $row2->{oc_int_value}; }
	  
	      if($row2->{oc_characteristic} == $ItemConstants::OC_GRADE_SPAN_START ) { $self->{gradeSpanStart} = $row2->{oc_int_value}; }

	      if($row2->{oc_characteristic} == $ItemConstants::OC_GRADE_SPAN_END ) { $self->{gradeSpanEnd} = $row2->{oc_int_value}; }

            }

            $self->{fullText}  = '';
            $self->{content}   = '';
            $self->{body}      = '';
            $self->{footnotes} = {};

            if ( -e "${ItemConstants::passagePath}lib$self->{bank}/p$self->{id}.htm" ) {
                open INFILE, "<${ItemConstants::passagePath}lib$self->{bank}/p$self->{id}.htm";
                while (<INFILE>) {
                    chomp;
                    $self->{fullText} .= $_;
                }
                close INFILE;

                $self->{content} = $self->{fullText};
                if ( $self->{content} =~ m/<body>(.*)<\/body>/s ) {
                    $self->{content} = $1;
                }

                $self->{body} = $self->{content};
                $self->{body} =~ s/<script[^>]+><\/script>//;
                $self->{body} =~ s/<div id="footnote\d+"[^>]+>(.*?)<\/div>//g;
                $self->{body} =~
                  s/<span[^>]+>(<sup>\[\d+\]<\/sup>)<\/span>/$1/g;

                my $content = $self->{content};
                while (
                    $content =~ m/<div id="footnote(\d+)"[^>]+>(.*?)<\/div>/ )
                {
                    $self->{footnotes}->{$1} = $2;
                    $content =~ s/<div id="footnote\d+"[^>]+>(.*?)<\/div>//;
                }
            }
            $loadDefaults = 0;
        }

        $sth->finish;
    }

    if ($loadDefaults) {

        $self->{id}              = 0;
        $self->{bank}            = 0;
        $self->{bankName}        = '';
        $self->{name}            = '';
        $self->{genre}           = 0;
        $self->{subGenre}        = '';
        $self->{topic}           = '';
        $self->{readingLevel}    = '';
        $self->{summary}         = '';
        $self->{wordCount}       = 0;
        $self->{url}             = '';
        $self->{crossCurriculum} = 0;
        $self->{charEthnicity}   = 0;
        $self->{charGender}      = 0;
        $self->{notes}           = '';
        $self->{buttonName}      = '';
        $self->{contentArea}     = '';
        $self->{gradeLevel}      = '';
        $self->{code}            = '';
        $self->{devState}        = 1;
        $self->{language}        = 1;
        $self->{author}          = 0;
        $self->{project}         = 0;
	$self->{publicationStatus} = 0;
	$self->{readabilityIndex} = '';
        $self->{fullText}        = '';
        $self->{content}         = '';
        $self->{body}            = '';
        $self->{footnotes}       = {};
      $self->{max_content_id} = 0;
    }


    bless( $self, $type );
    return ($self);
}

#
# GETTERS
#
sub getName            { return $_[0]->{name}; }
sub getBankName        { return $_[0]->{bankName}; }
sub getGenre           { return $_[0]->{genre}; }
sub getSubGenre        { return $_[0]->{subGenre}; }
sub getTopic           { return $_[0]->{topic}; }
sub getReadingLevel    { return $_[0]->{readingLevel}; }
sub getSummary         { return $_[0]->{summary}; }
sub getWordCount       { return $_[0]->{wordCount}; }
sub getCrossCurriculum { return $_[0]->{crossCurriculum}; }
sub getCharEthnicity   { return $_[0]->{charEthnicity}; }
sub getCharGender      { return $_[0]->{charGender}; }
sub getNotes           { return $_[0]->{notes}; }
sub getButtonName      { return $_[0]->{buttonName}; }
sub getContentArea     { return $_[0]->{contentArea}; }
sub getDevState        { return $_[0]->{devState}; }
sub getGradeLevel      { return $_[0]->{gradeLevel}; }
sub getCode            { return $_[0]->{code}; }
sub getProject         { return $_[0]->{project}; }
sub getFullText        { return $_[0]->{fullText}; }
sub getContent         { return $_[0]->{content}; }
sub getBody            { return $_[0]->{body}; }
sub getFootnotes       { return $_[0]->{footnotes}; }

sub getFootnotesAsString {
    my $self = shift;
    my $str  = '';
    foreach ( keys %{ $self->{footnotes} } ) {
        $str .=
            '<div id="footnote' 
          . $_
          . '" style="display:none;">'
          . $self->{footnotes}{$_}
          . '</div>';
    }
    return $str;
}

sub getFootnotesAsHtml {
    my $self = shift;

    my $html = '<table border="0" cellspacing="2" cellpadding="2">';

    foreach ( sort { $a <=> $b } keys %{ $self->{footnotes} } ) {
        $html .= <<END_HERE;
    <tr><td><b>[$_]</b></td><td> $self->{footnotes}->{$_}</td></tr>
END_HERE
    }

    $html .= '</table>';

    return $html;
}

sub getApprover {
    my ($self) = shift;
    $sql =
"SELECT CONCAT(u_last_name,', ', u_first_name) AS approver_name FROM user WHERE u_id="
      . " (SELECT ps_u_id FROM passage_status"
      . " WHERE p_id=$self->{id}"
      . " AND ps_new_dev_state=${ItemConstants::DS_CONTENT_REVIEW_2}"
      . " ORDER BY ps_timestamp DESC LIMIT 1)";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    if ( my $row = $sth->fetchrow_hashref ) {
        return $row->{approver_name};
    }

    return '';
}

sub getItems {
    my ($self) = shift;
    my %items = ();

    $sql =
"SELECT ic.i_id, (SELECT pi_sequence FROM passage_items WHERE p_id=$self->{id} AND i_id=ic.i_id) AS item_sequence FROM item_characterization AS ic WHERE ic.ic_type=${ItemConstants::OC_PASSAGE} AND ic.ic_value=$self->{id}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $items{ $row->{i_id} } =
          defined( $row->{item_sequence} ) ? $row->{item_sequence} : 0;
    }
    $sth->finish;

    return sort { $items{$a} <=> $items{$b} } keys %items;
}

sub getCompareBody {

    my ($self) = shift;

    my $sql =
"SELECT p_content FROM passage_status WHERE p_id=$self->{id} AND ps_new_dev_state != ${ItemConstants::DS_FIX_ART} AND ps_new_dev_state != ${ItemConstants::DS_NEW_ART} ORDER BY ps_timestamp DESC LIMIT 1, 1";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    if ( my $row = $sth->fetchrow_hashref ) {
        $sth->finish;
        return $row->{p_content};
    }
    else {
        $sth->finish;
        return '';
    }
}

sub getCompareFootnotes {

    my ($self) = shift;

    my $sql =
"SELECT ps_footnotes FROM passage_status WHERE p_id=$self->{id} AND ps_new_dev_state != ${ItemConstants::DS_FIX_ART} AND ps_new_dev_state != ${ItemConstants::DS_NEW_ART} ORDER BY ps_timestamp DESC LIMIT 1, 1";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute()
      || return $self->error( "Failed Query:" . $self->{dbh}->err );
    if ( my $row = $sth->fetchrow_hashref ) {
        $sth->finish;
        my %footnotes = ();
        my $str       = $row->{ps_footnotes};
        while ( $str =~ m/<div id="footnote(\d+)"[^>]+>(.*?)<\/div>/ ) {
            $footnotes{$1} = $2;
            $str =~ s/<div id="footnote\d+"[^>]+>(.*?)<\/div>//;
        }
        return %footnotes;

    }
    else {
        $sth->finish;
        return ();
    }
}

sub getHistory {
    my ($self) = shift;

    my %history = ();

    my $sql =
        "SELECT ps.*, u.* FROM passage_status AS ps, user AS u"
      . " WHERE ps.p_id=$self->{id} AND ps.ps_u_id=u.u_id"
      . " ORDER BY ps.ps_timestamp DESC";

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        next
          unless
            -e "${UrlConstants::orcaPath}passage-pdf/lib$row->{ib_id}/$self->{id}/$row->{ps_id}.pdf";

        my $key = $row->{ps_timestamp};
        $history{$key}            = {};
        $history{$key}{firstName} = $row->{u_first_name};
        $history{$key}{lastName}  = $row->{u_last_name};
        $history{$key}{devState}  = $dev_states{ $row->{ps_last_dev_state} };
        $history{$key}{view} =
"${UrlConstants::orcaUrl}passage-pdf/lib$row->{ib_id}/$self->{id}/$row->{ps_id}.pdf";
    }
    $sth->finish;

    return \%history;

}

sub getAllNotes {
    my ($self) = shift;

    my %notes = ();

    my $sql =
        "SELECT ps.*, u.* FROM passage_status AS ps, user AS u"
      . " WHERE ps.p_id=$self->{id} AND ps.p_notes != '' AND ps.ps_u_id=u.u_id"
      . " ORDER BY ps.ps_timestamp DESC";

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{ps_timestamp};
        $notes{$key}                = {};
        $notes{$key}{firstName}     = $row->{u_first_name};
        $notes{$key}{lastName}      = $row->{u_last_name};
        $notes{$key}{devState}      = $dev_states{ $row->{ps_last_dev_state} };
        $notes{$key}{devStateValue} = $row->{ps_last_dev_state};
	$notes{$key}{newDevStateValue} = $row->{ps_new_dev_state};
        $notes{$key}{notes}         = $row->{p_notes};
    }
    $sth->finish;

    return \%notes;
}

sub getMetafiles {
    my ($self) = shift;

    my %metafiles = ();

    my $sql =
        "SELECT pm.*, u.* FROM passage_metafiles AS pm, user AS u"
      . " WHERE pm.p_id=$self->{id} AND pm.u_id=u.u_id"
      . " ORDER BY pm.pm_timestamp DESC";

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{pm_timestamp};
        $metafiles{$key}            = {};
        $metafiles{$key}{firstName} = $row->{u_first_name};
        $metafiles{$key}{lastName}  = $row->{u_last_name};
        $metafiles{$key}{devState}  = $dev_states{ $row->{p_dev_state} };
        $metafiles{$key}{comment}   = $row->{pm_comment};
        $metafiles{$key}{name}      = $row->{pm_filename};
        $metafiles{$key}{view} =
          "${UrlConstants::orcaUrl}passage-metafiles/$self->{id}/$row->{pm_filename}";
    }
    $sth->finish;

    return \%metafiles;
}

#
# SETTERS
#
sub setGenre           { $_[0]->{genre}           = $_[1]; }
sub setSubGenre        { $_[0]->{subGenre}        = $_[1]; }
sub setTopic           { $_[0]->{topic}           = $_[1]; }
sub setReadingLevel    { $_[0]->{readingLevel}    = $_[1]; }
sub setSummary         { $_[0]->{summary}         = $_[1]; }
sub setCrossCurriculum { $_[0]->{crossCurriculum} = $_[1]; }
sub setCharEthnicity   { $_[0]->{charEthnicity}   = $_[1]; }
sub setCharGender      { $_[0]->{charGender}      = $_[1]; }
sub setNotes           { $_[0]->{notes}           = $_[1]; }
sub setButtonName      { $_[0]->{buttonName}      = $_[1]; }
sub setCode            { $_[0]->{code}            = $_[1]; }
sub setProject         { $_[0]->{project}         = $_[1]; }
sub setAuthor          { $_[0]->{author}          = $_[1]; }
sub setContentArea     { $_[0]->{contentArea}     = $_[1]; }
sub setGradeLevel      { $_[0]->{gradeLevel}      = $_[1]; }
sub setGradeSpanStart  { $_[0]->{gradeSpanStart} = $_[1]; }
sub setGradeSpanEnd  { $_[0]->{gradeSpanEnd} = $_[1]; }
sub setDevState        { $_[0]->{devState}        = $_[1]; }
sub setLanguage        { $_[0]->{language}        = $_[1]; }
sub setPublicationStatus        { $_[0]->{publicationStatus}        = $_[1]; }
sub setReadabilityIndex        { $_[0]->{readabilityIndex}        = $_[1]; }

sub setBody {

    my ($self) = shift;
    $self->{body} = ItemConstants::fixHtml(shift);
    $self->{body} =~ s/"\.\.\/passages\/lib/"${UrlConstants::orcaUrl}passages\/lib/g;
    $self->buildContent();
}

sub setFootnotes {

    my ($self) = shift;
    $self->{footnotes} = shift;

    foreach ( keys %{ $self->{footnotes} } ) {
        $self->{footnotes}{$_} =~ s/\s+$//;
        $self->{footnotes}{$_} =~ s/(?:&#160;)+$//;

        delete $self->{footnotes}{$_} if $self->{footnotes}{$_} eq '';
    }

    $self->buildContent();
}

#
# Create a new Passage
#
sub create {
    my ($self) = shift;
    my $bank   = shift;
    my $name   = shift;

    return 0 if $name eq '';

    my $sql = sprintf( 'SELECT p_id FROM passage WHERE p_name=%s AND ib_id=%d',
        $self->{dbh}->quote($name), $bank );
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute() || return 0;

    if ( $sth->fetchrow_hashref ) { $sth->finish; return 0; }

    $sql = sprintf( 'INSERT INTO passage SET p_name=%s, ib_id=%d',
        $self->{dbh}->quote($name), $bank );
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute() || return 0;

    $self->{id}   = $self->{dbh}->{mysql_insertid};
    $self->{bank} = $bank;
    $self->{name} = $name;

    my $pImageDir = "${ItemConstants::passagePath}lib${bank}/images/p$self->{id}/";
    mkdir $pImageDir;
    system( "chmod", "a+rw", "${pImageDir}" );

    $sth->finish;
    return 1;

}

#
# Save this Passage
#
sub save {
    my ($self) = shift;
    my $save_process = shift || 'System';
    my $save_user_id = shift || 0;
    my $save_detail = shift || '';

    return 0 if ( $self->{id} == 0 );

    my $parsedText = $self->{body};
    $parsedText =~ s/&#160;/ /g;
    $parsedText =~ s/&nbsp;/ /g;
    $parsedText =~ s/<[^>]+>/ /g;
    my @words = split /\s+/, $parsedText;
    $self->{wordCount} = scalar @words;

    $sql = sprintf(
'UPDATE passage SET p_genre=%d, p_subgenre=%s, p_topic=%s, p_reading_level=%s'
          . ', p_summary=%s, p_word_count=%d, p_cross_curriculum=%d, p_char_ethnicity=%d'
          . ', p_char_gender=%d, p_notes=%s, p_button_name=%s, p_code=%s'
          . ', p_dev_state=%d, p_lang=%d, p_author=%d, p_url=%s, ip_id=%d, p_publication_status=%d'
	  . ', p_readability_index=%s WHERE p_id=%d',
        $self->{genre},
        $self->{dbh}->quote( $self->{subGenre} ),
        $self->{dbh}->quote( $self->{topic} ),
        $self->{dbh}->quote( $self->{readingLevel} ),
        $self->{dbh}->quote( $self->{summary} ),
        $self->{wordCount},
        $self->{crossCurriculum},
        $self->{charEthnicity},
        $self->{charGender},
        $self->{dbh}->quote( $self->{notes} ),
        $self->{dbh}->quote( $self->{buttonName} ),
        $self->{dbh}->quote( $self->{code} ),
        $self->{devState},
        $self->{language},
        $self->{author},
        $self->{dbh}->quote("${ItemConstants::passageUrl}lib$self->{bank}/p$self->{id}.htm"),
        $self->{project},
	$self->{publicationStatus},
        $self->{dbh}->quote( $self->{readabilityIndex} ),
        $self->{id}
    );

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sth->finish;

    if ( $self->{contentArea} ne '' ) {
        &ItemConstants::dbCharUpdate( $self->{dbh}, $ItemConstants::OT_PASSAGE, $self->{id}, $ItemConstants::OC_CONTENT_AREA,
            $self->{contentArea} );
    }

    if ( $self->{gradeLevel} ne '' ) {
        &ItemConstants::dbCharUpdate( $self->{dbh}, $ItemConstants::OT_PASSAGE, $self->{id}, $ItemConstants::OC_GRADE_LEVEL,
            $self->{gradeLevel} );
    }

    if ( $self->{gradeSpanStart} ne '' ) {
        &ItemConstants::dbCharUpdate( $self->{dbh}, $ItemConstants::OT_PASSAGE, $self->{id}, $ItemConstants::OC_GRADE_SPAN_START,
            $self->{gradeSpanStart} );
    }

    if ( $self->{gradeSpanEnd} ne '' ) {
        &ItemConstants::dbCharUpdate( $self->{dbh}, $ItemConstants::OT_PASSAGE, $self->{id}, $ItemConstants::OC_GRADE_SPAN_END,
            $self->{gradeSpanEnd} );
    }

    # Figure out which auto-generated tag ID sequence we have already hit in this item

    my $max_id = $self->{max_content_id};

    while($self->{body} =~ / id="cde_([\d]+)"/g) {
      $max_id = int($1) if int($1) > $max_id;
    }

    $max_id++;

    $self->{max_content_id} = $max_id++;
     
    $self->{body} =~ s/<([^\s\/\!>]+)>/$self->get_tag_with_id($1,'')/eg;
    $self->{body} =~ s/<([^\s\/\!>]+)\s+([^>]+)>/$self->get_tag_with_id($1,$2)/eg;

    $self->buildContent();

    # save the content to the data file
    if ( $self->{fullText} ne '' ) {
        open OUT, ">${ItemConstants::passagePath}lib$self->{bank}/p$self->{id}.htm";
        print OUT $self->{fullText};
        close OUT;
    }

    # update the stored max content id
    $sql = 'UPDATE passage SET p_max_content_id=' . $self->{max_content_id} . ' WHERE p_id=' . $self->{id};
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    $sth->finish;

    if($save_user_id) {

      $sql = sprintf('INSERT INTO user_action_passage SET p_id=%d, u_id=%d, uap_process=%s, uap_detail=%s',
                   $self->{id},
		   $save_user_id,
		   $self->{dbh}->quote($save_process),
		   $self->{dbh}->quote($save_detail));
      $sth = $self->{dbh}->prepare($sql);
      $sth->execute();
      $sth->finish;
    }

    return 1;
}

#
# Copy the passage
#
sub copy {

    my ($self) = shift;
    my $newName = shift;

    $newName =~ s/[\\\/.\s]/_/g;
    if ( length($newName) > 30 ) {
        return 'Passage name exceeds 30 characters';
    }

    # Make sure there are no duplicates
    my $sql = "SELECT p_id FROM passage WHERE ib_id=$self->{bank} AND p_name="
      . $self->{dbh}->quote($newName);
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $sth->finish;
        return 'Passage name already exists in target bank';
    }

    # Proceed with the copy if we made it this far
    $sql = sprintf(
'INSERT INTO passage SET ib_id=%d, p_name=%s, p_summary=%s, p_genre=%d, p_subgenre=%s'
          . ', p_dev_state=1, p_button_name=%s',
        $self->{bank},
        $self->{dbh}->quote($newName),
        $self->{dbh}->quote( $self->{summary} ),
        $self->{genre},
        $self->{dbh}->quote( $self->{subGenre} ),
        $self->{dbh}->quote( $self->{buttonName} )
    );
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    my $psgId = $self->{dbh}->{mysql_insertid};
    my $html  = '';

    open IN, '<', "${ItemConstants::passagePath}lib$self->{bank}/p$self->{id}.htm";
    while (<IN>) { $html .= $_; }
    close IN;

    my $oldLib = "lib$self->{bank}/images/p$self->{id}";
    my $newLib = "lib$self->{bank}/images/p${psgId}";

    $html =~ s/\/$oldLib\//\/$newLib\//gs;

    open OUT, '>', "${ItemConstants::passagePath}lib$self->{bank}/p${psgId}.htm";
    print OUT $html;
    close OUT;

    system( "cp", "-r", "${ItemConstants::passagePath}${oldLib}/",
        "${ItemConstants::passagePath}${newLib}/" );

    $sql =
"SELECT * FROM object_characterization WHERE oc_object_type=${ItemConstants::OT_PASSAGE} AND oc_object_id=$self->{id}";
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $sql =
"INSERT INTO object_characterization SET oc_object_type=${ItemConstants::OT_PASSAGE}, oc_object_id=${psgId}, oc_characteristic=$row->{oc_characteristic}, oc_int_value=$row->{oc_int_value}";
        my $sth2 = $self->{dbh}->prepare($sql);
        $sth2->execute();
        $sth2->finish;
    }

    $sth->finish;

    return "Copied passage to '${newName}'";
}

#
# rebuild $self->{content}
#
sub buildContent {
    my ($self) = shift;

    my $footnoteText = '';
    foreach ( keys %{ $self->{footnotes} } ) {
        $footnoteText .= <<END_HERE;
		<div id="footnote$_" style="display:none;">$self->{footnotes}->{$_}</div>
END_HERE
    }

    $self->{content} = <<END_HERE;
	  <script language="JavaScript" src="${UrlConstants::orcaUrl}js/footnotes.js"></script>
		${footnoteText}
    $self->{body} 
END_HERE

    $self->{content} =~
s/<sup>\[(\d+)\]<\/sup>/<span style="content-decoration:underline;" onMouseOver="showFootnote('footnote$1');" onMouseOut="hideFootnote('footnote$1');"><sup>[$1]<\/sup><\/span>/g;

    $self->buildFullText();
}

#
# rebuild $self->{fullText}
#
sub buildFullText {
    my ($self) = shift;

    $self->{fullText} = <<END_HERE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head>
	  <link href="${UrlConstants::orcaUrl}style/uir.css" rel="stylesheet" type="text/css" />
  </head>
	<body>
  $self->{content}
	</body>
</html>	
END_HERE
}

sub toHTML {
    my ($self) = shift;

    return <<END_HERE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head>
	  <link href="${UrlConstants::orcaUrl}style/uir.css" rel="stylesheet" type="text/css" />
  </head>
	<body>
  $self->{body}
	</body>
</html>	
END_HERE
}

sub get_tag_with_id {

 my ($self) = shift;
 my $tag = shift;
 my $attribute_string = shift || '';

 unless($attribute_string =~ /id=["']/ || $tag eq 'br' || $tag eq 'hr') {

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

sub error {
    my ($self) = shift;
    my $message = shift;

    warn( $message );
    return 0;
}

1;
