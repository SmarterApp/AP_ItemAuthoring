#!/usr/bin/perl -w

# Have to set instance name in BEGIN block, else our custom libs will not load

BEGIN {

  my $instance_name = $ARGV[0] || '';
  die "Must specify an instance to monitor!" if $instance_name eq '';
  $ENV{instance_name} = $instance_name;

}

my $debug = $ARGV[1] || 0;

use strict;
use DBI;
use File::Copy 'cp';
use File::Glob ':glob';
use Cwd;
use Config::General;
use File::stat;
use Time::localtime;
use File::chdir;
use XML::Compile;
use XML::LibXML;
use REST::Client;
use Data::Dumper;
use ItemConstants;
use UrlConstants;
use Item;
use Rubric;

my $UA_ITEM_IMPORT = 1;

my $IIA_CREATE = 1;
my $IIA_UPDATE = 2;
my $IIA_ERROR = 3;

my $IIM_STARTED = 1;
my $IIM_VALIDATED_PACKAGE = 2;
my $IIM_VALIDATED_CONTENT = 3;
my $IIM_COMPLETED = 4;
my $IIM_FAILED_PACKAGE = 5;
my $IIM_FAILED_CONTENT = 6;

my @mc_letters = qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;

my %inclusion_order_types = ( 1 => 'brailleDefaultOrder',
                              2 => 'textOnlyDefaultOrder',
			      3 => 'textOnlyOnDemandOrder',
			      4 => 'textGraphicsDefaultOrder',
			      5 => 'textGraphicsOnDemandOrder',
			      6 => 'graphicsOnlyOnDemandOrder',
			      7 => 'nonVisualDefaultOrder' );

my %interaction_types = ( 'choice' => $IT_CHOICE,
                          'textEntry' => $IT_TEXT_ENTRY,
			  'extendedText' => $IT_EXTENDED_TEXT
                        );


# globally track uploaded assets so that we don't upload more than once
my %uploaded_assets = ();

# quit if this process is already running

my $progress_file = $webPath . '/cde_tmp/' . $instance_name . '/item-import-monitor.inprogress';
exit if -e $progress_file;

# create a progress file

open PRO, '>', $progress_file;
print PRO '1';
close PRO;

# redirect stdout to our log file

open STDOUT, '>>', $webPath . '/cde_log/' . $instance_name . '/item-import-monitor.log';
$|++;

print "Running at " . ctime() . "\n" if $debug;

# set up globals

my $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );

my $restClient = &getMetadataClient();

# for each item bank that has an importer defined ..

my $sql = 'SELECT ib_id, ib_importer_u_id FROM item_bank WHERE ib_importer_u_id > 0';
my $sth = $dbh->prepare($sql);
$sth->execute();

