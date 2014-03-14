#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $usage = qq{eval.pl [-m -v] -g <gold> < input
Calculates many-to-one and v-measure evaluations.
-m prints many-to-one (default)
-v prints v-measure (homogeneity, completeness, v-measure)
-c prints Mintz(2002) pairwise score (accuracy(hit/(hit+false)), completeness(hit / (hit + miss)))
-g file with gold answers
};

use Getopt::Std;
our($opt_m, $opt_v, $opt_c, $opt_g);
getopts('mvcg:');
die $usage unless $opt_g;
$opt_g = "zcat $opt_g |" if $opt_g =~ /\.gz$/;

my (%cnt, %rcnt);
open(GOLD, $opt_g) or die $!;
while(<>) {
    my $g = <GOLD>;
    $cnt{$_}{$g}++;
    $rcnt{$g}{$_}++;
}
#print Dumper(\%cnt);
close(GOLD);

my @ans;
if ($opt_m and $opt_v and $opt_c) {
    push @ans, m2o();
    push @ans, vm();
    push @ans, chi();
} elsif ($opt_m and $opt_v ) {
    push @ans, m2o();
    push @ans, vm();
} elsif ($opt_v) {
    push @ans, vm();
} elsif ($opt_c){
    push @ans, chi();
} else{
    push @ans, m2o();
} 

$_ = sprintf("%f", $_) for @ans;
print STDERR join("\t", @ans)."\n";

sub chi {
    my $total = 0;
    my $hit = 0;
    my (%cnt, %rcnt);
    for my $a (keys %cnt){
	my $cc = 0;
	for my $g (keys %{$cnt{$a}}){
	    my $cn = $cnt{$a}{$g};
	    $cc += $cn;
	    $hit += $cn * 0.5 * ($cn - 1);	    
	}
	$total += $cc * 0.5 * ($cc - 1);
    }
    my $miss = 0;
    my @k = keys %rcnt;
    for(my $i = 0 ; $i < @k; $i++){
	my @a = keys(%{$rcnt{$k[$i]}});
	for(my $j = 0; $j < @a; $j++){
	    for(my $l = $j + 1 ; $l < @a; $l++){
		$miss += $rcnt{$k[$i]}{$a[$j]} * $rcnt{$k[$i]}{$a[$l]};
	    }
	}
    }
    return ($hit / $total, $hit * 1.0 / ($hit + $miss));
}


sub m2o {
    my $total = 0;
    my $correct = 0;

    for my $l (keys %cnt) {
	my $max;
	for my $p (keys %{$cnt{$l}}) {
	    my $n = $cnt{$l}{$p};
	    if (not defined $max or $n > $max) {
		$max = $n;
	    }
	    $total += $n;
	}
	$correct += $max;
    }

    return $correct / $total;
}

sub vm {
    my (%acnt, %gcnt, $N);
    for my $a (keys %cnt) {
	for my $g (keys %{$cnt{$a}}) {
	    my $n = $cnt{$a}{$g};
	    $acnt{$a} += $n;
	    $gcnt{$g} += $n;
	    $N += $n;
	}
    }
    my $log2 = log(2);
    my $H_a;
    for my $a (keys %acnt) {
	my $p = $acnt{$a} / $N;
	$H_a -= $p * log($p);
    }
    my $H_g;
    for my $g (keys %gcnt) {
	my $p = $gcnt{$g} / $N;
	$H_g -= $p * log($p);
    }
    my ($H_ag, $H_ga);
    for my $a (keys %cnt) {
	my $na = $acnt{$a};
	for my $g (keys %{$cnt{$a}}) {
	    my $ng = $gcnt{$g};
	    my $nag = $cnt{$a}{$g};
	    my $p = $nag / $N;
	    my $pag = $nag / $ng;
	    my $pga = $nag / $na;
	    $H_ag -= $p * log($pag);
	    $H_ga -= $p * log($pga);
	}
    }    
    my $h = 1 - $H_ga / $H_g;
    my $c = 1 - $H_ag / $H_a;
    my $v = (2*$h*$c / ($h+$c));
    return ($h, $c, $v);
}
