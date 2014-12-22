############################################################################
#
# PerlTags 
# Walter Higgins walterh@rocketmail.com
# This is a simple light-weight way of providing custom tags in HTML.
# It is similar in principle to JSP and PHP. The intent is to provide
# A CGI mechanism that doesn't require writing lots of embedded HTML in 
# perl code nor the opposite (the equally evil lots-of-perl/php/java 
# in html code). 
# The emphasis is on Lightweight and Simple, so there is _NO_ error
# handling code as yet.
#
# 20021206 : split code into 2 modules, PerlTagsDefault just dispatches
#            tags via the handleTag method. Subclasses (PerlTagsBasic)
#            Do the heavy lifting of handling individual tags.
#
############################################################################
package PerlTagsDefault;
require Exporter;
use strict;
our @ISA = ("Exporter");
our $VERSION = 0.11;
############################################################################
# 
# Constructor:
#
############################################################################
sub new 
{
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = { @_ };
  bless ($self, $class);
  return $self;
}
sub process {
  my ($self,%params) = @_;
  if (exists $params{filename}){
	 $self->preprocessFile($params{filename},$params{output});
  }
}
############################################################################
#
# preprocess an input file. The file is opened, split into tokens and 
# to preprocessTokens
#
############################################################################
sub preprocessFile 
{
  my ($pg, $inputFile,$PT_OUTPUT) = @_;
  my $buffered = 1;
  unless ($PT_OUTPUT){
	 $buffered = 0;
	 $PT_OUTPUT = [];
  }
  my $template_files = $pg->{PARSING};
  $template_files = [] unless ($template_files);
  # wph 20030219 : check for recursive includes/preprocessing
  foreach (@{$template_files}){
	 if ($_ eq $inputFile){
		die "Can't preprocess recursively (files:@{$template_files}) $!";
	 }
  }
  push @$template_files, ($inputFile);
  $pg->{PARSING} = $template_files;
  use Cwd;
  open (FH, "$pg->{ROOT}$inputFile") or die "Can't open file $pg->{ROOT}$inputFile: (from @$template_files) $! (cwd=" . cwd() . ")";
  my $bodyRef = [<FH>];
  close FH;
  $pg->preprocessText($bodyRef,$PT_OUTPUT);
  pop @$template_files;
  $pg->{PARSING} = $template_files;
  # 
  # if not buffered then output buffer contents now
  #
  unless ($buffered){
	 print join ('',@$PT_OUTPUT);
  }
  return 1;
}
sub preprocessText
{
  my ($pg, $bodyRef, $PT_OUTPUT) = @_;
  my @PT_TOKENS = split (/(\{\@.*?\@})/s, join('',@$bodyRef));
  
  $pg->preprocessTokens(\@PT_TOKENS,$PT_OUTPUT);
}
############################################################################
#
# preprocess an array of tokens. This is the main driver for this class.
# this method is also called by for/if/while etc block tags.
#
############################################################################
sub preprocessTokens 
{
    my ($pg, $PT_TOKENS,$PT_OUTPUT) = @_;
    my $i = 0;
    my $last = scalar @$PT_TOKENS -1;


    while ($i <= $last){ # while not at end-of-array
		my $tkn = @$PT_TOKENS[$i];
		chomp $tkn;
		if ($tkn =~ /\{\@.*?\@}/s){ # is token a tag ?
		
		  # tag of the form ${...} encountered
		  my $PT_TAG = $tkn;
		  # strip away shell ...
		  $PT_TAG =~ s/\{\@\s*|\s*\@}//g; 
		  
		  my $ei = indexOfClosingTag($pg,
											  $PT_TAG,
											  @$PT_TOKENS[$i..$last]) + $i;
		  if ($ei > $last){
			 $pg->handleTag($PT_TAG,[],$PT_OUTPUT);
		  }else{
			 $pg->handleTag($PT_TAG,
								 [@$PT_TOKENS[$i+1..$ei-1]],
								 $PT_OUTPUT);
			 $i = $ei;
		  }
		}else{
		  push @$PT_OUTPUT,$tkn;
		  #print $tkn;
		}
		$i++;
    }
  }
############################################################################
#
# Find the closing tag if there is one.
#
############################################################################
sub indexOfClosingTag {

  my ($pg, $PT_TAG, @PT_TOKENS) = @_;
  ($PT_TAG) = split(" ",$PT_TAG); # get element id
  ($PT_TAG) = split('\=',$PT_TAG); # remove delimiter suffix if any
  my $i = 1; # start from next element in array
  my $lvl = 0;

  while ($i <= $#PT_TOKENS){ # while not at end-of-array
	 my $tkn = $PT_TOKENS[$i];
	 if ($tkn =~ /\{\@\s*$PT_TAG(\s|\@)/i){
	 
		$lvl++;
	 }
	 if ($tkn =~ /\{\@\s*\/$PT_TAG(\s|\@)/i){
	 
		last if ($lvl eq 0);
		$lvl--;
	 }
	 $i++;
  }
  return $i;
}
############################################################################
#
# handleTag method is passed the tag and any body attached to the tag
#
############################################################################
sub handleTag 
{
  my ($pg, $PT_TAG,$PT_BODY,$PT_OUTPUT) = @_;
  if ($PT_TAG =~ /^\#$/){
	 # do nothing - it's a comment
  }else{
	 my @result = eval ($PT_TAG);
	 if ($@){
		push @$PT_OUTPUT, "ERROR: cant evaluate: $PT_TAG\n" ;
		my @pageStack = @{$pg->{PARSING}};
		my $badPage = $pageStack[$#pageStack];
		die "Evaluation of perl code failed on page $badPage: \n-----$PT_TAG\n----$!\n$@";
	 }else{
		push @$PT_OUTPUT, @result;
	 }
  }
}

1;
