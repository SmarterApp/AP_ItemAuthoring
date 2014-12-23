package ItemConstants;

use warnings;
use strict;
use UrlConstants;
use URI::Escape;
use File::Glob ':glob';
use File::Copy 'cp';
use Time::HiRes;
use Passage;
use REST::Client;

BEGIN {
    use Exporter ();
    use vars qw(@ISA @EXPORT @EXPORT_OK);

    @ISA       = qw(Exporter);
    @EXPORT_OK = qw();
    @EXPORT =
      qw($asset_path $assetCreateFramesetUrl $assetCreateUrl $assetInsertUrl
      $assetUploadUrl $itemCharacterizeUrl $assignStandardUrl
      $assignPassageUrl $imagesUrl $imagesDir $textogif_dir
      $itemCreateUrl $itemFindUrl $imageEditUrl $assetBlankUrl
      $assetFindUrl $findByStandardUrl $USE_ITEM_XML
      $assignRubricUrl $projectConfigDir $escapeChars $mediaUploadUrl $mediaViewUrl $mediaInsertUrl $mediaDeleteUrl
      $DS_DEVELOPMENT $DS_REVIEW $DS_TESTING $DS_APPROVED $DS_RELEASED
      $DS_SUSPENDED $DS_CANCELLED $DS_IMPORTED $DS_REJECTED $DS_PM_FIX
      $DS_RETIRED $DS_CONTENT_REVIEW $DS_CONTENT_REVIEW_2 $DS_ON_HOLD
      $DS_SCHEDULED $DS_CONTENT_APPROVED $DS_COPY_REVIEW $DS_COPY_REVIEW_2 $DS_COPY_APPROVED
      $DS_CLIENT_APPROVED $DS_CLIENT_APPROVED_2 $DS_CLIENT_APPROVED_3
      $DS_COPY_TEACHER_REVIEW $DS_COPY_F2F_REVIEW $DS_COPY_FINAL_REVIEW
      $DS_NEW_ART $DS_FIX_ART $DS_SUPERVISOR_REVIEW $DS_CLIENT_PREVIEW $DS_CUSTOMER_PROOF $DS_READY_FOR_AUDIO
      $DS_CONTENT_REVIEW_1 $DS_ITEM_UPDATE_1 $DS_COMMITTEE_REVIEW
      $DS_ITEM_UPDATE_2 $DS_CONTENT_REVIEW_3 $DS_SENSITIVITY_REVIEW
      $DS_EXTERNAL_EDITOR_REVIEW $DS_CONTENT_REVIEW_4 $DS_ITEM_UPDATE_3 $DS_CONTENT_REVIEW_5
      $DS_ART_REQUEST_REVIEW $DS_PENDING_ART $DS_READY_FOR_ART $DS_PROOFREADING
      $DS_CONTENT_REVIEW_6 $DS_ITEM_UPDATE_4 $DS_CONTENT_REVIEW_7 $DS_QA_REVIEW
      $DS_PROGRAM_DIRECTOR_REVIEW $DS_ART_REQUEST_REVIEW
      $DS_BANKED $DS_CONSORTIUM_REVIEW $DS_DNU_ITEM_POOL $DS_FIX_MEDIA $DS_NEW_MEDIA
      $DS_QUERY_RESOLUTION $DS_DATA_REVIEW $DS_OPERATIONAL_ITEM_POOL
      $DS_POST_ADMIN_REVIEW $DS_QC_PRESENTATION_REVIEW $DS_POST_COMMITTEE
      $DS_NEW_ACCESSIBILITY $DS_FIX_ACCESSIBILITY
       
      @graphic_extensions @media_extensions @asset_extensions @banned_extensions @choice_chars %reverse_choice_chars
      $OC_ITEM_STANDARD
      $OC_CONTENT_AREA $OC_GRADE_LEVEL $OC_PASSAGE $OC_POINTS $OC_DOK
      $OC_RUBRIC $OC_PROTRACTOR $OC_RULER $OC_CALCULATOR $OC_GRADE_SPAN_START $OC_GRADE_SPAN_END
      $OC_COMPASS $OC_SCORING_METHOD $OC_ITEM_FORMAT $OC_SCALE_VALUE
      $OC_MAP_VALUE $OC_MINOR_EDIT $OC_SECONDARY_STANDARD $OC_TERTIARY_STANDARD $OC_BENCHMARK
      $OC_SECONDARY_BENCHMARK $OC_TERTIARY_BENCHMARK $OC_CONTENT_STANDARD $OC_SECONDARY_CONTENT_STANDARD
      $OC_TERTIARY_CONTENT_STANDARD $OC_COMP_CURRICULUM
      $OC_CATEGORY $OC_SECONDARY_CATEGORY $OC_TERTIARY_CATEGORY
      $OC_DEFAULT_ANSWER $OC_LAYOUT $OC_ANSWER_FORMAT $OC_FORM_GROUP
      $OC_ACCESSIBILITY_AUDIO $OC_ACCESSIBILITY_LARGE_PRINT
      $OC_ITEM_ENEMY $OC_CHOICE_SHUFFLE
      $OT_TEST $OT_SECTION $OT_MODULE $OT_PASSAGE $OT_RUBRIC
      $OT_ITEM $IT_X_MC $IT_NON_X_MC $IT_SHORT_CR
      $IT_EXTENDED_CR $IT_BUBBLE $IT_MULTI_SHORT_CR
      $IT_MULTI_EXTENDED_CR $IT_INTERACTIVE
      $IT_CHOICE $IT_TEXT_ENTRY $IT_EXTENDED_TEXT $IT_INLINE_CHOICE $IT_MATCH
      $UP_VIEW_ITEM_BANK $UP_VIEW_TEST_BANK $UP_VIEW_WORKGROUP
      $RP_EDIT_ITEM $RP_REVIEW_ITEM $RP_COMMENT_ITEM $RP_DATA_REVIEW_ITEM
      $RP_EDIT_TEST $RP_REVIEW_TEST $RP_COMMENT_TEST
      $IF_STEM $IF_CHOICE $IF_DISTRACTOR_RATIONALE $IF_PROMPT $IF_CHOICE_MATCH
      $IF_FEEDBACK_INITIAL $IF_FEEDBACK_FINAL
      @labels @const @ctypes @tools
      $HD_STD_HIERARCHY $HD_CONTENT_AREA $HD_STANDARD_STRAND
      $HD_GRADE_CLUSTER $HD_BENCHMARK $HD_GRADE_LEVEL $HD_GLE
      $HD_SUBSTRAND $HD_GRADE_LEVEL_COURSE $HD_ROOT $HD_LEAF %standard_types
      $P_ITEM_EDIT $P_ITEM_REVIEW_CONTENT $P_ITEM_REVIEW_COPY $P_ITEM_AUDIO_SCRIPTOR
      $P_ITEM_APPROVE $P_ITEM_ART $P_ITEM_ADMIN $P_ITEM_SUPER_ADMIN
      $P_CONTENT_SPECIALIST $P_COPY_EDITOR $P_GRAPHIC_DESIGNER $P_MEDIA_DESIGNER
      $P_COMMITTEE_REVIEWER $P_QC_PRESENTATION $P_DATA_MANAGER $P_PSYCHOMETRICIAN
      $P_COMMITTEE_FACILITATOR
      $UA_NONE $UA_SUPER $UA_ORG $UA_PROGRAM
      %admin_type
      $UR_NONE $UR_ITEM_EDIT $UR_CONTENT_SPECIALIST $UR_COPY_EDITOR $UR_GRAPHIC_DESIGNER
      $UR_MEDIA_DESIGNER $UR_COMMITTEE_REVIEWER $UR_QC_PRESENTATION $UR_DATA_MANAGER 
      $UR_PSYCHOMETRICIAN $UR_COMMITTEE_FACILITATOR $UR_DATA_REVIEWER $UR_ACCESSIBILITY_SPECIALIST
      %review_type
      $UT_ITEM_EDITOR %publication_status %export_ok %read_only 
      %item_types %item_formats @dev_states_workflow_ordered_keys %dev_states %genres %languages
      %difficulty_levels %defaults %layout_types %asy_colors
      $rubricUrl $rubricPath %contentStandards
      $pxn8Url $passageUrl $passagePath $imageSaveUrl
      %default $textogif_url $chartDisplayUrl
      %charts $chartsUrl $passageUploadAssetUrl
      $passageInsertAssetUrl $rubricUploadAssetUrl %itemStandardChar
      $rubricInsertAssetUrl &setImageSize &sendNewItemNotification
      $sourcesUrl $sourcesDir &replaceChars &fixHtml &getStandardsUnderRoot
      &getBubbleHtml $CODED_ERROR_TYPE %error_types &getPassageAssets &getRubricAssets &getItemsByUser
      &hashToSelect &hashToCheckbox &readOgtFile &getStandard &dbCharUpdate
      &getEditors &getUsers &print_no_auth &printNoAuthPage &get_ts &getNewItemPrefix &getItemAssets
      &getSession &setItemReviewState &setPassageReviewState &getNextItemSequence
      &get_project_config  %workStates &getProjects &getPassageList %itemNotesTags
      $dbDsn $dbUser $dbPass $webPath $orcaPath $orcaUrl $webHost &getItemXml &getItemBanks
      &getStandards &isHTMLContentEmpty
      &escapeHTML &unescapeHTML &escapeFlashValue &unescapeFlashValue &setAssetAttributes
      &getContentStandard &getGLENumber &getUsersWithPermissions &getUsersByItemBank 
      &getWorkgroups &getWorkgroupFilters
      &getFileContent &getItemArchive &getImageSrcTranslate $USE_FLASH_CHARTS %stringCharacteristics
      &getActionMap &getWorkListForUserType %action_key_states
      $commonUrl $commonPath %CDE_CONFIG $instance_name $_config
      &getContentAssetPair &setContentAssetPair
      $ITEM_ACTION_MAP $PASSAGE_ACTION_MAP
      %role_item_permission_types %role_test_permission_types %default_role_permissions
      @role_types %role_labels
      &getMediaAssetAttributes &getMediaTableHtml &getMediaHtml &getMediaReadyFunction
      &addItemComment &addPassageComment %item_rating &getBankMetafilesForItem
      $IB_METAFILE_ITEM_SPEC $IB_METAFILE_PASSAGE_SPEC $IB_METAFILE_COPYRIGHT $IB_METAFILE_OTHER
      %ib_metafile_types %mc_answer_choices
      &getOrganizations %review_type_map &getCurrentItemIdByName
      &getUsersWithReviewType @review_with_edit @review_per_user %item_interactions
      $ST_MATCH_RESPONSE $ST_RUBRIC &attributeStringToHash &hashToAttributeString
      %tags_with_no_id %characterization_view_types
      &makeQueryWithWorkgroupFilter %review_flags &getMetadataClient $metadataServiceUrl
    );

    push @INC, '/usr/lib/perl5/vendor_perl/5.8.6/';
}

our @EXPORT;

our $CODED_ERROR_TYPE = 0;
our $USE_ITEM_XML     = 0;
our $USE_FLASH_CHARTS = 1;

our $escapeChars = "^A-Za-z0-9";

#my $asset_url = "${orcaUrl}images/";
our $asset_path             = "${orcaPath}images/";
our $assetCreateFramesetUrl = "${orcaUrl}cgi-bin/assetCreateFrameset.pl";
our $assetCreateUrl         = "${orcaUrl}cgi-bin/assetCreate.pl";
our $assetInsertUrl         = "${orcaUrl}cgi-bin/assetInsert.pl";
our $assetUploadUrl         = "${orcaUrl}cgi-bin/assetUpload.pl";
our $itemCharacterizeUrl    = "${orcaUrl}cgi-bin/itemCharacterize.pl";
our $assignStandardUrl      = "${orcaUrl}cgi-bin/itemAssignStandard.pl";
our $assignPassageUrl       = "${orcaUrl}cgi-bin/itemAssignPassage.pl";
our $assignRubricUrl        = "${orcaUrl}cgi-bin/itemAssignRubric.pl";
our $itemCreateUrl          = "${orcaUrl}cgi-bin/itemCreate.pl";
our $itemFindUrl            = "${orcaUrl}cgi-bin/itemFind.pl";
our $assetFindUrl           = "${orcaUrl}cgi-bin/assetFind.pl";
our $mediaUploadUrl         = "${orcaUrl}cgi-bin/mediaUpload.pl";
our $mediaViewUrl           = "${orcaUrl}cgi-bin/mediaView.pl";
our $mediaInsertUrl         = "${orcaUrl}cgi-bin/mediaInsert.pl";
our $mediaDeleteUrl         = "${orcaUrl}cgi-bin/mediaDelete.pl";
our $assetBlankUrl          = "${orcaUrl}assetCreateBlank.html";
our $passageUploadAssetUrl  = "${orcaUrl}cgi-bin/passageUploadAsset.pl";
our $passageInsertAssetUrl  = "${orcaUrl}cgi-bin/passageInsertAsset.pl";
our $rubricUploadAssetUrl   = "${orcaUrl}cgi-bin/rubricUploadAsset.pl";
our $rubricInsertAssetUrl   = "${orcaUrl}cgi-bin/rubricInsertAsset.pl";
our $imageEditUrl           = "${orcaUrl}cgi-bin/editImage.pl";
our $imageSaveUrl           = "${orcaUrl}cgi-bin/saveImage.pl";
our $pxn8Url                = "${commonUrl}pixenate/";
our $passageUrl             = "${orcaUrl}passages/";
our $passagePath            = $webPath . $passageUrl;
our $rubricUrl              = "${orcaUrl}rubrics/";
our $rubricPath             = $webPath . $rubricUrl;
our $findByStandardUrl      = "${orcaUrl}cgi-bin/itemFindByStandard.pl";
our $chartDisplayUrl        = "${orcaUrl}cgi-bin/chartDisplay.pl";
our $projectConfigDir       = "${webPath}${orcaUrl}project/";

our $metadataServiceUrl = $javaUrl . 'service/import/itemMetadata/';

our $imagesUrl = "${orcaUrl}images/";
our $imagesDir = $webPath . $imagesUrl;
our $chartsUrl = "${commonUrl}charts/";

our $sourcesUrl = "${orcaUrl}sources/";
our $sourcesDir = $webPath . $sourcesUrl;

our $textogif_dir = $webPath . "/textogif/";
our $textogif_url = "${orcaUrl}cgi-bin/textogif.pl";

our @graphic_extensions = qw/gif png jpg jpeg svg/;
our @media_extensions = qw/mp3 m4a m4v swf mp4/;
our @banned_extensions = qw/exe EXE dll DLL bat BAT/;
our @asset_extensions = (@graphic_extensions, @media_extensions, qw/xml/);

our @choice_chars = (
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
);