while (my $row = $sth->fetchrow_hashref) {

  my $bank = $row->{ib_id};
  my $importerId = $row->{ib_importer_u_id};

  # .. for each zip file in the item bank's upload folder 

  my $data_path = $webPath . '/' . $instance_name . '/item-import/lib' . $bank . '/';
  my $log_dir = $data_path . 'logs/';
  my $uploads_path = $data_path . 'uploads/*.zip';
  my $secure_uploads_path = $data_path . 'uploads/*.gpg';

  #print "Checking secure upload path: ${secure_uploads_path}\n" if $debug;

  foreach my $file ( bsd_glob($secure_uploads_path) ) {
    
  }

  #print "Checking upload path: ${uploads_path}\n" if $debug;

  foreach my $file ( bsd_glob($uploads_path) ) {

    my $work_file_name = '';

    if($file =~ /\/([^\/]+)$/) {

      $work_file_name = $1;
    }

    my $file_modified_time = localtime_to_mysql(localtime(stat($file)->mtime));

    # .. make sure that this upload file has not already been processed, and then

    $sql = sprintf('SELECT iim_id FROM item_import_monitor WHERE ib_id=%d AND iim_import_file_name=%s AND iim_import_file_modified=%s',
                   $bank,
                   $dbh->quote($work_file_name),
		   $dbh->quote($file_modified_time));

    my $sth2 = $dbh->prepare($sql);
    $sth2->execute();

    #print "Check if upload file has been processed: ${sql}\n" if $debug;

    next if $sth2->fetchrow_hashref;

    # .. create the db records and get a unique work id

    $sql = sprintf('INSERT INTO item_import_monitor SET ib_id=%d, u_id=%d, iim_status=%d, iim_dev_state=%d, iim_import_file_name=%s, iim_import_file_modified=%s',
                   $bank,
		   $importerId,
		   $IIM_STARTED,
		   1,
		   $dbh->quote($work_file_name),
		   $dbh->quote($file_modified_time));

    $sth2 = $dbh->prepare($sql);
    $sth2->execute();

    print "Create import task: ${sql}\n" if $debug;

    my $importId = $dbh->{mysql_insertid};

    # .. set up our log file

    my $log_name = $work_file_name;
    $log_name =~ s/zip$/log/;

    open LOG, '>', $log_dir . $log_name;  

    # .. create a working directory and copy our upload file there

    my $work_dir = $webPath . '/cde_tmp/' . $instance_name . '/item-import-' . $importId . '/';

    mkdir $work_dir;

    print "Create work dir: ${work_dir}\n" if $debug;

    my $work_file = $work_dir . $work_file_name;

    cp $file, $work_file;

    my $is_package_fail = 0;

    # using File::chdir, we can localize our directory change
    {
      local $CWD = $work_dir;
    
      print "Moved cwd to: ${CWD}\n" if $debug;

      # clear the cache of uploaded assets
      %uploaded_assets = ();
     
      # unzip the package
      system('unzip',$work_file_name);

      # make sure it's writable
      system('chmod','-R','a+rw',$work_dir);

      # .. check for imsmanifest.xml at this level, if not there navigate to any sub-folder
      unless(-e 'imsmanifest.xml') {

        opendir(DIR, $CWD);
	while (my $entry = readdir(DIR)) {
	  # it's a folder
	  next unless (-d "$CWD/$entry");

          # it has an imsmanifest.xml
	  next unless (-e "$CWD/$entry/imsmanifest.xml");

          $CWD = "$CWD/$entry";
	  last;
	}
      }

      # .. make sure we have a valid IMS Manifest

      unless(-e 'imsmanifest.xml') {

        print "Unable to locate imsmanifest.xml, stopping.\n";

        set_monitor_status($importId, $IIM_FAILED_PACKAGE,"Manifest XML not found", *LOG);
	$is_package_fail = 1;
	
      }

      my @item_xml_files = ();
      my %item_metadata = ();
      my %md_cache = ();

      if(-e 'imsmanifest.xml') {

        # begin manifest validation

	my $x_manifest;

	# first step, ensure xml is valid

        eval {

          $x_manifest = XML::Compile->dataToXML('imsmanifest.xml');

        };

	if($@) {

          # not valid, so we're done here

          set_monitor_status($importId, $IIM_FAILED_PACKAGE,"Manifest XML not valid",*LOG);
	  $is_package_fail = 1;
	  
	}

        unless($is_package_fail) {

          # for each resource that is referenced, make sure it exists in the package 

          foreach my $x_resources ( $x_manifest->getChildrenByTagName('resources') ) {

	    foreach my $x_resource ( $x_resources->getChildrenByTagName('resource') ) {

	      my $is_resource_an_item = ( $x_resource->getAttribute('type') =~ /^imsqti\_apipitem/ ) ? 1 : 0;
	      my $item_key = '';

	      foreach my $x_file ( $x_resource->getChildrenByTagName('file') ) {

	        my $resource_href = $x_file->getAttribute('href');

	        unless(-e $resource_href) {

	          print "Unable to locate resource: ${resource_href}\n" if $debug;

                  set_monitor_status($importId, $IIM_FAILED_PACKAGE,"Manifest resource not found: ${resource_href}",*LOG);
		  $is_package_fail = 1;
	        }

	        if($is_resource_an_item) {

		  $item_key = $x_file->getAttribute('href');

	          push @item_xml_files, $item_key;

		  foreach my $x_metadata ($x_resource->getChildrenByTagName('metadata')) {
		    $item_metadata{$item_key} = $x_metadata->toString();
		    $item_metadata{$item_key} =~ s/^\s*<metadata(.*?)>\s*//;
		    $item_metadata{$item_key} =~ s/\s*<\/metadata>\s*$//;
                  }
                }
	      }

	      foreach my $x_depend ( $x_resource->getChildrenByTagName('dependency') ) {

	        if($is_resource_an_item) {

	          my $depend_id = $x_depend->getAttribute('identifierref');

		  if($depend_id =~ /^metadata/) {
		    $md_cache{$depend_id} = $item_key;
                  }
	        } 
	      }
 
              # check if this is metadata
	      if ( $x_resource->getAttribute('type') =~ /^controlfile/
	        && $x_resource->getAttribute('identifier') =~ /^metadata/ ) {

		my $md_href = $x_resource->getAttribute('href');

	        unless(-e $md_href) {

	          print "Unable to locate metadata resource: ${md_href}\n" if $debug;

                  set_monitor_status($importId, $IIM_FAILED_PACKAGE,"Manifest metadata resource not found: ${md_href}",*LOG);
		  $is_package_fail = 1;
	        }

		my $md_id = $x_resource->getAttribute('identifier');
		$item_key = $md_cache{$md_id};

                $item_metadata{$item_key} = ItemConstants::getFileContent($md_href); 
	        $item_metadata{$item_key} =~ s/^.*<\?xml(.*?)\?>[^<]*//;
	        #$item_metadata{$item_key} =~ s/^\s*<metadata(.*?)>\s*//;
	        #$item_metadata{$item_key} =~ s/\s*<\/metadata>\s*$//;
              }
	    }

	  } # end foreach my $x_resources

	} # end unless $is_package_fail

      } # end if -e 'imsmanifest.xml'

      # if no APIP items found, call that an error

      unless(scalar @item_xml_files) {

        set_monitor_status($importId, $IIM_FAILED_PACKAGE,"Package contains no APIP items",*LOG);
        $is_package_fail = 1;
      }

      if($is_package_fail) {

        # if package failed at this point, remove working directory and move on
        close LOG;

        print "Removing work dir: ${work_dir}\n" if $debug;
        system('rm','-rf', $work_dir);
	next;
      }

      unless($is_package_fail) {

        # .. the package was fine, so update the status, create a user action, and work on the item files

        set_monitor_status($importId, $IIM_VALIDATED_PACKAGE);

	my $uaId = create_user_action($importerId, $UA_ITEM_IMPORT);

        $sql = 'UPDATE item_import_monitor SET ua_id=' . $uaId . ' WHERE iim_id=' . $importId;
        $sth2 = $dbh->prepare($sql);
        $sth2->execute();

	my $is_content_fail = 0;

        foreach my $file ( @item_xml_files ) {

	  print "Found Item XML file: ${file}\n" if $debug;

	  my $relDir = $CWD;
	  if($file =~ /^(.*)\/[^\/]+$/) {
	    $relDir = $CWD . '/' . $1;
	  }

          # begin item validation

	  my $x_item;
          my $fullItemXml;

	  # first step, ensure xml is valid

          eval {

            $x_item = XML::Compile->dataToXML($file);

          };

	  if($@) {

            # not valid, so we're done here

            set_monitor_status($importId, $IIM_FAILED_CONTENT,"Item XML not valid: ${file}",*LOG);
	    print "Item XML ${file} could not be parsed: $!" if $debug;
	    $is_content_fail = 1;
	  }

	  unless($is_content_fail) {

            # get the xml text and remove the comments
	    $fullItemXml = $x_item->serialize();
            $fullItemXml =~ s/<!--.*?-->//sg;

	    # replace any high-ascii characters with equivalent HTML entities
	    $fullItemXml = replaceChars($fullItemXml);

	    # replace hex entities with decimal entities
	    $fullItemXml =~ s/(&#x)(\d+)(;)/'&#' . hex($2) . $3/eg;


	    # make sure all image references are valid
	    while($fullItemXml =~ /src="([^"]+)"/g) {

	      my $url = $1;
              if ( $url =~ /^\.\// ) { $url = substr( $url, 2 ); }
              unless( -e $relDir . '/' . $url ) {
	        print "Reference ${relDir}/${url} not found in file: ${file}\n" if $debug;
                set_monitor_status($importId, $IIM_FAILED_CONTENT,"Item XML source ref not found: ${file}",*LOG);
	        $is_content_fail = 1;
	      }  
	    }
	  }


	  if($is_content_fail) {
	    $is_package_fail = 1;
	    last;
	  }

	  unless($is_content_fail) {

	    # okay, try to process this one

	    my $itemName = '';
	    my $itemDescription = '';
	    my $itemBody = '';
	    my @correctList = ();
	    my $correctKeys = {};
	    my $stylesheet = '';

	    if( $x_item->hasAttribute('identifier') ) { $itemName = $x_item->getAttribute('identifier'); }
	    if( $x_item->hasAttribute('title') ) { $itemDescription = $x_item->getAttribute('title'); }

	    foreach my $x_response ( $x_item->getChildrenByTagName('responseDeclaration') ) {

	      my $responseId = $x_response->getAttribute('identifier'); 

	      foreach my $x_correct ( $x_response->getChildrenByTagName('correctResponse') ) {

	         foreach my $x_value ( $x_correct->getChildrenByTagName('value') ) {

                   my $correctValue = $x_value->textContent;

		   $correctKeys->{$responseId}{$correctValue} = 1;
	           print "correct value found = ${correctValue}\n" if $debug;
		 }
	      }
	    } # end foreach my $x_response

            # find an item-specific stylesheet

	    if($fullItemXml =~ /<stylesheet.*?href="(.*?)"/) {
	      $stylesheet = $1;  
	    }


	    foreach my $x_body ( $x_item->getChildrenByTagName('itemBody') ) {

	      $itemBody = $x_body->serialize();

	      # replace any high-ascii characters with equivalent HTML entities
	      $itemBody = replaceChars($itemBody);

	      # replace hex entities with decimal entities
	      $itemBody =~ s/(&#x)(\d+)(;)/'&#' . hex($2) . $3/eg;

	      print "Serialized item body\n" if $debug;

              # this is one way to decompose the <itemBody> content, but I'll use reg-exp below instead

	      foreach my $x_interaction ( $x_body->getChildrenByTagName('choiceInteraction') ) {

	        foreach my $x_prompt ( $x_interaction->getChildrenByTagName('prompt') ) {
		}

		foreach my $x_choice ( $x_interaction->getChildrenByTagName('simpleChoice') ) {

		  if( $x_choice->hasAttribute('identifier') ) { 
		    #print "Choice ID: " . $x_choice->getAttribute('identifier') . "\n"; 
		  }
		}
	      }
	    } # end foreach my $x_body

            # now that we have the components, let's do our content validation steps

	    if($itemName eq '') {

              set_monitor_status($importId, $IIM_FAILED_CONTENT,"Item identifier is missing: ${file}",*LOG);
	      $is_content_fail = 1;

	    } 
	    elsif($itemBody eq '') {

              set_monitor_status($importId, $IIM_FAILED_CONTENT,"Item body is missing: ${file}",*LOG);
	      $is_content_fail = 1;

	    } else {

	      # if we make it to the end, go ahead and try to load the item to the database

	      # first see if we're adding or updating

	      my $item_create_or_update = 0;
	      my $found_item_id = 0;

	      $sql = sprintf('SELECT i_id FROM item WHERE ib_id=%d AND i_external_id=%s ORDER BY i_version DESC LIMIT 1', 
	                     $bank, 
			     $dbh->quote($itemName));
              $sth2 = $dbh->prepare($sql);
              $sth2->execute();

	      if(my $row2 = $sth2->fetchrow_hashref) {
                
		$item_create_or_update = $IIA_UPDATE;
		$found_item_id = $row2->{i_id};

                # if item is imported, we don't have a way to preserve existing fragments or interactions
		$sql = 'DELETE FROM item_interaction WHERE i_id=' . $row2->{i_id};
		my $sth3 = $dbh->prepare($sql);
		$sth3->execute();

		$sql = 'DELETE FROM item_fragment WHERE i_id=' . $row2->{i_id};
		$sth3 = $dbh->prepare($sql);
		$sth3->execute();

	      } else {

	        $item_create_or_update = $IIA_CREATE;
	      }

              # create an item object and populate it

              my $item;

	      if($item_create_or_update == $IIA_CREATE) {

                $item = new Item($dbh);

		$item->create($bank, $itemName);

	      } elsif ( $item_create_or_update == $IIA_UPDATE) {

                $item = new Item($dbh, $found_item_id);

	      }

              # decompose the <itemBody> content into its parts 

	      $item->{format} = 1;

	      #print $itemBody . "\n" if $debug;
	      my $itemUrl = $orcaUrl . 'images/lib' . $item->{bankId} . '/' . $item->{name} . '/';

              if($itemBody =~ /<itemBody\s?([^>]*)>(.*?)<\/itemBody>/s) {

                my $item_body_text = $2;

	        # replace any high-ascii characters with equivalent HTML entities
		#$item_body_text = replaceChars($item_body_text);

		# retrieve and create/update any content in rubric blocks
		$item_body_text =~ s/(<rubricBlock [^>]+>.*?<\/rubricBlock>)/&updateRubricBlock($item,$1)/esg;

		# get the associated media, and update relative references
                $item_body_text =~ s/src="([^"]+)"/&getImageSrc($1,$itemUrl,$relDir,$item->{version})/eg;

	        # add media references as needed
		while($item_body_text =~ /<img(.*?)\/>/gs) {
                
		  my $atts = $1;
		  my $src = '';
		  my $alt = '';
		  my $name = '';

		  if($atts =~ / src="([^"]+)"/) {
		    $src = $1;
		    $name = $src;

		    if($src =~ /\/([^\/]*)$/) {
		      $name = $1;
		    }
		  }

		  if($atts =~ / alt="([^"]+)"/) {
		    $alt = $1;
		  }

                  # determine if this is a new asset and track accordingly

                  if(exists $uploaded_assets{$item->{id} . '_' . $src}) {
                    # do nothing if we already tracked it
                  } else {
                     track_uploaded_asset($item->{id}, $name, $src, $alt, $importerId);
		     $uploaded_assets{$item->{id} . '_' . $src} = 1;
                  }
		}


		# replace <object> tags with media references, and also update media table
		$item_body_text =~ s/<object ([^>]+)>.*?<\/object>/&createMedia($item->{id}, $importerId, $1,$itemUrl,$relDir,$item->{version})/egs;
		$item_body_text =~ s/<object ([^>]+)\/>/&createMedia($item->{id}, $importerId, $1,$itemUrl,$relDir,$item->{version})/egs;

		# replace <img> tags that have SVG sources to be compliant with web browsers
		$item_body_text =~ s/<img(.*?)src="([^"]+?\.svg)"(.*?)\/>/<object$1data="$2"$3><\/object>/g;

                my $item_content = {};
		$item_content->{id} = 0;
		$item_content->{name} = 'item_body';
		$item_content->{attributes} = $1;

		if($item_content->{attributes} =~ /id="(.*?)"/) {
		  $item_content->{name} = $1;
		}

                # create interactions, make substitutions in the item body content
                $item_body_text =~ s/<([a-zA-Z]+)Interaction\s?(.*?)>(.*?)<\/[a-zA-Z]+Interaction>/&createInteraction($item,$1,$2,$3,$correctKeys)/egs;
                $item_body_text =~ s/<([a-zA-Z]+)Interaction\s?(.*?)\/>/&createInteraction($item,$1,$2,'',$correctKeys)/egs;

		$item_content->{text} = $item_body_text;
                $item->{item_body}{content} = $item_content;

	      } else {

	        print "Could not find item body\n" if $debug;
	      } # end if $itemBody =~ /<itemBody

              #print Dumper($item->{item_body}) . "\n" if $debug;
              #print Dumper($item->{interactions}) . "\n" if $debug;

              # if we found a stylesheet, get it translated
	      if($stylesheet ne '') {

	        my $srcLink = &getImageSrc($stylesheet,$itemUrl,$relDir,$item->{version});
		
		if($srcLink =~ /src="(.*?)"/) {
		  $item->setStylesheet($1); 
		}
	      }

	      $item->setDescription($itemDescription);

              # set max points 

	      if($fullItemXml =~ /<outcomeDeclaration.*?identifier="SCORE".*?normalMaximum="(\d+)"/s) {
	        $item->setPoints($1);
	      }

	      # set the math tools if we have any

	      if($fullItemXml =~ /calculator>/) {
	        $item->setCalculator(1);
	      }

	      if($fullItemXml =~ /rule>/) {
	        $item->setRuler(1);
	      }

	      if($fullItemXml =~ /protractor>/) {
	        $item->setProtractor(1);
	      }

	      # finally, save it and log

              print "About to save item\n" if $debug;

              if($item_create_or_update == $IIA_UPDATE) {

	        $item->save("Item Import", $importerId, "Content Update" );

              } else {

	        $item->save();
	      }

	      create_item_import_action($uaId, $item->{id}, $item_create_or_update);

	      $sql = sprintf('UPDATE item SET i_qti_xml_data=%s WHERE i_id=%d',
			     $dbh->quote($fullItemXml),
			     $item->{id});
              $sth2 = $dbh->prepare($sql);
              $sth2->execute();

	      if($item_create_or_update == $IIA_UPDATE) {

	        # if this is an update, set a state change
		&setItemReviewState($dbh, $item->{id}, $item->{devState}, $item->{devState}, $importerId);
	      }

	      # if we make it this far, process the accessibility tags

	      if($fullItemXml =~ /(<(?:apip:)?apipAccessibility.*?<\/(?:apip:)?apipAccessibility>)/s) {

	        my $apipXml = $1;

		# strip all namespace strings for ease of use

		$apipXml =~ s/<apip:/</g;
		$apipXml =~ s/<\/apip:/<\//g;

                # first, clear any existing accessibility data

		$sql = <<SQL;
		DELETE FROM accessibility_feature WHERE ae_id IN 
		  (SELECT ae_id FROM accessibility_element WHERE i_id=$item->{id})
SQL
                $sth2 = $dbh->prepare($sql);
                $sth2->execute();

		$sql = 'DELETE FROM accessibility_element WHERE i_id=' . $item->{id};
                $sth2 = $dbh->prepare($sql);
                $sth2->execute();

		$sql = <<SQL;
		DELETE FROM inclusion_order_element WHERE io_id IN 
		  (SELECT io_id FROM inclusion_order WHERE i_id=$item->{id})
SQL
                $sth2 = $dbh->prepare($sql);
                $sth2->execute();

		$sql = 'DELETE FROM inclusion_order WHERE i_id=' . $item->{id};
                $sth2 = $dbh->prepare($sql);
                $sth2->execute();

		# now process the accessibility elements

		my %access_element_tags = (); 

		while( $apipXml =~ /<accessElement\s+identifier="(.*?)">(.*?)<\/accessElement>/sg) {

		  my $elementID = $1;
		  my $elementBody = $2;

		  # process the content link info

		  my $linkID = '';
                  my $linkBody = '';
		  my $linkType = 0;

		  my $textLinkType = 0;
		  my $wordSequence = 0;
		  my $charStart = 0;
		  my $charStop = 0;

		  if ( $elementBody =~ /<contentLinkInfo\s+qtiLinkIdentifierRef="(.*?)">(.*?)<\/contentLinkInfo>/sg) {

		    $linkID = $1;
		    $linkBody = $2;
		  }

		  if($linkBody =~ /<textLink>(.*?)<\/textLink>/s) {

		    $linkType = 1;

		    my $tlBody = $1;

		    if($tlBody =~ /<fullString/) {

		      $textLinkType = 1;

		    } elsif( $tlBody =~ /<wordLink>\s*(\d+)\s*<\/wordLink>/s) {

		      $textLinkType = 3;
		      $wordSequence = $1;

		    } elsif( $tlBody =~ /<characterStringLink>(.*?)<\/characterStringLink>/s) {

                      $textLinkType = 2;

		      my $cslBody = $1;

		      if($cslBody =~ /<startCharacter>(\d+)<\/startCharacter>/) {
		        $charStart = $1;
		      }

		      if($cslBody =~ /<stopCharacter>(\d+)<\/stopCharacter>/) {
		        $charStop = $1;
		      }
		    }

		  } elsif ($linkBody =~ /<objectLink/) {

		    $linkType = 2;
		  } # end if $linkBody =~ /<textLink>

		  # confirm we have valid access element, if so create record and proceed with related info

		  print "Have an access element ID=$elementID, link ID=$linkID, link type=$linkType\n" if $debug;

		  next if $elementID eq '' || $linkID eq '' || $linkType == 0;
		  next if $linkType == 1 && $textLinkType == 0;
		  next if $textLinkType == 2 && ($charStart == 0 || $charStop == 0 || $charStop < $charStart);
		  next if $textLinkType == 3 && $wordSequence == 0;

		  $sql = sprintf('INSERT INTO accessibility_element SET i_id=%d, ae_name=%s, ae_content_type=%d, '
		               . 'ae_content_name=%s, ae_content_link_type=%d, ae_text_link_type=%d, '
			       . 'ae_text_link_word=%d, ae_text_link_start_char=%d, ae_text_link_stop_char=%d',
                             $item->{id},
			     $dbh->quote($elementID),
			     1,
			     $dbh->quote($linkID),
			     $linkType,
			     $textLinkType,
			     $wordSequence,
			     $charStart,
			     $charStop);
                  $sth2 = $dbh->prepare($sql);
                  $sth2->execute();

		  my $elementKey = $dbh->{mysql_insertid};

		  next unless $elementKey;

                  # map the element ID to the key, for inclusion order 
		  $access_element_tags{$elementID} = $elementKey;

                  my $infoBody = '';

		  my @related_elements = ();
                  
		  # process the related element info

		  if ( $elementBody =~ /<relatedElementInfo>(.*?)<\/relatedElementInfo>/sg) {

		    $infoBody = $1;

		    if($infoBody =~ /<brailleTextString(.*?)>(.*?)<\/brailleTextString>/s) {

                      my %el = ();
		      $el{type} = 3;
		      $el{feature} = 3;
		      $el{info} = $2;
		      $el{lang} = '';

		      push @related_elements, \%el;
		    }

		    if($infoBody =~ /<spokenText(.*?)>(.*?)<\/spokenText>/s) {

                      my %el = ();
		      $el{type} = 1;
		      $el{feature} = 1;
		      $el{info} = $2;
		      $el{lang} = '';

		      push @related_elements, \%el;
		    }

		    if($infoBody =~ /<textToSpeechPronunciation(.*?)>(.*?)<\/textToSpeechPronunciation>/s) {

                      my %el = ();
		      $el{type} = 1;
		      $el{feature} = 2;
		      $el{info} = $2;
		      $el{lang} = '';

		      push @related_elements, \%el;
		    }

		    if($infoBody =~ /<keyWordTranslation>\s*<definitionId xml:lang="(.*?)">\s*<textString(.*?)>(.*?)<\/textString>\s*<\/definitionId>\s*<\/keyWordTranslation>/s) {

                      my %el = ();
		      $el{type} = 4;
		      $el{feature} = -1;
		      $el{info} = $3;
		      $el{lang} = $1;

		      push @related_elements, \%el;
		    }

		    if($infoBody =~ /<highlighting/s) {

                      my %el = ();
		      $el{type} = 5;
		      $el{feature} = 5;
		      $el{info} = '';
		      $el{lang} = '';

		      push @related_elements, \%el;
		    }

		  } # end if $elementBody =~ /<relatedElementInfo

                  foreach my $el_data (@related_elements) {

		    $sql = sprintf('INSERT INTO accessibility_feature SET ae_id=%d, af_type=%d, af_feature=%d, '
		  	         . 'af_info=%s',
                             $elementKey,
			     $el_data->{type},
			     $el_data->{feature},
			     $dbh->quote(replaceChars($el_data->{info})));
 
                    if($el_data->{lang} ne '') {
		      $sql .= ', af_lang=' . $dbh->quote($el_data->{lang});
                    }

                    $sth2 = $dbh->prepare($sql);
                    $sth2->execute();

		  } # end foreach my $el_data

                } # end while $apipXml =~ /<accessElement

	        # process the inclusion order info

	        if ( $apipXml =~ /<inclusionOrder>(.*?)<\/inclusionOrder>/s) {

                  my $inclusionBody = $1;

	          foreach my $inclusion_key (keys %inclusion_order_types) {

                    my $inclusion_label = $inclusion_order_types{$inclusion_key};

	            if($inclusionBody =~ /<$inclusion_label>(.*?)<\/$inclusion_label>/s) {

	              my $orderBody = $1;

	              $sql = sprintf('INSERT INTO inclusion_order SET i_id=%d, io_type=%d',
			         $item->{id},
				 $inclusion_key);
                      $sth2 = $dbh->prepare($sql);
                      $sth2->execute();

		      my $order_key = $dbh->{mysql_insertid};

		      while( $orderBody =~ /<elementOrder identifierRef="(.*?)">\s*<order>(\d+)<\/order>/gs) {

                        my $element_id = $access_element_tags{$1} || 0;
		        my $order_seq = $2 || 0;

		        if($order_seq && $element_id) {

		          $sql = sprintf('INSERT INTO inclusion_order_element SET io_id=%d, ae_id=%d, ioe_sequence=%d',
		                   $order_key,
				   $element_id,
				   $order_seq);
                          $sth2 = $dbh->prepare($sql);
                          $sth2->execute();
                        }

		      } # end while $orderBody

		    } # end if $inclusionBody

                  } # end foreach my $inclusion_key

		} # end if $apipXml =~ /<inclusionOrder

	      } # end if $fullItemXml =~ /<(?:apip:)?apipAccessibility

	      my $item_metadata_str = '';

	      if(exists $item_metadata{$file}) {
	        #print "Metadata = " . $item_metadata{$file} . "\n" if $debug;
	        $item_metadata_str = replaceChars($item_metadata{$file});

	        # replace hex entities with decimal entities
	        $item_metadata_str =~ s/(&#x)(\d+)(;)/'&#' . hex($2) . $3/eg;
	      } else {
	        $item_metadata_str = replaceChars($item->getDefaultMetadataXml());
	      }

	      $restClient->POST($metadataServiceUrl . $item->{id}, $item_metadata_str);
	      my $statusCode = $restClient->responseCode();
	      print "Using service $metadataServiceUrl" . $item->{id} . "\n" if $debug;

	      if($statusCode eq '200') {
	        print "Item Metadata update complete\n" if $debug;
	        #print $restClient->responseContent() . "\n" if $debug;
	      } else {
         	print "Unable to update Item Metadata: status ${statusCode}\n"
	        . $restClient->responseContent() . "\n"
	        . replaceChars($item_metadata{$file}) if $debug;
	      }

	    } # end if $itemName eq ''

          } # end unless $is_content_fail

          # finished an XML file, don't continue processing more if this one had an error

	  if($is_content_fail) {
	    $is_package_fail = 1;
	    last;
	  }

        } # end foreach my $file @item_xml_files

      } # end unless $is_package_fail
       
    } # end local $CWD

    # finished with this upload file

    set_monitor_status($importId, $IIM_COMPLETED,"Item Import complete",*LOG) unless $is_package_fail;

    close LOG;

    print "Removing work dir: ${work_dir}\n" if $debug;
    system('rm','-rf', $work_dir);

  } # end foreach my $file bsd_glob($uploads_path

  # finished checking for files in this item bank

} # end while my $row = $sth->fetchrow_hashref

