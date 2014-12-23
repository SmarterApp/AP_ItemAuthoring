package Action::importStandardXml;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Data::Dumper;
use ItemConstants;
use XML::XPath;
use HTML::Entities;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);


  our $this_url = "${orcaUrl}cgi-bin/importStandardXml.pl";
  
  our $sth;
  our $sql;
  
  our $sh_table = 'standard_hierarchy';
  our $hd_table = 'hierarchy_definition';
  our $ic_table = 'item_characterization';
  our $ql_table = 'qualifier_label';
  
  our %hd_types = ( 
                  #'hierarchy' => '1',
                  #'contentArea' => '2',
                  #'gradeLevel' => '3',
                  #'strand' => '4', 
                  #'gle' => '5',
                  #'substrand' => '6',
  		'Program' => 1,
  		'TestSubject' => 2,
  		'Area' => 3,
  		'GeneralContent' => 4,
  		'SpecificContent' => 5,
  		'SubSpecificContent' => 6,
                );
  
  $in{myAction} = '' unless exists $in{myAction};
  our @global_warnings = ();
  
  if($in{myAction} eq '')
  {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }  
  elsif($in{myAction} eq 'upload') {
  	
  
    my $shName = $in{hierarchyName};
    my $uploadHandle = $q->upload("myfile");
    my $fileName = "/tmp/standards_data_upload.$$";
  
    # check that file does not exceed the maximum file size
    my $MEGABYTE = 1048576;
    my $MAX_FILE_SIZE = 10 * $MEGABYTE;
  
    my $fileSize = -s $uploadHandle;
    
    if ($fileSize > $MAX_FILE_SIZE ) {
  
      # file has been determined to be a large file; prompt user to resize
      my $fileSizeRoundedMB = sprintf "%.2f", $fileSize/$MEGABYTE; 
  
      $in{message} = "You have selected a large file (".$fileSizeRoundedMB." MB) to upload. It is required that you decrease file size to less than ".$MAX_FILE_SIZE/$MEGABYTE."MB.";
 
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
    }
  
    open UPLOADED, "> $fileName";
    while( <$uploadHandle> ) {
      print UPLOADED;
    }
    close UPLOADED;
  
  
    if( $in{file_type} eq 'zip' ) {
  	my $zip = Archive::Zip->new($fileName);
    	$fileName .= '.xml';
          for( $zip->memberNames() ) {
  	    next unless /\.xml$/;
  	    $zip->extractMemberWithoutPaths($_, $fileName);
  	}
    }
    else {
      rename $fileName, $fileName . '.xml';
      $fileName .= '.xml';
    }
  
  
    # get the xml string, check for non-ascii characters
    my $xml = get_standard_xml_as_string($fileName);

    # replace high ascii chars
    $xml = replaceChars($xml);
  
    # return errors if any
    return [ $q->psgi_header('text/html'), [ check_global_warnings() ]] if scalar @global_warnings;
  
    # try just the XML Parser
    validate_xml_with_parser($xml);
  
    # return errors if any
    return [ $q->psgi_header('text/html'), [ check_global_warnings() ]] if scalar @global_warnings;
  
    # attempt to parse the entire file and identify any issues, last parameter = 1 for test mode
    parse_node($xml, 0, 0, '/', 1);

    # return errors if any
    return [ $q->psgi_header('text/html'), [ check_global_warnings() ]] if scalar @global_warnings;
  
    # xml input file is okay, so clean out the existing hierarchy, if we can
    clean_existing_hierarchy($shName);
  
    # return errors if any
    return [ $q->psgi_header('text/html'), [ check_global_warnings() ]] if scalar @global_warnings;
  
    # if we made it this far, start creating actual database records
  
    # create the root node records
  
    my $sh_id = new_standard_hierarchy($shName);
    my $root_hd_id = new_hierarchy_definition($shName, $sh_id);
  
    # parse the XML and load the records, for real
    parse_node($xml, $root_hd_id, 0, '/', 0);

    # return errors if any
    return [ $q->psgi_header('text/html'), [ check_global_warnings() ]] if scalar @global_warnings;
  
    #done
    $in{sh_id} = $sh_id;
    $in{hd_id} = $root_hd_id;
    $in{message} = "New Hierarchy '${shName}' has been loaded.";

    return [ $q->psgi_header('text/html'), [ print_success(\%in) ]];
  }
}
#
# subroutine definition
#