our %reverse_choice_chars = ( 'A' => 0, 'B' => 1, 'C' => 2, 'D' => 3, 'E' => 4, 'F' => 5, 'G' => 6, 'H' => 7, 
                              'I' => 8, 'J' => 9, 'K' => 10, 'L' => 11, 'M' => 12, 'N' => 13, 'O' => 14,
			      'P' => 15, 'Q' => 16, 'R' => 17, 'S' => 18, 'T' => 19, 'U' => 20, 'V' => 21);

our $DS_DEVELOPMENT         = 1;
our $DS_REVIEW              = 2;
our $DS_TESTING             = 3;
our $DS_APPROVED            = 4;
our $DS_RELEASED            = 5;
our $DS_SUSPENDED           = 6;
our $DS_CANCELLED           = 7;
our $DS_IMPORTED            = 8;
our $DS_REJECTED            = 9;
our $DS_PM_FIX              = 10;
our $DS_RETIRED             = 11;
our $DS_CONTENT_REVIEW      = 12;
our $DS_CONTENT_REVIEW_2    = 13;
our $DS_ON_HOLD             = 14;
our $DS_SCHEDULED           = 15;
our $DS_CONTENT_APPROVED    = 16;
our $DS_COPY_REVIEW         = 17;
our $DS_COPY_APPROVED       = 18;
our $DS_NEW_ART             = 19;
our $DS_FIX_ART             = 20;
our $DS_CLIENT_APPROVED     = 21;
our $DS_CLIENT_APPROVED_2   = 22;
our $DS_CLIENT_APPROVED_3   = 23;
our $DS_COPY_TEACHER_REVIEW = 24;
our $DS_COPY_F2F_REVIEW     = 25;
our $DS_COPY_FINAL_REVIEW   = 26;
our $DS_COPY_REVIEW_2       = 27;
our $DS_SUPERVISOR_REVIEW   = 28;
our $DS_CLIENT_PREVIEW      = 29;
our $DS_CUSTOMER_PROOF      = 30;
our $DS_READY_FOR_AUDIO     = 31;
### New CB Dev States
our $DS_CONTENT_REVIEW_1             = 40;
our $DS_ITEM_UPDATE_1                = 41;
our $DS_COMMITTEE_REVIEW             = 42;
our $DS_ITEM_UPDATE_2                = 43;
our $DS_CONTENT_REVIEW_3             = 44;
our $DS_SENSITIVITY_REVIEW           = 45;
our $DS_EXTERNAL_EDITOR_REVIEW       = 46;
our $DS_CONTENT_REVIEW_4             = 47;
our $DS_ITEM_UPDATE_3                = 48;
our $DS_CONTENT_REVIEW_5             = 49;
our $DS_ART_REQUEST_REVIEW           = 50;
our $DS_PENDING_ART                  = 51;
our $DS_READY_FOR_ART                = 52;
our $DS_PROOFREADING                 = 53;
our $DS_CONTENT_REVIEW_6             = 54;
our $DS_ITEM_UPDATE_4                = 55;
our $DS_CONTENT_REVIEW_7             = 56;
our $DS_QA_REVIEW                    = 57;
our $DS_PROGRAM_DIRECTOR_REVIEW      = 58;
### New SBAC Dev States
our $DS_BANKED	     		     = 60;
our $DS_CONSORTIUM_REVIEW	     = 61;
our $DS_DNU_ITEM_POOL	     	     = 62;
our $DS_FIX_MEDIA	     	     = 63;
our $DS_NEW_MEDIA	     	     = 64;
our $DS_QUERY_RESOLUTION	     = 65;
our $DS_DATA_REVIEW	     	     = 66;
our $DS_OPERATIONAL_ITEM_POOL	     = 67;
our $DS_POST_ADMIN_REVIEW	     = 68;
our $DS_QC_PRESENTATION_REVIEW	     = 69;
our $DS_POST_COMMITTEE     	     = 70;
our $DS_NEW_ACCESSIBILITY = 71;
our $DS_FIX_ACCESSIBILITY = 72;

our $OC_ITEM_STANDARD              = 1;
our $OC_CONTENT_AREA               = 2;
our $OC_GRADE_LEVEL                = 3;
our $OC_PASSAGE                    = 4;
our $OC_GRADE_SPAN_START           = 5;
our $OC_GRADE_SPAN_END             = 6;
our $OC_POINTS                     = 7;
our $OC_DOK                        = 8;
our $OC_PROTRACTOR                 = 9;
our $OC_RULER                      = 10;
our $OC_CALCULATOR                 = 13;
our $OC_RUBRIC                     = 16;
our $OC_COMPASS                    = 18;
our $OC_SCORING_METHOD             = 28;
our $OC_ITEM_FORMAT                = 30;
our $OC_SCALE_VALUE                = 31;
our $OC_MAP_VALUE                  = 32;
our $OC_MINOR_EDIT                 = 33;
our $OC_SECONDARY_STANDARD         = 34;
our $OC_TERTIARY_STANDARD          = 35;
our $OC_BENCHMARK                  = 36;
our $OC_SECONDARY_BENCHMARK        = 37;
our $OC_TERTIARY_BENCHMARK         = 38;
our $OC_CONTENT_STANDARD           = 39;
our $OC_SECONDARY_CONTENT_STANDARD = 40;
our $OC_TERTIARY_CONTENT_STANDARD  = 41;
our $OC_COMP_CURRICULUM            = 42;
our $OC_CATEGORY                   = 43;
our $OC_SECONDARY_CATEGORY         = 44;
our $OC_TERTIARY_CATEGORY          = 45;
our $OC_DEFAULT_ANSWER             = 46;
our $OC_LAYOUT                     = 47;
our $OC_ANSWER_FORMAT              = 48;
our $OC_FORM_GROUP                 = 49;
our $OC_ACCESSIBILITY_AUDIO = 50;
our $OC_ACCESSIBILITY_LARGE_PRINT = 51;
our $OC_ITEM_ENEMY = 52;
our $OC_CHOICE_SHUFFLE = 53;

our $OT_TEST    = 1;
our $OT_MODULE  = 2;
our $OT_SECTION = 3;
our $OT_ITEM    = 4;
our $OT_PASSAGE = 7;
our $OT_RUBRIC  = 8;

our $IF_STEM                 = 1;
our $IF_CHOICE               = 2;
our $IF_DISTRACTOR_RATIONALE = 3;
our $IF_FEEDBACK_INITIAL = 4;
our $IF_FEEDBACK_FINAL = 5;
our $IF_PROMPT = 6;
our $IF_CHOICE_MATCH = 7;

our $IT_X_MC              = 1;
our $IT_NON_X_MC          = 2;
our $IT_SHORT_CR          = 3;
our $IT_EXTENDED_CR       = 4;
our $IT_BUBBLE            = 5;
our $IT_INTERACTIVE       = 6;
our $IT_MULTI_SHORT_CR    = 23;
our $IT_MULTI_EXTENDED_CR = 24;

our $IT_CHOICE = 1;
our $IT_TEXT_ENTRY = 2;
our $IT_EXTENDED_TEXT = 3;
our $IT_INLINE_CHOICE = 4;
our $IT_MATCH = 5;

our $ST_MATCH_RESPONSE = 1;
our $ST_RUBRIC = 2;

our $HD_STD_HIERARCHY      = 1;
our $HD_CONTENT_AREA       = 2;
our $HD_STANDARD_STRAND    = 3;
our $HD_GRADE_CLUSTER      = 4;
our $HD_BENCHMARK          = 5;
our $HD_GRADE_LEVEL        = 6;
our $HD_GLE                = 7;
our $HD_SUBSTRAND          = 8;
our $HD_GRADE_LEVEL_COURSE = 9;

our %standard_types = ( 1 => 'Program',
                        2 => 'Test Subject',
			3 => 'Area',
			4 => 'General Content',
			5 => 'Specific Content',
			6 => 'Sub-Specific Content' );

our $HD_ROOT = 1; 
our $HD_LEAF = 6; 

our $IB_METAFILE_ITEM_SPEC = 1;
our $IB_METAFILE_PASSAGE_SPEC = 2;
our $IB_METAFILE_COPYRIGHT = 3;
our $IB_METAFILE_OTHER = 4;

our %ib_metafile_types = (
  $IB_METAFILE_ITEM_SPEC => 'Item Specification',
  $IB_METAFILE_PASSAGE_SPEC => 'Passage Specification',
  $IB_METAFILE_COPYRIGHT => 'Copyright/DRM',
  $IB_METAFILE_OTHER => 'Other'
);

our $P_ITEM_EDIT           = 1;
our $P_ITEM_REVIEW_CONTENT = 2;
our $P_ITEM_REVIEW_COPY    = 4;
our $P_ITEM_APPROVE        = 8;
our $P_ITEM_ADMIN          = 16;
our $P_ITEM_ART            = 32;
our $P_ITEM_AUDIO_SCRIPTOR = 40;
our $P_ITEM_SUPER_ADMIN    = 64;

our $P_CONTENT_SPECIALIST    = 128;
our $P_COPY_EDITOR           = 256;
our $P_GRAPHIC_DESIGNER      = 512;
our $P_MEDIA_DESIGNER        = 1024;
our $P_COMMITTEE_REVIEWER    = 2048;
our $P_QC_PRESENTATION 	     = 4096;
our $P_DATA_MANAGER 	     = 8192;
our $P_PSYCHOMETRICIAN 	     = 16384;
our $P_COMMITTEE_FACILITATOR = 32768;

our @role_types = ( $P_ITEM_EDIT, $P_CONTENT_SPECIALIST, $P_COPY_EDITOR, 
		    $P_GRAPHIC_DESIGNER, $P_MEDIA_DESIGNER, $P_COMMITTEE_REVIEWER, 
		    $P_QC_PRESENTATION, $P_DATA_MANAGER, $P_PSYCHOMETRICIAN, 
		    $P_COMMITTEE_FACILITATOR
);

my %role_labels = (
    $P_ITEM_EDIT             => 'Item Writer',
    $P_CONTENT_SPECIALIST    => 'Content Specialist',
    $P_COPY_EDITOR 	     => 'Copy Editor',
    $P_GRAPHIC_DESIGNER      => 'Graphic Designer',
    $P_MEDIA_DESIGNER        => 'Media Designer',
    $P_COMMITTEE_REVIEWER    => 'Committee Reviewer',
    $P_QC_PRESENTATION 	     => 'QC Presentation',
    $P_DATA_MANAGER 	     => 'Data Manager',
    $P_PSYCHOMETRICIAN 	     => 'Psychmetrician',
    $P_COMMITTEE_FACILITATOR => 'Committee Facilitator',
);

our $UP_VIEW_ITEM_BANK = 1;
our $UP_VIEW_TEST_BANK = 2;
our $UP_VIEW_WORKGROUP = 3;

our $UA_NONE = 0;
our $UA_SUPER = 1;
our $UA_ORG = 2;
our $UA_PROGRAM = 3;

our %admin_type = ( $UA_NONE => 'None',
                    $UA_SUPER => 'Super Admin',
		    $UA_ORG => 'Organization Admin',
		    $UA_PROGRAM => 'Program Admin' );

our $UR_NONE = 0;
our $UR_ITEM_EDIT = 1;
our $UR_CONTENT_SPECIALIST = 2;
our $UR_COPY_EDITOR = 3;
our $UR_GRAPHIC_DESIGNER = 4;
our $UR_MEDIA_DESIGNER = 5;
our $UR_COMMITTEE_REVIEWER = 6;
our $UR_QC_PRESENTATION = 7;
our $UR_DATA_MANAGER = 8;
our $UR_PSYCHOMETRICIAN = 9;
our $UR_COMMITTEE_FACILITATOR = 10;
our $UR_DATA_REVIEWER = 11;
our $UR_ACCESSIBILITY_SPECIALIST = 12;

our %review_type = ( $UR_NONE => 'None',
                     $UR_ITEM_EDIT => 'Item Writer',
		     $UR_CONTENT_SPECIALIST => 'Content Specialist',
		     $UR_COPY_EDITOR => 'Copy Editor',
		     $UR_GRAPHIC_DESIGNER => 'Graphic Designer',
		     $UR_MEDIA_DESIGNER => 'Media Designer',
		     $UR_ACCESSIBILITY_SPECIALIST => 'Accessibility Specialist',
		     $UR_COMMITTEE_REVIEWER => 'Committee Reviewer',
		     $UR_DATA_REVIEWER => 'Data Reviewer',
		     $UR_QC_PRESENTATION => 'QC Presentation',
		     $UR_DATA_MANAGER => 'Data Manager',
		     $UR_PSYCHOMETRICIAN => 'Psychometrician',
		     $UR_COMMITTEE_FACILITATOR => 'Committee Facilitator' );

our %review_type_map = ( $UR_NONE => '',
                     $UR_ITEM_EDIT => 'editor',
		     $UR_CONTENT_SPECIALIST => 'content_specialist',
		     $UR_COPY_EDITOR => 'copy_editor',
		     $UR_GRAPHIC_DESIGNER => 'graphic_designer',
		     $UR_MEDIA_DESIGNER => 'media_designer',
		     $UR_ACCESSIBILITY_SPECIALIST => 'accessibility_specialist',
		     $UR_COMMITTEE_REVIEWER => 'committee_reviewer',
		     $UR_DATA_REVIEWER => 'data_reviewer',
		     $UR_QC_PRESENTATION => 'qc_presentation',
		     $UR_DATA_MANAGER => 'data_manager',
		     $UR_PSYCHOMETRICIAN => 'psychometrician',
		     $UR_COMMITTEE_FACILITATOR => 'committee_facilitator' );

our @review_with_edit = qw/editor content_specialist copy_editor graphic_designer media_designer qc_presentation/;
our @review_per_user = qw/editor graphic_designer media_designer/;

# Do away with bit vectors for role permissions, as we would like to phase these out one day

our $RP_EDIT_ITEM 	 = 1;
our $RP_REVIEW_ITEM 	 = 2;
our $RP_COMMENT_ITEM 	 = 5;
our $RP_DATA_REVIEW_ITEM = 7;
our $RP_EDIT_TEST 	 = 3;
our $RP_REVIEW_TEST 	 = 4;
our $RP_COMMENT_TEST 	 = 6;

our %role_item_permission_types = ( 1 => 'Edit Item',
                                    2 => 'Review Item',
				    5 => 'Comment Item',
                                    7 => 'Data Review Item'
                                  );

our %role_test_permission_types = ( 3 => 'Edit Test',
                                    4 => 'Review Test',
				    6 => 'Comment Test'
                                  );

