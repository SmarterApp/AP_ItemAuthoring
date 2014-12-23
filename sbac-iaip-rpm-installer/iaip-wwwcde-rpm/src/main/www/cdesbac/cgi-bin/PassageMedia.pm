package PassageMedia;
require Exporter;

use CGI::Carp;
use UrlConstants;
use File::Path qw(make_path remove_tree);

@ISA = qw(Exporter);
#@EXPORT = qw(&get_server_filename);
@EXPORT_OK = qw(Media_Extensions);

use constant Media_Extensions =>  qw(mp3 m4a m4v swf mp4);
my %media_ext = map { $_ => 1 } Media_Extensions;
my %audio_media_ext = (
  "mp3" => 1,
  "m4a" => 1,
  "mp4" => 1 # not supported by jplayer as an audio format
);
my %video_media_ext = (
  "m4v" => 1,
  "mp4" => 1 # not supported by jplayer as a video format
);

sub new {
  my $class = shift;
  my $passage = shift;
  my $clnt_filename = shift;
  my $description = shift;

  # get extension and clean up generate file name
  $clnt_filename =~ /(.*)\.(\w+)$/;
  my $title = $1;
  my $ext = lc($2); 
  $title =~ tr/ /_/;
  $title =~ tr/./_/;
  $title =~ s/^V\d+\.//;
  $clnt_filename = $title . "." . $ext;

  # generate server name
  my @date = localtime(time);
  my $tstamp = sprintf('%4d%02d%02d_%02d%02d%02d', $date[5] + 1900, $date[4] + 1, $date[3], $date[2], $date[1], $date[0]);
  
  my $passage_name = $passage->{name};
  $passage_name =~ tr/ /_/;
  $passage_name =~ tr/./_/;

  my $srvr_filename = $passage_name . "_$tstamp.$ext";

  my $base_url = "${orcaUrl}passages/lib$passage->{bank}/media/p$passage->{id}/";

  my $self = {
    ITEM_BANK_ID => $passage->{bank},
    PASSAGE_ID => $passage->{id},
    PASSAGE_MEDIA_ID => 0,
    SERVER_FILENAME => $srvr_filename,
    CLIENT_FILENAME => $clnt_filename,
    DESCRIPTION => $description,
    FILE_EXTENSION => $ext,
    BASE_URL => $base_url,
    BASE_PATH => $webPath . $base_url,
    URL => $base_url . $srvr_filename,
    PATH => $webPath . $base_url . $srvr_filename
  };

  bless( $self, $class );
  make_path( $self->{BASE_PATH} );
  return $self;
}

sub from_db {
  my $class = shift;
  my $pm_id = shift;

  my $self = {};

  use DBI;
  my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
  my $sql = sprintf( "SELECT p.ib_id, p.p_id, pm_srvr_filename, pm_clnt_filename, pm_description FROM passage_media AS pm JOIN passage AS p on pm.p_id=p.p_id WHERE pm_id=%d", $pm_id );
  my $sth = $dbh->prepare( $sql );  
  $sth->execute();

  if ( my $row = $sth->fetchrow_hashref ) {
    $self->{ITEM_BANK_ID} = $row->{ib_id};
    $self->{PASSAGE_ID} = $row->{p_id};
    $self->{PASSAGE_MEDIA_ID} = $pm_id;
    $self->{SERVER_FILENAME} = $row->{pm_srvr_filename};
    $self->{CLIENT_FILENAME} = $row->{pm_clnt_filename};
    $self->{DESCRIPTION} = $row->{pm_description};
  };

  $sth->finish();
  $dbh->disconnect();

  $self->{CLIENT_FILENAME} =~ /(.*)\.(\w+)$/;
  $self->{FILE_EXTENSION} = lc($2);
  $self->{BASE_URL} = "${orcaUrl}passages/lib$self->{ITEM_BANK_ID}/media/p$self->{PASSAGE_ID}/";
  $self->{BASE_PATH} = $webPath . $self->{BASE_URL};
  $self->{URL} = $self->{BASE_URL} . $self->{SERVER_FILENAME};
  $self->{PATH} = $webPath . $self->{URL};

  bless( $self, $class );
  return $self;
}

sub create {
    my $self = shift;
    my $fh = shift;
    my $u_id = shift;

#carp "[media path exists:". (-e $self->{PATH}) ."]";

    # exit out if file already exists
    if ( -e $self->{PATH} ) { return 0; }
    
    open FILE, ">$self->{PATH}" || return 0;
    binmode FILE; 
    while (<$fh>) { print FILE; }
    close FILE;

#carp "[media path exists:". (-e $self->{PATH}) ."]";

    use DBI;
    my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
    my $sql = sprintf( "INSERT INTO passage_media SET p_id=%d, pm_clnt_filename=%s, pm_srvr_filename=%s, pm_description=%s, pm_u_id=%d, pm_timestamp=NOW();",
        $self->{PASSAGE_ID}, $dbh->quote($self->{CLIENT_FILENAME}), $dbh->quote($self->{SERVER_FILENAME}), $dbh->quote($self->{DESCRIPTION}), $u_id );
    my $sth = $dbh->prepare( $sql );
    $sth->execute() || return 0;
    $sth->finish();
    $self->{PASSAGE_MEDIA_ID} = $dbh->{mysql_insertid};
    $dbh->disconnect();

    return 1;
}

