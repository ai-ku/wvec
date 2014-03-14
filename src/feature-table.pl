#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use Data::Dumper;
use Encode qw(encode decode);
use utf8;
use open ':encoding(utf-8)';
binmode STDIN, ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

my $usage = qq{feature-table.pl -w wsj.words.gz -s wsj.segmentation.gz
};
##-s morfessor output
##-w tok.gz file
##-c double column feature set word feature
##-p no punctuation feature
##-m only morphology
our($opt_w, $opt_s, $opt_p, $opt_c, $opt_m);
getopts('w:s:c:pm');
die $usage unless ($opt_w);
$opt_w = "zcat $opt_w |" if $opt_w =~ /\.gz$/;
$opt_p = $opt_p || 0;
$opt_m = $opt_m || 0;
my %feat;
if(!$opt_m) {
  open(FP, $opt_w) or die $!;
  my $prev = ".";
  while (<FP>) {
    chomp;
    my @line = split;
    foreach(@line){
      if ($_ =~ /^\p{Lu}/ and $prev !~ /^[.`'?!:;]+$/ and \ 
      ($prev !~ /^[\p{Ps}\p{Pe}]/ and $prev !~ /^-[LR][RC]B-$/)) { #initial cap
      $feat{$_}{"/IC/"}++;
    } 
    $feat{$_}{"/CD/"}++ if $_ =~ /^[\-.]?(,?\p{Number}+)+(.\p{Number}+)?/; #contains digit
    $feat{$_}{"/CH/"}++ if ($_ =~ /([^-]+-)+[^-]+/ and $_ !~ /(\p{Upper}.*-)+\p{Upper}.*/ and $_ !~ /(\p{Number}+-)+\p{Number}+/ and $_ !~ /(\p{Letter}+-)+\p{Number}+/); #contains hypen
    $feat{$_}{"/IA/"}++ if $_ =~ /^'[\p{Letter}\p{Number}]+/; #initial apostrophe
    $feat{$_}{"/PP/"}++ if $opt_p && $_ =~ /^[\p{Punctuation}]+$/; # punctuation
#    $feat{$_}{"/CU/"}++ if $_ =~ /_/;#contains underscore
    $prev = $_;
  }
  $prev = ".";
}
close(FP);
}
my %hsuf;
if(defined $opt_c) {
  $opt_c = "zcat $opt_c |" if $opt_c =~ /\.gz$/;
  open(CP, $opt_c) or die $!;
  while(<CP>) {
    chomp;
    my ($w, $mor) = split;
    if(not defined $feat{$w}{"/CD/"}){#add suffix if CD is not defined
        $feat{$w}{"SUF:".$mor}++;
        $hsuf{"SUF:".$mor}++;
    } 
  }
  close(CP);
} elsif(defined $opt_s && not defined $opt_c) {
  $opt_s = "zcat $opt_s |" if $opt_s =~ /\.gz$/;
  open(FP, $opt_s) or die $!;
  %hsuf = ();
  my %info;
  while(<FP>){
    chomp;
    next if /^\#/;
    my ($cnt, @line) = split();
    my ($stem, $suf, $lsuf,$aff,$fstm) = ("","","","",0);
    foreach(@line){
      if ($_ =~ /(.*?)\/(.*)/){
        if (!$stem) {$stem .= $1;	    
        }
        elsif($fstm == 0){
          $stem .= $1; 	
        }
        elsif($2 eq "SUF"){
          $suf .= $1; 
          $aff .= $1;
        }
        else{		
          $suf = "";
          $aff .= $1;
        }
        $fstm = 1 if($2 eq "STM");
        $lsuf = $1;
      }	
    }
    next unless $aff;
    $info{$aff}{$stem.$aff} = 1;
  }

  while(my ($s, $v) = each(%info)){
#    next if (keys(%$v) == 1);
    while(my ($w, $v2) = each(%$v)){
      if(not defined $feat{$w}{"/CD/"}) {
        #if the word is not a number 
        $feat{$w}{"SUF:".$s}++;
        $hsuf{"SUF:".$s}++;
      }
    }
  }
}
# while (<FP>) {
#   next if $_ =~ /^#/;
#   chomp;
#   $_ =~ s/^[0-9]+ //g;
#   $_ =~ s/\/PRE//g;
#   $_ =~ s/\/STM//g;
#   $_ =~ s/(\S+)\/SUF/$1 \/SUF:$1\//g;
#   my @a = split;
#   my $w = "";
#   my @b;
#   foreach(@a) {
#     if ($_ ne "+") {
#       if ($_ =~ /\/SUF:(\S+)\//) {
# 	push(@b, $_);
#       } else {
# 	$w = $w.$_;
#       }
#     }
#   }
#   foreach(@b){
#       $feat{$w}{$_}++;
#       $hsuf{$_}++;
#   }
# }

#print "Any suf:".keys(%hsuf)." ".Dumper(\%hsuf);
#die;
while(my($word, $f) = each(%feat)) {
  $word =~ s/\|PSN\|/#/g;
  $word =~ s/\|AST\|/\\*/g;
  $word =~ s/\|SLH\|/\\\//g;
  $word =~ s/\|PLS\|/+/g;
  $word =~ s/\|OAST\|/*/g;
  $word =~ s/\|OSLH\|/\//g;
  print $word."\t".join("\t", keys(%$f))."\n";
}
