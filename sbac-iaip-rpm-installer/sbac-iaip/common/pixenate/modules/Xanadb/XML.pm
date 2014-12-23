############################################################################
# Copyright (c) 2003, Walter Higgins, All rights reserved.
############################################################################
package Xanadb::XML;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw(parseURL parseFile parseString to_string get_raw get_text set_text value);
#
# expects a string in XML format
# returns a hash ref
#
sub parseString
  {
    my $xml = shift;
	 # massage CDATA sections
	 my @t1 = split (/(<!\[CDATA\[.*?]]>)/s, $xml);
	 my $nxml = "";
	 foreach (@t1){
		if ($_ =~ /<!\[CDATA\[/){
		  $_ =~ s/<!\[CDATA\[//;
		  $_ =~ s/]]>//;
		  $_ =~ s/</&lt;/g;
		  $_ =~ s/>/&gt;/g;
		}
		$nxml .= $_;
	 }
    @tokens = split (/(<.*?>)/s,$nxml);
    walk_xml({},@tokens);
  }
#
# expects a url pointing to XML 
# returns a hash ref
#
sub parseURL
  {
    $url = shift;
    use LWP::Simple;
    $response = LWP::Simple::get($url);
    parseString($response);
  }
#
# expects a filename as a string
# returns a hash ref
#
sub parseFile
  {
    open XML, shift;
    @contents = <XML>;
    close XML;
    $xml = join '',@contents;
    parseString($xml);
  }
#
# parse tokenized XML and return a perl hashref representation
#
sub walk_xml
  {
    my ($tree, @tokens) = @_;
    my $i = 0;
    my $raw = "";
    for (; $i <= $#tokens, ; $i++) {
      # ignore decls comments and closing tags
      next if ($tokens[$i] =~ /^<\//);
      # ignore ws only
      next if ($tokens[$i] =~ /^\s*$/);
      #
      # what about comments and declarations ???
      #
      if ($tokens[$i] =~ /^<!/ || $tokens[$i] =~ /^<\?/) 
		  {
			 $raw .= $tokens[$i];
			 next;
		  }
      if ($tokens[$i] =~ /^<.*?>$/s) {
        # its an element    
        my ($id,$href) = element_to_hash($tokens[$i],$raw);
        $raw = "";
        if ($tokens[$i] !~ /\/>$/) {
          # tag not self contained
          my $nest = 0;
          my $j = $i+1;
          # find closing tag location
          for (; $j <= $#tokens; $j++) {
            $nest++ if ($tokens[$j] =~ /^<$id/ &&
                        $tokens[$j] !~ /\/>$/);
            if ($tokens[$j] =~ /<\/$id/) {
              last if ($nest == 0);
              $nest--;
            }
          }
          # walk the child node
          walk_xml($href,@tokens[$i+1..$j-1]);
          # move on to next node
          $i = $j+1;
        }
      
        # insert the new node into the tree
        my $value = $tree->{$id};
        if ($value) {
          # existing value
          if (ref $value eq 'ARRAY') {
            push @$value, ($href);
          } else {
            $tree->{$id} = [$value,$href];
          }
        } else {
          $tree->{$id} = $href;
        }
      
      } else {
        chomp $tokens[$i];
        set_text($tree,$tokens[$i]);
      }
    }
    $tree;
  }
# convert an XML Tag into a hashref
# xml attributes will be prepended with ':'
# e.g. <person gender="Male" age="32"> will be returned as
# a hash ref with the following key/values...
# :gender=Male
# :age=32
$GUID = 0;
sub element_to_hash
  {
    my $result = {};
    my ($element,$raw) = @_;
    $element =~ s/^<|\/*>$//g;
    ($id) = split /\s/, $element;
    $element =~ s/$id//;
    my %attrs = split /"/, $element;
    my %att2 = ();
    foreach my $key (keys %attrs) {
      next unless (defined $attrs{$key});
      my $value = $attrs{$key};
      $key =~ s/\W//g;
      $att2{$key} = $value;
    }
    foreach (keys %att2) {
      set_attribute($result,$_,$att2{$_}) if ($_ ne '');
    }
    set_raw($result,$raw) if ($raw ne "");
    set_uid($result,$GUID++);
    set_name($result,$id);
    return ($id,$result);
  }
#######################################
# special symbols
#
# # raw text (usually a comment)
# = the element uniqeid (used internally)
# : prefixes each element attribute
# $ text enclosed by an element
# ^ the element name
#
#######################################
sub get_raw{
  my $element = shift;
  $element->{'#'};
}
sub set_raw{
  my ($element, $raw) = @_;
  $element->{'#'} = $raw;
}
sub get_attr_names{
  my $element = shift;
  my @result = grep {/^@/} keys %$element;
  s/^@// foreach (@result);
  @result;
}
sub value{
  get_text(@_);
}
sub get_text{
  my $element = shift;
  $element->{'$'};
}
sub set_text{
  my ($element, $text) = @_;
  $text =~ s/&lt;/</g;
  $text =~ s/&gt;/>/g;
  $text =~ s/&amp;/&/g;
  $text =~ s/&#034;/"/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&#039;/'/g;
  $element->{'$'} = $text;
}
sub set_name{
  my ($element, $name) = @_;
  $element->{'^'} = $name;
}
sub get_name{
  my $element = shift;
  $element->{'^'};
}
sub set_attribute{
  my ($element, $name, $value) = @_;
  $element->{'@'."$name"} = $value;
}
sub get_attribute{
  my ($element, $name) = @_;
  $element->{'@'."$name"};
}
sub set_uid{
  my ($element, $uid) = @_;
  $element->{'='} = $uid;
}
sub get_uid
  {
    $var = shift;
    if (ref $var eq 'HASH') {
      return $var->{'='};
    }
    if (ref $var eq 'ARRAY') {
      return get_uid($var->[0])
    }
    return 0;
  }
sub by_guid{
  $aid = get_uid($a);
  $bid = get_uid($b);
  $aid <=> $bid;
}
#
# return a sorted list of child elements 
# (excluding attributes)
#
sub get_sorted_children{
  my $parent = shift;
  my @vals = values %$parent;
  my @childValues = sort by_guid @vals;
  @childValues = grep { ref $_ eq 'HASH' or ref $_ eq 'ARRAY'} @childValues;
}
# take a hashref and convert it to an xml string
# called recursively to build up an xml string from 
# a hashref
our $indent = 0;

sub to_string{
  my ($element) = @_;
  my $id = get_name($element);
  my $result = get_raw($element);
  $result .= "\n"."  " x $indent . "<$id";
  my @childElements = get_sorted_children($element);
  my @attr_names = get_attr_names($element);
  my $bodyText = get_text($element);

  my $hasBody = (scalar @childElements) + ($bodyText ne ''?1:0);
  # 1st pass - write attr_names
  foreach (@attr_names) {
    my $attr_name = $_;
    my $attr_value = get_attribute($element,$attr_name);
    $result .= " $attr_name=\"$attr_value\"" ;
  }
  $result .= "/" if $hasBody == 0;
  $result .= ">";  

  $result .= get_text($element);
  my $hasNested = scalar @childElements;
  # loop over each child element

  foreach (@childElements) {
    my $child = $_;
    if (ref $child eq 'HASH') {
      $indent++;
      $result .= to_string($child);
      $indent--;
    }
    if (ref $child eq 'ARRAY') {
      foreach (@$child) {
        $indent++;
        $result .= to_string($_);
        $indent--;
      }
    }
  }
  if ($hasBody) {
    $result .= "\n" . "  " x $indent if ($hasNested);
    $result .= "</$id>";
  }
  $result;
}
1;
