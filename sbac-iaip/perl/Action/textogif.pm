package Action::textogif;

use Cwd;
use File::Copy;
use URI;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  my $asset_dir = "${imagesDir}lib$in{itemBankId}/$in{itemId}";
  
  my $assetUrl = "${imagesUrl}lib$in{itemBankId}/$in{itemId}";
  
  #
  #                          T E X T O G I F
  #
  #                          by John Walker
  #                      http://www.fourmilab.ch/
  #
  $version = '1.1 (2003-11-07)';
  
  #
  #
  #   Converts a LaTeX file containing equations(s) into a GIF file for
  #   embedding into an HTML document.  The black and white image of the
  #   equation is created at high resolution and then resampled to the
  #   target resolution to antialias what would otherwise be jagged
  #   edges.
  #
  #   Online documentation with sample output is available on the Web
  #   at http://www.fourmilab.ch/webtools/textogif/
  #
  #   Write your equation (or anything else you can typeset with LaTeX)
  #   in a file like:
  #
  #       \documentclass[12pt]{article}
  #       \pagestyle{empty}
  #       \begin{document}
  #
  #       \begin{displaymath}
  #       \bf  % Compiled formulae often look better in boldface
  #       \int H(x,x')\psi(x')dx' = -\frac{\hbar2}{2m}\frac{d2}{dx2}
  #                                 \psi(x)+V(x)\psi(x)
  #       \end{displaymath}
  #
  #       \end{document}
  #
  #   The "\pagestyle{empty}" is required to avoid generating a huge
  #   image with a page number at the bottom.
  #
  #   Then (assuming you have all the software described below installed
  #   properly), you can simply say:
  #
  #       textogif [options] filename ...
  #
  #   to compile filename.tex to filename.gif, an interlaced,
  #   transparent background GIF file ready to use an an inline image.
  #   You can specify the base name, for example, "schrod", rather than
  #   the full name of the TeX file ("schrod.tex").  TeX requires the
  #   input file to have an extension of ".tex".  The command line
  #   options are described in the help text at the end of this program
  #   and in the "Default Configuration" section below.
  #
  #   A sample IMG tag, including the image width and height is printed
  #   on standard error, for example:
  #
  #       <img src="schrod.gif" width=508 height=56>
  #
  #                         Required Software
  #
  #   This script requires the following software to be installed
  #   in the standard manner.  Version numbers are those used in the
  #   development and testing of the script.
  #
  #   Perl        5.8.0 (anything later than 4.036 should work)
  #   TeX         3.14159 (Web2C 7.3.1)
  #   LaTeX2e     <2000/06/01>
  #   dvips       dvipsk 5.86
  #   Ghostscript 6.52 (2001-10-20)
  #   Netpbm      9.24
  #
  #
  #                       Default Configuration
  #
  #   The following settings are the defaults used if the -dpi and
  #   -res options are not specified on the command line.
  #
  $dpi = 300;
  
  #
  #
  $res = 0.125;
  if ( $in{quick} eq 'yes' ) { $res = 1.0; }
  
  #
  #   The $background parameter supplies a command, which may be
  #   void, to be inserted in the image processing pipeline to
  #   adjust the original black-on-white image so that its background
  #   agrees with that of the document in which it is to be inserted.
  #   For a document with the default grey background used by Mosaic
  #   and old versions of Netscape, use:
  #
  #       $background = "ppmdim 0.7 |";  $transparent = "b2/b2/b2";
  #
  #   If your document uses a white background, the void specification:
  #
  #       $background = "";  $transparent = "ff/ff/ff";
  #
  #   should be used.  For colour or pattern backgrounds, you'll have
  #   to hack the code.  The reason for adjusting the background is to
  #   ensure that when the image is resampled and then output with a
  #   transparent background the edges of the characters will fade
  #   smoothly into the page background.  Otherwise you'll get a
  #   distracting "halo" around each character.  You can override this
  #   default specification with the -grey command line option.
  #
  $background  = "";
  $transparent = "ff/ff/ff";
  
  #
  #   Image generation and decoding commands for GIF and PNG output.
  #
  $cmdGIF       = '/usr/bin/ppmtogif';
  $cmdGIFdecode = '/usr/bin/giftopnm';
  $cmdPNG       = '/usr/bin/pnmtopng';
  $cmdPNGdecode = '/usr/bin/pngtopnm';
  
  #
  #   Default image creation modes
  #
  $imageCmd  = $cmdGIF;
  $imageCmdD = $cmdGIFdecode;
  $imageExt  = 'gif';
  
  #
  #   Command line option processing
  #
  if ( defined $in{"gif"} ) {    # -gif
      $imageCmd  = $cmdGIF;
      $imageCmdD = $cmdGIFdecode;
      $imageExt  = 'gif';
  }
  if ( defined $in{grey} ) {     # -grey n
      $grey        = $in{grey};
      $background  = "/usr/bin/ppmdim ${grey} 2>/dev/null | ";
      $greylev     = int( 255 * $grey );
      $transparent = sprintf( "%02x/%02x/%02x", $greylev, $greylev, $greylev );
  }
  if ( defined $in{png} ) {      # -png
      $imageCmd  = $cmdPNG;
      $imageCmdD = $cmdPNGdecode;
      $imageExt  = 'png';
  }
  
  #
  #   Main file processing loop
  #
  
  my $f = $in{assetId};
  $f =~ s/\.tex$//;
  $f =~ s/\.asy$//;
  
  my $orig_dir = Cwd::abs_path;
  chdir($textogif_dir);
  
  my $pbm_file = "temp_$$.pbm";
  my $retcode = 0;
  
  if ( $in{type} eq 'asy' ) {
      my $fsize = int( 30 * sprintf( "%f", $in{size} ) );
      my $density;
      my $asyCmd     = "/usr/bin/asy ${f}";
      my $convertCmd = "/usr/bin/convert -density 300x300 -geometry ${fsize}\%x"
        . " ${f}.eps ${f}.${imageExt}";
      $retcode = &syscmd($asyCmd);
      $retcode = &syscmd($convertCmd) if $retcode == 0;
  }
  elsif ( $in{type} eq 'tex' ) {
      my $latexCmd =
        "echo x | /usr/bin/latex --interaction=nonstopmode ${f} >/dev/null 2>/dev/null";
  
      my $dviCmd =
        "/usr/bin/dvips -X 300 -Y 300 -E -f ${f} > temp_$$.ps 2>/dev/null";
  
      my $convertCmd =
  "/usr/bin/convert -density ${dpi}x${dpi} -quality 90 -trim -background white -sharpen 0.5 -resize 50\%x "
        . " temp_$$.ps ${f}.${imageExt}";
  
      $retcode = &syscmd($latexCmd);
      $retcode = &syscmd($dviCmd) if $retcode == 0;
      $retcode = &syscmd($convertCmd) if $retcode == 0;
  
      #   Sweep up debris left around by the various intermediate steps
      unlink("${f}.dvi");
      unlink("${f}.aux");
      unlink("${f}.tex");
      unlink("${f}.log");
      unlink("temp_$$.ps");
  }
  
  if ( $in{type} eq 'asy' ) {
      unlink("${f}.asy");
      unlink("${f}.eps");
  }
  
  if (-e "${asset_dir}/${f}.${imageExt}") {
      unlink("${asset_dir}/${f}.${imageExt}");
  }
  
  if (-e "${f}.${imageExt}") {
      copy( "${f}.${imageExt}", "${asset_dir}/${f}.${imageExt}" );
      unlink("${f}.${imageExt}");
  }
  
  chdir("${orig_dir}");
  
  my $imgPath      = "${assetUrl}/${f}.${imageExt}";
  my $imageAbsPath = "${asset_dir}/${f}.${imageExt}";
  
  if ($retcode == 0) {
    warn "returning image at $imgPath";
    return [ $q->psgi_redirect(
      -location      => $imgPath,
      -type          => "image/${imageExt}",
      -pragma        => 'nocache',
      -cache_control => 'no-cache, must-revalidate'), ['']];
  } else {
    my $psgi_out = <<END_HERE;
  <html>
    <head>
      <title>Graphic Error</title>
      <body>
        <div style="color:#ff0000;font-weight:bold;font-size:14pt">Error encountered creating graphic: Check TeX syntax!</div>
      </body>
    </head>
  </html>
END_HERE
    return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
}
# DONE!

#	Echo and execute a system command

sub syscmd {
    my $cmd = shift;

    system($cmd) == 0 || warn( "Error with: $cmd\n" );

    if ($? == -1) {
       warn "Failed to execute: $!\n";
    } elsif ($? & 127) {
       warn "Child died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? "with" : "without";
    } elsif ($? != 0) {
       warn "Child exited with value %d\n", $? >> 8;
    }

    return $?;
}

#	Print help text

sub help {
    warn <<EOD;
usage: textogif [ options ] texfile...
    Options:
        -dpi n          Set rendering dots per inch to n (default 150)
        -gif            Generate GIF image (default)
        -grey           Grey scale background level: 0 = black, 1 = white (default)
        -help           Print this message
        -png            Generate PNG image
        -res n          Set oversampling ratio, smaller = finer (default 0.5)
        -version        Print version number
For documentation and the latest version of this program
please visit the Web page:
    http://www.fourmilab.ch/webtools/textogif/
EOD
}
1;