sub print_success {

  my $params = shift;

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Import Hierarchy XML</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
	<script>
		function init() {
			window.opener.cde.hd_id.value = $params->{hd_id};
			window.opener.cde.sh_id.value = $params->{sh_id};
			window.opener.cde.submit();
		}
	</script>
	</head>
  <body onLoad="init();">
    <div class="title">Imported Hierarchy XML</div>
    <p>$params->{message}</p>
    <p><br><br><input type="button" name="Close" value="Close" onClick="window.close();"></p>
  </body>
</html>
END_HERE
}

sub print_welcome {

  my $params = shift;
  my $hierarchyName = $params->{hierarchyName} || '';

  my $message = ($in{message}) ? '<div style="color:red;">' . $in{message} . '</div>' : '';

  my $allowedTagList = '';
  foreach (sort { $hd_types{$a} <=> $hd_types{$b} } keys %hd_types) {
    $allowedTagList .= '<li>&lt;' . $_ . '></li>' unless $hd_types{$_} == $HD_ROOT;
  }

  return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Import Hierarchy XML</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">

      function doSubmit(f) {
		if( f.myfile.value.match(/\\.xml\$/i) ) {
		    f.file_type.value = 'xml';
		}
		else if( f.myfile.value.match(/\\.zip\$/i) ) {
		    f.file_type.value = 'zip';
		}
		else {
		    alert('Invalid File. Filetype must be XML or ZIP!');
		    f.file_type.value = '';
		    f.myfile.focus();
		    return false; 
		}
		document.getElementById('start_upload').innerHTML = '<font size="4" color="blue">Uploading... <img src="/common/images/spinner.gif" /></font>';
		document.dataUpload.submit();
	  }	

	  function doReload() {
    	  document.dataUpload.myAction.value = '';
		document.dataUpload.submit();
    	}

		</script>
	</head>
  <body>
    <div class="title">Import Hierarchy XML</div>
    $message
    <form name="dataUpload" action="${this_url}" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="myAction" value="upload" />
     <input type="hidden" name="file_type" value="" />
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
            <tr><td><span class="text">Name:</span></td><td><input type="text" name="hierarchyName" value="${hierarchyName}" size="20" /></td></tr>
			<tr><td><span class="text">Upload File:</span></td><td><input type="file" name="myfile" /></td></tr> 
			<tr>
        <td>&nbsp;</td>
         <td><span id="start_upload"><input type="button" value="Upload Hierarchy XML" onClick="doSubmit(this.form);" /></span>
        </td>
      </tr>
    </table>
    </form>
		<br />
		<h4><span class="text">Instructions:</span></h4>
		<p>The top-level tag must be &lt;$standard_types{$HD_ROOT}>.</p>
		<p>Each level tag must contain a &lt;name> tag, and may optionally have the following tags:
		<ul>
		<li>&lt;description></li>
		<li>&lt;extendedDescription></li>
		<li>&lt;children></li>
		</ul>
		<p>Children tags may have the following names:</p>
		<ul>
		${allowedTagList}
		</ul>
		</p>
		<p>File type must be either XML or a ZIP file containing an XML file.</p>
		<p>Upload file must be 10 MB or less.</p>
  </body>
</html>         
END_HERE
}          

sub check_global_warnings {
  my $psgi_out = '';

  my $xml = shift || '';

  if(scalar @global_warnings) {

    $psgi_out .= <<HTML;
    <!DOCTYPE html>
    <html>
      <head>
        <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
      </head>
        <body>
          <div class="title">Unable to Complete Hierarchy Upload</div>
          <br />
          <pre>
HTML

    $_ =~ s/</&lt;/g foreach @global_warnings;

    $psgi_out .= $_ . "\n" foreach @global_warnings;

    $psgi_out .= <<END_HERE;
    </pre>
    <br />
    <a href="${this_url}?hierarchyName=$in{hierarchyName}">Upload Another File</a>
    </body></html>
END_HERE

  }

  return $psgi_out;
}

sub new_standard_hierarchy {

  my $hierarchy_name = shift;

  $sql = <<SQL;
  INSERT INTO ${sh_table} SET sh_external_id='${hierarchy_name}', sh_name='${hierarchy_name}' 
SQL
  $sth = $dbh->prepare($sql);
  $sth->execute();

  my $sh_id = $dbh->{mysql_insertid};

  my $level_num = 1;
  $sql = 'INSERT INTO qualifier_label VALUES(?,?,?)';
  for ( keys %standard_types ) {
      my @bv = ( $sh_id, $_, $standard_types{$_} );
      $dbh->do( $sql, undef, @bv );
  }

  return $sh_id;
}