sub delete {
    my $self = shift;
    
    unlink( $self->{PATH} );

    use DBI;
    my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
    my $sql = sprintf( "DELETE FROM passage_media WHERE pm_id=%d", $self->{PASSAGE_MEDIA_ID});
    my $sth = $dbh->prepare( $sql );
    $sth->execute() || return 0;
    $sth->finish();
    $dbh->disconnect();

    return 1;
}

sub save {
    my $self = shift;
    my $fh = shift;
    my $u_id = shift;

    open FILE, ">$self->{PATH}" || return 0;
    binmode FILE;
    while (<$fh>) { print FILE; }
    close FILE;

    use DBI;
    my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
    my $sql = sprintf( "UPDATE passage_media SET p_id=%d, pm_clnt_filename=%s, pm_srvr_filename=%s, pm_description=%s, pm_u_id=%d, pm_timestamp=NOW() WHERE pm_id=%d;",
        $self->{PASSAGE_ID}, $dbh->quote($self->{CLIENT_FILENAME}), $dbh->quote($self->{SERVER_FILENAME}), $dbh->quote($self->{DESCRIPTION}), $u_id, $self->{PASSAGE_MEDIA_ID});
    my $sth = $dbh->prepare( $sql );
    $sth->execute() || return 0;
    $sth->finish();
    $dbh->disconnect();

    return 1;
}

sub get_id {
  my $self = shift;
  $self->{PASSAGE_MEDIA_ID}
}

sub get_server_filename {
  my $self = shift;
  return $self->{SERVER_FILENAME};
}

sub get_client_filename {
  my $self = shift;
  return $self->{CLIENT_FILENAME};
}

sub get_description {
  my $self = shift;
  return $self->{DESCRIPTION};
}

sub get_filesize {
  my $self = shift;
  return sprintf ("%.1f", (-s $self->{PATH})/1024);
}

sub get_extension {
  my $self = shift;
  return $self->{FILE_EXTENSION};
}

sub get_style_library_includes {
  my $self = shift;

  my $css_inc =  <<CSS_INCLUDES;
<link href="${orcaUrl}style/O2Template.css" rel="stylesheet" type="text/css">
<link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
CSS_INCLUDES
  if (exists $media_ext{$self->{FILE_EXTENSION}}) {
    if ($self->{FILE_EXTENSION} ne "swf") {
      $css_inc .= <<CSS_INCLUDES;
<link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
CSS_INCLUDES
    }
  }

  return $css_inc;
}

sub get_js_library_includes {
  my $self = shift;

  my $js_inc = <<JS_INCLUDES;
<script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
JS_INCLUDES

  if (exists $media_ext{$self->{FILE_EXTENSION}}) {
    if ($self->{FILE_EXTENSION} ne "swf") {
      $js_inc .= <<JS_INCLUDES;
<script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
JS_INCLUDES
    }
  }

  return $js_inc;
}

sub get_jquery_ready_function {
  my $self = shift;

  $self->{SERVER_FILENAME} =~ /(.*)\.(\w+)$/; 
  my $playerId = "orca_media_p$self->{PASSAGE_ID}_$1";

  my $html = '';

  if ($self->is_audio()) {

    $html = <<END_HTML;
\$("#${playerId}").jPlayer({
  ready: function(event) 
  {
    \$(this).jPlayer("setMedia", {
      $self->{FILE_EXTENSION}: "$self->{URL}"
    });
  },
  play: function() 
  {
    \$(this).jPlayer("pauseOthers");
  },
  swfPath: "/common/js",
  supplied: "$self->{FILE_EXTENSION}",
  cssSelectorAncestor: "#${playerId}_container",
  wmode: "window",
  warningAlerts: false,
  errorAlerts: true
});
END_HTML

  } elsif ($self->is_video()) {

    $html = <<END_HTML;
\$("#${playerId}").jPlayer({
  ready: function(event) 
  {
    \$(this).jPlayer("setMedia", {
      m4v: "$self->{URL}"
    });
  },
  play: function() 
  {
    \$(this).jPlayer("pauseOthers");
  },
  size: {
    width: "640px", 
    height: "360px", 
    cssClass: "jp-video-360p"
  },
  swfPath: "/common/js",
  supplied: "m4v",
  cssSelectorAncestor: "#${playerId}_container",
  warningAlerts: false,
  errorAlerts: true
});
END_HTML

  } else {
    $html = '';
  }

  return $html;
}