# close down the db

$sth->finish;
$dbh->disconnect;

# remove the progress file
unlink $progress_file;

exit;

#
# LOCAL SUBS
#

sub localtime_to_mysql {

  my $time_obj = shift;

  return sprintf('%04d-%02d-%02d %02d:%02d:%02d', 
                    $time_obj->year() + 1900,
		    $time_obj->mon() + 1,
		    $time_obj->mday(),
		    $time_obj->hour(),
		    $time_obj->min(),
		    $time_obj->sec());
}

sub set_monitor_status {

  my $importId = shift;
  my $status = shift;
  my $detail = shift || '';
  my $logfh = shift || undef;

  my $sql = sprintf('UPDATE item_import_monitor SET iim_status=%d, iim_status_detail=%s, iim_timestamp=NOW() WHERE iim_id=%d',
                      $status,
		      $dbh->quote($detail),
		      $importId);

  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;

  print $logfh ($detail . "\n") if $detail ne '' && defined $logfh;
}

sub create_user_action {

  my $userId = shift;
  my $userAction = shift;

  my $sql = 'INSERT INTO user_action SET u_id=' . $userId . ', ua_type=' . $userAction; 
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;

  return $dbh->{mysql_insertid};
}

sub create_item_import_action {

  my $userActionId = shift;
  my $itemId = shift;
  my $itemAction = shift;

  my $sql = 'INSERT INTO item_import_action SET ua_id=' . $userActionId 
          . ', i_id=' . $itemId . ', iia_type=' . $itemAction; 
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;

}