our %default_role_permissions = ( 
                                  $P_ITEM_EDIT => { 
				                    $RP_EDIT_ITEM => 1,
						    $RP_REVIEW_ITEM => 1
                                                  },
                                  $P_CONTENT_SPECIALIST => {
				                    $RP_EDIT_ITEM => 1,
						    $RP_REVIEW_ITEM => 1
                                                  },
				  $P_COPY_EDITOR => {
				                    $RP_EDIT_ITEM => 1,
						    $RP_REVIEW_ITEM => 1
                                                  },
				  $P_GRAPHIC_DESIGNER => {
				                    $RP_EDIT_ITEM => 1,
						    $RP_REVIEW_ITEM => 1
                                                  },
				  $P_MEDIA_DESIGNER => {
				                    $RP_EDIT_ITEM => 1,
						    $RP_REVIEW_ITEM => 1
                                                  },
				  $P_COMMITTEE_REVIEWER => {
						    $RP_REVIEW_ITEM => 1,
						    $RP_COMMENT_ITEM => 1
                                                  },
				  $P_COMMITTEE_FACILITATOR => {
						    $RP_REVIEW_ITEM => 1,
						    $RP_COMMENT_ITEM => 1
                                                  },
				  $P_QC_PRESENTATION => {
				                    $RP_EDIT_ITEM => 1,
						    $RP_REVIEW_ITEM => 1
                                                  },
				  $P_DATA_MANAGER => {
						    $RP_DATA_REVIEW_ITEM => 1,
                                                  },
				  $P_PSYCHOMETRICIAN => {
						    $RP_DATA_REVIEW_ITEM => 1
                                                  },
                             );

our $UT_ITEM_EDITOR = 11;

our @labels = ();
our @const  = ();
our @ctypes = ( $OC_CONTENT_AREA, $OC_GRADE_LEVEL, $OC_GRADE_SPAN_START, 
		$OC_GRADE_SPAN_END, $OC_DOK, $OC_POINTS );
our @tools  = ( $OC_PROTRACTOR, $OC_RULER, $OC_CALCULATOR, $OC_COMPASS );
our %stringCharacteristics =
  map { $_ => 1 }
  ( $OC_COMP_CURRICULUM );


$labels[$OC_CONTENT_AREA]     = 'Content Area:';
$labels[$OC_GRADE_SPAN_START] = 'Grade Span Start:';
$labels[$OC_GRADE_SPAN_END]   = 'Grade Span End:';
$labels[$OC_GRADE_LEVEL]      = 'Grade Level:';
$labels[$OC_POINTS]           = 'Item Points:';
$labels[$OC_DOK]              = 'Depth of Knowledge:';
$labels[$OC_PROTRACTOR]       = 'Protractor:';
$labels[$OC_RULER]            = 'Ruler:';
$labels[$OC_CALCULATOR]       = 'Calculator:';
$labels[$OC_COMPASS]          = 'Compass:';
$labels[$OC_SCORING_METHOD]   = 'Scoring:';
$labels[$OC_COMP_CURRICULUM]  = 'Comprehensive Curriculum:';
$labels[$OC_FORM_GROUP]       = 'Form Group:';
$labels[$OC_CHOICE_SHUFFLE]   = 'Choice Shuffle? :';

$const[$OC_CONTENT_AREA] = {
    '1' => 'MATH',
    '2' => 'ELA'
};

$const[$OC_GRADE_LEVEL] = {
    '0'  => 'K',
    '1'  => '1',
    '2'  => '2',
    '3'  => '3',
    '4'  => '4',
    '5'  => '5',
    '6'  => '6',
    '7'  => '7',
    '8'  => '8',
    '9'  => '9',
    '10' => '10',
    '11' => '11',
    '12' => '12'
};

$const[56] = {
    '0'  => 'K',
    '1'  => '1',
    '2'  => '2',
    '3'  => '3',
    '4'  => '4',
    '5'  => '5',
    '6'  => '6',
    '7'  => '7',
    '8'  => '8',
    '9'  => '9',
    '10' => '10',
    '11' => '11',
    '12' => '12',
};

$const[$OC_GRADE_SPAN_START] = {
    '-1'   => '-',
    '0'  => 'K',
    '1'  => '1',
    '2'  => '2',
    '3'  => '3',
    '4'  => '4',
    '5'  => '5',
    '6'  => '6',
    '7'  => '7',
    '8'  => '8',
    '9'  => '9',
    '10' => '10',
    '11' => '11',
    '12' => '12',
};

$const[$OC_GRADE_SPAN_END] = {
    '-1'   => '-',
    '0'  => 'K',
    '1'  => '1',
    '2'  => '2',
    '3'  => '3',
    '4'  => '4',
    '5'  => '5',
    '6'  => '6',
    '7'  => '7',
    '8'  => '8',
    '9'  => '9',
    '10' => '10',
    '11' => '11',
    '12' => '12',
};

$const[$OC_POINTS] = {
    '0'  => '0',
    '1'  => '1',
    '2'  => '2',
    '3'  => '3',
    '4'  => '4',
    '5'  => '5',
    '6'  => '6',
    '7'  => '7',
    '8'  => '8',
    '9'  => '9',
    '10' => '10',
    '11' => '11',
    '12' => '12',
    '13' => '13',
    '14' => '14',
    '15' => '15',
    '16' => '16'
};

$const[$OC_DOK] = {
    '1' => '1',
    '2' => '2',
    '3' => '3',
    '4' => '4'
};

$const[$OC_PROTRACTOR] = {
    '0' => 'NO',
    '1' => 'YES',
    '2' => 'MAYBE'
};

$const[$OC_RULER] = {
    '0' => 'NO',
    '1' => 'YES',
    '2' => 'MAYBE'
};

$const[$OC_CALCULATOR] = {
    '0' => 'NO',
    '1' => 'YES',
    '2' => 'MAYBE'
};

$const[$OC_COMPASS] = { '1' => 'YES' };

$const[$OC_SCORING_METHOD] = {
    '1' => 'Match Response',
    '2' => 'Rubric'
};

$const[$OC_ITEM_FORMAT] = {
    '1' => 'Selected Response',
    '2' => 'Constructed Response',
    '3' => 'Activity Based',
    '4' => 'Performance Task',
    '5' => 'Unsupported'
};

$const[$OC_CHOICE_SHUFFLE] = {
    '0' => 'No',
    '1' => 'Yes',
};

$const[$OC_FORM_GROUP] = { '1' => 'Applied Algebra' };

our %mc_answer_choices = (
  '0' => '0',
  '1' => '1',
  '2' => '2',
  '3' => '3',
  '4' => '4',
  '5' => '5',
  '6' => '6',
  '7' => '7',
  '8' => '8',
  '9' => '9',
  '10' => '10'
);

our %charts = (
    '2dline'      => 'Line.swf',
    '2dcolumn'    => 'Column2D.swf',
    '2dpie'       => 'Pie2D.swf',
    'scatterplot' => 'Scatter.swf'
);

our %item_types = (
    '1'  => 'SR, exclusive',
    '2'  => 'SR, non-exclusive',
    '3'  => 'CR, single-line',
    '4'  => 'CR, multi-line',
    '5'  => 'Bubble/Grid',
    '6'  => 'Interactive',
    '23' => 'CR, multi-entry, single-line',
    '24' => 'CR, multi-entry, multi-line',
);

our %item_formats = (
   '1' => 'Selected Response',
   '2' => 'Constructed Response',
   '3' => 'Activity Based',
   '4' => 'Performance Task',
   '5' => 'Unsupported'
);

our %item_interactions = (
    '1' => 'Choice',
    '2' => 'Text Entry',
    '3' => 'Extended Text', 
    '4' => 'Inline Choice',
    '5' => 'Match'
    );

our @dev_states_workflow_ordered_keys = (1,40,19,20,64,63,71,72,69,42,13,17,65,44,61,60,66,68,4,5,9,11);

our %dev_states = (
    '1' => 'Development',
    '2' => 'Review',
    '3' => 'Testing',
    '4' => 'Approved',
    '5' => 'Released',
    '6' => 'Suspended',
    '9' => 'Rejected',
    '11' => 'Retired',
    '12' => 'Content Review',
    '13' => 'Content Review 2',
    '14' => 'On Hold',
    '15' => 'Scheduled',
    '16' => 'Query Resolution',
    '17' => 'Copy Review',
    '18' => 'Copy/Proof Approval',
    '19' => 'Create Art',
    '20' => 'Edit Art',
    '21' => 'Client Approval',
    '22' => 'Client Approval 2',
    '23' => 'Client Approval 3',
    '24' => 'Copy Teacher Review',
    '25' => 'Copy F2F Review',
    '26' => 'Copy Final Review',
    '27' => '2nd Copy Review',
    '28' => 'Supervisor Review',
    '29' => 'Client Preview',
    '30' => 'Customer Proof',

    40 =>  'Content Review 1',
    41 =>  'Item Update 1',
    42 =>  'Committee Review',
    13 =>  'Content Review 2',
    43 =>  'Item Update 2',
    44 =>  'Content Review 3',
    45 =>  'Sensitivity Review',
    46 =>  'External Editor Review',
    47 => 'Content Review 4',
    48 => 'Item Update 3',
    49 => 'Content Review 5',
    50 => 'Art Request Review',
    51 => 'Pending Art',
    52 => 'Ready for Art',
    53 => 'Proofreading',
    54 => 'Content Review 6',
    55 => 'Item Update 4',
    56 => 'Content Review 7',
    57 => 'QA Review',
    58 => 'Program Director Review',

    60 => 'Banked',
    61 => 'Consortium Review',
    62 => 'DNU Item Pool',
    63 => 'Edit Media',
    64 => 'Create Media',
    65 => 'Query Resolution',
    66 => 'Data Review',
    67 => 'Operational Item Pool',
    68 => 'Post Admin Review',
    69 => 'QC Presentation Review',
    70 => 'Post Committee',
    71 => 'Create Accessibility',
    72 => 'Edit Accessibility'
);

our %publication_status = (
     1 => 'Field Test',
     2 => 'Embedded Field Test',
     3 => 'Operational',
     4 => 'Field Tested',
     5 => 'Pilot',
     6 => 'Equating',
     7 => 'Released',
     8 => 'Ready for Operational',
     9 => 'Ready for Field Test',
    10 => 'Ready for Pilot Test',
    11 => 'Pilot Tested',
    12 => 'Ready for Field Review',
    13 => 'Field Reviewed',
    14 => 'Operational Equating',
    15 => 'Rejected',
);

our %export_ok = (
    '0' => 'no',
    '1' => 'yes'
);

our %read_only = (
    '0' => 'no',
    '1' => 'yes'
);

our %difficulty_levels = (
    '1' => 'easy',
    '2' => 'medium',
    '3' => 'hard'
);

our %layout_types = (
    '1' => 'single column',
    '2' => '2 columns',
    '3' => 'single row'
);

our %genres = (
    '0' => '',
    '1' => 'Poem',
    '2' => 'Fiction',
    '3' => 'Proofreading',
    '4' => 'Non-Fiction',
    '5' => 'Biography/Interview',
    '6' => 'Information Resource',
    '7' => 'Drama'
);

our %languages = (
    '1' => 'English',
    '2' => 'Spanish'
);

our %error_types = (
    'c' => 'Concept',
    'g' => 'Guess',
    'p' => 'Process'
);

our %default = ( $OC_POINTS => '1' );

our %asy_colors = (
    'black'     => 'Black',
    'gray'      => 'Gray',
    'white'     => 'White',
    'red'       => 'Red',
    'green'     => 'Green',
    'blue'      => 'Blue',
    'yellow'    => 'Yellow',
    'magenta'   => 'Magenta',
    'cyan'      => 'Cyan',
    'brown'     => 'Brown',
    'darkgreen' => 'Dark Green',
    'darkblue'  => 'Dark Blue',
    'orange'    => 'Orange',
    'purple'    => 'Purple',
    'lightblue' => 'Light Blue',
    'pink'      => 'Pink',
    'lavender'  => 'Lavender'
);

our %workStates = (
    '1'  => $DS_DEVELOPMENT,
    '2'  => $DS_CONTENT_REVIEW,
    '3'  => $DS_CONTENT_REVIEW_2,
    '4'  => $DS_COPY_REVIEW,
    '5'  => $DS_CONTENT_APPROVED,
    '6'  => $DS_COPY_APPROVED,
    '7'  => $DS_SUPERVISOR_REVIEW,
    '8'  => $DS_CLIENT_PREVIEW,
    '9'  => $DS_CLIENT_APPROVED,
    '10' => $DS_READY_FOR_AUDIO,

    40 => $DS_CONTENT_REVIEW_1,
    41 => $DS_ITEM_UPDATE_1,
    42 => $DS_COMMITTEE_REVIEW,
    43 => $DS_ITEM_UPDATE_2,
    44 => $DS_CONTENT_REVIEW_3,
    45 => $DS_SENSITIVITY_REVIEW,
    46 => $DS_EXTERNAL_EDITOR_REVIEW,
    47 => $DS_CONTENT_REVIEW_4,
    48 => $DS_ITEM_UPDATE_3,
    49 => $DS_CONTENT_REVIEW_5,
    50 => $DS_ART_REQUEST_REVIEW,
    51 => $DS_PENDING_ART,
    52 => $DS_READY_FOR_ART,
    53 => $DS_PROOFREADING,
    54 => $DS_CONTENT_REVIEW_6,
    55 => $DS_ITEM_UPDATE_4,
    56 => $DS_CONTENT_REVIEW_7,
    57 => $DS_QA_REVIEW,
    58 => $DS_PROGRAM_DIRECTOR_REVIEW,

    60 => $DS_BANKED,
    61 => $DS_CONSORTIUM_REVIEW,
    62 => $DS_DNU_ITEM_POOL,
    63 => $DS_FIX_MEDIA,
    64 => $DS_NEW_MEDIA,
    65 => $DS_QUERY_RESOLUTION,
    66 => $DS_DATA_REVIEW,
    67 => $DS_OPERATIONAL_ITEM_POOL,
    68 => $DS_POST_ADMIN_REVIEW,
    69 => $DS_QC_PRESENTATION_REVIEW,
    70 => $DS_POST_COMMITTEE,
    71 => $DS_NEW_ACCESSIBILITY,
    72 => $DS_FIX_ACCESSIBILITY
);

our %characterization_view_types = (
  $OC_CONTENT_AREA => 'content_area',
  $OC_GRADE_LEVEL => 'grade_level'
);

our %itemNotesTags = (
    '1' => {
        'accepted all'      => 'Accepted all edits.',
        'query resolved'    => 'Query resolved/additional edits.',
        'rewritten'         => 'Rewritten.',
        'no comments/edits' => 'No comments or edits from Copy.',
        'verified'          => 'CR verified.',
        'art corrections'   => 'Art corrections made.',
        'fixed eoc view'    => 'Fixed EOC view.'
    }
);

