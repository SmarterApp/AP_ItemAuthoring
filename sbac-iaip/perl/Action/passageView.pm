package Action::passageView;

use ItemConstants;
use Passage;
use PassageMediaTable qw(View_Mode);
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $psg = new Passage( $dbh, $in{passageId} );

  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );

  unless( $banks->{$psg->{bank}} ) {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ]];
  } 

  return [ $q->psgi_header('text/html'), [ &print_show_passage() ]];
}

### ALL DONE! ###

sub print_show_passage {

    my $genreName = $genres{ $psg->{genre} };
    my $content   = $psg->getContent();
    my $accessibilityData = $psg->{accessibilityData};
    
    my $onLoad    = exists( $in{print} ) ? 'window.print();' : '';

    my $footnoteText = $psg->getFootnotesAsHtml();
    my $bankName     = $psg->{bankName};

    my $mediaTable = new PassageMediaTable();

    return <<END_HERE;
<!DOCTYPE html> 
<html>
  <head>
    <title>View Passage</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css" />
    @{[$mediaTable->get_style_library_includes()]}
    @{[$mediaTable->get_js_library_includes(1)]}
    <script language="JavaScript">
    <!--
      \$(document).ready(function() {
          @{[$mediaTable->get_jquery_ready_function()]}
        }
      );

      function myOpenTTS(name, url, w, h) {
            var myWin = window
                    .open(
                            url,
                            name,
                            'width='
                                    + w
                                    + ',height='
                                    + h
                                    + ',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        
            return false;
    }  
    
    function showData() {
                var s =jQuery('#passageAccessibility').html();
        jQuery.each(JSON.parse(s), function(idx, myObject) {
        
                var name = myObject.name;
                var linkType = myObject.linkType;
                var textType = myObject.textType;
                var word = myObject.word;
                var info = myObject.info;
                var wordid =  myObject.name+''+myObject.word;
                var parentElement = jQuery('#'+myObject.name);

                if(linkType == 2 || (linkType == 1 && textType == 1)) {
                   parentElement.css( 'cursor', 'pointer' );
                   //parentElement.css( 'background-color', 'yellow' );
                   parentElement.click(function() { 
                    myOpenTTS('TTSPreview'+wordid,'/orca-sbac/TextToSpeechPreview.jsf?text='+encodeURI(info),450,100);
                  });
            } else if(linkType == 1 && textType == 3) {
                 var text = parentElement.text().split(' ');
                 for( var w = 0; w < text.length; w++ ) {
                 if(w == (word-1)) {
                   text[w] = '<a id="'+ wordid +'" style="text-decoration:none;cursor:pointer;">' + text[w] + '</a>';
                 }
            }
                  parentElement.html(text.join(' '));
                  var element = jQuery('#'+wordid);
                  element.click(function() { 
                   myOpenTTS('TTSPreview'+wordid,'/orca-sbac/TextToSpeechPreview.jsf?text='+encodeURI(info),450,100); 
                  });
            }
        });
    }

      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(350,150); 
	return true; 
      }
    //-->
    </script>
  </head>
  <body onLoad="${onLoad}">
    <table border="0" cellpadding="0" cellspacing="0" class="no-style">
    <tr><td>
      <table class="no-style" border="0" cellpadding="3" cellspacing="3">
        <tr><td><span class="text">Name:</span></td><td>$psg->{name}</td></tr> 
        <tr><td><span class="text">Genre:</span></td><td>${genreName}</td></tr>
      </table>
    </td></tr>
    <tr><td>
      ${content}
    </td></tr>
    <tr><td>
    <div id="passageAccessibility" style="display:none;"> 
       ${accessibilityData}
     </div>
      @{[$mediaTable->draw($psg, $mediaTable->find_media_for_passage($psg), View_Mode)]}
    </td></tr>
    <tr><td>
      <hr />
    </td></tr>
    <tr><td>
      ${footnoteText}
    </td></tr>
    </table>
  </body>
</html>
END_HERE
}
1;
