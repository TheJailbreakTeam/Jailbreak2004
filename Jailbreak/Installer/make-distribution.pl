#!/usr/bin/perl

###############################################################################
#
#  make-distribution-int.pl
#
#  Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
#  $Id$
#
#  Automatically updates and creates distribution packages for Jailbreak.
#

use strict;
use warnings;

use Cwd;
use File::Copy;


###############################################################################
#
#  Configuration
#


#####################################################################
#
#  Settings
#

our $localization;
our $product;
our $version;

our $UT200x;
our $UT200xSuffix;
our $UT200xExt;
our $UT200xVersion;


#####################################################################
#
#  Modules
#
#  List of CVS modules and their rebuilding methods. All modules
#  will be updated from CVS and rebuilt if necessary. The script
#  uses the paths from the game config to find the corresponding
#  package file.
#

our %modules = ();


#####################################################################
#
#  Maps
#
#  List of files relative to the game base directory which belong
#  into the Maps section of the installer. Includes all required
#  additional files such as music, texture or static mesh packs.
#

our @maps = ();


#####################################################################
#
#  Keys
#
#  List of key bindings. The user can choose whether those default
#  bindings should be set up when installing the game.
#

our %keys = ();


#####################################################################
#
#  Import
#

do 'make-distribution.conf';


###############################################################################
#
#  Globals
#

our $dirGame;

our @paths;


###############################################################################
#
#  findDirGame
#
#  Based on the current directory, finds and returns the game base directory.
#

sub findDirGame ()
{
  my $dirGame = '.';
  
  while (not -e "$dirGame/System/ucc.exe") {
    if ($dirGame eq '.')
           { $dirGame = '..' }
      else { $dirGame = "../$dirGame" }
    
    return undef if length($dirGame) > 3 * 64;
  }
  
  return $dirGame;
}


###############################################################################
#
#  findFileIni
#
#  Returns the file name of the main game configuration file or undef if none
#  can be found.
#

sub findFileIni ()
{
  foreach my $file ('UT2003.ini', 'UT2004.ini') {
    my $fileIni = "$dirGame/System/$file";
    return $fileIni
      if -e $fileIni;
  }
  
  return undef;
}


###############################################################################
#
#  findFilePackage $package
#
#  Returns the file name corresponding to the given package or undef if no
#  corresponding file could be found.
#

sub findFilePackage ($)
{
  my $package = shift;

  if (not @paths) {
    my $fileIni = findFileIni();
    die "Unable to find game configutation file.\n"
      unless defined $fileIni;
  
    open INI, '<', $fileIni
      or die "Unable to read game configuration file.\n";
    
    while (my $setting = <INI>) {
      chomp $setting;
      push @paths, $setting
        if $setting =~ s/^Paths=//i;
    }
    
    close INI;
  }

  foreach my $path (@paths) {
    my $filePackage = "$dirGame/System/$path";
    $filePackage =~ s/\*/$package/;
    return $filePackage
      if -e $filePackage;
  }
  
  return undef;
}


###############################################################################
#
#  getTimeFile $fileOrDir
#
#  Returns the modification timestamp of the given file or directory. If a
#  directory is given, recursively checks all files in all subdirectories of
#  it, skipping CVS and Installer directories.
#

sub getTimeFile ($);
sub getTimeFile ($)
{
  my $fileOrDir = shift;

  return undef
    unless defined $fileOrDir;

  my $timeFileLast;

  if (-f $fileOrDir) {
    $timeFileLast = (stat($fileOrDir))[9];
  }
  elsif (-d $fileOrDir) {
    opendir DIR, $fileOrDir
      or die "Unable to open directory $fileOrDir.\n";
    my @files = grep !/^(?:\.|\.\.|CVS|Installer)$/i, readdir(DIR);
    closedir DIR;
  
    foreach my $file (@files) {
      my $timeFile = getTimeFile("$fileOrDir/$file");
      $timeFileLast = $timeFile
        if not defined $timeFileLast
        or $timeFileLast < $timeFile;
    }
  }

  return $timeFileLast;
}