sub getImageSrc {

    my $url    = shift;
    my $itemUrl  = shift;
    my $relDir = shift; 
    my $version = shift || 0;

    my $imageName = '';

    if($url =~ /\/([^\/]+)$/) {
      $imageName = $1;
    } elsif ($url =~ /^(.*)$/) {
      $imageName = $1;
    }

    $imageName = "V$version.$imageName" if $version;

    print "Creating asset for $imageName\n" if $debug;

    if ( $url =~ /^\.\// ) { $url = substr( $url, 2 ); }

    my $srcImagePath = $relDir . '/' . $url;
    my $assetUrl = $itemUrl . $imageName;
    my $assetPath = $webPath . $assetUrl;

    print "Copying $srcImagePath to $assetPath\n" if $debug;
    cp( $srcImagePath, $assetPath ) || print "Unable to copy: $srcImagePath to $assetPath :$!\n";


    #print "Returning replacement URL $assetUrl\n" if $debug;
    return 'src="' . $assetUrl . '"';
}

sub createMedia {

    my $itemId = shift;
    my $u_id = shift;
    my $atts    = shift;
    my $itemUrl  = shift;
    my $relDir = shift; 
    my $version = shift || 0;

    my $url = '';
    if($atts =~ /data="([^"]+)"/) {
      $url = $1;
    }

    my $alt = '';
    if($atts =~ /alt="([^"]+)"/) {
      $alt = $1;
    }

    my $mediaName = '';

    if($url =~ /\/([^\/]+)$/) {
      $mediaName = $1;
    } elsif ($url =~ /^(.*)$/) {
      $mediaName = $1;
    }

    my $literalMediaName = $mediaName;
    $literalMediaName = "V$version.$mediaName" if $version;

    print "Creating asset for $literalMediaName\n" if $debug;

    if ( $url =~ /^\.\// ) { $url = substr( $url, 2 ); }

    my $srcMediaPath = $relDir . '/' . $url;
    my $assetUrl = $itemUrl . $literalMediaName;
    my $assetPath = $webPath . $assetUrl;

    print "Copying $srcMediaPath to $assetPath\n" if $debug;
    cp( $srcMediaPath, $assetPath ) || print "Unable to copy: $srcMediaPath to $assetPath :$!\n";

    &track_uploaded_asset($itemId, $mediaName, $assetUrl, $alt, $u_id);  

    #print "Returning replacement URL $assetUrl\n" if $debug;
    return '<div class="orca:media:' . $mediaName . '">' . $mediaName . '</div>';
}