our %itemStandardChar = (
    '0' => {
        'gle'       => $OC_ITEM_STANDARD,
        'standard'  => $OC_CONTENT_STANDARD,
        'benchmark' => $OC_BENCHMARK,
        'category'  => $OC_CATEGORY
    },
    '1' => {
        'gle'       => $OC_SECONDARY_STANDARD,
        'standard'  => $OC_SECONDARY_CONTENT_STANDARD,
        'benchmark' => $OC_SECONDARY_BENCHMARK,
        'category'  => $OC_SECONDARY_CATEGORY
    },
    '2' => {
        'gle'       => $OC_TERTIARY_STANDARD,
        'standard'  => $OC_TERTIARY_CONTENT_STANDARD,
        'benchmark' => $OC_TERTIARY_BENCHMARK,
        'category'  => $OC_TERTIARY_CATEGORY
    }
);

#
# The 1st key references the hd_id of the standards hierarchy root
# The 2nd key references the content area (Math, ELA)
#
our %contentStandards = (
    '1' => {
        '1' => {
            '1' => 'Number and Number Relations',
            '2' => 'Algebra',
            '3' => 'Measurement',
            '4' => 'Geometry',
            '5' => 'Data Analysis, Probability, and Discrete Math',
            '6' => 'Patterns, Relations, and Functions'
        },
        '2' => {
            '1' => 'Standard 1',
            '2' => 'Standard 2',
            '3' => 'Standard 3',
            '4' => 'Standard 4',
            '5' => 'Standard 5',
            '6' => 'Standard 6',
            '7' => 'Standard 7'
        }
    },

    '2184' => {
        '1' => {
            '1' => 'Number Sense',
            '2' => 'Algebra and Functions',
            '3' => 'Measurement and Geometry',
            '4' => 'Statistics, Data Analysis, and Probability',
            '5' => 'Mathematical Reasoning'
        },
        '2' => {
            '1' => 'Word Analysis',
            '2' => 'Reading Comprehension',
            '3' => 'Literary Response and Analysis',
            '4' => 'Writing Strategies',
            '5' => 'Writing Applications',
            '6' => 'Writing Conventions'
        }
    }
);

our %action_key_states = (
    development             => $DS_DEVELOPMENT,
    content_review      => $DS_CONTENT_REVIEW,
    content_review_2    => $DS_CONTENT_REVIEW_2,
    copy_review         => $DS_COPY_REVIEW,
    copy_review_2       => $DS_COPY_REVIEW_2,
    copy_approve        => $DS_COPY_APPROVED,
    content_approve     => $DS_CONTENT_APPROVED,
    supervisor_review   => $DS_SUPERVISOR_REVIEW,
    client_preview      => $DS_CLIENT_PREVIEW,
    client_approve      => $DS_CLIENT_APPROVED,
    client_approve_2    => $DS_CLIENT_APPROVED_2,
    client_approve_3    => $DS_CLIENT_APPROVED_3,
    copy_teacher_review => $DS_COPY_TEACHER_REVIEW,
    copy_f2f_review     => $DS_COPY_F2F_REVIEW,
    copy_final_review   => $DS_COPY_FINAL_REVIEW,
    customer_proof      => $DS_CUSTOMER_PROOF,
    new_art             => $DS_NEW_ART,
    fix_art             => $DS_FIX_ART,

    reject                  => $DS_REJECTED,
    approve                 => $DS_APPROVED,
    content_review_1        => $DS_CONTENT_REVIEW_1,
    item_update_1           => $DS_ITEM_UPDATE_1,
    committee_review        => $DS_COMMITTEE_REVIEW,
    item_update_2           => $DS_ITEM_UPDATE_2,
    content_review_3        => $DS_CONTENT_REVIEW_3,
    sensitivity_review      => $DS_SENSITIVITY_REVIEW,
    external_editor_review  => $DS_EXTERNAL_EDITOR_REVIEW,
    content_review_4        => $DS_CONTENT_REVIEW_4,
    item_update_3           => $DS_ITEM_UPDATE_3,
    content_review_5        => $DS_CONTENT_REVIEW_5,
    art_request_review      => $DS_ART_REQUEST_REVIEW,
    pending_art             => $DS_PENDING_ART,
    ready_for_art           => $DS_READY_FOR_ART,
    proofreading            => $DS_PROOFREADING,
    content_review_6        => $DS_CONTENT_REVIEW_6,
    item_update_4           => $DS_ITEM_UPDATE_4,
    content_review_7        => $DS_CONTENT_REVIEW_7,
    qa_review               => $DS_QA_REVIEW,
    program_director_review => $DS_PROGRAM_DIRECTOR_REVIEW,

    banked	    	    => $DS_BANKED,
    consortium_review	    => $DS_CONSORTIUM_REVIEW,
    dnu_item_pool	    => $DS_DNU_ITEM_POOL,
    new_media	    	    => $DS_NEW_MEDIA,
    fix_media	    	    => $DS_FIX_MEDIA,
    new_accessibility       => $DS_NEW_ACCESSIBILITY,
    fix_accessibility       => $DS_FIX_ACCESSIBILITY,
    query_resolution	    => $DS_QUERY_RESOLUTION,
    data_review	    	    => $DS_DATA_REVIEW,
    operational_item_pool   => $DS_OPERATIONAL_ITEM_POOL,
    post_admin_review	    => $DS_POST_ADMIN_REVIEW,
    qc_presentation         => $DS_QC_PRESENTATION_REVIEW,
    committee_facilitator   => $DS_POST_COMMITTEE,

    last_state              => 'last_state',
);

our %item_rating = (

  1 => 'Poor',
  2 => 'Fair',
  3 => 'Good',
  4 => 'Very Good',
  5 => 'Excellent'
);

our %review_flags = (
  notes => { 'color' => 'blue',
             'tag' => 'N' },
  new_media => { 'color' => 'green',
             'tag' => 'M' },
  edit_media => { 'color' => 'red',
             'tag' => 'M' },
  new_art => { 'color' => 'green',
             'tag' => 'A' },
  edit_art => { 'color' => 'red',
             'tag' => 'A' },
  reject_writer => { 'color' => 'red',
             'tag' => 'X' },
  resubmit_writer => { 'color' => 'green',
             'tag' => 'X' },
  minor_edit => { 'color' => 'blue',
             'tag' => 'E' },
);

our @tags_with_no_id_list = qw/br hr em b i strong font u
                               maligngroup malignmark menclose merror mfenced mfrac mglyph mi mlabeledtr
                               mlongdiv mmultiscripts mn mo mover mpadded mphantom mroot mrow ms mscarries 
			       mscarry msgroup msline mspace msqrt msrow mstack mstyle msub msup msubsup mtable
			       mtd mtext mrt munder munderover
                             /;
our %tags_with_no_id = map { $_ => 1 } @tags_with_no_id_list;

sub replaceChars {

  my $source    = shift;

  my @char_array = split //, $source;

  for(my $i=0; $i < scalar(@char_array); $i++) {

    my $ascii_num = ord($char_array[$i]);

    if($ascii_num >= 160) {
      $char_array[$i] = '&#' . $ascii_num . ';';
    }
  }

  return join ('', @char_array);

}

sub getNewItemPrefix {
    my $dbh         = shift;
    my $contentArea = shift;
    my $grade       = shift;
    my $hdId        = shift;
    my $year        = shift;
    my $format      = shift;
    my $passage     = shift || '';

    my $std = &getStandard( $dbh, $hdId );
    my $strand = substr( $std->{$HD_STANDARD_STRAND}->{value}, 0, 1 );
    my $gle = $std->{$HD_LEAF}->{value};
    $gle =~ m/(\d+)/;
    $gle         = $1;
    $grade       = $const[$OC_GRADE_LEVEL]->{$grade};
    $format      = $const[$OC_ITEM_FORMAT]->{$format};
    $contentArea = $const[$OC_CONTENT_AREA]->{$contentArea};

    if (   $contentArea eq 'MATH' )
    {
        return "${grade}${strand}${gle}_${year}_${format}";
    }
    elsif ( $contentArea eq 'ELA' ) {
        my $psg = new Passage( $dbh, $passage );
        return "${grade}${strand}${gle}_${year}_${format}_$psg->{code}";
    }

    return '';

}

sub getNextItemSequence {
    my $dbh    = shift;
    my $bank   = shift;
    my $prefix = shift;

    my $sql =
"SELECT i_external_id FROM item WHERE ib_id=${bank} AND i_external_id LIKE '${prefix}%' ORDER BY LENGTH(i_external_id) DESC, i_external_id DESC LIMIT 1";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        my $lastId = $row->{i_external_id};
        $sth->finish;
        $lastId =~ m/(\d+)$/;
	my $seq = $1;
	$seq =~ s/^0+//;
        return int($seq) + 1;
    }
    else {
        $sth->finish;
        return 1;
    }
}

sub sendNewItemNotification {

  use MIME::Lite;

  my $dbh = shift;
  my $bankName = shift;
  my $writerId = shift;

  return 0 unless $writerId;

  # by default, assume it doesn't work
  my $status = 0;

  my $sql = 'SELECT * FROM user WHERE u_id=' . $writerId;
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  if(my $row = $sth->fetchrow_hashref) {

     my $body = <<END_HERE;
Hello $row->{u_first_name} $row->{u_last_name},

SBAC IAIP ITEM(s) have been placed in your queue and needs your attention:
Program   : ${bankName}

If you have any questions, please contact customer support.
SBAC7PacMetTeam\@pacificmetrics.com

Regards,
SBAC IAIP Notifier
END_HERE

     eval {

       my $message = MIME::Lite->new(
         To      => $row->{u_email},
         From    => '"SBAC IAIP" <SBAC7PacMetTeam@pacificmetrics.com>',
         Subject => 'SBAC IAIP ITEM Needs Your Attention!',
         Data    => $body,
       );
       $message->send( 'smtp', 'localhost' );
    };

    if($@) { 
      # problem sending the e-mail
    } else {
      $status = 1;
    }

  } else {
    # user not found
  }
  $sth->finish;

  return $status;
}

sub getFileContent {

    my $filePath   = shift;
    my $fileString = '';

    open FILE, '<', $filePath;
    while (<FILE>) { $fileString .= $_; }
    close FILE;

    return $fileString;
}

sub getContentStandard {

    my $dbh         = shift;
    my $hdId        = shift;
    my $contentArea = shift;

    my $strand = 0;

    my $parentPath = '';
    my $sql =
"SELECT hd_parent_path, hd_value FROM hierarchy_definition WHERE hd_id=${hdId}";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $parentPath = $row->{hd_parent_path};
    }
    else {
        $parentPath = 0;
    }

    my @parentList = split /,/, $parentPath;
    @parentList = reverse @parentList;

    my $standardsHierarchy = $parentList[0] ? $parentList[0] : $parentList[1];

    if ( $standardsHierarchy == 1 && $contentArea == 2 ) {
        $sql =
"SELECT hd_value FROM hierarchy_definition WHERE hd_type=${HD_SUBSTRAND} AND hd_id IN (${parentPath})";
        $sth = $dbh->prepare($sql);
        $sth->execute();
        if ( my $row = $sth->fetchrow_hashref ) {
            if ( $row->{hd_value} =~ /(\d+)/ ) {
                $strand = $1;
            }
        }
    }
    else {
        $sql =
"SELECT hd_posn_in_parent FROM hierarchy_definition WHERE hd_type=${HD_STANDARD_STRAND} AND hd_id IN (${parentPath})";
        $sth = $dbh->prepare($sql);
        $sth->execute();
        if ( my $row = $sth->fetchrow_hashref ) {
            $strand = $row->{hd_posn_in_parent};
        }
    }

    return $strand;
}

sub getGLENumber {
    my $dbh   = shift;
    my $gleId = shift;

    my $gleNumber = 0;

    my $sql = "SELECT hd_value FROM hierarchy_definition WHERE hd_id=${gleId}";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $row->{hd_value} =~ /(\d+)/;
        $gleNumber = $1;
    }

    return $gleNumber;
}

sub getStandardsUnderRoot {
    my $dbh    = shift;
    my $rootId = shift;
    my %hd     = ();

    # Build data structure from hierarchy_definition
    my $sql =
        'SELECT * FROM hierarchy_definition WHERE hd_parent_path LIKE \'%,'
      . $rootId
      . ',%\' OR hd_parent_id = '
      . $rootId
      . ' ORDER BY hd_posn_in_parent';
    my $sth = $dbh->prepare($sql);
    $sth->execute()
      || print( STDERR "Failed Query:" . $dbh->err . "," . $dbh->errstr );

    while ( my $row = $sth->fetchrow_hashref ) {

        my @hdParentPath = split /,/, $row->{hd_parent_path};
        foreach (@hdParentPath) { $hd{$_} = {} unless exists $hd{$_}; }

        $hd{ $row->{hd_id} } = {} unless exists $hd{ $row->{hd_id} };
        $hd{ $row->{hd_id} }->{type}   = $row->{hd_type};
        $hd{ $row->{hd_id} }->{value}  = $row->{hd_value};
        $hd{ $row->{hd_id} }->{posn}   = $row->{hd_posn_in_parent};
        $hd{ $row->{hd_id} }->{parent} = $row->{hd_parent_id};
        $hd{ $row->{hd_id} }->{path}   = $row->{hd_parent_path};

        $hd{ $row->{hd_parent_id} }->{child} = []
          unless exists $hd{ $row->{hd_parent_id} }->{child};
        push @{ $hd{ $row->{hd_parent_id} }->{child} }, $row->{hd_id};

        if ( $row->{hd_std_desc} or $row->{hd_type} == $HD_LEAF ) {
            $hd{ $row->{hd_id} }->{text} = $row->{hd_std_desc} || '';
        }
    }
    $sth->finish;
    return \%hd;
}

sub getSession {
    my $dbh    = shift;
    my $sessId = shift;
    my $user   = { writer_code => 'WCNONE',
		   type => 0,
        	   id   => 0,
		   roles => 0,
		   adminType => 0,
		   reviewType => 0,
		   organizationId => 0,
		   itemBanks => {},
		   rolePermissions => {},
		 };

    my $sql =
        'SELECT user.*, session.ss_id FROM user, session'
      . ' WHERE user.u_id=session.u_id AND session.ss_id='
      . $dbh->quote($sessId)
      . ' ORDER BY ss_expiration DESC LIMIT 1';
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $user->{type} = $row->{u_type};
        $user->{id}   = $row->{u_id};
        $user->{roles} = $row->{u_permissions};
	$user->{organizationId} = $row->{o_id};
	$user->{adminType} = $row->{u_admin_type};
	$user->{reviewType} = $row->{u_review_type};
	$user->{writer_code} = $row->{u_writer_code};
	$user->{rolePermissions} = {};

        $sql =
            'SELECT up_value FROM user_permission WHERE u_id='
          . $row->{u_id}
          . ' AND up_type=' . $UP_VIEW_ITEM_BANK;
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute();
        while ( my $row2 = $sth2->fetchrow_hashref ) {
            $user->{itemBanks}{ $row2->{up_value} } = 1;
        }
        $sth2->finish;

        foreach my $role (@role_types) {

	  next unless exists $default_role_permissions{$role};

	  if($role & $user->{roles}) {

            foreach my $perm (keys %{$default_role_permissions{$role}}) {

              $user->{rolePermissions}{$perm} = 1;
            }

	  }
        }

    }

    return $user;
}