###############################################################################
#
#  timestamp $file
#
#  Replaces the pattern %%%%-%%-%% %%:%% by the current timestamp in the given
#  binary file.
#

sub timestamp ($)
{
  my $file = shift;
  
  local $/;
  undef $/;

  open FILE, '<', $file
    or die "Unable to read file $file.\n";
  binmode FILE;
  my $content = <FILE>;
  close FILE;

  my $timestamp = sprintf('%04d-%02d-%02d %02d:%02d',
    (localtime)[5] + 1900,
    (localtime)[4] +    1,
    (localtime)[3],
    (localtime)[2],
    (localtime)[1],
  );

  $content =~ s[%%%%-%%-%% %%:%%] [$timestamp]g;
  
  open FILE, '>', $file
    or die "Unable to write to file $file.\n";
  binmode FILE;
  print FILE $content;
  close FILE;
}


###############################################################################
#
#  canonPath $path
#
#  Canonicalizes and returns the given directory path.
#

sub canonPath ($)
{
  my $path = shift;
  
  return undef
    unless defined $path;
  
  1 while $path =~ s[(^|[:/\\])(?!\.\.[/\\])[^/\\]+[/\\]\.\.(?:[/\\]|$)] [$1];
  return $path;
}


###############################################################################
#
#  Main
#

$dirGame = findDirGame();
die "Unable to find game base directory.\n"
  unless defined $dirGame;


#####################################################################
#
#  Modules
#

my @modules = sort { uc($a) cmp uc($b) } keys %modules;


###########################################################
#
#  Update
#
#  Updates all modules from their CVS repositories. This
#  assumes that all modules have been initially checked
#  out already to ensure that the right branch is used.
#

print "Updating modules:\n";

foreach my $module (@modules) {
  next if $module =~ /[\\\/]/;
  print "...$module\n";
  
  die "Module $module has not been checked out yet.\n"
    unless -d "$dirGame/$module/CVS";

  my $dirCurrent = cwd();
  chdir "$dirGame/$module"
    or die "Unable to change into module directory for $module.\n";

  my $output = `cvs update -d -P 2>nul`;
  die "Unable to update module $module from CVS. $!\n"
    if ($? >> 8) != 0;
  die "Module $module has uncommitted local changes or conflicts.\n"
    if $output =~ m[^[ARMC]\s(?!Installer/make-distribution\.(?:pl|conf)$)]m; 

  chdir $dirCurrent
    or die "Unable to change to directory $dirCurrent.\n";
}

print "\n";


###########################################################
#
#  Rebuild
#
#  Rebuilds all modules whose corresponding packages do
#  not exist or have an earlier modification date than the
#  most recently changed of their source files.
#

print "Rebuilding modules:\n";

foreach my $module (@modules) {
  my $isUpToDate;

  if ($module =~ /[\\\/]/) {
    $isUpToDate = 0;
  }
  else {
    my $filePackage = canonPath(findFilePackage($module));
  
    my $timeFilePackage = getTimeFile($filePackage);
    my $timeFileModule  = getTimeFile("$dirGame/$module");

    $isUpToDate = (defined $timeFilePackage and $timeFileModule <= $timeFilePackage);
  }

  if ($isUpToDate) {
    print "...$module: up to date\n";
  }
  else {
    print "...$module: rebuilding\n";

    my $method = $modules{$module};

    if ($method eq 'ucc') {
      my $filePackage = canonPath(findFilePackage($module));
      my $filePackageBackup;
      
      if (defined $filePackage) {
        $filePackageBackup = "$filePackage.backup";
  
        unlink $filePackageBackup
          or die "Unable to remove file $filePackageBackup."
          if -e $filePackageBackup;
        rename $filePackage, $filePackageBackup
          or die "Unable to rename file $filePackage to $filePackageBackup.";
      }

      my $dirCurrent = cwd();
      chdir "$dirGame/System"
        or die "Unable to change to System directory.\n";

      my $fileIni = canonPath("../$module/make.ini");
      die "No make.ini file found for module $module.\n"
        unless -e $fileIni;
      
      my $output = `ucc make ini=$fileIni`;

      chdir $dirCurrent
        or die "Unable to change to directory $dirCurrent.\n";

      if (($? >> 8) != 0) {
        rename $filePackageBackup, $filePackage
          if defined $filePackage;

        $output =~ s[^Analyzing .*\n] []xm;
        $output =~ s[^---       .*\n] []xmg;
        $output =~ s[^Deferring .*\n] []xmg;
        $output =~ s[^Parsing   .*\n] []xmg;
        $output =~ s[^Compiling .*\n] []xmg;
        $output =~ s[^Importing .*\n] []xmg;
        $output =~ s[^Failure   .*\n] []xm;

        die "Unable to recompile module $module.\n", $output, "\n"
      }

      $filePackage = findFilePackage($module);
      die "No package file found after recompiling module $module.\n"
        unless defined $filePackage;

      timestamp $filePackage;
    }
    else {
      my $dirCurrent = cwd();
      chdir "$dirGame/$module"
        or die "Unable to change into module directory for $module.\n";
      
      my $output = `$method 2>&1`;
      die "Unable to rebuild module $module using $method.\n", $output, "\n"
        if ($? >> 8) != 0;
      
      chdir $dirCurrent
        or die "Unable to change to directory $dirCurrent.\n";
    }
  }
}

