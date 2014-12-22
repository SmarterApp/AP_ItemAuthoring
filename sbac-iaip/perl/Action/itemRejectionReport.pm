package Action::itemRejectionReport;

use URI;
use URI::Escape;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $requestFile =
  "${orcaPath}workflow/rejection-report/state-$in{rejectState}/$in{itemId}.html";
  
  if ( $in{myAction} eq 'put' ) {
  
      if ( defined $in{createReport} ) {
  
          # Save the form in an HTML template
  
          if ( $in{rejectState} eq '1' ) {
  
              my $standardMatch = ( defined $in{standardMatch} ? 'CHECKED' : '' );
              my $standardAssessment =
                ( defined $in{standardAssessment} ? 'CHECKED' : '' );
              my $acCorrect    = ( defined $in{acCorrect}    ? 'CHECKED' : '' );
              my $acDistractor = ( defined $in{acDistractor} ? 'CHECKED' : '' );
              my $acMultiple   = ( defined $in{acMultiple}   ? 'CHECKED' : '' );
              my $acRationale  = ( defined $in{acRationale}  ? 'CHECKED' : '' );
              my $langSpelling = ( defined $in{langSpelling} ? 'CHECKED' : '' );
              my $langGrammar  = ( defined $in{langGrammar}  ? 'CHECKED' : '' );
              my $langWords    = ( defined $in{langWords}    ? 'CHECKED' : '' );
              my $langGrade    = ( defined $in{langGrade}    ? 'CHECKED' : '' );
              my $langPunc     = ( defined $in{langPunc}     ? 'CHECKED' : '' );
              my $styleReq     = ( defined $in{styleReq}     ? 'CHECKED' : '' );
              my $styleStem    = ( defined $in{styleStem}    ? 'CHECKED' : '' );
              my $styleFormat  = ( defined $in{styleFormat}  ? 'CHECKED' : '' );
              my $contextGrade = ( defined $in{contextGrade} ? 'CHECKED' : '' );
              my $contextPlaus = ( defined $in{contextPlaus} ? 'CHECKED' : '' );
              my $graphicsTool = ( defined $in{graphicsTool} ? 'CHECKED' : '' );
              my $graphicsRequest =
                ( defined $in{graphicsRequest} ? 'CHECKED' : '' );
              my $otherMissingComp =
                ( defined $in{otherMissingComp} ? 'CHECKED' : '' );
              my $otherOther = ( defined $in{otherOther} ? 'CHECKED'       : '' );
              my $otherNotes = ( defined $in{otherNotes} ? $in{otherNotes} : '' );
  
              open OUTFILE, ">${requestFile}";
              print OUTFILE <<END_HERE;
    <html>
      <head>
        <title>Rejection Report for Item $in{itemName}</title>
      </head>
      <body>
        <h3>Rejection Report for Item $in{itemName}</h3>
        <table border="0" cellpadding="2" cellspacing="2">
         <tr>
    		   <td colspan="2" align="left">Standard</td>
    		 </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="standardMatch" value="yes" ${standardMatch} /></td>
    			 <td valign="top">Standard match (<span style="color:red;">the item does not assess the given standard</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="standardAssessment" value="yes" ${standardAssessment} /></td>
    			 <td>Authentic assessment of standard (<span style="color:red;">the item does not use skills that would be addressed while understanding this standard in real-world situations, including the classroom</span>)</td>
         </tr>
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
         <tr>
    		   <td colspan="2" align="left">Answer Choices</td>
    		 </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acCorrect" value="yes" ${acCorrect} /></td>
    			 <td valign="top">Correct response (<span style="color:red;">the correct response is not correct</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acDistractor" value="yes" ${acDistractor} /></td>
    			 <td>Distractor plausibility (<span style="color:red;">any or all of the distractors are not plausible and/or are not common errors committed by students</span>)</td>
         </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acMultiple" value="yes" ${acMultiple} /></td>
    			 <td valign="top">Multiple correct responses (<span style="color:red;">there is more than one possible correct response</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acRationale" value="yes" ${acRationale} /></td>
    			 <td valign="top">Rationales (<span style="color:red;">the distractors need rationales</span>)</td>
         </tr>  
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
         <tr>
    		   <td colspan="2" align="left">Language</td>
    		 </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langSpelling" value="yes" ${langSpelling} /></td>
    			 <td valign="top">Spelling (<span style="color:red;">there are spelling errors</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langGrammar" value="yes" ${langGrammar} /></td>
    			 <td>Grammar (<span style="color:red;">there are grammar errors</span>)</td>
         </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langWords" value="yes" ${langWords} /></td>
    			 <td valign="top">Wordiness (<span style="color:red;">the item does not conform to guidelines set for the specific project</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langGrade" value="yes" ${langGrade} /></td>
    			 <td valign="top">Grade level vocabulary (<span style="color:red;">the item contains vocabulary that is above the given grade level</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langPunc" value="yes" ${langPunc} /></td>
    			 <td valign="top">Punctuation (<span style="color:red;">there are punctuation errors</span>)</td>
         </tr>  
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
         <tr>
    		   <td colspan="2" align="left">Style</td>
    		 </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="styleReq" value="yes" ${styleReq}/></td>
    			 <td valign="top">Style requirements (<span style="color:red;">the item does not conform to guidelines set for the specific project</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="styleStem" value="yes" ${styleStem}/></td>
    			 <td>Open-ended stem (<span style="color:red;">the item has an open-ended stem</span>)</td>
         </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="styleFormat" value="yes" ${styleFormat} /></td>
    			 <td valign="top">Question format (<span style="color:red;">the item is not in proper question format</span>)</td>
         </tr>  
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
         <tr>
    		   <td colspan="2" align="left">Context</td>
    		 </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="contextGrade" value="yes" ${contextGrade} /></td>
    			 <td valign="top">Grade level appropriate (<span style="color:red;">the context is not appropriate for the given grade level</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="contextPlaus" value="yes" ${contextPlaus} /></td>
    			 <td>Plausibility (<span style="color:red;">the context is forced and/or is not plausible in real-world situations</span>)</td>
         </tr>
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
         <tr>
    		   <td colspan="2" align="left">Graphics</td>
    		 </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="graphicsTool" value="yes" ${graphicsTool} /></td>
    			 <td valign="top">Use of Asymptote tool (<span style="color:red;">graphics are not included and/or are incorrect</span>)</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="graphicsRequest" value="yes" ${graphicsRequest} /></td>
    			 <td>Art request form (<span style="color:red;">the form is blank, incomplete, or incorrect</span>)</td>
         </tr>
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
         <tr>
    		   <td colspan="2" align="left">Other</td>
    		 </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="otherMissingComp" value="yes" ${otherMissingComp} /></td>
    			 <td valign="top">Missing Components</td>
         </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top"><input type="checkbox" name="otherOther" value="yes" ${otherOther} /></td>
    			 <td>Other</td>
         </tr>
    		 <tr>
    		   <td width="60px" align="right" valign="top">Notes:</td>
    			 <td><textarea name="otherNotes" rows="4" cols="55">${otherNotes}</textarea></td>
         </tr>
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
        <tr><td colspan="2"><input type="button" value="Close" onClick="window.close();" /></td></tr>
        </table>
      </body>
    </html>  
END_HERE
              close OUTFILE;
          }
          elsif ( $in{rejectState} eq '9' ) {
              my $standard   = ( defined $in{standard}   ? 'CHECKED'       : '' );
              my $content    = ( defined $in{content}    ? 'CHECKED'       : '' );
              my $context    = ( defined $in{context}    ? 'CHECKED'       : '' );
              my $technical  = ( defined $in{technical}  ? 'CHECKED'       : '' );
              my $other      = ( defined $in{other}      ? 'CHECKED'       : '' );
              my $otherNotes = ( defined $in{otherNotes} ? $in{otherNotes} : '' );
  
              open OUTFILE, ">${requestFile}";
              print OUTFILE <<END_HERE;
    <html>
      <head>
        <title>Client Review Rejection Report for Item $in{itemName}</title>
      </head>
      <body>
        <h3>Client Review Rejection Report for Item $in{itemName}</h3>
        <table border="0" cellpadding="2" cellspacing="2">
  		 <tr>
  		   <td width="60px" align="right" valign="top"><input type="checkbox" name="standard" ${standard} value="yes" /></td>
  			 <td valign="top">Standard</td>
       </tr>  
  		 <tr>
  		   <td width="60px" align="right" valign="top"><input type="checkbox" name="content" ${content} value="yes" /></td>
  			 <td valign="top">Content</td>
       </tr>  
  		 <tr>
  		   <td width="60px" align="right" valign="top"><input type="checkbox" name="context" ${context} value="yes" /></td>
  			 <td valign="top">Context</td>
       </tr>  
  		 <tr>
  		   <td width="60px" align="right" valign="top"><input type="checkbox" name="technical" ${technical} value="yes" /></td>
  			 <td valign="top">Technical issues</td>
       </tr>  
  		 <tr>
  		   <td width="60px" align="right" valign="top"><input type="checkbox" name="other" ${other} value="yes" /></td>
  			 <td valign="top">Other</td>
       </tr>  
    		 <tr>
    		   <td width="60px" align="right" valign="top">Notes:</td>
    			 <td><textarea name="otherNotes" rows="4" cols="55">${otherNotes}</textarea></td>
         </tr>
    		 <tr><td colspan="2">&nbsp;<br /></td></tr>
        <tr><td colspan="2"><input type="button" value="Close" onClick="window.close();" /></td></tr>
        </table>
      </body>
    </html>  
END_HERE
              close OUTFILE;
          }
  
          my $onLoad = 'closeWindow();';
          if ( $in{submitForm} eq 'yes' ) {
              $onLoad = 'submitParentForm();';
          }
  
          $in{language} = 1 unless exists $in{language};
  
          my $psgi_out = <<END_HERE;
  <html>
    <head>
      <title></title>
      <script language="JavaScript">
        function submitParentForm() {
          window.opener.document.form1.submit();
  	      window.opener.parent.menuFrame.location='${orcaUrl}cgi-bin/itemApproveMenu.pl?language=$in{language}&itemBankId=$in{itemBankId}';
          window.close();
        }
  
        function closeWindow() {
          window.close();
        }	
      </script>
    </head>
    <body onLoad="${onLoad}">
    </body>
  </html>  
END_HERE
        return [ $q->psgi_header('text/html'), [ $psgi_out ]]; 
      }
      else {
  
          $sql =
  "SELECT t1.*, (SELECT ic_value FROM item_characterization WHERE ic_type=${OC_GRADE_LEVEL} AND i_id=t1.i_id) AS grade_level FROM item AS t1 WHERE t1.i_id="
            . $dbh->quote( $in{itemId} );
          $sth = $dbh->prepare($sql);
          $sth->execute();
          if ( my $row = $sth->fetchrow_hashref ) {
              $in{itemBankId} = $row->{ib_id};
              $in{itemName}   = $row->{i_external_id};
              $in{gradeLevel} = $row->{grade_level};
          }
	  return [ $q->psgi_header('text/html'), [ &print_put_welcome(\%in) ]];
      }
  }
  elsif ( $in{myAction} eq 'get' ) {
  
      
  
      # Print the saved HTML template
      my $psgi_out = '';
  
      if(-e $requestFile) {
  
        open INFILE, "<${requestFile}";
        while (<INFILE>) {
          $psgi_out .= $_;
        }
        close INFILE;
      } else {
  
        $psgi_out .= <<HTML;
        <html>
          <head>
  	  <title>Rejection Report Not Available</title>
          </head>
  	<body>
  	<h3>Rejection Report Not Available</h3>
  	<p>A Rejection Report was not completed for this item.</p>
          </body>
         </html>
HTML
      }
      return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
}  

### ALL DONE! ###

sub print_put_welcome {
  my $psgi_out = '';

    my $params     = shift;
    my $itemId     = $params->{itemId};
    my $itemBank   = $params->{itemBank};
    my $itemBankId = $params->{itemBankId};
    my $itemName   = $params->{itemName};
    my $gradeLevel = $params->{gradeLevel};

    $psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Rejection Report for Item $in{itemName}</title>
  </head>
  <body>
   <form name="form1" action="itemRejectionReport.pl" method="POST">
     
     <input type="hidden" name="itemBank" value="${itemBank}" />
     <input type="hidden" name="itemBankId" value="${itemBankId}" />
     <input type="hidden" name="itemId" value="${itemId}" />
     <input type="hidden" name="itemName" value="${itemName}" />
     <input type="hidden" name="gradeLevel" value="${gradeLevel}" />
     <input type="hidden" name="submitForm" value="$in{submitForm}" />
     <input type="hidden" name="rejectState" value="$in{rejectState}" />
     <input type="hidden" name="myAction" value="put" />
     <input type="hidden" name="createReport" value="" />
END_HERE

    if ( $in{rejectState} eq '1' ) {

        $psgi_out .= <<END_HERE;
    <h3>Rejection Report for Item $in{itemName}</h3>
    <table border="0" cellpadding="2" cellspacing="2">
     <tr>
		   <td colspan="2" align="left">Standard</td>
		 </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="standardMatch" value="yes" /></td>
			 <td valign="top">Standard match (<span style="color:red;">the item does not assess the given standard</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="standardAssessment" value="yes" /></td>
			 <td>Authentic assessment of standard (<span style="color:red;">the item does not use skills that would be addressed while understanding this standard in real-world situations, including the classroom</span>)</td>
     </tr>
		 <tr><td colspan="2">&nbsp;<br /></td></tr>
     <tr>
		   <td colspan="2" align="left">Answer Choices</td>
		 </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acCorrect" value="yes" /></td>
			 <td valign="top">Correct response (<span style="color:red;">the correct response is not correct</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acDistractor" value="yes" /></td>
			 <td>Distractor plausibility (<span style="color:red;">any or all of the distractors are not plausible and/or are not common errors committed by students</span>)</td>
     </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acMultiple" value="yes" /></td>
			 <td valign="top">Multiple correct responses (<span style="color:red;">there is more than one possible correct response</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="acRationale" value="yes" /></td>
			 <td valign="top">Rationales (<span style="color:red;">the distractors need rationales</span>)</td>
     </tr>  
		 <tr><td colspan="2">&nbsp;<br /></td></tr>
     <tr>
		   <td colspan="2" align="left">Language</td>
		 </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langSpelling" value="yes" /></td>
			 <td valign="top">Spelling (<span style="color:red;">there are spelling errors</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langGrammar" value="yes" /></td>
			 <td>Grammar (<span style="color:red;">there are grammar errors</span>)</td>
     </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langWords" value="yes" /></td>
			 <td valign="top">Wordiness (<span style="color:red;">the item does not conform to guidelines set for the specific project</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langGrade" value="yes" /></td>
			 <td valign="top">Grade level vocabulary (<span style="color:red;">the item contains vocabulary that is above the given grade level</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="langPunc" value="yes" /></td>
			 <td valign="top">Punctuation (<span style="color:red;">there are punctuation errors</span>)</td>
     </tr>  
		 <tr><td colspan="2">&nbsp;<br /></td></tr>
     <tr>
		   <td colspan="2" align="left">Style</td>
		 </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="styleReq" value="yes" /></td>
			 <td valign="top">Style requirements (<span style="color:red;">the item does not conform to guidelines set for the specific project</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="styleStem" value="yes" /></td>
			 <td>Open-ended stem (<span style="color:red;">the item has an open-ended stem</span>)</td>
     </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="styleFormat" value="yes" /></td>
			 <td valign="top">Question format (<span style="color:red;">the item is not in proper question format</span>)</td>
     </tr>  
		 <tr><td colspan="2">&nbsp;<br /></td></tr>
     <tr>
		   <td colspan="2" align="left">Context</td>
		 </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="contextGrade" value="yes" /></td>
			 <td valign="top">Grade level appropriate (<span style="color:red;">the context is not appropriate for the given grade level</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="contextPlaus" value="yes" /></td>
			 <td>Plausibility (<span style="color:red;">the context is forced and/or is not plausible in real-world situations</span>)</td>
     </tr>
		 <tr><td colspan="2">&nbsp;<br /></td></tr>
     <tr>
		   <td colspan="2" align="left">Graphics</td>
		 </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="graphicsTool" value="yes" /></td>
			 <td valign="top">Use of Asymptote tool (<span style="color:red;">graphics are not included and/or are incorrect</span>)</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="graphicsRequest" value="yes" /></td>
			 <td>Art request form (<span style="color:red;">the form is blank, incomplete, or incorrect</span>)</td>
     </tr>
		 <tr><td colspan="2">&nbsp;<br /></td></tr>
     <tr>
		   <td colspan="2" align="left">Other</td>
		 </tr>
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="otherMissingComp" value="yes" /></td>
			 <td valign="top">Missing Components</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="otherOther" value="yes" /></td>
			 <td>Other</td>
     </tr>
END_HERE
    }
    elsif ( $in{rejectState} eq '9' ) {

        $psgi_out .= <<END_HERE;
    <h3>Client Review Rejection Report for Item $in{itemName}</h3>
    <table border="0" cellpadding="2" cellspacing="2">
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="standard" value="yes" /></td>
			 <td valign="top">Standard</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="content" value="yes" /></td>
			 <td valign="top">Content</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="context" value="yes" /></td>
			 <td valign="top">Context</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="technical" value="yes" /></td>
			 <td valign="top">Technical issues</td>
     </tr>  
		 <tr>
		   <td width="60px" align="right" valign="top"><input type="checkbox" name="other" value="yes" /></td>
			 <td valign="top">Other</td>
     </tr>  
END_HERE
    }

    $psgi_out .= <<END_HERE;
		 <tr>
		   <td width="60px" align="right" valign="top">Notes:</td>
			 <td><textarea name="otherNotes" rows="4" cols="55"></textarea></td>
     </tr>
		 <tr><td colspan="2">&nbsp;<br /></td></tr>
    <tr>
      <td>&nbsp;</td>
      <td>
      <input type="submit" value="Submit Rejection Report" />
      </td>
     </tr>
   </table>             
   </form>
  </body>
</html>         
END_HERE
  return $psgi_out;
}
1;