sub setItemReviewState {
    my $dbh               = shift;
    my $itemId            = shift;
    my $lastDevState      = shift;
    my $newDevState       = shift;
    my $userId            = shift;
    my $acceptedTimestamp = shift || 'NOW()';
    if ( $acceptedTimestamp ne 'NOW()' ) {
        $acceptedTimestamp = "'${acceptedTimestamp}'";
    }

    my $sql = 'SELECT i_xml_data, i_notes, i_qti_xml_data, i_tei_data, ib_id FROM item WHERE i_id=' . $itemId;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    
    my $row = $sth->fetchrow_hashref;

    $sql = sprintf('INSERT INTO item_status SET i_id=%d, is_last_dev_state=%d, is_new_dev_state=%d,'
                 . ' is_timestamp=NOW(), is_accepted_timestamp=%s, is_u_id=%d, i_xml_data=%s, i_notes=%s,'
		 . 'i_qti_xml_data=%s, i_tei_data=%s, ib_id=%s',
                      $itemId,
		      $lastDevState,
		      $newDevState,
		      $acceptedTimestamp,
		      $userId,
		      $dbh->quote($row->{i_xml_data}),
		      $dbh->quote($row->{i_notes}),
		      $dbh->quote($row->{i_qti_xml_data}),
                      $dbh->quote($row->{i_tei_data}),
                      $row->{ib_id}
		  );
    $sth = $dbh->prepare($sql);
    $sth->execute();

    # copy all the item_fragment records to item_status_fragment
    my $is_id = $dbh->{mysql_insertid};
    $sql = sprintf('SELECT * FROM item_fragment WHERE i_id=' . $itemId);
    $sth = $dbh->prepare($sql);
    $sth->execute();
   
    $sql = <<SQL;
    INSERT INTO item_status_fragment SET is_id=?, i_id=?, if_id=?, isf_text=?
SQL
    my $sth2 = $dbh->prepare($sql);

    while(my $row = $sth->fetchrow_hashref) {
      $sth2->execute($is_id, $itemId, $row->{if_id}, $row->{if_text});
    }
    $sth->finish;
    $sth2->finish;

    my @itemToPDFargs = ( "${orcaPath}cgi-bin/itemToPDF.pl", $instance_name, $itemId );
    system(@itemToPDFargs);

    $sql =
"UPDATE item SET i_review_lock=0, i_dev_state=${newDevState}, i_notes='', i_last_save_user_id=0 WHERE i_id=${itemId}";
    $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;

}

sub attributeStringToHash {
  my $attString = shift;
  my %out = ();

  while($attString =~ /(\w+)\s?=\s?"([^"]+)"/g) {
    $out{$1} = $2;
  }

  return \%out;
}

sub hashToAttributeString {

  my $data = shift;

  return join(' ', map { $_ . '="' . $data->{$_} . '"' } keys %$data);
}

sub getItemXml {
    my $dbh      = shift;
    my $itemId   = shift;
    my $itemName = shift || '';

    my $xml = '';

    my $sql =
      "SELECT * FROM item WHERE "
      . ( $itemName eq ''
        ? "i_id=${itemId}"
        : "ib_id=${itemId} AND i_external_id='${itemName}' ORDER BY i_version DESC LIMIT 1"
      );
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    if ( my $row = $sth->fetchrow_hashref ) {
        $xml = $row->{i_xml_data};
        $xml =~ s/(<item [^>]+>)/$1 <name>$row->{i_external_id}<\/name> /;
    }
    $sth->finish;

    return $xml;
}

