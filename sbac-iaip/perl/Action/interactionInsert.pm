package Action::interactionInsert;

use URI;
use File::Copy;
use ItemConstants;
use Item;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => join (' ', $q->param($_) ) } $q->param;

  our $debug = 0;

  our $thisUrl    = "${orcaUrl}cgi-bin/interactionInsert.pl";
  
  our $sth;
  our $sql;
  
  # Authorize user (must be user type UT_ITEM_EDITOR)
  our $user = Session::getUser($q->env, $dbh);
  unless ( int( $user->{type} ) == $UT_ITEM_EDITOR )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ];
  }
  
  our $item = new Item($dbh, $in{itemId});
  
  return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
}

### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

  $psgi_out .= <<HTML;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>SBAC IAIP Insert Interaction</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <script language="JavaScript">
    <!--

      function copyInteractionTag (id,type,name) {

        var block_type = (type == $IT_TEXT_ENTRY || type == $IT_INLINE_CHOICE) ? 'span' : 'div';
	var suffix = (type == $IT_TEXT_ENTRY || type == $IT_INLINE_CHOICE) ? '&#160;' : '&#160;';

        var content;

	if(type == $IT_TEXT_ENTRY || type == $IT_INLINE_CHOICE) {
	  content = '<' + block_type + ' style="-ro-editable-inside:true;">'
	          + '<' + block_type + ' class="orca:interaction" id="interaction_' + id 
	          + '" style="-ro-editable-inside:false;font-weight:bold;text-decoration:underline;">' + name 
	          + '</' + block_type + '>'
		  + '</' + block_type + '>';
        } else {
	  content = '<' + block_type + ' class="orca:interaction" id="interaction_' + id  
	          + '" style="font-weight:bold;text-decoration:underline;">' + name
	          + '</' + block_type + '>';
	}
        window.opener.tmpEditorObj.insertContent(content);
	if(type != $IT_TEXT_ENTRY && type != $IT_INLINE_CHOICE) {
          window.opener.tmpEditorObj.invokeAction("move-next-block","null")
        }
        window.opener.tmpEditorObj.insertContent(suffix);
	window.close();
      }

      function removeInteractionTag (id,type,name) {

        var block_type = (type == $IT_TEXT_ENTRY || type == $IT_INLINE_CHOICE) ? 'span' : 'div';

	var match = '//html:body//html:' + block_type + '[\@id="interaction_' + id + '"]'; 
	if(type == $IT_TEXT_ENTRY || type == $IT_INLINE_CHOICE) {
	  match += '/..';
	}
        if(window.opener.tmpEditorObj.select(match)) {
	  //alert('Interaction Found');
	  window.opener.tmpEditorObj.invokeAction("delete-selection","null");   
	} else {
	  alert('Interaction Not Found.');
	}
	window.close();
      }
    -->
    </script>
  </head>
  <body>
    <form name="interactionCreate" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemId" value="$item->{id}" />
    <div class="title">Insert Interaction</div>
    <table class="no-style" border="0" cellpadding="2" cellspacing="2">
      <tr>
        <td>Insert</td>
	<td>Type</td>
	<td>Name</td>
	<td>Delete</td>
      </tr>
HTML

  foreach my $ii_key (keys %{$item->{interactions}}) {

    my $ii = $item->{interactions}{$ii_key};
    my $label = $item_interactions{$ii->{type}};

    $psgi_out .= <<HTML;
      <tr>
        <td><input type="button" value="Insert" onClick="copyInteractionTag($ii_key,$ii->{type},'$label');" /></td>
	<td>$label</td>
	<td>$ii->{name}</td>
        <td><input type="button" value="Delete" onClick="removeInteractionTag($ii_key,$ii->{type},'$label');" /></td>
      </tr>
HTML
  }

  $psgi_out .= <<HTML;
    </table>
    </form>
  </body>
</html>
HTML

  return $psgi_out;
}

1;
