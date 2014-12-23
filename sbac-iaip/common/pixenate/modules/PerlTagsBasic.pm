############################################################################
#
# All code copyright (c) Sxoop Technologies 2002-2005
#
############################################################################
package PerlTagsBasic;

require PerlTagsDefault;
use strict;
our @ISA = qw(PerlTagsDefault);
sub debug
  {
    open DEBUG, ">>debug.txt";
    print DEBUG scalar localtime() ."> @_\n";
    close DEBUG;
  }
############################################################################
# 
# Return a hashref containing all of the attributes for the tag.
#
############################################################################
sub getAttributes
  {
    my ($pg, $attrAsString, $delimiter) = @_;
    my %attributes = grep(/\w/i, 
                          split(/([a-z]*?)\s*$delimiter(?!>)/,
                                $attrAsString) );
    foreach my $key (keys %attributes) {
      $key =~ s/\s*$//;
      my $rawValue = $attributes{$key};
      $rawValue =~ s/\s*$//;
      $attributes{$key} = $pg->resolveAttribute($rawValue);
    }
    return \%attributes;
  }
############################################################################
#
# Resolve an attribute to it's true value.
# if an attribute begins with * then it should refer to an existing variable
# or parameter
# if an attribute begins with ? then it will be evaluated.
# 
############################################################################
sub resolveAttribute
  {
    my ($pg,$rawValue) = @_;
    if ($rawValue =~ /^\*[a-z]/i) {
      # it's a variable name
      $rawValue =~ s/^\*//;
      return $pg->getValue(lc $rawValue); 
    } elsif ($rawValue =~ /^\?/) {
      # it should be evaluated
      $rawValue =~ s/^\?//;
      my $evaluated = eval $rawValue;
      die "ERROR: can't evaluate attribute=$rawValue\nfilenames:".
        " @{$pg->{PARSING}}\n$@ $!\n" if ($@);
      return $evaluated;
    } else {
      return $rawValue;
    }
  }
############################################################################
# 
# Handle the tag.
#
############################################################################
sub handleTag {
  my ($pg, $PT_TAG, $PT_BODY,$PT_OUTPUT) = @_;

  my ($tid,$attributes,$d) = split(' ',$PT_TAG, 2);
  ($tid,$d) = split('\=',$tid,2);
  $d = '=' unless ($d);
  my $attrs = $pg->getAttributes($attributes,$d);
  my $handler = $pg->{HANDLERS}->{lc $tid};
  if ($handler) {
    &$handler($pg,$PT_TAG,$attrs,$PT_BODY,$PT_OUTPUT);
  } elsif ($PT_TAG =~ /^\./) {
    $PT_TAG =~ s/^\.// ;
    my $value = $pg->getValue($PT_TAG);
    push @$PT_OUTPUT, ($value);
  } else {
    # pass it on to superclass.
    $pg->SUPER::handleTag($PT_TAG,$PT_BODY,$PT_OUTPUT);
  }
}
############################################################################
#
# Constructor
#
############################################################################
sub new {
  my ($self,$cgi) = @_;
  use CGI;
  $cgi = new CGI() unless ($cgi);

  my $params = $cgi->Vars;

  return PerlTagsDefault::new(shift, 
                              HANDLERS  => {
                                            "esc"        => \&doEscTag,
                                            "replace"    => \&doReplaceTag,
                                            "foreach"    => \&doForeachTag,
                                            "if"         => \&doIfTag,
                                            "include"    => \&doIncludeTag,
                                          #  "database"   => \&doDatabaseTag,
                                          #  "sql"        => \&doSqlTag, 
                                            "while"      => \&doWhileTag,
                                            "read_xml"   => \&doReadXMLTag,
														  "source"     => \&doSourceTag,
                                           },
                              "param"     => $params,
                              "cgi"       => $cgi);
}
sub doComment 
{
  # do nothing
} 
############################################################################
# Allows you to specify your own new tags and handlers or override existing
# tags.
############################################################################
sub setHandler {
  my ($pg,$tagId,$codeRef) = @_;
  $pg->{HANDLERS}->{$tagId} = $codeRef;
}
############################################################################
# get a variable's value
# param1 the variable name
# THis gets called when a non-keyword tag is encountered.
############################################################################
sub getValue {
  my ($pg, $varName) = @_;
  my $temp = $pg->{$varName};
  return $temp if ($temp);
  my @parts = split('\.',$varName);
  my $ref = undef;
  foreach my $part (@parts) {
    unless ($ref){
      $ref = $pg->{$part};
      next;
    }
    if ($part =~ /^\*/) {
      $part =~ s/^\*//;
      $ref = $ref->{$pg->getValue($part)};
    } else {
      if (ref $ref eq '') {
        die "Error: $varName : $ref is not a ref";
      }
      $ref = $ref->{$part};
    }
  }
  return $ref;
}
############################################################################
#
# handle the include tag
# this behaves the same as the #include preprocessor directive
#
############################################################################
sub doIncludeTag {
  my ($pg, $PT_TAG, $attrs,$PT_BODY,$PT_OUTPUT) = @_;
  if ($attrs->{filename} ne '') {
    $pg->preprocessFile($attrs->{filename},$PT_OUTPUT);
    return;
  }
  if ($attrs->{text} ne '') {
    $pg->preprocessText($attrs->{text},$PT_OUTPUT);
    return;
  }
}
############################################################################
#
# handle the source tag
# this behaves the same as the include tag and the esc tag combined
#
############################################################################
sub doSourceTag {
  my ($pg, $PT_TAG, $attrs,$PT_BODY,$PT_OUTPUT) = @_;
  if ($attrs->{filename} ne '') {
	 open (SOURCE, "$pg->{ROOT}$attrs->{filename}") or die "could not open source file $attrs->{filename} from $pg->{ROOT}, $!\n";
	 my @contents = <SOURCE>;
    # print out all the tokens and move on
    foreach my $i (@contents) {
		$i =~ s/</\&lt;/g;
		$i =~ s/ /\&nbsp;/g;
		$i =~ s/\t/\&nbsp;\&nbsp;\&nbsp;/g;
		$i =~ s/\n/<br\/>\n/g;
      push @$PT_OUTPUT, $i;
    }
  }
}
# ############################################################################
# # 
# # Connect to and store connection to a database using DBI interface
# # The name attribute specifies the name of the connection. This can be 
# # used later by the sql tag (referenced using the sql source attribute)
# #
# ############################################################################
# sub doDatabaseTag {
#   my ($pg, $PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;