sub setPassageReviewState {
    use Passage;

    my $dbh               = shift;
    my $passageId         = shift;
    my $lastDevState      = shift;
    my $newDevState       = shift;
    my $userId            = shift;
    my $acceptedTimestamp = shift || 'NOW()';
    if ( $acceptedTimestamp ne 'NOW()' ) {
        $acceptedTimestamp = "'${acceptedTimestamp}'";
    }

    my $psg = new Passage( $dbh, $passageId );

    my $sql =
"INSERT INTO passage_status SET p_id=${passageId}, ps_last_dev_state=${lastDevState}, ps_new_dev_state=${newDevState}, ps_timestamp=NOW(), ps_accepted_timestamp=${acceptedTimestamp}, ps_u_id=${userId}, ib_id=$psg->{bank}, p_notes=(SELECT p_notes FROM passage WHERE p_id=${passageId}), p_content="
      . $dbh->quote( $psg->{body} )
      . ", ps_footnotes="
      . $dbh->quote( $psg->getFootnotesAsString() );
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    system( "${orcaPath}cgi-bin/passageToPDF.pl", $passageId );

    $sql =
"UPDATE passage SET p_review_lock=0, p_dev_state=${newDevState}, p_notes='' WHERE p_id=${passageId}";
    $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub getItemAssets {
    use ItemAsset;

    my $bankId      = shift;
    my $itemName    = shift;
    my $itemVersion = shift;
    my @assets      = ();
    my %asset_ext   = map { $_ => 1 } @asset_extensions;

    my $pathString =
      $itemVersion == 0
      ? "${imagesDir}lib${bankId}/${itemName}/*"
      : "${imagesDir}lib${bankId}/${itemName}/V${itemVersion}*";

    foreach ( bsd_glob($pathString) ) {
        $_ =~ /\.(\w+)$/;
        next unless exists $asset_ext{$1};

        my $assetName;

        if ($itemVersion) {
            $_ =~ /$itemName\/V\d+\.(.*?)$/;
            $assetName = $1;
        }
        else {
            next if $_ =~ /$itemName\/V\d+\./;
            $_ =~ /$itemName\/(.*)$/;
            $assetName = $1;
        }

        push @assets,
          new ItemAsset( $bankId, $itemName, $itemVersion, $assetName );
    }

    return @assets;
}

sub getPassageAssets {
    use PassageAsset;

    my $bankId    = shift;
    my $passageId = shift;
    my @assets    = ();
    my %asset_ext = map { $_ => 1 } @asset_extensions;

    warn "Searching ${passagePath}lib${bankId}/images/p${passageId}/*";

    foreach ( bsd_glob("${passagePath}lib${bankId}/images/p${passageId}/*") ) {
        $_ =~ /\.(\w+)$/;

        next unless exists $asset_ext{$1};

        $_ =~ /p$passageId\/(.*)$/;
        my $assetName = $1;
        push @assets, new PassageAsset( $bankId, $passageId, $assetName );
    }

    return @assets;
}

sub getRubricAssets {
    use RubricAsset;

    my $bankId    = shift;
    my $rubricId = shift;
    my @assets    = ();
    my %asset_ext = map { $_ => 1 } @asset_extensions;

    foreach ( bsd_glob("${rubricPath}lib${bankId}/images/r${rubricId}/*") ) {
        $_ =~ /\.(\w+)$/;
        next unless exists $asset_ext{$1};

        $_ =~ /r$rubricId\/(.*)$/;
        my $assetName = $1;

        push @assets, new RubricAsset( $bankId, $rubricId, $assetName );
    }

    return @assets;
}

sub setAssetAttributes {
    my $dbh       = shift;
    my $itemId    = shift;
    my $fileName  = shift;
    my $media_description = shift;
    my $sourceUrl = shift;
    my $uId       = shift;

    my $sql = sprintf(
'INSERT INTO item_asset_attribute SET i_id=%d, iaa_filename=%s, iaa_media_description=%s, iaa_source_url=%s, iaa_u_id=%d, iaa_timestamp=NOW()',
        $itemId,
        $dbh->quote($fileName),
        $dbh->quote($media_description),
        $dbh->quote($sourceUrl),
        $uId
    );
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

# using the database handle get media asset attirbutes for the specified item id
# from the database
#
# returns a reference to an array of hash references containting field name and field
# value pairs; NULL field values are returned as undef.
#
# undef may be returned if the asset is not found or errors occur during query exection.
# errors are sent to STDERR.

# to do ensure values are set
# to do ensure escape itemAssetId (SQL INJECTION)
sub getMediaAssetAttributes {
  my $dbh = shift;
  my $i_id = shift;
  my $interaction_id = shift || 0;

  my $out = [];

  my $sql = sprintf(q{
    SELECT i.i_id, i.ib_id, i.i_external_id, i.i_version, 
iaa.iaa_id,
iaa.iaa_filename,
iaa.iaa_source_url, 
iaa.iaa_media_description
FROM item_asset_attribute iaa, item AS i
WHERE i.i_id=%d
AND i.i_id=iaa.i_id
AND iaa.iaa_filename REGEXP "\.mp3$|\.m4a$|\.m4v$|\.mp4$|\.swf$"
}, $i_id);

  my $sth = $dbh->prepare($sql) or warn $dbh->errstr; # return undef;
  $sth->execute or warn $dbh->errstr; # return undef;
 
  while(my $row = $sth->fetchrow_hashref) {

    my $rec = {};

    foreach(qw/i_id ib_id i_external_id i_version iaa_id iaa_filename iaa_source_url iaa_media_description/) {
      $rec->{$_} = $row->{$_}; 
    }

    if($interaction_id) {
      $sql = sprintf(q{ 
    SELECT ifg.* 
FROM item_fragment AS ifg 
WHERE ifg.i_id = %d
AND ifg.if_type=2
AND ifg.ii_id=%d
AND ifg.if_text LIKE CONCAT("%%",%s,"%%") 
ORDER BY ifg.if_seq;
}, $i_id, $interaction_id, $dbh->quote($row->{iaa_filename}));
    } else {
      $sql = sprintf(q{ 
    SELECT ifg.* 
FROM item_fragment AS ifg
WHERE ifg.i_id=%d
AND ifg.if_type=1
AND ifg.if_text LIKE CONCAT("%%",%s,"%%") 
}, $i_id, $dbh->quote($row->{iaa_filename})); 
    }

    my $sth2 = $dbh->prepare($sql) or warn $dbh->errstr; # return undef;
    $sth2->execute or warn $dbh->errstr; # return undef;

    while(my $row2 = $sth2->fetchrow_hashref) {

      if($interaction_id) {
        $rec->{i_part} = 'Choice ' . $choice_chars[$row2->{if_seq} - 1];
      } else {
        $rec->{i_part} = 'Stem';
      }
    }

    push @{$out}, $rec;
  }
  return $out;
}

# generate media html table for an item
sub getMediaTableHtml {
  use HTML::Template;

  my $mediaAssets = shift;
  my $editMode = shift || 0;
  my $ib_id = shift;
  my $i_id = shift;
  my $i_external_id = shift;
  my $i_version = shift;
  my $interaction_id = shift || 0;

  my $mediaTmplt = HTML::Template->new(scalarref => \ <<TEMPLATE
  <div>
    <table id="mediaAssetTable" class="tablesorter" border="1" cellpadding="2" cellspacing="2">
      <caption>Media Assets<TMPL_IF NAME=SHOWUPLOAD><span style="float:right;"><input type="button" value="Upload" onClick="myOpen('mediaUpload', '<TMPL_VAR NAME=UPLOADURL>',550,450);"></span></TMPL_IF></caption>
      <thead>
      <tr>
        <th style="padding-right:20px;">Item Part</th>
        <th style="padding-right:20px;">Filename</th>
        <th style="padding-right:20px;">Description</th>
        <th style="padding-right:20px;">File Size</th>
        <th>Actions</th>
      </tr>
      </thead>
      <tfoot id="noMediaMessage"<TMPL_IF NAME=ASSETS> style="display:none;"</TMPL_IF>>
      <tr>
        <td colspan="5"><span style="font-style:italic;">No Media Assets</span></td>
      </tr>
      </tfoot>
      <tbody>
      <TMPL_LOOP NAME=ASSETS>
        <tr id="<TMPL_VAR NAME=IAA_FILENAME>">
          <td><TMPL_VAR NAME=ITEMPART></td>
          <td><TMPL_VAR NAME=FILENAME></td>
          <td><TMPL_VAR NAME=DESCRIPTION></td>
          <td><TMPL_VAR NAME=FILESIZE></td>
          <td><TMPL_VAR NAME=VIEWLINK><TMPL_IF NAME=SHOWEDITOPTS>&nbsp;|&nbsp;<TMPL_VAR NAME=INSERTLINK>&nbsp;|&nbsp;<TMPL_VAR NAME=DELETELINK></TMPL_IF></td>
        </tr>
      </TMPL_LOOP>
      </tbody>
    </table>
  </div>
TEMPLATE
);

  my $rows = [
   map {{
     IAA_FILENAME => $_->{iaa_filename},
     ITEMPART => (defined $_->{i_part} ? $_->{i_part} : "<span style=\"font-style:italic;\">Unassigned</span>"),
     FILENAME => $_->{iaa_source_url},
     DESCRIPTION => $_->{iaa_media_description},
     FILESIZE => sprintf("%.1f", (-s ${orcaPath} . 'images/lib' . $_->{ib_id} . '/' . $_->{i_external_id} . '/' . $_->{iaa_filename})/1024).' kb',
     VIEWLINK => "<a href=\"#\" onClick=\"myOpen('mediaViewer','${mediaViewUrl}?itemBankId=$_->{ib_id}&itemName=$_->{i_external_id}&version=$_->{i_version}&imageId=$_->{iaa_filename}',700,500);\">View</a>",
     SHOWEDITOPTS => $editMode,
     INSERTLINK => "<a href=\"#\" onClick=\"myOpen('mediaInsert','${mediaInsertUrl}?i_id=$_->{i_id}&iaa_id=$_->{iaa_id}&interaction_id=${interaction_id}',400,350);\">Associations</a>",
     DELETELINK => "<a href=\"#\" onClick=\"myOpen('mediaDelete','${mediaDeleteUrl}?i_id=$_->{i_id}&i_version=$_->{i_version}&iaa_id=$_->{iaa_id}&interaction_id=${interaction_id}',400,350);\">Delete</a>"
   }} @{$mediaAssets}
  ];

  my $mediaUploadUrlParams = "?itemBankId=$ib_id&itemId=$i_id&itemExternalId=$i_external_id&version=$i_version";
  $mediaTmplt->param(ASSETS=>$rows, SHOWUPLOAD=>$editMode, UPLOADURL=>$mediaUploadUrl.$mediaUploadUrlParams);

# this block is resulting in error pring() on unopened filehandle
  # Trick HTML::Template output subroutine into treating $mediaHtml as file
  #my $mediaHtml = '';
  #open(MEMORY, ">", \$mediaHtml) or warn "Could not open string for writing!";
#print MEMORY "test\n";
  #$mediaTmplt->output(print_to =>  \*MEMORY);
  #return $mediaHtml;
  $mediaTmplt->output;
}

sub getMediaHtml {

  my $playerId = shift;
  my $ext = shift;
  my $title = shift;
  my $path = shift;

  my $html = '';

  my $is_audio = 0;
  my $is_video = 0;

  if ($ext eq 'mp3' || $ext eq 'm4a') {
    $is_audio = 1;
  } elsif ($ext eq 'm4v') {
    $is_video = 1;
  } elsif ($ext eq 'mp4') {
    use Image::ExifTool qw(:Public);
    my $mp4_info = ImageInfo($path);
    $is_audio = $mp4_info->{MIMEType} =~ m/^audio\/mp4/;
    $is_video = $mp4_info->{MIMEType} =~ m/^video\/mp4/;
  }

  if($is_audio) {

    $html = <<END_HTML;

<div id="${playerId}" class="jp-jplayer"></div>

<div id="${playerId}_container" class="jp-audio">
  <div class="jp-type-single">
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
      <div class="jp-current-time"></div>
      <div class="jp-duration"></div>
    </div>
    <div class="jp-title">
       <ul>
         <li>${title}</li>
       </ul>
    </div> 
    <div class="jp-no-solution">
        <span>Update Required</span>
	To play the media you need to upgrade to a browser that supports HTML5 or Flash
    </div>
  </div>
</div>

END_HTML

  } elsif ($is_video) {

    $html = <<END_HTML;
<div id="${playerId}_container" class="jp-video jp-video-360p">
  <div class="jp-type-single">
    <div id="${playerId}" class="jp-jplayer"></div>
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
        <div class="jp-title">
          <ul>
            <li>${title}</li>
          </ul>
        </div>
        <div class="jp-controls-holder">
          <ul class="jp-controls">
            <li><a href="javascript:;" class="jp-play" tabindex="1">play</a></li>
            <li><a href="javascript:;" class="jp-pause" tabindex="1">pause</a></li>
            <li><a href="javascript:;" class="jp-stop" tabindex="1">stop</a></li>
            <li><a href="javascript:;" class="jp-volume-max" tabindex="1" title="max volume">max volume</a></li>
          </ul>
          <div class="jp-volume-bar">
            <div class="jp-volume-bar-value"></div>
          </div>
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

    $html = <<END_HTML;
    <div>Media Type ${ext} not recognized.</div>
END_HTML

  }

  return $html;
}

sub getMediaReadyFunction {

  my $playerId = shift;
  my $ext = shift;
  my $url = shift;
  my $path = shift;

  my $html = '';

  my $is_audio = 0;
  my $is_video = 0;

  if ($ext eq 'mp3' || $ext eq 'm4a') {
    $is_audio = 1;
  } elsif ($ext eq 'm4v') {
    $is_video = 1;
  } elsif ($ext eq 'mp4') {
    use Image::ExifTool qw(:Public);
    my $mp4_info = ImageInfo($path);
    $is_audio = $mp4_info->{MIMEType} =~ m/^audio\/mp4/;
    $is_video = $mp4_info->{MIMEType} =~ m/^video\/mp4/;
  }

  if($is_audio) {

    $html = <<END_HTML;
\$("#${playerId}").jPlayer({

  ready: function(event) 
           {
             \$(this).jPlayer("setMedia", {
               //${ext}: "${url}"
m4a: "${url}"
             });
           },

  play: function() 
       {
    \$(this).jPlayer("pauseOthers");
  },

  swfPath: "/common/js",
  //supplied: "${ext}",
supplied: "m4a",
  cssSelectorAncestor: "#${playerId}_container",
   wmode: "window"

});
END_HTML

  } elsif ($is_video) {

    $html = <<END_HTML;
\$("#${playerId}").jPlayer({

  ready: function(event) 
           {
             \$(this).jPlayer("setMedia", {
               m4v: "${url}"
             });
           },

  play: function() 
       {
    \$(this).jPlayer("pauseOthers");
  },

  swfPath: "/common/js",
  supplied: "m4v",
  size: {
    cssClass: "jp-video-360p" 
  },
  cssSelectorAncestor: "#${playerId}_container"
});
END_HTML

  } else {

    $html = '';
  }

  return $html;
}

sub getBankMetafilesForItem {

  my $dbh = shift;
  my $itemId = shift;
  my $type = shift || 0;

  my %metafiles = ();

  my $typeSql = '';

  if($type) {
    $typeSql = ' AND ibm.ibm_type_code=' . $type;
  }

  my $sql = <<SQL;
  SELECT ibm.* FROM item_bank_metafiles AS ibm, item_metafile_association AS ima 
    WHERE ima.i_id=${itemId} 
      AND ima.ibm_id=ibm.ibm_id
      ${typeSql}
    ORDER BY ibm.ibm_timestamp DESC
SQL

    my $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {

        my $key = $row->{ibm_id};

        $metafiles{$key}            = {};
        $metafiles{$key}{bankId}   = $row->{ib_id};
        $metafiles{$key}{comment}   = $row->{ibm_comment};
        $metafiles{$key}{timestamp}   = $row->{ibm_timestamp};
        $metafiles{$key}{name}      = $row->{ibm_orig_name};
        $metafiles{$key}{view} =
          "${orcaUrl}itembank-metafiles/lib$row->{ib_id}/$row->{ibm_id}.$row->{ibm_version}-$row->{ibm_orig_name}";
        $metafiles{$key}{view} =~ s/\s/%20/g;
    }
    $sth->finish;

    return \%metafiles;
}

sub addItemComment {

  my $dbh = shift;
  my $itemId = shift;
  my $userId = shift;
  my $type = shift;
  my $devState = shift;
  my $rating = shift;
  my $comment = shift || '';

  my $sql = sprintf('SELECT ic_id FROM item_comment WHERE i_id=%d AND u_id=%d AND ic_dev_state=%d',
              $itemId,
	      $userId,
	      $devState);

  my $sth = $dbh->prepare($sql);
  $sth->execute();

  if(my $row = $sth->fetchrow_hashref) {

    $sql = sprintf('UPDATE item_comment SET ic_rating=%d, ic_comment=%s, ic_timestamp=NOW() WHERE ic_id=%d',
             $rating,
	     $dbh->quote($comment),
	     $row->{ic_id});

  } else {

    $sql = sprintf('INSERT INTO item_comment SET i_id=%d, u_id=%d, ic_type=%d, ic_dev_state=%d, ic_rating=%d, ic_comment=%s, ic_timestamp=NOW()',
              $itemId,
	      $userId,
	      $type,
	      $devState,
	      $rating,
	      $dbh->quote($comment));

  }
  $sth->finish;

  $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;

}

sub addPassageComment {

  my $dbh = shift;
  my $passageId = shift;
  my $userId = shift;
  my $type = shift;
  my $devState = shift;
  my $rating = shift;
  my $comment = shift || '';

  my $sql = sprintf('SELECT pc_id FROM passage_comment WHERE p_id=%d AND u_id=%d AND pc_dev_state=%d',
              $passageId,
	      $userId,
	      $devState);

  my $sth = $dbh->prepare($sql);
  $sth->execute();

  if(my $row = $sth->fetchrow_hashref) {

    $sql = sprintf('UPDATE passage_comment SET pc_rating=%d, pc_comment=%s, pc_timestamp=NOW() WHERE pc_id=%d',
             $rating,
	     $dbh->quote($comment),
	     $row->{pc_id});

  } else {

    $sql = sprintf('INSERT INTO passage_comment SET p_id=%d, u_id=%d, pc_type=%d, pc_dev_state=%d, pc_rating=%d, pc_comment=%s, pc_timestamp=NOW()',
              $passageId,
	      $userId,
	      $type,
	      $devState,
	      $rating,
	      $dbh->quote($comment));

  }
  $sth->finish;

  $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;

}

sub getActionMap {

    my $file = shift;
    my $start_time = [Time::HiRes::gettimeofday()];

    my %map = ();
    my $xp = new XML::XPath( filename => $file );

    foreach my $workNode ( $xp->findnodes('/workflow_set/workflow') ) {

        my $type = $xp->find( 'user_type', $workNode )->string_value;

        #print "User ${type}\n";

        foreach my $actionNode ( $xp->findnodes( 'actions/action', $workNode ) )
        {

            my $seq = $xp->find( 'sequence', $actionNode )->string_value;
            my $fromState =
              $xp->find( 'from_state', $actionNode )->string_value;
            my $label = $xp->find( 'label', $actionNode )->string_value;
            print STDERR "Cannot find map for state ${fromState}\n"
              unless exists $action_key_states{$fromState};

            $map{$type}{$seq}{state}      = $action_key_states{$fromState};
            $map{$type}{$seq}{stateValue} = $fromState;
            $map{$type}{$seq}{label}      = $label;

            if ( $xp->exists( 'use_compare', $actionNode ) ) {
                $map{$type}{$seq}{compare} = 1;
            }
	    # NOTE: This is hard-coding comparison mode to always-on 
            $map{$type}{$seq}{compare} = 1;

            if ( $xp->exists( 'compare_state', $actionNode ) ) {
                my $compareState =
                  $xp->find( 'compare_state', $actionNode )->string_value;
                print STDERR "Cannot find map for compare state ${compareState}\n"
                  unless exists $action_key_states{$compareState};

                $map{$type}{$seq}{compareState} =
                  $action_key_states{$compareState};
                $map{$type}{$seq}{compareStateValue} = $compareState;
            }

            if ( $xp->exists( 'item_notes', $actionNode ) ) {
                $map{$type}{$seq}{itemNotesTag} =
                  $xp->find( 'item_notes', $actionNode )->string_value;
            }

            if ( $xp->exists( 'is_group_review', $actionNode ) ) {
                $map{$type}{$seq}{isGroupReview} = 1;
            }

            if ( $xp->exists( 'is_group_review_lead', $actionNode ) ) {
                $map{$type}{$seq}{isGroupReviewLead} = 1;
            }

            # a group review state won't use normal transitions, there is just a hard-coded accept

            if($map{$type}{$seq}{isGroupReview}) {

              my $auto = 'accept';

              $map{$type}{$seq}{$auto}{action} = join ('-', $map{$type}{$seq}{stateValue}, $auto);
              $map{$type}{$seq}{$auto}{label} = 'Accept';
              $map{$type}{$seq}{$auto}{state} = $map{$type}{$seq}{state};
              $map{$type}{$seq}{$auto}{stateValue} = $map{$type}{$seq}{stateValue};

	    } else {

              foreach my $transitionNode (
                $xp->findnodes( 'transitions/transition', $actionNode ) )
              {

                my $trans =
                  $xp->find( 'transition_type', $transitionNode )->string_value;
                my $label = $xp->find( 'label', $transitionNode )->string_value;
                my $toState =
                  $xp->find( 'to_state', $transitionNode )->string_value;
                print STDERR "Cannot find map for trans state '$toState'\n"
                  unless exists $action_key_states{$toState};

                $map{$type}{$seq}{$trans}{action} =
                  join( '-', $fromState, $trans );
                $map{$type}{$seq}{$trans}{label} = $label;
                $map{$type}{$seq}{$trans}{state} = $action_key_states{$toState};
                $map{$type}{$seq}{$trans}{stateValue} = $toState;

            	if ( $xp->exists( 'with_notification', $transitionNode ) ) {
                    $map{$type}{$seq}{$trans}{notify_user} =
                  	$xp->find( 'with_notification', $transitionNode )->string_value;
            	}
              }

            } 
	}

    }
    my $diff = Time::HiRes::tv_interval($start_time);
    warn "Map loaded in $diff\n";

    return \%map;
}

sub getWorkListForUserType {

    my $map      = shift;
    my $userType = shift;

    my %list = ();

    return %list unless exists $map->{$userType};

    foreach ( keys %{ $map->{$userType} } ) {
        $list{$_} = $map->{$userType}{$_}{label};
    }

    return %list;
}

sub getCurrentItemIdByName {
 
   my $dbh = shift;
   my $itemBankId = shift;
   my $itemName = shift;

   my $itemId = 0;

   my $sql = sprintf('SELECT i_id FROM item WHERE ib_id=%d AND i_external_id=%s ORDER BY i_version DESC LIMIT 1',
                     $itemBankId,
		     $dbh->quote($itemName));
   my $sth = $dbh->prepare($sql);
   $sth->execute();

   if ( my $row = $sth->fetchrow_hashref ) {
     $itemId = $row->{i_id};
   }
   $sth->finish;

   return $itemId;
}

sub getBubbleHtml {
    my $format = shift;
    $format =~ m/(\d+)(\.?)(\d*)$/;
    my $leading  = $1;
    my $trailing = $3;
    my $decimal  = $2;
    my $lCount   = length($leading);
    my $tCount   = length($trailing);
    my $html =
'<table border="1" cellpadding="0" cellspacing="0" style="border-color: #000000;">';

    # Build the header row
    $html .= '<tr style="border-color: #000000;">';
    for ( my $i = 0 ; $i < $lCount ; $i++ ) {
        $html .=
          '<td style="width: 30px; height: 30px;" class="bubble">&nbsp;</td>';
    }
    if ( $decimal eq '.' ) {
        $html .= '<td style="width: 30px; height: 30px;" class="bubble">'
          . '<span style="font-size:28pt; margin-top:8px;">.</span>' . '</td>';
    }
    for ( my $i = 0 ; $i < $tCount ; $i++ ) {
        $html .=
          '<td style="width: 30px; height: 30px;" class="bubble">&nbsp;</td>';
    }
    $html .= '</tr>';

    # build the rest
    $html .= '<tr>';
    for ( my $i = 0 ; $i < $lCount ; $i++ ) {
        $html .= '<td style="width: 27px;" class="bubble">';
        for ( my $j = 0 ; $j <= substr( $leading, $i, 1 ) ; $j++ ) {
            $html .=
              '<input type="button" value="' . $j . '" class="bubble" /><br />';
        }
        $html .= '</td>';
    }
    if ( $decimal eq '.' ) {
        $html .= '<td style="width: 27px;" class="bubble">&nbsp;</td>';
    }
    for ( my $i = 0 ; $i < $tCount ; $i++ ) {
        $html .= '<td style="width: 27px;" class="bubble">';
        for ( my $j = 0 ; $j <= substr( $trailing, $i, 1 ) ; $j++ ) {
            $html .=
              '<input type="button" value="' . $j . '" class="bubble" /><br />';
        }
        $html .= '</td>';
    }

    $html .= '</tr></table>';
    return $html;
}

sub readOgtFile {
    my $ogtFilePath = shift;
    my $params      = shift;
    $ogtFilePath =~ tr/ /_/;
    if ( -e $ogtFilePath ) {
        open OGTFILE, "<${ogtFilePath}";
        my $line = <OGTFILE>;
        close OGTFILE;
        $line =~ s/\s+$//;
        foreach my $namevalue ( split /&/, $line ) {
            my ( $n, $v ) = split /=/, $namevalue;
            $params->{ uri_unescape($n) } = uri_unescape($v);
        }
    }
}

sub hashToSelect {
    my $name  = shift;
    my $hash  = shift;
    my $match = shift;
    $match = '' unless defined $match;
    my $change = shift || '';
    my $blank  = shift || '';
    my $sort   = shift || '';
    my $style  = shift || ' ';

    $match = '' unless defined($match);

    my $out =
        '<select name="' 
      . $name . '"'
      . ( $change eq '' ? '' : ' onChange="' . $change . '"' )
      . ( $style  eq '' ? '' : ' style="' . $style . '"' ) . '>';

    $out .= '<option value=""></option>' unless $change eq '';

    if ( $blank ne '' ) {
        my $blankLabel = '';
        if ( $blank =~ m/^(\w+):(.*)$/ ) {
            $blank      = $1;
            $blankLabel = $2;
        }
        if ( $blank eq 'null' ) { $blank = ''; }
        $out .= '<option value="' . $blank . '">' . $blankLabel . '</option>';
    }

    my $sortSub = sub { $a <=> $b };

    # Check for non-numeric keys
    my $firstVal = (keys %{$hash})[0];
    if(defined($firstVal) && $firstVal !~ /^\d+$/) {
      $sortSub = sub { $a cmp $b };
    }

    # sort by value if preferred, instead of by key
    if ( $sort eq 'value' ) {
        $sortSub = sub { $hash->{$a} cmp $hash->{$b} };
    }

    foreach my $key ( sort $sortSub keys %{$hash} ) {
        $out .=
            '<option value="' 
          . $key . '"'
          . ( $key eq $match ? ' SELECTED' : '' ) . '>'
          . $hash->{$key}
          . '</option>';
    }
    $out .= '</select>';
    return $out;
}

sub hashToCheckbox {
    my $name       = shift;
    my $hash       = shift;
    my $breakCount = shift || 20;
    my $sort       = shift || '';

    my $fieldCounter = 0;

    my $sortSub = sub { $a <=> $b };
    if ( $sort eq 'value' ) {
        $sortSub = sub { $hash->{$a} cmp $hash->{$b} };
    }

    my $out = '';
    foreach ( sort $sortSub keys %{$hash} ) {
        $hash->{$_} =~ s/\s/&nbsp;/g;
        $out .=
          (       $fieldCounter > 0
              and $fieldCounter % $breakCount == 0 ? '<br />' : '' )
          . "$hash->{$_}&nbsp;<input type=\"checkbox\" name=\"${name}_$_\" value=\"yes\" />&nbsp;&nbsp;&nbsp;";
        $fieldCounter++;
    }

    return $out;
}

sub getItemArchive {

    my $dbh     = shift;
    my $itemIds = shift;

    my $debug = 0;

    my %in     = ();
    my $tmpDir = "/tmp/getItemXml_$$/";
    mkdir $tmpDir, 0777;

    print STDERR "Created tmpDir '$tmpDir'\n" if $debug;

    my $zipDir = $tmpDir . 'Items/';
    my $imgDir = $zipDir . 'images/';
    mkdir $zipDir, 0777;
    mkdir $imgDir, 0777;

    # The file $zipFile will be moved to $tmpFile just before deleting $tmpDir
    my $zipFile = "${tmpDir}getItemXml_$$.zip";
    my $tmpFile = "/tmp/itemXml_$$.zip";

    my $itemRelPath = './images/';

    my %standard_labels = ();

    # get standard labels
    my $sql = 'SELECT * FROM qualifier_label WHERE sh_id=1';

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $row->{ql_label} =~ s/[\s\/]/_/g;
        $standard_labels{ $row->{ql_type} } = lc( $row->{ql_label} );
    }
    $sth->finish;

    $sql =
"SELECT i.i_id, i.i_external_id, i.i_correct_response FROM item AS i WHERE i.i_id IN ("
      . join( ',', @{$itemIds} ) . ')'
      . " ORDER BY i.i_external_id";
    $sth = $dbh->prepare($sql);
    $sth->execute();

    print STDERR "Running query:  $sql\n" if $debug;

    while ( my $row = $sth->fetchrow_hashref ) {

        # Create the item images directory
        my $itemDir = "${imgDir}$row->{i_external_id}/";
        mkdir $itemDir, 0777;

        print STDERR "Created itemDir '$itemDir'\n" if $debug;

        # Build the item xml
        my $itemXml = &getItemXml( $dbh, $row->{i_id} );

# in the expression:
# $1 is the <item> tag
# $2 is the <item_name> tag
# $3 is everything between the <item> tag and the 1st <question> tag
# $4 is the 1st <question> tag
#$itemXml =~ s/(<item [^>]+>)\s+(<item_name>.*?<\/item_name>)(.*?)(<question [^>]+>)/$1 $2 $3 $4/;

# place the <correct> tag inside the corresponding <choice> tag at the end of the content
# in this expression:
# $1 is the <choice> tag
# $2 is the content before the end </span> tag
# $3 is the end </span> tag
# $4 is the end </choice> tag
#$itemXml =~ s/(<choice[^>]+value="$row->{i_correct_response}"[^>]*>)(.*?)(<\/span>)\s*(<\/choice>)/$1$2<correct>*<\/correct>$3$4/;

        # remove any blank choices
        #$itemXml =~ s/<choice[^>]+><span>&#160;<\/span><\/choice>//g;

        # Translate absolute URLs to relative
        $itemXml =~
s/src="([^"]+)"/&getImageSrcTranslate($1,$row->{i_external_id},${itemDir},${itemRelPath})/eg;

        open ITEM, '>', $zipDir . "$row->{i_external_id}.xml";
        print ITEM $itemXml;
        close ITEM;
    }
    $sth->finish;

    my $origDir = Cwd::abs_path;
    chdir $tmpDir;
    system( "zip", "-r", "getItemXml_$$", "Items" );

    chdir $origDir;

    rename $zipFile, $tmpFile;

    #system("rm","-rf",$tmpDir);

    return $tmpFile;
}