sub track_uploaded_asset {

  my $itemId = shift;
  my $name = shift;
  my $src = shift;
  my $alt = shift;
  my $u_id = shift;

  my $iaa_id=0;

  # figure out if we need to add or update
  my $sql = sprintf('SELECT iaa_id FROM item_asset_attribute WHERE i_id=%d AND iaa_source_url=%s',
                    $itemId,
		    $dbh->quote($src));
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  if(my $row = $sth->fetchrow_hashref) {
    $iaa_id = $row->{iaa_id};
  }
  $sth->finish;

  if($iaa_id) {

    #update
    $sql = sprintf('UPDATE item_asset_attribute SET iaa_media_description=%s, iaa_filename=%s, iaa_u_id=%d WHERE iaa_id=%d',
	   $dbh->quote($alt),
	   $dbh->quote($name),
	   $u_id,
	   $iaa_id);
   

  } else {

    #create
    $sql = sprintf('INSERT INTO item_asset_attribute SET i_id=%d, iaa_filename=%s, iaa_media_description=%s, iaa_source_url=%s, iaa_u_id=%d',
           $itemId,
	   $dbh->quote($name),
	   $dbh->quote($alt),
	   $dbh->quote($src),
	   $u_id);

  }

  $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;

}

sub createInteraction {

  my $item = shift;
  my $interaction_name = shift;
  my $interaction_params = shift;
  my $interaction_body = shift;
  my $correct_key = shift;

  # set up interaction data object, with some defaults
  my $i_obj = {};
  $i_obj->{type} = $interaction_types{$interaction_name};
  $i_obj->{name} = $item_interactions{$i_obj->{type}};
  $i_obj->{score_type} = $ST_MATCH_RESPONSE;
  $i_obj->{max_score} = 1.0;
  $i_obj->{attributes} = $interaction_params;
  $i_obj->{correct} = '';

  if($interaction_params =~ /responseIdentifier="(.*?)"/) {
    $i_obj->{name} = $1;
  }

  my $local_correct_key = $correct_key->{$i_obj->{name}} || 0;
  if($local_correct_key) {
    $i_obj->{correct} = join (' ', keys %{$local_correct_key});
  }

  print "Interaction type/id = $interaction_name/$i_obj->{name}\n" if $debug;

  # determine item format and score type

  if($interaction_name eq 'choice') {

    $item->{format} = 1;

  } elsif ($interaction_name eq 'textEntry') {

    $item->{format} = 2;

  } elsif ($interaction_name eq 'extendedText') {

    $item->{format} = 2;
    $i_obj->{score_type} = $ST_RUBRIC;
  } else {
    # if we don't support the import type of interaction, then stop here
    return '<div style="font-weight:bold;text-decoration:underline;">Unsupported Interaction</div>';
  }

  if($interaction_body =~ /<prompt\s?(.*?)>(.*?)<\/prompt>/s) {

    my $prompt = {};
    $prompt->{id} = 0;
    $prompt->{name} = 'prompt';
    $prompt->{text} = $2;
    $prompt->{attributes} = $1;


    # if prompt has an id, then encapsulate in a div tag, in case APIP data is associated
    if($prompt->{attributes} =~ /id="(.*?)"/) {
      $prompt->{text} = '<div id="' . $1 . '">' . $prompt->{text} . '</div>';
    }

    $i_obj->{content}{prompt} = $prompt;

    print "Prompt = $prompt->{text}\n" if $debug;
  }

  my $choice_ord = 0;

  while($interaction_body =~ /<simpleChoice\s?(.*?)>(.*?)<\/simpleChoice>/gs) {

    my $choice_params= $1;

    my $choice = {};
    $choice->{id} = 0;
    $choice->{text} = $2;
    $choice->{attributes} = $1;

    my $dr = {};
    $dr->{id} = 0;
    $dr->{text} = '';
    $dr->{attributes} = '';

    # check for distractor rationale
    if($choice->{text} =~ /<feedbackBlock ([^>]+)>(.*?)<\/feedbackBlock>/s) {
      $dr->{attributes} = $1;
      $dr->{text} = $2;
    }

    # and strip the rationale too
    $choice->{text} =~ s/<feedbackBlock ([^>]+)>(.*?)<\/feedbackBlock>//s;

    $choice->{name} = $mc_letters[$choice_ord];
    if($choice_params =~ /identifier="(.*?)"/) {
      $choice->{name} = $1;
    } else {               
      print "Unable to find choice identifier\n" if $debug;
    }
    $dr->{name} = $choice->{name};

    $i_obj->{content}{choices}[$choice_ord] = $choice;
    $i_obj->{content}{distractorRationale}[$choice_ord] = $dr;

    $choice_ord++;
  }

  my $ii_id = $item->createInteraction($i_obj);

  my $block_type = ($i_obj->{type} == $IT_TEXT_ENTRY) ? 'span' : 'div';
  my $suffix = ( $i_obj->{type} == $IT_TEXT_ENTRY ) ? '<span>&#160;</span>' : '<br />';
  my $name = $item_interactions{$i_obj->{type}};

  my $content;

  if($i_obj->{type} == $IT_TEXT_ENTRY) {
    $content = <<HTML;
    <$block_type style="-ro-editable-inside:true;">
      <$block_type class="orca:interaction" id="interaction_$ii_id" 
                   style="-ro-editable-inside:false;font-weight:bold;text-decoration:underline;">$name</$block_type>
    </$block_type>
    $suffix
HTML
  } else {
    $content = <<HTML;
      <$block_type class="orca:interaction" id="interaction_$ii_id" 
                   style="font-weight:bold;text-decoration:underline;">$name</$block_type>
      $suffix
HTML
  }

  return $content; 
}

