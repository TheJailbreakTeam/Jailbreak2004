#!/usr/bin/perl

###############################################################################
#
#  make-distribution-reference.pl
#
#  Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
#  $Id$
#
#  Creates a reference text file reporting on the file versions contained in a
#  zip installer. Used later to create a delta installer.
#

use strict;
use warnings;

use FileHandle;
use Digest::MD5 'md5_hex';


###############################################################################
#
#  Parameters
#

my $fileZip = shift;

die "Usage: $0 REFERENCE_ZIP_FILE\n"
  unless defined $fileZip;
die "$fileZip does not exist.\n"
  unless -e $fileZip;


###############################################################################
#
#  Read zip file contents
#

my $filelist = `unzip -l "$fileZip"`;

die "Unable to read file list from $fileZip. $!\n"
  if ($? >> 8) != 0;

my %fileinfo;

while ($filelist =~ /^\s*(\d+)\s+\d+-\d+-\d+\s+\d+:\d+\s+(.*)$/gm) {
  my $sizeFile = $1;
  my $file     = $2;

  $fileinfo{$file}{size} = $sizeFile;
}


###############################################################################
#
#  Calculate checksums
#

print "Calculating checksums\n";

my @progress = qw(- \ | /);
my $iProgress = 0;

STDOUT->autoflush();

foreach my $file (keys %fileinfo) {
  print "...$file ";

  open PIPE, qq[unzip -p "$fileZip" "$file" |]
    or die "Unable to read file $file from $fileZip.\n";
  binmode PIPE;

  my $buffer;
  my $md5full = Digest::MD5->new();

  while (read(PIPE, $buffer, 256 * 1024)) {
    print $progress[$iProgress++ % @progress], "\b";

    $fileinfo{$file}{md5short} = md5_hex(substr($buffer, 0, 4096))
      unless defined $fileinfo{$file}{md5short};

    $md5full->add($buffer);
  }

  $fileinfo{$file}{md5short} = md5_hex(substr($buffer, 0, 4096))
    unless defined $fileinfo{$file}{md5short};
  $fileinfo{$file}{md5full} = $md5full->hexdigest();

  close PIPE;
  print " \n";
}

print "\n";


###############################################################################
#
#  Write reference file
#

print "Writing reference file\n";

my $fileReference = $fileZip;
$fileReference =~ s/(?:\.\w+)?$/-reference.txt/;

open REFERENCE, '>', $fileReference
  or die "Unable to write to $fileReference.\n";

foreach my $file (sort { lc($a) cmp lc($b) } keys %fileinfo) {
  printf REFERENCE "%s  %s  %s\n",
    $fileinfo{$file}{md5short},
    $fileinfo{$file}{md5full},
    $file;
}

close REFERENCE;

print "\n";
print "Done.\n";