sub getImageSrcTranslate {
    my $url      = shift;
    my $itemId   = shift;
    my $itemPath = shift;
    my $relDir   = shift;

    my $itemUrl = "${relDir}${itemId}/";
    my $imgUrl  = '';

    if ( $url =~ m/$itemId\/(.*)/ ) {

        my $imgPath = $itemPath . $1;
        $imgUrl = $itemUrl . $1;

        cp( $webPath . $url, $imgPath )
          || print STDERR "Unable to copy ${webPath}${url} to ${imgPath}";
    }
    else {
        print STDERR "${url} does not contain the string '${itemId}'";
    }

    return 'src="' . $imgUrl . '"';
}

sub getStandard {

    my $dbh = shift;
    my $hdId = shift || '';
    my $sth;

    $hdId = 0 if $hdId eq '';

    my $standard = {};
    my $pos      = 0;
    while ( $hdId != 0 ) {
        my $sql = "SELECT * FROM hierarchy_definition WHERE hd_id=${hdId}";
        $sth = $dbh->prepare($sql);
        $sth->execute()
          || print( STDERR "Failed Query:" . $dbh->err . "," . $dbh->errstr );
        if ( my $row = $sth->fetchrow_hashref ) {
            $standard->{ $row->{hd_type} }          = {};
            $standard->{ $row->{hd_type} }->{pos}   = $pos++;
            $standard->{ $row->{hd_type} }->{value} = $row->{hd_value};
            $standard->{ $row->{hd_type} }->{sibling_pos} =
              $row->{hd_posn_in_parent};
            $standard->{ $row->{hd_type} }->{id} = $row->{hd_id};
            $hdId = $row->{hd_parent_id};

            if ( int( $row->{hd_type} ) == $HD_ROOT ) {
                $hdId = 0;
            }
            elsif ( int( $row->{hd_type} ) == $HD_LEAF ) {
                $standard->{ $row->{hd_type} }->{text} = $row->{hd_std_desc};
            }
        }
        else {
            $hdId = 0;
        }
    }
    $sth->finish if defined $sth;
    return $standard;
}

sub makeQueryWithWorkgroupFilter {
  my $sql = shift;
  my $wg = shift;
  my $objectType = shift;
  my $objQueryRef = shift;

  my $charTable = ($objectType == $OT_ITEM) ? 'item_characterization' : 'object_characterization';

  my @wgFilters = ();
  my %filter_types = ();
  foreach my $fkey (keys %{$wg->{filters}}) {
    my @filterParts = ();

    my $fpart = $wg->{filters}{$fkey}{parts};
    foreach my $fpkey (keys %{$fpart}) {
      my $fptable = 'ocfp' . $fpkey;

      if($objectType == $OT_ITEM) {
        push @filterParts, "(${objQueryRef}.i_id=${fptable}.i_id AND ${fptable}.ic_type=${fpkey} AND ${fptable}.ic_value="
                         . $fpart->{$fpkey} . ')';
      } elsif ($objectType == $OT_PASSAGE) {
        push @filterParts, "(${fptable}.oc_object_type=${OT_PASSAGE} AND ${objQueryRef}.p_id=${fptable}.oc_object_id "
	                   . "AND ${fptable}.oc_characteristic=${fpkey} AND ${fptable}.oc_int_value="
	                   . $fpart->{$fpkey} . ')';
      }
      $filter_types{$fpkey} = 1;  
    }
    push @wgFilters, join (' AND ', @filterParts);
  }

  my $wgJoinQuery = ' (' . join (' OR ', map { '(' . $_ . ')' } @wgFilters) . ') AND';
  my $wgJoinTable = '';
  $wgJoinTable .= $charTable . ' AS ocfp' . $_ . ', ' foreach keys %filter_types;

  unless(scalar @wgFilters) {
    $wgJoinTable = '';
    $wgJoinQuery = '/*empty-workgroup*/ 1=0 AND'; 
  }
 
  $sql =~ s/(FROM \/\*cde\-filter\*\/)/$1 $wgJoinTable/;
  $sql =~ s/(WHERE \/\*cde\-filter\*\/)/$1 $wgJoinQuery/;

  return $sql;
}

sub getMetadataClient {

  my $restClient = REST::Client->new();
  $restClient->setHost('https://' . $webHost);
  $restClient->setTimeout(5);
  $restClient->setFollow(1);
  #$restClient->getUseragent()->credentials("${webHost}:443",'SBAC',
  #                                         "ws-user-1","ping");

  return $restClient;
}

sub getEditors {
    my $dbh     = shift;
    my $itemBankId = shift || 0;

    my %editors = ();

    my $sql = '';

    # set up the query different if we restrict by item bank access

    if($itemBankId) {
      $sql = <<SQL;
      SELECT u.* 
        FROM user AS u, user_permission AS up
	  WHERE u.u_id=up.u_id
	    AND up.up_type=${UP_VIEW_ITEM_BANK}
	    AND up.up_value=${itemBankId}
	    AND u.u_type=11
SQL
    } else {
      $sql = 'SELECT u.* FROM user AS u WHERE u.u_type=11';
    }

    # add stuff here to the query that applies either way
    $sql .=  ' AND u.u_deleted=0 AND u.u_review_type=1';

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $editors{ $row->{u_id} } =
          "$row->{u_last_name}, $row->{u_first_name} [$row->{u_username}]";
    }
    $sth->finish;
    return \%editors;
}

sub getUsersWithReviewType {
    my $dbh     = shift;
    my $reviewType = shift || 0;
    my $itemBankId = shift || 0;

    my %users = ();

    return \%users unless $reviewType && $itemBankId;

    my $sql = '';

    # set up the query different if we restrict by item bank access

      $sql = <<SQL;
      SELECT u.* 
        FROM user AS u, user_permission AS up
	  WHERE u.u_id=up.u_id
	    AND up.up_type=${UP_VIEW_ITEM_BANK}
	    AND up.up_value=${itemBankId}
            AND u.u_type=11 AND u.u_deleted=0 AND u.u_review_type=${reviewType}
SQL

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $users{ $row->{u_id} } =
          "$row->{u_last_name}, $row->{u_first_name} [$row->{u_username}]";
    }
    $sth->finish;
    return \%users;
}

sub getUsers {
    my $dbh   = shift;
    my $organizationId = shift || 0;
    my %users = ();

    my $sql =
'SELECT t1.* FROM user AS t1 WHERE'
      . ' t1.u_type=11 AND t1.u_permissions>0';

    if($organizationId) {
      $sql .= ' AND t1.o_id=' . $organizationId;
    }

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $users{ $row->{u_id} } = "$row->{u_last_name}, $row->{u_first_name} [$row->{u_username}]";
    }
    $sth->finish;
    return \%users;
}

sub getUsersWithPermissions {
    my $dbh   = shift;
    my $organizationId = shift || 0;
    my %users = ();

    my $sql =
'SELECT u.* FROM user AS u WHERE'
      . ' u.u_type=11 AND u.u_deleted=0 AND u.u_permissions > 0';

    if($organizationId) {

      $sql .= ' AND u.o_id=' . $organizationId;
    }

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{u_id};
        $users{$key}            = {};
        $users{$key}{name}      = "$row->{u_last_name}, $row->{u_first_name} [$row->{u_username}]";
        $users{$key}{roles}     = $row->{u_permissions};
        $users{$key}{itemBanks} = {};
        $users{$key}{testBanks} = {};
	$users{$key}{reviewType} = $row->{u_review_type};
	$users{$key}{adminType} = $row->{u_admin_type};
	$users{$key}{organizationId} = $row->{o_id};

        $sql =
            'SELECT up_value FROM user_permission WHERE u_id='
          . $row->{u_id}
          . ' AND up_type='
          . $UP_VIEW_ITEM_BANK;
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute();
        while ( my $row2 = $sth2->fetchrow_hashref ) {
            $users{$key}{itemBanks}{ $row2->{up_value} } = 1;
        }
        $sth2->finish;

        $sql =
            'SELECT up_value FROM user_permission WHERE u_id='
          . $row->{u_id}
          . ' AND up_type='
          . $UP_VIEW_TEST_BANK;
        $sth2 = $dbh->prepare($sql);
        $sth2->execute();
        while ( my $row2 = $sth2->fetchrow_hashref ) {
            $users{$key}{testBanks}{ $row2->{up_value} } = 1;
        }
        $sth2->finish;
    }
    $sth->finish;
    return \%users;
}

sub getUsersByItemBank {
    my $dbh   = shift;
    my $itemBankId = shift || 0;
    my %users = ();

    my $sql = <<SQL;
    SELECT u.* FROM user AS u, user_permission AS up 
      WHERE u.u_type=11
        AND u.u_deleted=0
	AND u.u_id=up.u_id
	AND up.up_type=${UP_VIEW_ITEM_BANK}
	AND up.up_value=${itemBankId}
SQL

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
      my $user = {};
      
      $user->{name}      = "$row->{u_last_name}, $row->{u_first_name} [$row->{u_username}]";
      $user->{reviewType} = $row->{u_review_type};
      $user->{adminType} = $row->{u_admin_type};
      $user->{organizationId} = $row->{o_id};
    
      $users{$row->{u_id}} = $user;
    }
    return \%users;
}