print "\n";


#####################################################################
#
#  Zip Installer
#

print "Packing .zip installer:\n";

my $fileZip = cwd() . "/$product$UT200xSuffix-zip.zip";
unlink $fileZip
  or die "Unable to remove old archive $fileZip.\n"
  if -e $fileZip;


###########################################################
#
#  Modules
#
#  Adds the module packages and all files from their
#  Installer directories to the archive.
#

print "...adding modules\n";

foreach my $module (@modules) {
  next if $module =~ /[\\\/]/;
  print ".....$module\n";
  
  my $filePackage = findFilePackage($module);
  die "No package file found for module $module.\n"
    unless defined $filePackage;
  
  my $dirCurrent = cwd();
  chdir $dirGame
    or die "Unable to change to game base directory.\n";
  
  $filePackage =~ s[^\Q$dirGame\E[/\\]] [];
  $filePackage = canonPath($filePackage);
  
  my $output = `zip -9 "$fileZip" "$filePackage" 2>&1`;
  die "Unable to add $filePackage to archive.\n", $output, "\n"
    if ($? >> 8) != 0;

  if (-d "$module/Installer") {
    chdir "$module/Installer"
      or die "Unable to change to Installer directory of module $module.\n";
    
    my $output = `zip -Dr9 "$fileZip" */* -x CVS/* */CVS/* 2>&1`;
    die "Unable to add Installer directory contents to archive.\n", $output, "\n"
      if ($? >> 8) != 0;
  }
  
  chdir $dirCurrent
    or die "Unable to change to directory $dirCurrent.\n";
}


###########################################################
#
#  Maps
#
#  Adds all maps and their related files to the archive.
#

if (@maps) {
  print "...adding maps and related files\n";

  my $dirCurrent = cwd();
  chdir $dirGame
    or die "Unable to change to game directory.\n";

  foreach my $file (@maps) {
    print ".....$file\n";
    
    my $output = `zip -r9 "$fileZip" "$file" 2>&1`;
    die "Unable to add file $file to archive.\n", $output, "\n"
      if ($? >> 8) != 0;
  }

  chdir $dirCurrent
    or die "Unable to change to directory $dirCurrent.\n";
}

print "\n";


#####################################################################
#
#  UMod Installer
#

print "Packing .$UT200xExt installer:\n";
print "...distributing files and creating configuration\n";

die "Previous run did not clean up correctly. Restore Manifest-original.ini.\n"
  if -e "$dirGame/System/Manifest-original.ini";

rename "$dirGame/System/Manifest.ini", "$dirGame/System/Manifest-original.ini"
  or die "Unable to backup Manifest.ini.\n"
  if -e "$dirGame/System/Manifest.ini";

open MANIFEST, '>', "$dirGame/System/Manifest-$product.ini"
  or die "Unable to write to Manifest-$product.ini.\n";


###########################################################
#
#  Header
#
#  Sets up header information for the installer, including
#  the requirement on the base game and all groups.
#

