#!/usr/bin/perl

###############################################################################
#
#  make-manualbot.pl
#
#  Copyright 2004 by tarquin <tarquin@planetjailbreak.com>
#  $Id: make-manualbot.pl,v 1.1.2.3 2004/05/25 21:16:45 tarquin Exp $
#
#  Jailbreak manual maker bot
#  Automatically creates the manual HTML files, reading the text from the JDN.
#

# manual bot has an account on JDN: 
#   user id 1157
#   randkey=147247314

use warnings;
use v5.8.0;

use LWP::UserAgent;
use HTTP::Cookies;
use File::Slurp;

#################################### configuration

$platform = 'ut2003'; # what platform are you creating the manual for? (you can override this with the command line)

#### read

  # URL of the wiki
  $baseURL      = q[http://mychaeel.no-ip.com/jailbreak/]; 

  # all subpages of this page are taken as manual pages
  $parentPage   = q[Manual];
  
  # action URLs for this wiki
  $pageURL      = qq[keywords=$parentPage/%&embed=1];

  # file to use as template
  $templateFile = q[manual-template.html];

#### write

  # where to write manual files
  $baseDir      = q[Help\Jailbreak\\]; # you need a double \\ at the end for perl

  # base url to write into IMG tags
  $imagesURL    = q[Images/];

#################################### command line options

foreach (@ARGV) {
  /-(ut200[34])/ and do {
    $platform = $1;
    print "overriding configuration: platform is $1\n";
  };
  /-p-(\w+)/ and do {
    $soloPage = ucfirst($1);
    print "requested single page: $1\n";
  };
}

#################################### definitions

sub bounce (\@@) {
  my $bouncearrayref = shift;
  my @bouncearray = @$bouncearrayref;
  my @result;
  while (@bouncearray) {
    push @result, shift @bouncearray;
    push @result, shift;
  }
  return @result, @_;
}

#################################### OO

$cookie_jar = HTTP::Cookies->new;
$cookie_jar->set_cookie(1, 'JDN', 'rev&1&id&1157&randkey&147247314', '/', 'mychaeel.no-ip.com');

$ua = LWP::UserAgent->new(
  cookie_jar => $cookie_jar,
);

#################################### setup

# get *ordered* list of page names

@pageNames =
  $ua->get("$baseURL$parentPage")->{_content}
    =~ m[<a href="/jailbreak/Manual/(.*?)">]g;
    
print 'Found pages: ', join ', ', @pageNames, "\n" unless $soloPage;

@templateHtml = split m[%title%|%links%|%content%], read_file($templateFile);

#################################### generate
foreach $wikiname ( $soloPage or @pageNames ) { 
  $wikiname =~ s/ /_/m;
  
  ########## read content from the web
  
  my $url = $baseURL . $pageURL;
  $url =~ s[%][$wikiname];

  # read content from the web
  ($content) = 
    $ua->get($url)->{_content} 
      =~ m[<div class="wiki-content">(.*)</div>]s;
      
  #die unless $content;    
  
  ########## formatting
  
  for ($content) {
    # some variables for regexps 
    my %unwantedplatform = qw[ ut2003 ut2004 ut2004 ut2003 ]; # just gives the opposite of the desired platform
    my $internalLinks = join '|', @pageNames;
    
    ### text labelled as "Title:" in wikisource becomes html page title
    s[^<p>Title:(.*?)</p>]{
      $pagetitle = $1;
      qq[<h1>$pagetitle</h1>];
      }ei; 

    ### make links pretty
    # section links
    s
      {<a href="http://mychaeel.no-ip.com/jailbreak/Manual/($internalLinks)#(.*?)">\[(.*?)\]</a>}
      {<a href="\L$1\E.html#$2">$3</a>}ig;
    # wiki links
    s
      {(?:<img src="/jailbreak-ext/page-private.gif".*?>)?\s*<a href="/jailbreak/Manual/(.+?)">(.*?)</a>}
      {<a href="\L$1\E.html">$2</a>}ig;
      
    # external hidden links
    s
      {\[([^<]+)\](?=</a>)}
      {$1}ig;

    ### platform filters
    
    # remove this platform's labels
    s[$platform\::][]img; 
    
    # paragraphs and list items
    s[<(p|li)>\s*$unwantedplatform{$platform}::.*?</\1>][]img; 
    
    # sections with a marked heading
    s[<h(\d)>(?:<a name="[^"]*"></a>)?\s*$unwantedplatform{$platform}::.*?</h\1>.*?(?=<h\d>|\Z)][]imsg; #"
    
    # inline bits
    s[\{\{$unwantedplatform{$platform}::.*?}}][]img;
    s[{{$platform\::(.*?)}}][$1]img;
    
    # insert platform name
    (my $platformdate = $platform) =~ s/\D*//; # just the 2003 or 2004 part
    s[200x][$platformdate]ig;

    ### embed images
    s
      [{{Image:(.*?)\|(.*?)}}]
      [<div class="image"><img src="$imagesURL$1"><p>$2</p></div>]ig;

  }
 
  
  ########## linkbar
  $linkbar = join(
    ' | ', map { 
      (my $prettyname = $_) =~ s/_/ /g;
      /$wikiname/ ? 
        $_ : 
        qq[<a href="\L$_\E.html">$prettyname</a>];
    } 
    @pageNames 
  );
  
  ########## write file
  $filename = lc($wikiname);
  write_file("$baseDir$filename.html", bounce @templateHtml, $pagetitle, $linkbar, $content);
  
  ########## log
  print "$url\n";
  print " > $baseDir$filename.html\n";
}