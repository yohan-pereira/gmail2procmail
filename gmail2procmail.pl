#Copyright (c) 2013 Yohan Pereira
#
#This software is provided 'as-is', without any express or implied
#warranty. In no event will the authors be held liable for any damages
#arising from the use of this software.
#
#Permission is granted to anyone to use this software for any purpose,
#including commercial applications, and to alter it and redistribute it
#freely, subject to the following restrictions:
#
#   1. The origin of this software must not be misrepresented; you must not
#   claim that you wrote the original software. If you use this software
#   in a product, an acknowledgment in the product documentation would be
#   appreciated but is not required.
#
#   2. Altered source versions must be plainly marked as such, and must not be
#   misrepresented as being the original software.
#
#   3. This notice may not be removed or altered from any source
#   distribution.
use XML::Parser;
use strict;
use warnings;


my $xmlfile = shift @ARGV;              # the file to parse
 
# initialize parser object and parse the string
my $parser = new XML::Parser( Style => 'Tree' );

my $tree = $parser->parsefile( $xmlfile);

parseTree($tree);

=item
process's an entry from the xml file and returns
a procmail rule.
arguments: tag name and the content of the tag.
=cut
sub processEntry
{
  my ($tag, $content) = @_;
  if(!$tag eq "entry") {
    # not a tag
    return 0;
  }
  
  my @attributes;
  for(my $i = 1; $i < $#$content; $i += 2) {
    if(${$content}[$i] eq "apps:property") {
      push(@attributes, ${$content}[$i + 1]);
    }
  }
  return createProcRule(@attributes);
}

=item
creates a proc rule from the given attributes. 
returns 0 if the attributes are not supported.
arguments : an array of hash refrences, that 
contains the values for apps:property key in the 
xml.
=cut

sub createProcRule 
{
  my @attributes = @_;
  my $list_id;
  my $destination;
  foreach(@attributes) {
    my $attr_ref = $_->[0];
    # \b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b
    #print $attr_ref->{"name"} . " " . $attr_ref->{"value"} . "\n";
    if($attr_ref->{"name"} eq "hasTheWord") {
      #extract list id
      if( $attr_ref->{"value"} =~ /list:\W*([A-Za-z0-9._%+-]+)\W*/) {
	$list_id = $1;
      }
    } elsif ($attr_ref->{"name"} eq "label") {
      $destination =  $attr_ref->{"value"} . "/";
      $destination =~ s/\s/-/g
    }
  }
  my $rule =  ""; 
  if($list_id && $destination) {
    #create rule
    $rule = ":0:\n* ^List-ID:.*$list_id\n$destination\n\n";
    print $rule;
  }
  return $rule;
}

sub parseElement
{
  my ($tag, $content) = @_;

  if (ref $content) {
    if($tag eq "entry") {
      processEntry($tag, $content);    
    } else {
      # This is a XML element:
      #$print "<$tag>";           # I'm ignoring attributes
      for (my $i = 1; $i < $#$content; $i += 2) {
        parseElement(@$content[$i, $i+1]);
      }
    }
  } else {

  }
} # end printElement

sub parseTree
{
  # The root tree is always a 2-element array
  # of the root element and its content:
  parseElement(@{ shift @_ });
  print "\n";
}