print MANIFEST "[Setup]\n";
print MANIFEST "Product=$product\n";
print MANIFEST "Version=$version\n";
print MANIFEST "Language=int\n";
print MANIFEST "Archive=$product.$UT200xExt\n";
print MANIFEST "SrcPath=.\n";
print MANIFEST "MasterPath=..\n";
print MANIFEST "Requires=Requirement$UT200x\n";
print MANIFEST "Visible=True\n";

print MANIFEST "Group=GroupSetup\n";
print MANIFEST "Group=GroupMain\n";
print MANIFEST "Group=GroupMaps\n" if @maps;
print MANIFEST "Group=GroupKeys\n" if %keys;

print MANIFEST "[Requirement$UT200x]\n";
print MANIFEST "Product=$UT200x\n";
print MANIFEST "Version=$UT200xVersion\n";

print MANIFEST "[GroupSetup]\n";
print MANIFEST "Copy=(Src=System\\Manifest.ini,Flags=3)\n";

foreach my $ext qw(int det est frt itt kot smt tmt) {
  print MANIFEST "Copy=(Src=System\\Manifest.$ext,Master=System\\Manifest.int,Flags=3)\n";
}


###########################################################
#
#  Modules
#
#  Adds a group containing all modules. Each module gets
#  a ServerPackages entry, and all files from the module's
#  Installer directory are copied to the game directory.
#

print MANIFEST "[GroupMain]\n";
print MANIFEST "Optional=False\n";
print MANIFEST "Visible=True\n";

foreach my $module (@modules) {
  next if $module =~ /[\\\/]/;
  print ".....$module\n";
  
  my $filePackage = findFilePackage($module);
  die "No package file found for module $module.\n"
    unless defined $filePackage;
  
  my $sizeFilePackage = -s $filePackage;

  $filePackage =~ s[^\Q$dirGame\E[/\\]] [];
  $filePackage = canonPath($filePackage);
  $filePackage =~ tr[/] [\\];

  print MANIFEST "AddIni=$UT200x.ini,Engine.GameEngine.ServerPackages=$module\n"
    if $filePackage =~ /\.u$/;
  print MANIFEST "File=(Src=\"$filePackage\",Size=$sizeFilePackage)\n";

  if (-e "$dirGame/$module/Installer") {
    my @dirSub;

    opendir DIR, "$dirGame/$module/Installer"
      or die "Unable to open Installer directory.\n";
    
    foreach my $fileOrDir (readdir(DIR)) {
      next
        if $fileOrDir eq '.'
        or $fileOrDir eq '..'
        or $fileOrDir eq 'CVS';

      if (-d "$dirGame/$module/Installer/$fileOrDir") {
        push @dirSub, $fileOrDir;
        mkdir "$dirGame/$fileOrDir"
          or die "Unable to create directory $fileOrDir.\n"
          unless -d "$dirGame/$fileOrDir";
      }
    }
    
    closedir DIR;
    
    while (my $dirSub = shift @dirSub) {
      opendir DIR, "$dirGame/$module/Installer/$dirSub"
        or die "Unable to open Installer/$dirSub directory.\n";
      
      foreach my $fileOrDir (readdir(DIR)) {
        next
          if $fileOrDir eq '.'
          or $fileOrDir eq '..'
          or $fileOrDir eq 'CVS';
        
        if (-d "$dirGame/$module/Installer/$dirSub/$fileOrDir") {
          push @dirSub, "$dirSub/$fileOrDir";
          mkdir "$dirGame/$dirSub/$fileOrDir"
            or die "Unable to create directory $dirSub/$fileOrDir.\n"
            unless -d "$dirGame/$dirSub/$fileOrDir";
        }
        else {
          my $fileOriginal = "$module/Installer/$dirSub/$fileOrDir";
          my $fileTarget   =                   "$dirSub/$fileOrDir";
          $fileTarget =~ tr[/] [\\];
          
          my $sizeFile = -s "$dirGame/$fileOriginal";
          print MANIFEST "File=(Src=\"$fileTarget\",Size=$sizeFile)\n";
        
          my $timeFileOriginal = getTimeFile("$dirGame/$fileOriginal");
          my $timeFileTarget   = getTimeFile("$dirGame/$fileTarget");
          
          copy "$dirGame/$fileOriginal", "$dirGame/$fileTarget"
            or die "Unable to copy $fileTarget from Installer directory to game directory.\n"
            if not defined $timeFileTarget or $timeFileOriginal > $timeFileTarget;
        }
      }

      closedir DIR;
    }
  }
}