sub new_hierarchy_definition {

  my $hierarchy_name = shift;
  my $standard_hierarchy_id = shift;

  $sql = <<SQL;
  INSERT INTO ${hd_table} 
    SET hd_type=${HD_ROOT}, 
        hd_value='${hierarchy_name}', 
        hd_parent_id=0,
        hd_posn_in_parent=0, 
        hd_parent_path=0
SQL
  #warn $sql;
  $sth = $dbh->prepare($sql);
  $sth->execute();

  my $new_hd_id = $dbh->{mysql_insertid};

  $sql = <<SQL;
  UPDATE ${sh_table} SET hd_id=${new_hd_id} WHERE sh_id=${standard_hierarchy_id}
SQL
  #warn $sql;
  $sth = $dbh->prepare($sql);
  $sth->execute();

  return $new_hd_id;
}

sub validate_xml_with_parser {

  my $xml = shift;

  eval {

    my $xp = XML::XPath->new('xml' => $xml);
    my $testval = $xp->findnodes('/');
  };

  if($@) {

    push @global_warnings, 'Error: Invalid XML';

    my $warn_text = join ("\n", $@);

    $warn_text =~ s/at \/usr.*$//;
    $warn_text =~ s/column \d+,//i;
    $warn_text =~ s/byte \d+://i;

    push @global_warnings, $warn_text;
  }
}

sub get_standard_xml_as_string {

  my $file_name = shift;
  my $xml_string = '';
  my $lineCount = 1;

  open FILE, '<', $file_name;

  while(<FILE>) {

    my $line = $_; 
    my @chars = split //, $line;

    my $a = 0;
    for(@chars) {
      if(ord($_) > 127) {
	$a = 1;
	$_ = encode_entities($_);
        #push @global_warnings, "Error: Line ${lineCount} contains an invalid character: $_";
        #push @global_warnings, ">> " . $line;
      }
    }
    if( $a == 1 ) {
        $line = join('', @chars);
        warn $line;
    }

    $xml_string .= $line;

    $lineCount++; 
  }
  close FILE;

  unlink $file_name;

  $xml_string =~ s/^\s+//;
  $xml_string =~ s/\s+$//;

  return $xml_string;
}

sub parse_node {

  my $xml = shift;
  my $parentIdString = shift;
  my $siblingPosition = shift;
  my $locationString = shift;
  my $run_in_test_mode = shift || 0;

  my @parentIdList = split /,/, $parentIdString;

  if($xml =~ /^<([\w]+)>\s*<name>(.+?)<\/name>\s*(.*)\s*<\/\1>\s*$/s) {

    my $element = $1;
    my $name = $2;
    my $body = $3;
    my $description = '';
    my $extendedDescription = '';
    my $childText = '';
    my $childElement = '';

    if(0 && $hd_types{$element} == $HD_LEAF) {
      warn <<TEXT;
Element: $element
Name: $name
Body:
$body
TEXT
    }

    if($locationString eq '/' && $hd_types{$element} != $HD_ROOT) {

      push @global_warnings, 'Error: Root-level tag must be <' . $standard_types{$HD_ROOT} . '>';
      return;
    }

    $locationString .= " ${element} [ name = \"${name}\" ]/";

    unless(exists $hd_types{$element}) {

      push @global_warnings, "Error: Unknown element type: ${element}"; 
      push @global_warnings, 'Location: ' . $locationString;
      push @global_warnings, 'Around: ' . get_text_around($xml);

      return;
    }

    my $elementType = $hd_types{$element};

    if($body =~ /^<description>(.*?)<\/description>\s*(.*)$/s) {
      $description = $1;
      $body = $2;
    }

    if($body =~ /^<extendedDescription>(.*?)<\/extendedDescription>(.*)$/s) {
      $extendedDescription = $1;
      $body = $2;
    }

    $name =~ s/^\s*<!\[CDATA\[\s*//s;
    $name =~ s/\s*\]\]>\s*$//s;

    $description =~ s/^\s*<!\[CDATA\[\s*//s;
    $description =~ s/\s*\]\]>\s*$//s;

    $extendedDescription =~ s/^\s*<!\[CDATA\[\s*//s;
    $extendedDescription =~ s/\s*\]\]>\s*$//s;

    if(0) {
    warn <<OUT;
Element: $element
Name: $name
Description: $description
Extended Description: $extendedDescription
Parent: $parentIdList[0]
Body: $body
OUT
}

    unless($elementType == $HD_ROOT) {

      # Create a hierarchy_definition record for this node
      my $sql = sprintf('INSERT INTO %s SET hd_type=%d, hd_value=%s, hd_parent_id=%d, hd_posn_in_parent=%d, hd_std_desc=%s, hd_extended_desc=%s, hd_parent_path=%s',
                        $hd_table,
                        $elementType,
                        $dbh->quote($name),
                        $parentIdList[0],
                        $siblingPosition,
                        $dbh->quote($description),
                        $dbh->quote($extendedDescription),
                        $dbh->quote(join(',',@parentIdList)));
      #warn $sql . "\n";

      unless($run_in_test_mode) {

        my $sth = $dbh->prepare($sql);
        $sth->execute();
      
        my $this_hd_id = $dbh->{mysql_insertid};

        # Add this record to the front of the parent record id list
        unshift(@parentIdList,$this_hd_id);
      }
    }

    if($body =~ /^\s*<children>\s*(.+)\s*<\/children>\s*$/s) {

      if($hd_types{$element} == $HD_LEAF) {

        push @global_warnings, 'Error: A <' . $element . '> tag cannot have <children> tags';
        push @global_warnings, 'Location: ' . $locationString;
        push @global_warnings, 'Around: ' . get_text_around($xml);

        return;
      }
    
      $childText = $1;

      $childText =~ /^<([\w]+)>/;

      my $childType = $1;

      unless(exists $hd_types{$childType}) {

        push @global_warnings, "Error: Unknown child element type: ${childType}"; 
        push @global_warnings, 'Location: ' . $locationString;
        push @global_warnings, 'Around: ' . get_text_around($xml);

        return;
      }

      #warn "Child Type: ${childType}\n\n";

      my $childPos = 1;

      while($childText =~ /(<$childType>.*?<\/$childType>)\s*/gs) {

        parse_node($1, join(',',@parentIdList), $childPos, $locationString, $run_in_test_mode);

        $childPos++;
      }

    } else {
      #warn "\n";
    }

  } else {

    push @global_warnings, 'Error: Unable to find proper XML tag definition';
    push @global_warnings, 'Location: ' . $locationString;
    push @global_warnings, 'Around: ' . get_text_around($xml);

    return;
  }
}


