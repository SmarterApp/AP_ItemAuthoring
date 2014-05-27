package SupplementalInfoConstants;

use warnings;
use strict;
use URI::Escape;
use ItemConstants;

BEGIN {

    use Exporter ();
    use vars qw(@ISA @EXPORT @EXPORT_OK);

    @ISA       = qw(Exporter);
    @EXPORT_OK = qw();
    @EXPORT    = qw(
      %artType %colorFormat %graphicFormat %graphicFileType %imageUnit %itemContentSection %objectTypes 
      %workStates %workTypes $WT_ART $WT_MEDIA $WT_ACCESSIBILITY %accessibilityType %workAssigneeTypes
      %mediaType %mediaLength
      %requestField %requestPartField %fieldDefinition &get_params &set_params &get_todays_date
    );

}

our @EXPORT;

our %artType = (
    'graphA'     => 'Graph A',
    'graphB'     => 'Graph B',
    'graphC'     => 'Graph C',
    'graphD'     => 'Graph D',
    'graphE'     => 'Graph E',
    'graphF'     => 'Graph F',
    'scatter'    => 'Scatter Plot',
    'monetary'   => 'Monetary Graphic',
    'numberline' => 'Number Line',
    'equation'   => 'Equation',
    'table'      => 'Table',
    'other'      => 'Other'
);

our %mediaType = (
   '1' => 'Simulation',
   '2' => 'Observation',
   '3' => 'Experiment'
);

our %mediaLength = (
   '1' => 'Short',
   '2' => 'Medium',
   '3' => 'Long'
);

our %accessibilityType = ( 
                   '1' => 'Spoken, Text &amp; Speech',
		   '2' => 'Spoken, Text Only',
		   '3' => 'Spoken, Non-Visual',
		   '4' => 'Spoken, Graphics Only',
		   '5' => 'Braille'
                 );

our %colorFormat = (
    'bw' => 'Black &amp; White',
    'fc' => 'Full Color',
    'gs' => 'Grayscale'
);

our %graphicFormat = (
    'print' => 'Print',
    'web'   => 'Web',
    'both'  => 'Print &amp; Web'
);

our %graphicFileType = (
    'gif' => 'GIF',
    'png' => 'PNG',
    'jpg' => 'JPG',
);

our %imageUnit = (
    'px' => 'Pixels',
    'in' => 'Inches'
);

our %itemContentSection = (
  '0' => 'Stem',
  '1' => 'Choice A',
  '2' => 'Choice B',
  '3' => 'Choice C',
  '4' => 'Choice D',
  '5' => 'Choice E' );

our $WT_ART = 1;
our $WT_MEDIA = 2;
our $WT_ACCESSIBILITY = 3;

our %workTypes = ( '1' => 'Art',
                   '2' => 'Media',
		   '3' => 'Accessibility' );

our %objectTypes = ( '4' => 'Item',
                     '7' => 'Passage',
		     '8' => 'Rubric' );


our %workAssigneeTypes = ( '1' => $UR_GRAPHIC_DESIGNER,
                           '2' => $UR_MEDIA_DESIGNER,
			   '3' => $UR_ACCESSIBILITY_SPECIALIST );

our %workStates = ( '1' => { $DS_FIX_ART => 1,
                             $DS_NEW_ART => 1 },
                    '2' => { $DS_FIX_MEDIA => 1,
		             $DS_NEW_MEDIA => 1 },
                    '3' => { $DS_FIX_ACCESSIBILITY => 1,
		             $DS_NEW_ACCESSIBILITY => 1 }
                  );

our %requestField = ( '1' => [ 
                                'program', 'name', 'gradeLevel', 'contentArea',
                                'requestDate', 'dueDate', 'designer'          
                              ],
                       '2' => [ 
                                'program', 'name', 'gradeLevel', 'contentArea',
                                'requestDate', 'dueDate', 'designer'          
		              ],
		       '3' => [ 
                                'program', 'name', 'gradeLevel', 'contentArea',
                                'requestDate', 'dueDate'          
		              ] 
	              );

