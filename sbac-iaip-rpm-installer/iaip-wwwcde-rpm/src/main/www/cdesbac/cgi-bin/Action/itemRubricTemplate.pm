package Action::itemRubricTemplate;

use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/itemRubricTemplate.pl";
  
  our %templates = (
      '1' => 'Two - Point Rubric',
      '2' => 'Four - Point Rubric'
  );
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  if ( $in{myAction} eq 'copy' ) {
    return [ $q->psgi_header('text/html'), [ &print_rubric_template(\%in) ]];
  }
}
### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    my $params = shift;

    my $itemBankId = $params->{itemBankId};
    my $templateId = $params->{templateId} || 1;

    my $templateHtml = &hashToSelect( 'templates', \%templates, $templateId,
        'changeForm(this.options[this.selectedIndex].value)' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Item Rubric</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--

      function doUpdateSubmit() {
        document.itemRubric.myAction.value = 'copy';
        document.itemRubric.submit();
      }

      function changeForm(id) {
        document.itemRubric.templateId.value = id;
        document.itemRubric.myAction.value = '';  
        document.itemRubric.submit();
      }

    //-->
    </script>
  </head>
  <body>
    <form name="itemRubric" action="${thisUrl}" method="POST">
      <input type="hidden" name="templateId" value="${templateId}" />
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="myAction" value="" />

      <p>Template:&nbsp;&nbsp;${templateHtml}</p>
END_HERE

    if ( $templateId == 1 ) {
        $psgi_out .= <<END_HERE;
  <table class="no-style" border="0" cellpadding="2" cellspacing="2">
    <tr>
      <td colspan="2">Exemplary Response:<br />
        <textarea rows="4" cols="60" name="exemplary"></textarea>
      </td>
    </tr>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr>
      <td>2-point description:</td>
      <td><input type="text" size="70" name="descTwoPoint" /></td>
    </tr>  
    <tr>
      <td>1-point description:</td>
      <td><input type="text" size="70" name="descOnePoint" value="1 point or minimal understanding of"/></td>
    </tr>  
    <tr>
      <td>0-point description:</td>
      <td><input type="text" size="70" name="descZeroPoint" value="The student's response is incorrect, irrelevant, too brief to evaluate, or blank"/></td>
    </tr>  
  </table>  
END_HERE
    }
    elsif ( $templateId == 2 ) {
        $psgi_out .= <<END_HERE;
  <table class="no-style" border="0" cellpadding="2" cellspacing="2">
    <tr>
      <td colspan="2">Exemplary Response:<br />
        <textarea rows="4" cols="60" name="exemplary"></textarea>
      </td>
    </tr>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr>
      <td colspan="2">Points Assigned:&nbsp;
        <small>(one line per point remark)</small>
        <br />
        <textarea rows="4" cols="60" name="pointsAssigned"></textarea>
      </td>
    </tr>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr>
      <td>4-point description:</td>
      <td><input type="text" size="70" name="descFourPoint" /></td>
    </tr>  
    <tr>
      <td>3-point description:</td>
      <td><input type="text" size="70" name="descThreePoint" /></td>
    </tr>  
    <tr>
      <td>2-point description:</td>
      <td><input type="text" size="70" name="descTwoPoint" /></td>
    </tr>  
    <tr>
      <td>1-point description:</td>
      <td><input type="text" size="70" name="descOnePoint" value="1 point or minimal understanding of"/></td>
    </tr>  
    <tr>
      <td>0-point description:</td>
      <td><input type="text" size="70" name="descZeroPoint" value="The student's response is incorrect, irrelevant, too brief to evaluate, or blank"/></td>
    </tr>  
  </table>  
END_HERE

    }

    $psgi_out .= <<END_HERE;
    <p><input type="button" value="Update Content" onClick="doUpdateSubmit();" /></p>
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_rubric_template {
    my $params = shift;

    my $templateId = $params->{templateId};

    if ( $templateId == 1 ) {
        return &print_rubric_template_2_point($params);
    }
    elsif ( $templateId == 2 ) {
        return &print_rubric_template_4_point($params);
    }
}

sub print_rubric_template_2_point {
    my $params = shift;

    my $itemBankId = $params->{itemBankId};
    my $output;

    # 2 point template
    $output = <<END_HERE;
<p>
<span style="TEXT-DECORATION: underline">Exemplary Response</span>
<br />
<br />
$params->{exemplary}
<br />
<br />
<span style="TEXT-DECORATION: underline">Points Assigned</span></p>
<ul>
  <li>1 point for response that mean is not helpful AND limited reasoning to support answer</li>
  <li>1 additional point if support for answer is very strong</li>
</ul>  
<br />
<strong>Note</strong>: A response that includes no justification should not earn either of the above points.<br />
<br />
<span style="TEXT-DECORATION: underline">Scoring Rubric</span> <br />
<p>
     <table style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; WIDTH: 100%; BORDER-BOTTOM: black 1px solid; BORDER-COLLAPSE: collapse">
           <tbody>
              <tr>
                 <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
                    <p align="center"><strong>Score</strong></p></td>
                 <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
                    <p align="center"><strong>Description</strong></p></td>
              </tr>
              <tr>
                <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
                     <p align="center">2</p></td>
                <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descTwoPoint}</td>
              </tr>
              <tr>
               <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
                 <p align="center">1</p></td>
               <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descOnePoint}</td>
            </tr>
            <tr>
               <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
                 <p align="center">0</p></td>
               <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descZeroPoint}</td>
           </tr>
         </tbody>
      </table></p>
