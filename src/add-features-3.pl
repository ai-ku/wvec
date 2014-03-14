#!/usr/bin/perl -w
use strict;

my $usage = qq{add-features.pl [-f dict] < input
Add suffix-features from dict for each word on the left side of the two column input.
-f file that contains a word and one or more features on each line.
};

use Getopt::Std;
our($opt_f, $opt_a);
getopts('f:a');
die $usage unless $opt_f;
$opt_f = "zcat $opt_f |" if $opt_f =~ /\.gz$/;

my %features;
my %feat;
my %suff;
open(FP, $opt_f) or die $!;
while(<FP>) {
  my @a = split;
  my $w = shift(@a);
  foreach(@a){
    if($_ !~ /^SUF:/){
      $feat{$w}{$_}++;
      $features{$_}++;
    }
    else{
      $feat{$w}{"SUF"}++;
      $features{"SUF"}++;
      $suff{$w} = $_;
    }
  }
}
close(FP);

if ($opt_a) {
  print scalar (keys %features) + 2 . "\n";
  exit;
}

foreach (keys %features) { $features{$_} = 0; }

my $prev;
while(<>) {
  my ($w, $x) = split;
  next if $w eq '</s>';
  my @tuple = ($w, $x);
  my $fi = 0;
  foreach my $f (keys %features) {
    if (defined $feat{$w} and defined $feat{$w}{$f}) {
      if (($f eq '/IC/') and
        ((not defined $prev) or
          ($prev =~ /^[.`'?!:;]+$/) or
          ($prev =~ /^-[LR][RC]B-$/))) {
        push @tuple, "/XX/";
        next;
      }
      elsif($f eq "SUF"){
        if (defined $suff{$w}){
          push @tuple, $suff{$w};}
        else{push @tuple, "/XX/";}
        next;
      }
      push @tuple,$f;
    } else {
      push @tuple, "/XX/";
    }
    $fi++;
  }
  $prev = $w;
  print join ("\t", @tuple, "\n");
}