###########################################################
#
#  Maps
#
#  Adds a group for all maps and their related files to
#  the installer setup.
#

if (@maps) {
  print "...maps and related files\n";
  
  print MANIFEST "[GroupMaps]\n";
  print MANIFEST "Optional=True\n";
  print MANIFEST "Visible=True\n";

  foreach my $file (@maps) {
    my $sizeFile = -s "$dirGame/$file";
    die "File $file does not exist.\n"
      unless defined $sizeFile;
    print MANIFEST "File=(Src=\"$file\",Size=$sizeFile)\n";
  }
}


###########################################################
#
#  Keys
#
#  Adds a group for default key bindings. If selected, it
#  adds the necessary configuration file entries.
#

if (%keys) {
  print "...default key bindings\n";

  print MANIFEST "[GroupKeys]\n";
  print MANIFEST "Optional=True\n";
  print MANIFEST "Visible=True\n";
  print MANIFEST "Selected=False\n";
  
  foreach my $key (sort keys %keys) {
    print MANIFEST "Ini=System\\User.ini,Engine.Input.$key=$keys{$key}\n";
  }
}

close MANIFEST;


###########################################################
#
#  Make
#
#  Creates the installer file and puts it along with the
#  readme file into the installer archive.
#

print "...creating installer\n";

foreach my $file (<Manifest-$product.*t>) {
  copy $file, "$dirGame/System/$file"
    or die "Unable to copy file $file to System directory.\n";
}

{
  my $dirCurrent = cwd();
  chdir "$dirGame/System"
    or die "Unable to change to System directory.\n";

  unlink "$product.$UT200xExt";
  my $output = `ucc master Manifest-$product.ini`;
  
  chdir $dirCurrent
    or die "Unable to change to directory $dirCurrent.\n";

  die "Installer file was not created.\n", $output, "\n"
    unless -e "$dirGame/System/$product.$UT200xExt";
}

copy "$dirGame/System/Manifest.ini", "Manifest-$product.ini";

unlink "$dirGame/System/Manifest.ini"
  or die "Unable to delete temporary Manifest.ini.\n"
  if -e "$dirGame/System/Manifest.ini";
rename "$dirGame/System/Manifest-original.ini", "$dirGame/System/Manifest.ini"
  or die "Unable to restore Manifest.ini.\n";

unlink <$dirGame/System/Manifest-$product.*>;
unlink <$dirGame/System/Manifest.*t>;

print "...packing archive\n";

my $fileZipUMod = "$product$UT200xSuffix-umod.zip";
unlink $fileZipUMod
  or die "Unable to remove old archive $fileZipUMod.\n"
  if -e $fileZipUMod;

`zip -j9 "$fileZipUMod" "$dirGame/Help/$product.txt"`;
die "Unable to add $product.txt to archive.\n"
  if ($? >> 8) != 0;

`zip -j9 "$fileZipUMod" "$dirGame/System/$product.$UT200xExt"`;
die "Unable to add $product.$UT200xExt to archive.\n"
  if ($? >> 8) != 0;

unlink "$dirGame/System/$product.$UT200xExt"
  or die "Unable to remove file $product.$UT200xExt.\n";

print "\n";


#####################################################################
#
#  Done
#

print "Done.\n";


###############################################################################
#
#  Cleanup
#

END
{
  unlink <$dirGame/System/Manifest-$product.*>;
  unlink <$dirGame/System/Manifest.*t>;

  if (-e "$dirGame/System/Manifest-original.ini") {
    unlink "$dirGame/System/Manifest.ini";
    rename "$dirGame/System/Manifest-original.ini", "$dirGame/System/Manifest.ini";
  }

  print "Press [Enter] to continue\n";
  <STDIN>;
}