sub draw {
  my $self = shift;

  if (exists($media_ext{$self->{FILE_EXTENSION}})) {
    if ($self->{FILE_EXTENSION} eq "swf") {
      return <<END_HERE;
<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" width="550" height="400">
  <PARAM NAME="movie" VALUE="$self->{URL}">
  <PARAM NAME="FlashVars" VALUE="">
  <PARAM NAME="quality" VALUE="high">
  <EMBED SRC="$self->{URL}" FlashVars="" quality="high" WIDTH="550" HEIGHT="400" TYPE="application-x-shockwave-flash" />
</OBJECT>
END_HERE
    } else {
      $self->{SERVER_FILENAME} =~ /(.*)\.(\w+)$/; 
      my $playerId = "orca_media_p$self->{PASSAGE_ID}_$1";

      if ($self->is_audio()) {
        return <<END_HTML;
<div id="${playerId}" class="jp-jplayer"></div>
<div id="${playerId}_container" class="jp-audio">
  <div class="jp-type-single">
    <div class="jp-title">
       <ul>
         <li>$self->{CLIENT_FILENAME}</li>
       </ul>
    </div> 
    <div class="jp-gui jp-interface">
      <ul class="jp-controls">
        <li><a href="javascript:;" class="jp-play" tabindex="1">play</a></li>
        <li><a href="javascript:;" class="jp-pause" tabindex="1">pause</a></li>
        <li><a href="javascript:;" class="jp-stop" tabindex="1">stop</a></li>
	<li><a href="javascript:;" class="jp-mute" tabindex="1" title="mute">mute</a></li>
        <li><a href="javascript:;" class="jp-unmute" tabindex="1" title="unmute">unmute</a></li>
	<li><a href="javascript:;" class="jp-volume-max" tabindex="1" title="max volume">max volume</a></li>
      </ul>
      <div class="jp-progress">
        <div class="jp-seek-bar">
	  <div class="jp-play-bar"></div>
	</div>
      </div>
      <div class="jp-volume-bar">
         <div class="jp-volume-bar-value"></div>
      </div>
      <div class="jp-current-time"></div>
      <div class="jp-duration"></div>
    </div>
    <div class="jp-no-solution">
        <span>Update Required</span>
	To play the media you need to upgrade to a browser that supports HTML5 or Flash
    </div>
  </div>
</div>
END_HTML
  } elsif ($self->is_video()) {
    return <<END_HTML;
<div id="${playerId}_container" class="jp-video jp-video-360p">
  <div class="jp-type-single">
    <div class="jp-title">
       <ul>
         <li>$self->{CLIENT_FILENAME}</li>
       </ul>
    </div> 
    <div id="${playerId}" class="jp-jplayer" style="margin:auto;"></div>
    <div class="jp-gui">
      <div class="jp-video-play">
        <a href="javascript:;" class="jp-video-play-icon" tabindex="1">play</a>
      </div>
      <div class="jp-interface">
        <div class="jp-progress">
          <div class="jp-seek-bar">
            <div class="jp-play-bar"></div>
          </div>
        </div>
        <div class="jp-current-time"></div>
        <div class="jp-duration"></div>
        <div class="jp-controls-holder">
          <ul class="jp-controls">
            <li><a href="javascript:;" class="jp-play" tabindex="1">play</a></li>
            <li><a href="javascript:;" class="jp-pause" tabindex="1">pause</a></li>
            <li><a href="javascript:;" class="jp-stop" tabindex="1">stop</a></li>
	    <li><a href="javascript:;" class="jp-mute" tabindex="1" title="mute">mute</a></li>
            <li><a href="javascript:;" class="jp-unmute" tabindex="1" title="unmute">unmute</a></li>
            <li><a href="javascript:;" class="jp-volume-max" tabindex="1" title="max volume">max volume</a></li>
          </ul>
          <div class="jp-volume-bar">
            <div class="jp-volume-bar-value"></div>
          </div>
          <ul class="jp-toggles">
            <li><a href="javascript:;" class="jp-full-screen" tabindex="1" title="full screen">full screen</a></li>
            <li><a href="javascript:;" class="jp-restore-screen" tabindex="1" title="restore screen">restore screen</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="jp-no-solution">
      <span>Update Required</span>
      To play the media you will need to either update your browser to a recent version or update your <a href="http://get.adobe.com/flashplayer/" target="_blank">Flash plugin</a>.
    </div>
  </div>
</div>
END_HTML
      } else {
        return <<END_HTML;
    <div>Media Type $self->{FILE_EXTENSION} not recognized.</div>
END_HTML
      }

      return $html;
    }
  } else {
    return <<END_HERE;
<a href="$self->{URL}">Click to download</a>
END_HERE
  }
}

sub is_audio {
  my $self = shift();

  if (exists($audio_media_ext{$self->{FILE_EXTENSION}}) && $self->{FILE_EXTENSION} ne "mp4") {
    return 1;
  } else {
    use Image::ExifTool qw(:Public);
    my $mp4_info = ImageInfo($self->{PATH});
    return $mp4_info->{MIMEType} =~ m/^audio\/mp4/;
  }
}

sub is_video {
  my $self = shift();

  if (exists($video_media_ext{$self->{FILE_EXTENSION}}) && $self->{FILE_EXTENSION} ne "mp4") {
    return 1;
  } else {
    use Image::ExifTool qw(:Public);
    my $mp4_info = ImageInfo($self->{PATH});
    return $mp4_info->{MIMEType} =~ m/^video\/mp4/;
  }
}

1;