sub getWorkgroups {
  my $dbh = shift;
  my $itemBankId = shift;

  my %out = ();
  my $sql = sprintf('SELECT * FROM workgroup WHERE ib_id=%d ORDER BY w_name',$itemBankId);
  my $sth = $dbh->prepare($sql);
  $sth->execute();

  while(my $row = $sth->fetchrow_hashref) {
    my $wg = {};

    $wg->{name} = $row->{w_name};
    $wg->{description} = $row->{w_description};

    $out{$row->{w_id}} = $wg;
  }

  return \%out;
}

sub getWorkgroupsByUser {
  my $dbh = shift;
  my $userId = shift;

  my %out = ();
  my $sql = <<SQL;
  SELECT w.* FROM workgroup AS w, user_permission AS up 
    WHERE up.u_id=${userId}
      AND up.up_type=${UP_VIEW_WORKGROUP}
      AND up.up_value=w.w_id
SQL
  my $sth = $dbh->prepare($sql);
  $sth->execute();

  while(my $row = $sth->fetchrow_hashref) {
    my $wg = {};
    
    $wg->{bank} = $row->{ib_id};
    $wg->{name} = $row->{w_name};
    $wg->{description} = $row->{w_description};
    $wg->{filters} = &getWorkgroupFilters($dbh, $row->{w_id});

    $out{$row->{w_id}} = $wg;
  }

  return \%out;
}

sub getWorkgroupFilters {
  my $dbh = shift;
  my $workGroupId = shift;

  my %out = ();

  my $sql = <<SQL;
     SELECT wfp.* FROM workgroup_filter_part AS wfp, workgroup_filter AS wf
       WHERE wf.w_id=${workGroupId}
         AND wfp.wf_id=wf.wf_id
SQL
  my $sth = $dbh->prepare($sql);
  $sth->execute();

  while(my $row = $sth->fetchrow_hashref) {
    $out{$row->{wf_id}}{parts}{$row->{wf_type}} = $row->{wf_value};
  }

  return \%out;
}

sub getItemsByUser {
    my $dbh        = shift;
    my $user       = shift || 0;
    my $itemBankId = shift || 0;

    my %items = ();

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);

    my $today = sprintf( '%04d-%02d-%02d', $year + 1900, $mon + 1, $mday );

    my $sql =
"SELECT its.*, i.i_external_id FROM item_status AS its, item AS i WHERE its.is_u_id=${user} AND its.is_timestamp >= '${today}' AND its.i_id=i.i_id AND i.ib_id=${itemBankId}";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    print STDERR "getItemsByUser: $sql";
    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{is_timestamp};

        $items{$key}               = {};
        $items{$key}{id}           = $row->{i_id};
        $items{$key}{name}         = $row->{i_external_id};
        $items{$key}{lastDevState} = $dev_states{ $row->{is_last_dev_state} };
        $items{$key}{newDevState}  = $dev_states{ $row->{is_new_dev_state} };

    }
    $sth->finish;

    return \%items;
}

sub getProjects {

    my $dbh        = shift;
    my $itemBankId = shift || 0;
    my %projects   = ();

    my $sql = "SELECT * FROM item_project WHERE ib_id=${itemBankId}";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $projects{ $row->{ip_id} } = $row->{ip_name};
    }
    $sth->finish;
    return \%projects;
}

sub getOrganizations {

    my $dbh    = shift;
    my %orgs  = ();

    my $sql = "SELECT * FROM organization";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{o_id};
        $orgs{$key}              = {};
        $orgs{$key}{name}        = $row->{o_name};
        $orgs{$key}{description} = $row->{o_description};

        $orgs{$key}{name_escaped} = &escapeHTML($row->{o_name});
        $orgs{$key}{description_escaped} = &escapeHTML($row->{o_description});
    }
    $sth->finish;
    return \%orgs;
}

sub getItemBanks {

    my $dbh    = shift;
    my $userId = shift || 0;
    my $organizationId = shift || 0;
    my %banks  = ();

    my $sql;
    if ($userId) {
        $sql = "SELECT ib.* FROM item_bank AS ib, user_permission AS up"
          . " WHERE up.u_id=${userId} AND up.up_type=${UP_VIEW_ITEM_BANK} AND up.up_value=ib.ib_id";
    }
    else {
        $sql = "SELECT * FROM item_bank";

	if($organizationId) {
	  $sql .= " WHERE o_id=${organizationId}";
	}
    }
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{ib_id};

        $banks{$key}              = {};
        $banks{$key}{name}        = $row->{ib_external_id};
        $banks{$key}{description} = $row->{ib_description};
        $banks{$key}{owner}       = $row->{ib_owner};
        $banks{$key}{hostBase}    = $row->{ib_host_base};
        $banks{$key}{hasIMS}      = $row->{ib_has_ims};
        $banks{$key}{assignIMSId} = $row->{ib_assign_ims_id};
        $banks{$key}{organization} = $row->{o_id};
        $banks{$key}{tb_id} 	  = $row->{tb_id};
        $banks{$key}{sh_id} 	  = $row->{sh_id};
    }
    $sth->finish;
    return \%banks;
}

sub getStandards {
    my $dbh = shift;
    my %tbl = ();
    my $sql = "SELECT * FROM standard_hierarchy ORDER BY sh_external_id";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        $tbl{$row->{sh_id}} = $row->{sh_external_id};
    }
    $sth->finish;
    return \%tbl;
}

sub getPassageList {

    my $dbh         = shift;
    my $itemBankId  = shift || 0;
    my $contentArea = shift || '';
    my $gradeLevel  = shift || '';
    my %passages    = ();

    my $sql =
      "SELECT p.* FROM passage AS p WHERE p.ib_id=${itemBankId}"
      . ( $contentArea eq '' ? ''
        : " AND ${contentArea} = (SELECT oc_int_value FROM object_characterization WHERE oc_object_type=${OT_PASSAGE} AND oc_object_id=p.p_id AND oc_characteristic=${OC_CONTENT_AREA} LIMIT 1)"
      )
      . ( $gradeLevel eq '' ? ''
        : " AND ${gradeLevel} = (SELECT oc_int_value FROM object_characterization WHERE oc_object_type=${OT_PASSAGE} AND oc_object_id=p.p_id AND oc_characteristic=${OC_GRADE_LEVEL} LIMIT 1)"
      );
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ) {
        $passages{ $row->{p_id} } = $row->{p_name};
    }
    $sth->finish;
    return \%passages;
}

sub dbCharUpdate {
    my $dbh    = shift;
    my $oType  = shift;
    my $oID    = shift;
    my $cType  = shift;
    my $cValue = shift;

    my $sql =
        "SELECT * FROM object_characterization"
      . " WHERE oc_object_type=${oType}"
      . " AND oc_object_id=${oID} AND oc_characteristic=${cType}";
    my $sth = $dbh->prepare($sql);
    $sth->execute() || print( STDERR "Failed Query:" . $dbh->err );
    if ( my $row = $sth->fetchrow_hashref ) {
        $sql =
            "UPDATE object_characterization SET oc_int_value=${cValue}"
          . " WHERE oc_object_type=${oType}"
          . " AND oc_object_id=${oID} AND oc_characteristic=${cType}";
    }
    else {
        $sql =
            'INSERT INTO object_characterization'
          . ' (oc_object_type,oc_object_id,oc_characteristic,oc_int_value)'
          . " VALUES (${oType},${oID},${cType},${cValue})";
    }
    $sth = $dbh->prepare($sql);
    $sth->execute() || print( STDERR "Failed Query:" . $dbh->err );
    $sth->finish;
}

sub get_project_config {
    my $projectId = shift;
    my %config    = ();

    use XML::XPath;
    my $xp =
      XML::XPath->new( 'filename' => "${projectConfigDir}${projectId}.xml" );
    $config{startDate}  = $xp->getNodeText('/project/@startDate');
    $config{endDate}    = $xp->getNodeText('/project/@endDate');
    $config{writers}    = {};
    $config{workstates} = {};

    foreach ( $xp->find('/project/writers/writer')->get_nodelist ) {
        $config{writers}->{ $_->getAttribute('id') } = {};
        $config{writers}->{ $_->getAttribute('id') }->{rate} =
          $_->getAttribute('rate');
        $config{writers}->{ $_->getAttribute('id') }->{rateType} =
          $_->getAttribute('rateType');
    }

    foreach ( $xp->find('/project/workstates/state')->get_nodelist ) {
        $config{workstates}->{ $_->getAttribute('id') } = {};
        $config{workstates}->{ $_->getAttribute('id') }->{estimate} =
          $_->getAttribute('timeEstimate');
    }

    return \%config;
}

sub fixHtml {
    my $html = shift;
    $html =~ s/http:\/\/$ENV{SERVER_NAME}//gs if defined $ENV{SERVER_NAME};
    $html =~ s/<\/img (?:style|src)[^>]*>/<\/p>/gs;
    $html =~ s/<\/span[^>]+>/<\/span>/gs;
    $html =~ s/<\/td[^>]+>/<\/td>/gs;
    $html =~ s/<\/li[^>]+>/<\/li>/gs;
    $html =~ s/<\/p[^>]+>/<\/p>/gs;
    $html =~ s/<align="\w*"><\/align="\w*">//gs;
    $html =~ s/<\/?st1:[^>]*>//gs;
    $html =~ s/<\/?o:[^>]*>//gs;
    $html =~ s/<\/?v:[^>]*>//gs;
    $html =~ s/<\/?w:[^>]*>//gs;
    $html =~ s/<\/>//gs;
    $html =~
      s/classid=''/classid='clsid:D27CDB6E-AE6D-11cf-96B8-444553540000'/gs;
    $html =~
      s/classid=""/classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"/gs;

    while ( $html =~ m/(?:value|flashvars)="(?:[^"]*)\&amp;amp;/ ) {
        $html =~
          s/(value|flashvars)="([^"]*?)\&(?:amp;){2,}([^"]*)"/$1="$2\&amp;$3"/s;
    }
    return $html;
}

sub setImageSize {

    my $srcLine = shift;

    $srcLine =~ /src="([^"]+)"/;

    #unless($1 =~ /\.gif$/) { return $srcLine; }

    my $file = $webPath . $1;

    my $output = `identify $file`;
    $output =~ /(\d{1,4})x(\d{1,4})/;

    if ( defined($1) ) {
        my $width  = $1;
        my $height = $2;
        if ( $width =~ /^\d+$/ && $width > 0 ) {
            return
                $srcLine
              . ' width="'
              . int($width)
              . '" height="'
              . int($height) . '" ';
        }
        else {
            return $srcLine;
        }
    }
    else {
        return $srcLine;
    }
}

# tests to see if html content is empty, decodes any mutlibyte characters and
# strips html, finally checks to see if any spaces (single or multibyte)
sub isHTMLContentEmpty {
  my $html_content = shift;
  
  use HTML::Entities;
  my $html_decoded = decode_entities($html_content);
  my $plain_content = $html_decoded;
  return ($plain_content=~/^\p{Zs}*$|^\s*$/);
}

sub escapeHTML {
    my $html = shift;

    return '' unless defined $html;

    $html =~ s/&/&amp;/g;
    $html =~ s/(value|flashvars)="([^"]+)"/&escapeFlashValue($1,$2)/eg;
    $html =~ s/</&lt;/g;
    $html =~ s/>/&gt;/g;
    $html =~ s/"/&quot;/g;
    $html =~ s/'/&apos;/g;

    return $html;
}

sub unescapeHTML {
    my $html = shift;

    return '' unless defined $html;

    $html =~ s/(value|flashvars)="([^"]+)"/&unescapeFlashValue($1,$2)/eg;
    return $html;
}

sub escapeFlashValue {
    my $name  = shift;
    my $value = shift;
    $value =~ s/&/&amp;/g;
    return $name . '="' . $value . '"';
}

sub unescapeFlashValue {
    my $name  = shift;
    my $value = shift;
    $value =~ s/&amp;/&/g;
    return $name . '="' . $value . '"';
}

sub print_no_auth {
    return <<END_HTML;
<html>
  <head> 
    <title>Not Authorized</title>
    <link rel="stylesheet" href="${UrlConstants::orcaUrl}style/text.css" type="text/css" />
  </head>
  <body>
  <div class="title">You Are Not Authorized to Access this Application. Click here <a href="#" onClick="parent.document.location.href='${UrlConstants::authUrl}logout';">to Log Out.</a></div>
  </body>
</html>
END_HTML
}

sub printNoAuthPage {
    my $msg = shift;
    print <<END_HTML;
<html>
  <head> 
    <title>Not Authorized</title>
  </head>
  <body>
  <h3>You Are Not Authorized to Access this page!</h3>
  </body>
</html>
END_HTML
}

sub get_ts {
    my $time_shift = shift;
    my $addSeconds = ( $time_shift ? $time_shift : 0 );
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime( time + $addSeconds );
    return sprintf(
        "%4d-%02d-%02d %02d:%02d:%02d",
        $year + 1900,
        $mon + 1, $mday, $hour, $min, $sec
    );
}

sub getContentAssetPair {

  my $dbh = shift;
  my $object_type = shift;
  my $object_id = shift;
  my $assetName = shift;

  my $pairName = '';
  $assetName = $dbh->quote($assetName);

  my $sql = <<SQL;
  SELECT cap_pair_name FROM content_asset_pair 
    WHERE cap_object_type=${object_type}
      AND cap_object_id=${object_id}
      AND cap_asset_name=${assetName}
SQL
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  if(my $row = $sth->fetchrow_hashref) {
      $pairName = $row->{cap_pair_name};
  } 

  $sth->finish;
  return $pairName;
}

sub setContentAssetPair {
  my $dbh = shift;
  my $object_type = shift;
  my $object_id = shift;
  my $assetName = shift;
  my $pairName = shift;

  $assetName = $dbh->quote($assetName);
  $pairName = $dbh->quote($pairName);

  my $sql = <<SQL;
  SELECT cap_id FROM content_asset_pair 
    WHERE cap_object_type=${object_type}
      AND cap_object_id=${object_id}
      AND cap_asset_name=${assetName}
SQL
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  if(my $row = $sth->fetchrow_hashref) {
    $sql = "UPDATE content_asset_pair SET cap_pair_name=${pairName} WHERE cap_id=$row->{cap_id}";
  } else {
    $sql = <<SQL;
    INSERT INTO content_asset_pair 
      SET cap_object_type=${object_type},
          cap_object_id=${object_id},
	  cap_asset_name=${assetName}, 
	  cap_pair_name=${pairName}
SQL
  }
  #print STDERR $sql;

  $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;

}
1;
