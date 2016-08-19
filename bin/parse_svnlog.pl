#!/usr/bin/perl -w 
#########################################################################
#
# This script creates output in text format from svn xml log
#
#########################################################################
#
# 'logentry' => [
#      {
#       'msg' => 'correct small typo',
#       'revision' => '515',
#       'date' => '2011-01-17T14:27:52.634120Z',
#       'author' => 'dems8888',
#       'paths' => {
#                   'path' => [
#                              {
#                               'kind' => 'file',
#                               'content' => '/2009_07/trunk/I_Interface/Platform_Env/CCS_ENV/ServiceInterface/IPDriver_interface.h',
#                               'action' => 'M'
#                              }
#                             ] 
#                  }
#      }
# ]
#
#########################################################################

use strict;
use Data::Dumper;
use XML::Simple;
$| = 1;   # OUTPUT_AUTOFLUSH

if (!defined $ARGV[2])
{
  print ("MISSING PARAMETER!\nUSAGE: $0 <revision number new> <revision number old> <branch> [<selector>]\n");
  print ("if selector defined only interface changes will be printed out\n"); 
  exit(-1);
}

my $log = `svn log -v -g --xml -r$ARGV[1]:$ARGV[0] $ARGV[2]`;
if ( $? != 0 ) { exit 1 }

my $ref;
my $found = "false";
eval { $ref = XMLin($log, ForceArray=> qr/^(logentry|path)$/); };
die "Cannot read xml output of svn log -v -g --xml -r$ARGV[0]HEAD:$ARGV[1]: $@" if($@);
#print Dumper($ref);
foreach my $e (@{ $ref->{'logentry'} }) {
  my @xmls;
  foreach my $p (@{ $e->{'paths'}->{'path'} }) {
    if ($p->{'kind'} =~ /file/)    {$p->{'content'} =~ s/^/File    : $p->{'action'} /mg;}
    elsif ($p->{'kind'} =~ /dir/)  {$p->{'content'} =~ s/^/Dir     : $p->{'action'} /mg;}
    else                           {$p->{'content'} =~ s/^/Path    : $p->{'action'} /mg;}
    push @xmls, $p->{'content'};
  }
#printf "DEBUG: arr %s, dump %s\n", join(", ", @xmls), Dumper($e->{'paths'}->{'path'});
  next unless @xmls;

  my $interface = "false";
  foreach my $i (@xmls) {    
    if ($i =~ /I_Interface\/Platform_Env/) {
      $interface = "true";
    }
  }

  if ( $interface eq "true" || !defined $ARGV[3]) {  # if ARGV[3] print out only interfaces
    print "\n------------------------------------------------------------\n";
    printf "Revision: %s\n", $e->{'revision'};
    printf "Author  : %s\n", $e->{'author'};
    printf "Date    : %s\n", $e->{'date'};

    # substitute all non-ascii characters and html specific characters
    # substitute in HOOK keywords the character % with #
    for($e->{'msg'}) {
      s/[^[:ascii:]]/"/g;
      s/&/&amp;/g; s/'/&apos;/g; s/</&lt;/g; s/>/&gt;/g; s/"/&quot;/g;
#      s/%FIN/#FIN/g; s/%TBC/#TBC/g; s/%BCK/#BCK/g; s/%REM/#REM/g;
#      s/%PR/#PR/g; s/%NF/#NF/g; s/%CN/#CN/g;
    }

    # distinguish between new or old syntax
    if ($e->{'msg'} =~ /^%/ | $e->{'msg'} =~ /[\n\r]%/ ) {
      #print "\nDEBUG: ====> NEW STYLE\n";
      printf "%s\n", join("\n", @xmls);
      my @messages = split('\n', $e->{'msg'});
      foreach my $i (@messages) {
        print "Item    : $i\n";
      }
    } else {
      #print "\nDEBUG: ====> OLD STYLE\n";
      $e->{'msg'} =~ s/\n/ /g;                 # remove new line in msg text
      if ($e->{'msg'} =~ /^[A-Z]*-[0-9]* /) { $e->{'msg'} =~ s/^/Item    : /mg; }
      else                                  { $e->{'msg'} =~ s/^/Text    : /mg; }
      printf "%s\n", join("\n", @xmls);
      print "$e->{'msg'}";
    }
    $interface = "false";
  }
}
print "\n------------------------------------------------------------\n";

#########################################################################
