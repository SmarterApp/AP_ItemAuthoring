package Rubric;

use URI::Escape;
use DBI;
use ItemConstants;
use File::Glob ':glob';

#
# Constructor takes 2 params
# 1) DB handle
# 2) Rubric ID
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
            'SELECT r.*'
          . ", (SELECT oc_int_value FROM object_characterization WHERE oc_object_type=${ItemConstants::OT_RUBRIC} AND oc_object_id=r.sr_id AND oc_characteristic=${ItemConstants::OC_CONTENT_AREA}) AS content_area"
          . ", (SELECT oc_int_value FROM object_characterization WHERE oc_object_type=${ItemConstants::OT_RUBRIC} AND oc_object_id=r.sr_id AND oc_characteristic=${ItemConstants::OC_GRADE_LEVEL}) AS grade_level"
          . ' FROM scoring_rubric AS r WHERE '
          . ( $self->{name} eq ''
            ? "r.sr_id=$self->{id}"
            : 'r.sr_name='
              . $self->{dbh}->quote( $self->{name} )
              . " AND r.ib_id=$self->{id}" );
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute();

        if ( my $row = $sth->fetchrow_hashref ) {
            $sql = 'SELECT * FROM item_bank WHERE ib_id=' . $row->{ib_id};
            my $sth2 = $self->{dbh}->prepare($sql);
            $sth2->execute();
            if ( my $row2 = $sth2->fetchrow_hashref ) {
                $self->{bankName} = $row2->{ib_external_id};
            }

            $self->{id}          = $row->{sr_id};
            $self->{bank}        = $row->{ib_id};
            $self->{name}        = $row->{sr_name};
            $self->{summary}     = $row->{sr_description};
            $self->{url}         = $row->{sr_url};
            $self->{contentArea} = $row->{content_area} || '';
            $self->{gradeLevel}  = $row->{grade_level} || '';

            $self->{fullText} = '';
            $self->{content}  = '';

            if ( -e "${ItemConstants::rubricPath}lib$self->{bank}/r$self->{id}.htm" ) {
                open INFILE, "<${ItemConstants::rubricPath}lib$self->{bank}/r$self->{id}.htm";
                while (<INFILE>) {
                    chomp;
                    $self->{fullText} .= $_;
                }
                close INFILE;

                $self->{content} = $self->{fullText};
                if ( $self->{content} =~ m/<body>(.*)<\/body>/s ) {
                    $self->{content} = $1;
                }

            }
            $loadDefaults = 0;
        }

        $sth->finish;
    }

    if ($loadDefaults) {

        $self->{id}          = 0;
        $self->{bank}        = 0;
        $self->{name}        = '';
        $self->{summary}     = '';
        $self->{url}         = '';
        $self->{contentArea} = '';
        $self->{gradeLevel}  = '';
        $self->{fullText}    = '';
        $self->{content}     = '';
    }

    bless( $self, $type );
    return ($self);
}

#
# GETTERS
#
sub getName        { return $_[0]->{name}; }
sub getSummary     { return $_[0]->{summary}; }
sub getContentArea { return $_[0]->{contentArea}; }
sub getGradeLevel  { return $_[0]->{gradeLevel}; }
sub getFullText    { return $_[0]->{fullText}; }
sub getContent     { return $_[0]->{content}; }

sub getItems {
    my ($self) = shift;
    my @items = ();

    $sql =
"SELECT i_id FROM item_characterization WHERE ic_type=${ItemConstants::OC_RUBRIC} AND ic_value=$self->{id}";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        push( @items, $row->{i_id} );
    }
    $sth->finish;
    return @items;
}

#
# SETTERS
#
sub setSummary     { $_[0]->{summary}     = $_[1]; }
sub setContentArea { $_[0]->{contentArea} = $_[1]; }
sub setGradeLevel  { $_[0]->{gradeLevel}  = $_[1]; }

sub setContent {

    my ($self) = shift;
    $self->{content} = &fixHtml(shift);
    $self->{content} =~ s/"\.\.\/rubrics\/lib/"${UrlConstants::orcaUrl}rubrics\/lib/g;
    $self->buildFullText();
}

#
# Create a new Rubric
#
sub create {
    my ($self) = shift;
    my $bank   = shift;
    my $name   = shift;

    my $sql =
      sprintf( 'SELECT sr_id FROM scoring_rubric WHERE sr_name=%s AND ib_id=%d',
        $self->{dbh}->quote($name), $bank );
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute() || return 0;

    if ( $sth->fetchrow_hashref ) { $sth->finish; return 0; }

    $sql = sprintf( 'INSERT INTO scoring_rubric SET sr_name=%s, ib_id=%d',
        $self->{dbh}->quote($name), $bank );
    $sth = $self->{dbh}->prepare($sql);
    $sth->execute() || return 0;

    $self->{id}   = $self->{dbh}->{mysql_insertid};
    $self->{bank} = $bank;
    $self->{name} = $name;

    my $rImageDir = "${ItemConstants::rubricPath}lib${bank}/images/r$self->{id}/";
    mkdir $rImageDir;
    system( "chmod", "a+rw", "${rImageDir}" );

    $sth->finish;
    return 1;

}

#
# Save this Rubric
#
sub save {
    my ($self) = shift;

    return 0 if ( $self->{id} == 0 );

    $sql = sprintf(
        'UPDATE scoring_rubric SET'
          . ' sr_description=%s, sr_url=%s'
          . ' WHERE sr_id=%d',
        $self->{dbh}->quote( $self->{summary} ),
        $self->{dbh}->quote("${ItemConstants::rubricUrl}lib$self->{bank}/r$self->{id}.htm"),
        $self->{id}
    );

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();

    $sth->finish;

    if ( $self->{contentArea} ne '' ) {
        &ItemConstants::dbCharUpdate( $self->{dbh}, $ItemConstants::OT_RUBRIC, $self->{id}, $ItemConstants::OC_CONTENT_AREA,
            $self->{contentArea} );
    }

    if ( $self->{gradeLevel} ne '' ) {
        &ItemConstants::dbCharUpdate( $self->{dbh}, $ItemConstants::OT_RUBRIC, $self->{id}, $ItemConstants::OC_GRADE_LEVEL,
            $self->{gradeLevel} );
    }

    # save the content to the data file
    if ( $self->{fullText} ne '' ) {
        open OUT, ">${ItemConstants::rubricPath}lib$self->{bank}/r$self->{id}.htm";
        print OUT $self->{fullText};
        close OUT;
    }

    return 1;
}

#
# rebuild $self->{fullText}
#
sub buildFullText {
    my ($self) = shift;

    $self->{fullText} = <<END_HERE;
<html>
  <head>
  </head>
	<body>
  $self->{content}
	</body>
</html>	
END_HERE
}

1;