our %requestPartField = ( '1' => [ 
                                'artType', 'colorFormat', 'graphicFormat', 'graphicFileType', 
				'graphicWidth', 'graphicHeight', 'imageUnit', 'graphicScale',
				'contentSection', 'description', 'sampleGraphic'
                              ],
                       '2' => [ 
                               'mediaType', 'mediaLength', 'contentSection', 'description', 'sampleGraphic', 'sampleMedia'
		              ],
		       '3' => [ 
                               'accessibilityType', 'description'
		              ] 
	              );


our %fieldDefinition = ( 
                         'artType' => {
                                        'type' => 'list',
					'valueMap' => \%artType,
					'label' => 'Art Type',
                                      },
                         'mediaType' => {
                                        'type' => 'list',
					'valueMap' => \%mediaType,
					'label' => 'Media Type',
                                      },
                         'accessibilityType' => {
                                        'type' => 'list',
					'valueMap' => \%accessibilityType,
					'label' => 'Accessibility Context',
                                      },
                         'mediaLength' => {
                                        'type' => 'list',
					'valueMap' => \%mediaLength,
					'label' => 'Media Length',
                                      },
                         'colorFormat' => {
                                        'type' => 'list',
                                        'valueMap' => \%colorFormat,
					'label' => 'Color Format',
			                  },
                         'graphicFormat' => {
                                        'type' => 'list',
                                        'valueMap' => \%graphicFormat,
					'label' => 'Graphic Format',
			                    },
                         'graphicFileType' => {
                                        'type' => 'list',
                                        'valueMap' => \%graphicFileType,
					'label' => 'Graphic File Type',
			                      },
                         'imageUnit' => {
                                        'type' => 'list',
                                        'valueMap' => \%imageUnit,
					'label'  => 'Image Size Units',
			                },
                         'requestDate' => { 'type' => 'generated', 
			                    'value' => '2012-01-30',
				            'generator' => \&get_todays_date, 
			                    'label' => 'Request Date' },
                         'dueDate' => { 'type' => 'date', 'label' => 'Due Date' },
                         'description' => { 'type' => 'string', 'label' => 'Description', 'size' => '50' },
			 'contentSection' => { 'type' => 'list', 
			                       'valueMap' => \%itemContentSection,
			                       'label' => 'Component' },
			 'graphicWidth' => { 'type' => 'string', 'label' => 'Image Width' },
			 'graphicHeight' => { 'type' => 'string', 'label' => 'Image Height' },
			 'graphicScale' => { 'type' => 'string', 'label' => 'Export at %' },
			 'sampleGraphic' => { 'type' => 'graphic', 'label' => 'Sample Graphic' },
			 'sampleMedia' => { 'type' => 'media', 'label' => 'Sample Media' },
			 'designer' => { 'type' => 'assignee', 'label' => 'Designer' },
                         'name' => { 'type' => 'readonly',
			             'value' => 'name',
				     'label' => 'Item Name' },
                         'program' => { 'type' => 'readonly',
			                'value' => 'bankName',
					'label' => 'Program' },
                         'gradeLevel' => { 'type' => 'readonly',
			                   'value' => $OC_GRADE_LEVEL,
					   'valueMap' => $const[$OC_GRADE_LEVEL],
					   'label' => 'Grade Level' },
                         'contentArea' => { 'type' => 'readonly',
			                    'value' => $OC_CONTENT_AREA,
					    'valueMap' => $const[$OC_CONTENT_AREA],
					    'label' => 'Subject' },
); 

sub get_params {

  my $paramsFile = shift;
  my %params = ();

  print STDERR "Unable to write to $paramsFile" unless -r $paramsFile;

  if(-e $paramsFile) {
    open PARAMS, "<${paramsFile}";
    while (<PARAMS>) {
      chomp;
      my ( $key, $val ) = split(/=/, $_, 2);
      $params{$key} = uri_unescape($val);
    }
    close PARAMS;
  }

  return \%params;
}

sub set_params {
  my $paramsFile = shift;
  my $params = shift;

  print STDERR "Unable to write to $paramsFile" unless -w $paramsFile;

  open PARAMS, ">${paramsFile}";
  foreach my $key (keys %{$params}) {

    print PARAMS $key . '=' . uri_escape($params->{$key}) . "\n";
  }
  close PARAMS;

  return 1;
}

sub get_todays_date {

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);

    return sprintf( '%04d-%02d-%02d', $year + 1900, $mon + 1, $mday );
}

1;
