package Action::itemApproveMenu;

use UrlConstants;
use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $thisUrl = "${orcaUrl}cgi-bin/itemApproveMenu.pl";

  our $sth;
  our $sql;


  unless (exists( $user->{type} )
	and int( $user->{type} ) == $UT_ITEM_EDITOR)
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ];	
  }

  $in{myaction} = '' unless exists( $in{myaction} );

  our $userType = $review_type_map{ $user->{reviewType} };
  our $isAdmin  = $user->{adminType} ? 1 : 0;

  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
}

sub print_welcome {

  my $psgi_out;

  my $params = shift;
  my $saveId = $params->{saveId} || '';

  my $msg = (
		defined( $params->{message} )
		? "<div style='color:#ff0000;'>$params->{message}</div>"
		: ""
	);

  my $spaceWidth =
	  ( $userType eq 'editor' or $userType eq 'graphic_designer' ? 20 : 8 );

  my $frameTarget = 'rightFrame';

  $params->{$_} ||= '' for (qw( doCompare doCompareState itemNotesTag ));

  if ( $userType eq 'psychometrician' ) {

        $psgi_out .= <<END_HERE;
        <html>
        <head>
        <title>Statistics Management</title>
        <script language="JavaScript">
        <!-- 
            parent.frames[1].location = '${ItemConstants::javaUrl}Psychometrics.jsf';
        -->
        </script>
        </head>
        <body><span><input type="button" class="action_button_long" onClick="parent.document.location.href='${authUrl}logout';" value="Log Out" /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span></body>
        </html>
END_HERE
	}

	if ( $userType ne 'psychometrician' ) {

		$psgi_out .= <<END_HERE;
    <html>
      <head>
        <title>SBAC IAIP Item Review for $userType</title>
        <script language="JavaScript">
        <!-- 
          function doReviewSubmit() {
            document.form1.myaction.value = 'select_review_filter';
        document.form1.target = 'rightFrame';
        document.form1.submit();
        return true;
          }

          function selectReviewOption(val, menu) {

            if(val == '') {
          return false;
            }

        var dest = '';
        var root = '${orcaUrl}cgi-bin/';

            if(val == 'item') {
              dest = 'itemApproveMain.pl';
            } else if(val == 'passage') {
              dest = 'passageApprove.pl';
            }

            if(val == 'item') {

          parent.rightFrame.document.location.href = root + dest;

            } else {

              parent.document.location.href =  root + dest;
        }

            menu.selectedIndex = 0;
            return true;
          }

          function selectReportOption(val, menu) {

            if(val == '') {
          return false;
            }

        var dest = '';
        var root = '${orcaUrl}cgi-bin/';

            if(val == 'item') {
              dest = root + 'itemReport.pl';
            } else if(val == 'passage') {
              dest = root + 'passageReport.pl';
            } else if(val == 'custom') {
              dest = '${javaUrl}CustomReport.jsf';
            }

        if(val == 'custom') {

          parent.rightFrame.document.location.href = dest;

        } else {

              window.open(dest,'_blank','directories=no,toolbar=no,status=no,scrollbars=yes,width=780,height=570,left=50,top=50');
            }

            menu.selectedIndex = 0;
            return true;
          }

        //--> 
        </script>
        <link href="../style/text.css" rel="stylesheet" type="text/css">
      </head>
      <body>
        <form name="form1" action="${thisUrl}" method="POST">
          <input type="hidden" name="myaction" value="" />
          
          <input type="hidden" name="doCompare" value="$params->{doCompare}" />
          <input type="hidden" name="doCompareState" value="$params->{doCompareState}" />
          <input type="hidden" name="itemNotesTag" value="$params->{itemNotesTag}" />
          <input type="hidden" name="language" value="1" />
          <input type="hidden" name="saveId" value="${saveId}" />
      <div align="left">
END_HERE
	}

	if ($isAdmin) {
		$psgi_out .= <<END_HERE;
            <span><input class="action_button" type="button" onClick="parent.menuFrame.document.location.href='${orcaUrl}cgi-bin/itemAdminMenu.pl';" value="Item Admin" /></span>
        <span style="width:${spaceWidth}px;">&nbsp;</span>
END_HERE
	}

	if ( $user->{reviewType} == $UR_DATA_MANAGER ) {
		$psgi_out .= <<END_HERE;
        <span><input type="button" class="action_button" value="Data Review" onClick="parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/cde.pl?action=dataManager&instance_name=$instance_name';"  /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
END_HERE
	}

	if (   $user->{reviewType}
		&& $user->{reviewType} != $UR_DATA_MANAGER
		&& $userType ne 'psychometrician' )
	{
		$psgi_out .= <<END_HERE;
        <span><select style="font-size:11px;width:110px;" name="review" onChange="selectReviewOption(this.options[this.selectedIndex].value, this);">
             <option value="">Select Review</option>
             <option value="item">Item</option>
             <option value="passage">Passage</option>
             </select></span>
END_HERE
	}

	if ( $userType eq 'content_specialist' || $isAdmin ) {
		$psgi_out .= <<END_HERE;
    <span><select style="font-size:11px;width:110px;" name="report" onChange="selectReportOption(this.options[this.selectedIndex].value, this);">
           <option value="">Select Report</option>
           <option value="item">Item</option>
           <option value="passage">Passage</option>
           <option value="custom">Custom</option>
        </select></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
          <span><input type="button" class="action_button" onClick="parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/itemView.pl'" value="View Item" /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
END_HERE
	}

	if (   $userType eq 'content_specialist'
		|| $userType =~ /^committee/
		|| $isAdmin )
	{
		$psgi_out .= <<END_HERE;
    <span><input type="button" class="action_button" value="Print Item" onClick="parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/itemPrintList.pl'" /> </span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
    <span><input type="button" class="action_button_long" value="Print Passage" onClick="parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/passagePrintList.pl'" /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
END_HERE
	}

	if (   $userType eq 'editor'
		|| $userType eq 'content_specialist'
		|| $isAdmin )
	{
		$psgi_out .= <<END_HERE;
          <span><input type="button" class="action_button_long" onClick="window.parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/itemPassageCreate.pl';" value="Create/Edit Passage" /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
          <span><input type="button" class="action_button_long" onClick="window.parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/itemRubricCreate.pl';" value="Create/Edit Rubric" /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
END_HERE
	}

	if ($isAdmin) {
		$psgi_out .= <<END_HERE;
          <span><input type="button" class="action_button_long" onClick="window.parent.rightFrame.document.location.href='${javaUrl}Psychometrics.jsf';" value="Psychometrics" /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
        
END_HERE
	}

	if ( $userType ne 'psychometrician' ) {
		$psgi_out .= <<END_HERE;
<span><input type="button" class="action_button_long" onClick="parent.document.location.href='${authUrl}logout';" value="Log Out" /></span>
        <span style="width:${spaceWidth}px">&nbsp;</span>
        </div>
        </form>
      </body>
    </html>
END_HERE
	}
  return $psgi_out;
}

1;