sub updateRubricBlock {

  my $item = shift;
  my $rubricBlock = shift;

  if ($rubricBlock =~ /<rubricBlock ([^>]+)>(.*?)<\/rubricBlock>/s) {

    my $atts = &attributeStringToHash($1);
    my $text = $2;

    # determine what type of object is in the rubric block 
    if($atts->{view} eq 'scorer' && $atts->{use} eq 'ScoringGuidance') {

      # This is what we call a Rubric
      my $rubricName = 'rubric_' . $item->{name};

      # create or update this rubric
      my $rubric = new Rubric($dbh, $item->{bankId}, $rubricName);
      unless ($rubric->{id}) {
        $rubric->create($item->{bankId}, $rubricName);
        $item->insertChar($OC_RUBRIC, $rubric->{id});
      }

      print "Create/update rubric '$rubricName'\n" if $debug;

      $rubric->setContent($text);
      $rubric->save();
    }
    elsif($atts->{view} eq 'candidate') {

      # This is what we call a Passage
      my $passageName = exists($atts->{id}) ? $atts->{id} : 'passage_' . $item->{name};

      # create or update this passage
      my $psg = new Passage($dbh, $item->{bankId}, $passageName);
      unless ($psg->{id}) {
        $psg->create($item->{bankId}, $passageName);
      }

      print "Create/update passage '$passageName'\n" if $debug;

      $item->insertChar($OC_PASSAGE, $psg->{id});

      $psg->setBody($text);
      $psg->save();
    }
    else {
      return $rubricBlock;
    }

    return '';
  } 

  return $rubricBlock;
}

END {

  # make sure we shutdown properly 

  if(-e $progress_file) {

    print "Item Import was terminated abnormally. Please investigate!\n";

    $sth->finish if defined $sth;
    $dbh->disconnect if defined $dbh;

    # remove the progress file
    unlink $progress_file;
  }


}
