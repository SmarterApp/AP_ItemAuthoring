package RubricAsset;

use File::Glob ':glob';
use File::Copy 'cp';
use UrlConstants;
use Rubric;

#
# Constructor takes 3 params
# 1) Item Bank ID
# 2) Rubric ID
# 3) Asset Name (e.g. image.gif)
#

sub new {

    my ($type) = shift;
    my ($self) = {};
    $self->{bankId}   = shift;
    $self->{rubricId} = shift;
    $self->{name}     = shift || '';
    $self->{width}       = '';
    $self->{height}      = '';

    $self->{name} =~ /(.*)\.(\w+)$/;

    $self->{title} = $1;
    $self->{ext}   = $2;
    $self->{title} =~ tr/ /_/;
    $self->{title} =~ tr/./_/;
    $self->{title} =~ s/^V\d+\.//;

    $self->{name} = $self->{title} . '.' . $self->{ext};

    $self->{baseUrl} =
      "${UrlConstants::orcaUrl}rubrics/lib$self->{bankId}/images/r$self->{rubricId}/";
    $self->{basePath} = $UrlConstants::webPath . $self->{baseUrl};

    $self->{url}  = $self->{baseUrl} . $self->{name};
    $self->{path} = $UrlConstants::webPath . '/' . $self->{url};

    bless( $self, $type );

    if ( $self->{ext} eq 'svg' ) {
        $self->initSVG();
    }
 
    return ($self);
}

sub save {

    my ($self) = shift;
    my $fh = shift;

    open FILE, ">$self->{url}" || return 0;
    binmode FILE;
    while (<$fh>) { print FILE; }
    close FILE;

    return 1;
}

sub create {

    my ($self) = shift;
    my $fh = shift;

    unless ( -e $self->{basePath} ) {
    	mkdir $self->{basePath};
    }
    
    if ( -e $self->{path} ) { return 0; }
    #warn "RubricAsset->create [path: $self->{path}]\n";
    open FILE, ">$self->{path}" || return 0;
    #warn "RubricAsset->create [$!]\n";
    binmode FILE;
    while (<$fh>) { print FILE; }
    close FILE;

    return 1;
}

sub copy {

    my ($self) = shift;

    my $counter = 0;

    my $prefix = "$self->{basePath}$self->{title}";

    while ( -e "${prefix}_${counter}.$self->{ext}" ) {
        $counter++;
    }

    cp( "${prefix}.$self->{ext}", "${prefix}_${counter}.$self->{ext}" );

    return 1;
}

sub delete {

    my ($self) = shift;
    my $dbh = shift;

    my $rub = new Rubric( $dbh, $self->{bankId}, $self->{rubricId} );
    my $url = $self->{url};
    if ( $rub->{content} =~ /$url/ ) {
        return 0;
    }
    else {
        my $prefix = $self->{path};
        $prefix =~ s/\.\w+$//;

        foreach ( bsd_glob( $prefix . '.*' ) ) {
            unlink($_);
        }
    }
    return 1;
}

sub initSVG {
    my ($self) = shift;

    # Read the width and height from the SVG file, and add initSVG(evt) call if needed
    if ( -e $self->{path} ) {
        my $foundInit = 0;

        open SVG, "<$self->{path}";
        my $svgString = '';
        while (<SVG>) {
            $svgString .= $_;
        }
        close SVG;

        if ( $svgString =~ /width="([\d.]+)pt"\s+height="([\d.]+)pt"/ ) {
            $self->{width}  = int( $1 * 2.2 );
            $self->{height} = int( $2 * 2.2 );
        }
        elsif ( $svgString =~ /width="([\d.]+)px"\s+height="([\d.]+)px"/ ) {
            $self->{width}  = int($1);
            $self->{height} = int($2);
        }
        elsif ( $svgString =~ /width="([\d.]+)in"\s+height="([\d.]+)in"/ ) {
            $self->{width}  = int( $1 * 300 );
            $self->{height} = int( $2 * 300 );
        }
        elsif ( $svgString =~ /width="([\d.]+)"\s+height="([\d.]+)"/ ) {
            $self->{width}  = int($1);
            $self->{height} = int($2);
        }

        unless ( $svgString =~ /initSVG/ ) {
            $svgString =~ s/<i:pgf [^>]+>.*<\/i:pgf>//s;

            open SVG, ">$self->{path}";
            print SVG $svgString;
            close SVG;
        }
    }
}

1;
