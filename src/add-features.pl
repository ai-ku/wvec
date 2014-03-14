#!/usr/bin/perl -w
use strict;

my $usage = qq{add-features.pl [-f dict] < input
Add features from dict for each word on the left side of the two column input.
-f file that contains a word and one or more features on each line.
};

use Getopt::Std;
our($opt_f);
getopts('f:');
die $usage unless $opt_f;
$opt_f = "zcat $opt_f |" if $opt_f =~ /\.gz$/;

my %feat;
open(FP, $opt_f) or die $!;
while(<FP>) {
    my @a = split;
    my $w = shift(@a);
    $feat{$w}{$_}++ for @a;
}
close(FP);

my $prev;
while(<>) {
    my ($w, $x) = split;
    next if $w eq '</s>';
    print;
    if (defined $feat{$w}) {
	for my $f (keys %{$feat{$w}}) {
	    if (($f eq '/IC/') and
		((not defined $prev) or
		 ($prev =~ /^[.`'?!:;]+$/) or
		 ($prev =~ /^-[LR][RC]B-$/))) {
		next;
	    }
	    print "$w\t$f\n";
	}
    }
    $prev = $w;
}
