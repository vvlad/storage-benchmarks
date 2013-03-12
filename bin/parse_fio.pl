#!/usr/bin/perl
#
# By Phil2k@gmail.com
#

use warnings;
use strict;
use Getopt::Std;

my @fio_keys=("random read", "random read write", "random write");

my $syntax="$0 [-j] <fio.out>|<path_to_fio.out_files> ...";

my %opts=();
$Getopt::Std::STANDARD_HELP_VERSION=1;
sub main::VERSION_MESSAGE() { print STDERR "parse_fio.pl Version 1.0 by Phil2k\@gmail.com\n"; };
sub main::HELP_MESSAGE() { print STDERR $syntax."\n"; };
getopts('j', \%opts);
my $output_json=0;
if (exists($opts{j})) { $output_json=1; }
if ($#ARGV<0) {
  print STDERR $syntax."\n";
  exit 1;
  }

print "var tests = {\n" if ($output_json);

my $path;
my %bw_vals=();
my %iops_vals=();

foreach $path (@ARGV) {
  %bw_vals=();
  %iops_vals=();
  
  my $category="";
  my $category_found_in_file=0;
  
  if (-d $path) {
    opendir DIR, $path or die "Cannot list directory from path $path: $!\n";
    my $file;
    while(defined($file=readdir DIR)) {
      next if ($file=~/^\.{1,2}$/);
      my $file_path=$path."/".$file;
      if (($file=~/^desc.*?\.txt$/i) || ($file=~/^category\.txt$/i)) { # if there's a file with name "desc.txt" , "description.txt" or "category.txt"
        local *FILE;
        my $ok;
        my $line;
        $ok = open FILE, $file_path;
        if ($ok) {
          while(!eof(FILE)) {
            $line = <FILE>;
            chomp($line);
            $line=~s/(#;\/\/).*$//; # remove comments
            $line=~s/^\s+//; # remove beging spaces
            $line=~s/\s+$//; # remove ending spaces
            if (length($line)) {
              $category=$line;
              $category_found_in_file=1;
              last;
              }
            }
          close(FILE);
          }
        if (!length($category)) {
          print STDERR "No description/category found in file $file_path !\n";
          }
        }
      &parse_file($file_path) if (-f $file_path && ($file=~/\.out$/)); # parse only ".out" files !
      }
    closedir DIR;
    }
  elsif (-f $path) {
    &parse_file($path);
    }
  else {
    print STDERR "Unknown file/dir type: $path !\n";
    next;
    }
  
  my $name=&basename($path);
  if ($name=~/^([^.]+)\.(.+)$/) {
    my $cat=$1;
    my $nam=$2;
    if ($nam ne "out") { # dont' extract category/description from fio files (.out) that doesn't have any other dots (.) !
      $name=$nam;
      if (!length($category)) {
        $cat=~s/[-_]/ /g;
        $category=$cat;
        }
      }
    }
  if (!length($category)) {
    print STDERR "Category/Description for $path (ex.: Amazon Cloud): "; $category=<STDIN>; chomp($category);
    $category=~s/^\s+//;
    $category=~s/\s+$//;
    }
  if (length($category) && (!$category_found_in_file)) {
    local *FILE;
    my $desc_file="";
    if (-d $path) { $desc_file = $path."/desc.txt"; }
    else { $desc_file = &dirname($path)."/desc.txt"; }
    open FILE, ">".$desc_file;
    print FILE $category."\n";
    close FILE;
    }
  
  print "\n\t\"".$name."\" : {\n" if ($output_json);
  if  (length($category)) {
    print "\t\t\"category\" : \"".$category."\",\n";
    }

  my ($i, $oper);
  print "\nAverage bandwidth:\n" if (!$output_json);
  foreach $oper (keys %bw_vals) {
    my $bw=0;
    for($i=0;$i<=$#{$bw_vals{$oper}};$i++) {
      $bw+=$bw_vals{$oper}->[$i];
      }
    $bw/=($#{$bw_vals{$oper}}+1);
    printf " $oper : %.2f mbps\n",($bw*8/1024/1024) if (!$output_json);
    print "\t\t\"".$oper.".bw\" : ".int($bw*8/1024/1024+0.5).",\n" if ($output_json);
    }

  print "\nAverage iops (IO operations / sec):\n" if (!$output_json);
  foreach $oper (keys %iops_vals) {
    my $iops=0;
    for($i=0;$i<=$#{$iops_vals{$oper}};$i++) {
      $iops+=$iops_vals{$oper}->[$i];
      }
    $iops/=($#{$iops_vals{$oper}}+1);
    printf " $oper : %.2f iops\n",($iops) if (!$output_json);
    print "\t\t\"".$oper.".iops\" : ".int($iops+0.5).",\n" if ($output_json);
    }
  print "\n" if (!$output_json);
  print "\t},\n" if ($output_json);
  }

print "};\n" if ($output_json);

exit 0;



sub parse_file() {
  my $file=$_[0];
  local *FILE;
  print "\nParsing file $file ...\n" if (!$output_json);
  my $ok = open FILE, $file;
  if (!$ok) {
    print STDERR "Cannot open file $file: $!\n";
    return 0;
    }
  my $last_key="";
#random read: (groupid=0, jobs=1): err= 0: pid=5786
# read : io=16114MB, bw=55003KB/s, iops=13750 , runt=300001msec

#random read: (groupid=0, jobs=1): err= 0: pid=2470
#  read : io=231MB, bw=3,945KB/s, iops=986, runt= 60015msec
  while(!eof(FILE)) {
    my $line=<FILE>;
    chomp($line);
    if ($line=~/^\s+/) { # starts with space(s):
      if (($last_key ne "") && ($line=~/^\s+(read|write)\s*:\s+io=\s*([0-9.,]+)([KMG ])B, bw=\s*([0-9.,]+)([KMG ])B\/s, iops=\s*([0-9.]+)\s*, runt=\s*([0-9.]+)msec/)) {
        my $oper=$1;
        my $transfered=$2;
        my $transfered_unit=$3;
        my $bw=$4;
        my $bw_unit=$5;
        my $iops=$6;
        my $runt=$7;
        $transfered=~s/,//g; # remove commas from thousands, million, etc.
        if ($transfered_unit eq "K") {
          $transfered*=1024;
          }
        elsif ($transfered_unit eq "M") {
          $transfered*=1048576;
          }
        elsif ($transfered_unit eq "G") {
          $transfered*=1073741824;
          }
        $bw=~s/,//g; # remove commas from thousands, million, etc.
        if ($bw_unit eq "K") {
          $bw*=1024;
          }
        elsif ($bw_unit eq "M") {
          $bw*=1048576;
          }
        elsif ($bw_unit eq "G") {
          $bw*=1073741824;
          }
        print "$last_key ($oper) : bw=$bw iops=$iops\n" if (!$output_json);
        push @{$bw_vals{$oper}},$bw;
        push @{$iops_vals{$oper}},$iops;
        }
      } else {
      $last_key="";
      if ($line=~/^([^:]+?)\s*: \(/) {
        my $key=$1;
        if (&in_array($key, \@fio_keys)) {
          $last_key=$key;
          }
        }
      }
    }
  close FILE;
  }

sub in_array() {
  my ($el, $array_ref)=@_;
  my $cmp;
  foreach $cmp (@{$array_ref}) {
    return 1 if ($el eq $cmp);
    }
  return 0;
  }

sub basename() {
  my ($file_path)=@_;
  my ($basename)=$file_path=~/([^\/]+)$/;
  if (not(defined($basename))) { $basename=""; }
  return $basename;
  }

sub dirname() {
  my ($file_path)=@_;
  my ($dirname)=$file_path=~/^(.*?)[^\/]+$/;
  if (not(defined($dirname)) || ($dirname eq "")) { $dirname="."; }
  return $dirname;
  }
