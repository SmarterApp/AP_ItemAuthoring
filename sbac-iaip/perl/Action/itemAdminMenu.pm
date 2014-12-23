package Action::itemAdminMenu;

use ItemConstants;
use UrlConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $user = Session::getUser($q->env, $dbh);
 our $userId= $q->env->{'HTTP_REMOTE_USER'};


  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
}

sub print_welcome {
  my $psgi_out = '';

  my $params = shift;

  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Administration</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      function myOpen (url, width, height)
      {
        window.open(url,'mywindow','width='+width+',height='+height+',left=300,top=100,resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        return true;
      } 

      function selectAdminOption(val, menu) {
        if(val == '') {
          return false; 
        }

        var dest = '';
        var root = '${orcaUrl}cgi-bin/';

        if(val == 'item') {
          dest = 'items_manager.pl?instance_name=${instance_name}';
        } else if(val == 'passage') {
          dest = 'itemPassageManage.pl';
        } else if(val == 'rubric') {
          dest = 'itemRubricManage.pl';
        } else if(val == 'passageSet') {
	  dest = 'passageSetManage.pl';
        } else if(val == 'user') {
          dest = 'itemUserManage.pl';
        } else if(val == 'itemBank') {
          dest = 'itemBankManage.pl';
        } else if(val == 'contentMoves') {
          root = '${javaUrl}';
          dest = 'ContentMoves.jsf?userName=${userId}';
        } else if(val == 'contentMonitor') {
            root = '${javaUrl}';
            dest = 'ContentMonitor.jsf?userName=${userId}'
        } else if(val == 'organization') {
          dest = 'organizationManage.pl';
        } else if (val == 'workGroup') {
	  dest = 'workgroupManage.pl';
        } else if(val == 'itemImport') {
          dest = 'viewItemImportStatus.pl';
        } else if(val == 'itemAudit') {
          dest = 'viewItemAuditReport.pl';
        } else if(val == 'passageAudit') {
          dest = 'viewPassageAuditReport.pl';
        } else if(val == 'itemBankShare') {
          dest = 'itemBankShareManage.pl';
        } else if(val == 'itemMove') {
          dest = 'itemMoveManage.pl';
        } else if(val == 'hierarchy') {
          dest = 'standards_manager.pl?instance_name=${instance_name}';
        } else if(val == 'metafiles') {
          root = '${javaUrl}';
          dest = 'IBMetafiles.jsf'
        } else if(val == 'customReports') {
	  root = '/';
	  dest = 'jasperserver/';
	}

        parent.rightFrame.location = root + dest;
        return true;
      }

      function selectGenerateOption(val, menu) {
        if(val == '') {
          return false; 
        }

        var dest = '';
        var root = '${orcaUrl}cgi-bin/';

        if(val == 'item') {
          dest = 'items_manager.pl?action=itemGenerator&bp=1&instance_name=${instance_name}';
        } else if(val == 'item_alternate') {
          dest = 'itemAlternateGenerate.pl';
        } else if(val == 'passage_set') {
          dest = 'itemPassageGenerate.pl';
        } else if(val == 'item_version') {
          dest = 'itemVersionGenerate.pl';
        }

        parent.rightFrame.location = root + dest;
        return true;
      }

    //-->
    </script>
    <style type="text/css">
      input.button { font-size: 12px; }
    </style>  
  </head>
  <body onLoad="parent.rightFrame.location='${orcaUrl}cgi-bin/items_manager.pl?instance_name=${instance_name}';">
  <form name="form1">
    <table width="95%" border=0 cellpadding=2 cellspacing=2 class="no-style">
      <tr>
        <td nowrap><span class="title">Item Admin</span></td>
        <td>Manage:&nbsp;&nbsp;
          <select style="font-size:11px;" name="manage" onChange="selectAdminOption(this.options[this.selectedIndex].value, this);">
            <option value=""></option>
            <option value="item">Items</option>
            <option value="passage">Passages</option>
            <option value="rubric">Rubrics</option>
	    <option value="passageSet">Passage Clusters</option>
            <option value="metafiles">Metafiles</option>
            <option value="itemImport">Item Imports</option>
            <option value="itemAudit">Item Audits</option>
            <option value="passageAudit">Passage Audits</option>
END_HERE

  if ( $user->{adminType} == $UA_SUPER ) {
    $psgi_out .= <<END_HERE;
            <option value="customReports">Custom Reports</option>
          <!--  <option value="hierarchy">Hierarchies</option> -->
            <option value="organization">Organizations</option>
            <option value="itemBank">Programs</option>
            <option value="user">Users</option>
            <option value="contentMoves">Content Moves</option>
	    <option value="contentMonitor">Content Monitor</option>
            
END_HERE
  }
  elsif ( $user->{adminType} == $UA_ORG ) {
    $psgi_out .= <<END_HERE;
            <option value="itemBank">Programs</option>
            <option value="user">Users</option>
END_HERE
  }
  elsif ( $user->{adminType} == $UA_PROGRAM ) {
    $psgi_out .= <<END_HERE;
            <option value="itemBank">Programs</option>
END_HERE
  }

  $psgi_out .= <<END_HERE;
	   <!-- <option value="itemMove">Item Move</option> -->
            <option value="workGroup">Workgroups</option>
	    <option value="itemBankShare">Program Share</option>
          </select>
        </td>
        <td>Generate:&nbsp;&nbsp;
          <select style="font-size:11px;" name="manage" onChange="selectGenerateOption(this.options[this.selectedIndex].value, this);">
            <option value=""></option>
            <option value="item">Items</option>
            <option value="item_alternate">Item Alternates</option>
            <option value="passage_set">Passage/Item Sets</option>
            <option value="item_version">Item Versions</option>
          </select>
        </td>
        <td><input class="action_button_long" type="button" onClick="parent.menuFrame.location='${orcaUrl}cgi-bin/itemApproveMenu.pl'; parent.rightFrame.location='${orcaUrl}blank.html';" value="Main Menu" /></td> 
      </tr>
    </table>
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;