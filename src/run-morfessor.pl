#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use File::Temp qw/tempdir/;

my $usage = qq{run-mofessor.pl -m morfessor_path -p PPLTHRESH < vocablary_file
};

our($opt_m, $opt_p);
getopts('m:p:');
die $usage unless ($opt_m and $opt_p);
$opt_m =~ s/\/$//g;

my %words;
while (<>) {
  chomp;
  $_ =~ s/#/|PSN|/g;
  $_ =~ s/\\\*/|AST|/g;
  $_ =~ s/\\\//|SLH|/g;
  $_ =~ s/\+/|PLS|/g;
  #un-escaped characters are also catched.
  $_ =~ s/\*/|OAST|/g;
  $_ =~ s/\//|OSLH|/g;
  my @l = split();
  if (@l == 2) {
    $words{$l[1]} += $l[0];
  } else {
    $words{$l[0]}++;
  }
}

open(FP, "| gzip > $opt_m/train/wsj.words.clean.gz") or die $!;
while (my($word, $c) = each(%words)) {
  print FP "$c $word\n";
}
close(FP);

my $tmp = tempdir("$opt_m/train-XXXX", CLEANUP => 1);
system("cd $tmp; cp ../train/* .; sed 's/^GZIPPEDINPUTDATA = mydata.gz/GZIPPEDINPUTDATA = wsj.words.clean.gz/g' Makefile | sed 's/^PPLTHRESH = [0-9]\\+/PPLTHRESH = $opt_p/g' > tmp; mv tmp Makefile; make > /dev/null");

open(FP, "zcat $tmp/segmentation.final.gz |") or die $!;
while (<FP>) {
  print $_;
}
close(FP);

`cd $tmp; make realclean`;