END_HERE

    return &get_html_from_template($output);
}

sub print_rubric_template_4_point {
    my $params = shift;

    my $itemBankId = $params->{itemBankId};
    my $output;

    # 4 point template

    my @pointsAssigned = split /\r?\n/, $params->{pointsAssigned};
    my $pointsHtml =
        '<li><div>'
      . join( '</div></li><li><div>', @pointsAssigned )
      . '</div></li>';

    $output = <<END_HERE;
<p><span style="TEXT-DECORATION: underline">Exemplary Response</span><br />
<br />
$params->{exemplary}
<br />
<br />
<span style="TEXT-DECORATION: underline">Points Assigned</span>
</p>
<ul>
  ${pointsHtml}
</ul>
<br />
<br />
<span style="TEXT-DECORATION: underline">Scoring Rubric</span> <br />

<p>
   <table style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; WIDTH: 100%; BORDER-BOTTOM: black 1px solid; BORDER-COLLAPSE: collapse">
     <tbody>
       <tr>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
           <p align="center"><strong>Score</strong></p></td>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
           <p align="center"><strong>Description</strong></p></td>
      </tr>
       <tr>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
           <p align="center">4</p></td>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descFourPoint}</td>
      </tr>
       <tr>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
           <p align="center">3</p></td>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descThreePoint}</td>
      </tr>
       <tr>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
           <p align="center">2</p></td>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descTwoPoint}</td>
      </tr>
       <tr>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
           <p align="center">1</p></td>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descOnePoint}</td>
      </tr>
       <tr>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">
           <p align="center">0</p></td>
         <td style="BORDER-RIGHT: black 1px solid; BORDER-TOP: black 1px solid; BORDER-LEFT: black 1px solid; BORDER-BOTTOM: black 1px solid">$params->{descZeroPoint}</td>
      </tr>
    </tbody>
  </table></p>
END_HERE

    return &get_html_from_template($output);
}
1;

sub get_html_from_template {

    my $output = shift;

    $output =~ s/>\s*/>/sg;
    $output =~ s/\s*</</sg;
    $output =~ s/'/\\'/g;

    return <<END_HERE;
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
      <head>
    <script language="JavaScript">
            function updateContent() {
      parent.oEdit1.setBodyFragment('${output}');
            }
      </script>
     </head>
  <body onLoad="updateContent();">
        <h3>Click the 'Preview' tab to view the content, or the 'Content' tab to edit it</h3>
      </body>
    </html>  
END_HERE
}

