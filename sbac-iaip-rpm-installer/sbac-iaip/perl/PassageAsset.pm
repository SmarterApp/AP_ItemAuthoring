package PassageAsset;

use File::Glob ':glob';
use File::Copy 'cp';
use File::Path qw(make_path remove_tree);
use UrlConstants;
use Passage;

#
# Constructor takes 3 params
# 1) Item Bank ID
# 2) Passage ID
# 3) Asset Name (e.g. image.gif)
#

sub new {

    my ($type) = shift;
    my ($self) = {};
    $self->{bankId}    = shift;
    $self->{passageId} = shift;
    $self->{name}      = shift || '';

    $self->{name} =~ /(.*)\.(\w+)$/;

    $self->{title} = $1;
    $self->{ext}   = lc($2);
    $self->{title} =~ tr/ /_/;
    $self->{title} =~ tr/./_/;
    $self->{title} =~ s/^V\d+\.//;

    $self->{name} = $self->{title} . '.' . $self->{ext};

    $self->{baseUrl} =
      "${UrlConstants::orcaUrl}passages/lib$self->{bankId}/images/p$self->{passageId}/";
    $self->{basePath} = $UrlConstants::webPath . $self->{baseUrl};
    make_path( $self->{basePath} );

    $self->{url}  = $self->{baseUrl} . $self->{name};
    $self->{path} = $UrlConstants::webPath . $self->{url};

    $self->{date} = ( stat( $self->{path} ) )[9];

    bless( $self, $type );

    if ( $self->{ext} eq 'svg' ) {
        $self->initSVG();
    }

    return ($self);
}

sub save {

    my ($self) = shift;
    my $fh = shift;

    open FILE, ">$self->{path}" || return 0;
    binmode FILE;
    while (<$fh>) { print FILE; }
    close FILE;

    return 1;
}

sub create {

    my ($self) = shift;
    my $fh = shift;

    if ( -e $self->{path} ) { return 0; }

    open FILE, ">$self->{path}" || return 0;
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

    my $psg = new Passage( $dbh, $self->{bankId}, $self->{passageId} );
    my $url = $self->{url};
    if ( $psg->{content} =~ /$url/ ) {
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

BEGIN {
}

1;
