package ItemAsset;

use File::Glob ':glob';
use File::Copy 'cp';
use File::Path qw(make_path remove_tree);
use Cwd;
use ItemConstants;
use UrlConstants;
use Item;

my @source_extensions = qw/tex asy/;
my $config_extension  = 'ogt';

sub from_db {
  my $class = shift;
  
  bless($self, $class);
  
  if ( $self->{ext} eq 'svg' ) {
        $self->initSVG();
  }
  return $self;
}

#
# Constructor takes 4 params
# 1) Item Bank ID
# 2) Item Name
# 3) Item Version
# 4) Asset Name (e.g. image.gif)
#
sub new {

    my ($type) = shift;
    my ($self) = {};
    $self->{bankId}      = shift;
    $self->{itemName}    = shift;
    $self->{itemVersion} = shift || 0;
    $self->{name}        = shift || '';
    $self->{width}       = '';
    $self->{height}      = '';
    $self->{sourcePath}  = '';
    $self->{configPath}  = '';

    $self->{name} =~ /(.*)\.(\w+)$/;

    $self->{title} = $1;
    $self->{ext}   = $2;
    $self->{ext}   = lc( $self->{ext} );
    $self->{title} =~ tr/ /_/;
    $self->{title} =~ tr/./_/;
    $self->{title} =~ s/^V\d+\.//;

    $self->{name} = $self->{title} . '.' . $self->{ext};
    $self->{fileName} =
      $self->{itemVersion}
      ? "V$self->{itemVersion}.$self->{title}.$self->{ext}"
      : "$self->{title}.$self->{ext}";

    $self->{baseUrl} = "${UrlConstants::orcaUrl}images/lib$self->{bankId}/$self->{itemName}/";
    $self->{basePath} = ${UrlConstants::webPath} . $self->{baseUrl};

    $self->{url}  = $self->{baseUrl} . $self->{fileName};
    $self->{path} = ${UrlConstants::webPath} . $self->{url};

    my $asset_path = sprintf '%s/%simages/lib%d/%s/', ${UrlConstants::webPath}, $orcaUrl, $self->{bankId}, $self->{itemName};
    make_path( $asset_path ) unless(-e $asset_path);

    # Get the path to any source or config files
    $self->{path} =~ /^(.+)\.\w+$/;
    foreach (@source_extensions) {
        if ( -e $1 . '.' . $_ ) {
            $self->{sourcePath} = $1 . '.' . $_;
        }
    }

    if ( -e $1 . '.' . $config_extension ) {
        $self->{configPath} = $1 . '.' . $config_extension;
    }

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

    if ( $self->{ext} eq 'svg' ) {
        $self->initSVG();
    }

    return 1;
}

sub copy {

    my ($self) = shift;

    my $counter = 0;

    my $prefix =
      $self->{itemVersion}
      ? "$self->{basePath}V$self->{itemVersion}.$self->{title}"
      : "$self->{basePath}$self->{title}";

    while ( -e "${prefix}_${counter}.$self->{ext}" ) {
        $counter++;
    }

    cp( "${prefix}.$self->{ext}", "${prefix}_${counter}.$self->{ext}" );

    return 1;
}

sub delete {

    my ($self) = shift;
    my $dbh = shift;

    my $item =
      new Item( $dbh, $self->{bankId}, $self->{itemName},
        $self->{itemVersion} );
    my $url = $self->{url};
    if ( $item->{rawXML} =~ /$url/ ) {
        return 0;
    }
    else {
        my $prefix = $self->{path};
        $prefix =~ s/\.\w+$//;

        foreach ( bsd_glob( $prefix . '.*' ) ) {
            unlink($_);
        }

	# Delete Asset Pair file as well
	my @nodes = split /\//, $self->{path};
	my $cap_asset_name = pop @nodes;
	my $cap_pair_name  = &getContentAssetPair($dbh, $OT_ITEM, $item->{id}, $cap_asset_name);
	if( $cap_pair_name ) {
	    push @nodes, $cap_pair_name;
	    unlink(join('/',@nodes));
	}
	
	my $sql = sprintf('DELETE FROM content_asset_pair WHERE cap_object_type=%d AND cap_object_id=%d AND cap_asset_name=%s',
	                  $OT_ITEM, $item->{id}, $dbh->quote($cap_asset_name));
        my $sth = $dbh->prepare($sql);
	$sth->execute();
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

        # make sure a view box is set so it scales properly
	unless($svgString =~ /viewBox="/) {
	  $svgString =~ s/<svg\s/<svg viewBox="0 0 $self->{width} $self->{height}" /s;
	}

        $svgString =~ s/<i:pgf [^>]+>.*<\/i:pgf>//s;

        open SVG, ">$self->{path}";
        print SVG $svgString;
        close SVG;
    }
}

1;