sub get_text_around {

  my $xml = shift;
  my @xml_lines = split /\r?\n/, $xml;
  return join("\n", @xml_lines[0..3] );

}

sub clean_existing_hierarchy {

  my $hierarchy_name = shift;
  my $status = '';

  my $rootId = 0;
  my $sh_id = 0;

  # Try to find an existing standards hierarchy, and delete it if found and no items are associated

  $sql = <<SQL;
  SELECT * FROM ${sh_table} WHERE sh_external_id='${hierarchy_name}'
SQL

  $sth = $dbh->prepare($sql);
  $sth->execute();

  if(my $row = $sth->fetchrow_hashref) {

    # delete this hierarchy before importing new one

    $rootId = $row->{hd_id};
    $sh_id  = $row->{sh_id};

    $sql = <<SQL;
  SELECT i_id FROM ${ic_table}
    WHERE ic_type=1 
      AND ic_value IN 
        (SELECT hd_id FROM ${hd_table} 
          WHERE hd_parent_path LIKE '%,${rootId}' 
            OR hd_parent_path LIKE '%,${rootId},0'
            OR hd_parent_id=${rootId})
    LIMIT 1
SQL

    my $sth2 = $dbh->prepare($sql);
    $sth2->execute();

    if($sth2->fetchrow_hashref) {

       $sth2->finish;
       push @global_warnings, "Error: Hierarachy '${hierarchy_name}' cannot be removed";
       push @global_warnings, "Reason: Some items are linked to its Hierarchy";
    } 
  } else {

    return;
  }

  $sth->finish;

  $sql = <<SQL;
  DELETE FROM ${hd_table}  
    WHERE hd_parent_path LIKE '%,${rootId}' 
      OR hd_parent_path LIKE '%,${rootId},0'
      OR hd_parent_id=${rootId}
SQL

  my $sth3 = $dbh->prepare($sql);
  $sth3->execute();

  $sql = <<SQL;
  DELETE FROM ${hd_table} WHERE hd_id=${rootId}
SQL

  $sth3 = $dbh->prepare($sql);
  $sth3->execute();

  $sql = <<SQL;
  DELETE FROM ${sh_table} WHERE hd_id=${rootId}
SQL

  $sth3 = $dbh->prepare($sql);
  $sth3->execute();

  $sql  = "DELETE FROM $ql_table WHERE sh_id=$sh_id";
  $sth3 = $dbh->prepare($sql);
  $sth3->execute();

}
1;