#   use DBI;
#   my $db_password = $attrs->{password};
#   unless ($db_password){
#     $db_password = $pg->getValue("db_password") ;
#   }
#   if ($db_password) {
#     $pg->{$attrs->{name}}=DBI->connect($attrs->{dsn},
#                                        $attrs->{username},
#                                        $db_password);
#   } else {
#     $pg->{$attrs->{name}}=DBI->connect($attrs->{dsn});
#   }
# }
# ############################################################################
# #
# # Execute a SQL select and store the result for use later by FOR tag. 
# # This tag stores the result (an array of hashes) in the variables key 
# # referenced by the name attribute.
# #
# ############################################################################
# sub doSqlTag {
#   my ($pg, $PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;

#   my ($type, $pname, $db) = split(" ",$PT_TAG);
#   my $sqlBuffer = [];
#   $pg->preprocessTokens($PT_BODY, $sqlBuffer);
    
#   my $sql = join '',@$sqlBuffer;
#   my $sth = $pg->getValue($attrs->{source})->prepare($sql);
#   my $rv = $sth->execute;
#   return unless ($attrs->{name});
#   return unless ($sql =~ /^\s*select/);
#   my @store = ();
#   my $row = $sth->fetchrow_hashref;
#   while ($row) { 
#     push (@store, {%$row}); 
#     $row = $sth->fetchrow_hashref;
#   }
#   $pg->{$attrs->{name}}=\@store;
# }
sub doReplaceTag
  {
    my ($pg, $PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;
    my $tempBuffer = [];
    $pg->preprocessText($PT_BODY,$tempBuffer);
    foreach my $text (@$tempBuffer) {
      foreach (keys %{$attrs->{hash}}) {
        my $find = $_;
        my $replace = $attrs->{hash}->{$find};
        $text =~ s/$find/$replace/g;
      }
    }
    push @$PT_OUTPUT, @$tempBuffer;
  }
############################################################################
#
# The .esc tag allows you to include PerlTags within your code without
# them being interpolated by the PerlTags parser. This will be handy when
# I finally get around to documenting this stuff in HTML.
# 
# param 1 : $ The start of the token array
# param 2 : $ the end of the token array
# param 3 : @ the token array 
# returns $ offset to where processing should resume ...
#           (after the ${./esc} token)
############################################################################
sub doEscTag 
  {
    my ($pg, $PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;

    my ($tagId, $escType) = split(" ",$PT_TAG);
    # print out all the tokens and move on
    foreach my $i (@$PT_BODY) {
      if ($escType && 
          $escType =~ /html/) {
        $i =~ s/</\&lt;/g;
		  $i =~ s/  / \&nbsp;/g;
		  $i =~ s/\n/<br\/>\n/g;
      }
      #print $i;
      push @$PT_OUTPUT, $i;
    }
  }
############################################################################
#
# Handle the .if keyword
# the if tag has 1 attribute
# subroutine : The name of the subroutine that will be called 
# ${.if mySubroutine} will call 'mySubroutine()' and test the return value
# if the return value is non-null, all of the text within this start tag and 
# the closing ${./if} tag will be parsed.
#
# param $ : tag contents e.g. ( .if myConditionFunc)
# param $ : start index of array 
# param $ : end index to finish search at (see findClosingTag())
# param @ : The array of tokens to search
# return : The index where the closing tag was found
############################################################################
sub doIfTag {
  my ($pg, $PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;

  my ($type, $condition) = split(" ", $PT_TAG,2);
  # TODO: handle {@ else @} tag !!!!
  my @body = @$PT_BODY;
  my $lvl = 0;
  my $i = 0;
  my $true = $PT_BODY;
  my $false = [];

  foreach (@body) {
    $lvl++ if (/\{\@\s*if(\s|\@)/i);
    $lvl-- if (/\{\@\s*\/if(\s|\@)/i);
    if (/\{\@\s*else(\s|\@)/i && $lvl == 0) {
      $false = [@body[$i+1..$#body]];
      $true = [@body[0..$i-1]];
      last;
    }
    $i++;
  }
  my $val = eval ($condition);
  die "ERROR: tag=$PT_TAG\nfilenames: ".
    "@{$pg->{PARSING}}\n$@ $!\n" if ($@);
  if ($val) {
    $pg->preprocessTokens($true, $PT_OUTPUT) ;
  } else {
    $pg->preprocessTokens($false, $PT_OUTPUT) ; 
  }
}
############################################################################
#
# Handle the .while keyword
# the while tag has 1 attribute
# subroutine : The name of the subroutine that will be called 
# ${.while mySubroutine} will call 'mySubroutine()' and test the return value
# if the return value is non-null, all of the text within this start tag and 
# the closing ${./while} tag will be parsed. This process will be repeated
# until mySubroutine() returns false
#
# param $ : tag contents e.g. ( .while conditionFunc )
# param $ : start index of array 
# param $ : end index to finish search at (see findClosingTag())
# param @ : The array of tokens to search
# return : The index where the closing tag was found
############################################################################
sub doWhileTag {
  my ($pg,$PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;

  my ($type, $condition) = split(" ", $PT_TAG,2);
  my $val = eval $condition;
  die "ERROR: tag=$PT_TAG\nfilenames: ".
    "@{$pg->{PARSING}}\n$@ $!\n" if ($@);
  while ($val) {
    $pg->preprocessTokens($PT_BODY, $PT_OUTPUT) ;
    $val = eval $condition;
  }
}
############################################################################
#
# Handle the foreach keyword
# the for tag has 2 attributes : 'name' stores the element in named variable
#                                'list' this value will be evaluated, should
#                                evaluate to a list context.
############################################################################
sub doForeachTag
  {
    my ($pg, $PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;

    my $aref = $attrs->{list};
    if (ref $aref ne 'ARRAY') {
      # wph 20030331 : if an array is not passed then just loop once
      my $ref = $aref;
      $aref = [$ref];
    }
    foreach my $item (@$aref) {
      $pg->{$attrs->{name}} = $item;
      $pg->preprocessTokens($PT_BODY, $PT_OUTPUT);
    }
    # once the loop is finished , the variable name should
    # go out of scope.
    delete $pg->{$attrs->{name}};
  }
############################################################################
#
# Read and parse and XML file from 'source' and store dom-like result in 
#  'name'
# example: following creates a table of news from www.xanadb.com
# {@read_xml name=news source=http://www.xanadb.com/rss.xml@}
# <table><tr><td>
#    <a href="{@.news.rss.channel.link@}">{@.news.rss.channel.title@}</a>
#   </td></tr>
# {@foreach name=item list=*news.rss.channel.item@}
# <tr><td>
# <a href="{@.item.link@}">{@.item.title@}</a>
# </td></tr>
# {@/foreach@}
# </table>
############################################################################
sub doReadXMLTag
  {

    my ($pg, $PT_TAG, $attrs, $PT_BODY, $PT_OUTPUT) = @_;
    my $interval = $attrs->{interval} eq ''?0:$attrs->{interval};
    my $cache = $attrs->{source};
    $cache =~ tr/a-zA-Z0-9/_/cs;
    $cache = "var/cache/$cache";
    open CACHE, "<$pg->{ROOT}$cache";
    my @CACHE_CONTENTS = <CACHE>;
    close CACHE;
    my $currentTime = time();
    my $lastModified = shift @CACHE_CONTENTS;
    chomp $lastModified;
    my $xmlBody = join '',@CACHE_CONTENTS;
    my $elapsed = $currentTime - $lastModified;
    # if there are no contents or if the cache is old
    unless (@CACHE_CONTENTS && $elapsed < $interval)
      {
        use LWP::Simple;
        my $response = LWP::Simple::get($attrs->{source});
        if ($response) {
          $xmlBody = $response;
        }
        open CACHE, ">$pg->{ROOT}$cache" or die "Can't open file for output: $pg->{ROOT}/$cache because $!";
        print CACHE "$currentTime\n";
        print CACHE "$xmlBody";
        close CACHE; 
      }
    if ($xmlBody) {
      use Xanadb::XML;
      $pg->{$attrs->{name}} = Xanadb::XML::parseString($xmlBody);
    }
    #
    # delete any files in cache that are older than 1 day
    #
    my @cachedFiles = glob("$pg->{ROOT}var/cache/*");
    foreach (@cachedFiles) {
      open (FH, $_) or die "flushing cache: Could not open file: $_";
      $lastModified = <FH>;
      close FH;
      if ($currentTime - $lastModified > 86400) {
        unlink ($_);
      }
    }
  }

1;
