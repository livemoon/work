#!/usr/bin/perl

use warnings;
use strict;

my $file = "/proc/net/dev";
#my $out = "net_result";

my $date = localtime;

open my $FH, '<', $file or die "Cannot open $file\n";
#open my $OUT, '>>', $out or die "Cannot write $out\n";

print "$date\n";
print "\tnic\t\tInbound\t\tOutbound\n";
while(<$FH>) {
    if (/eth/) {
        my @fields = split /\s+|:/;
        printf ("\t%s\t\t%.1fMB\t\t%.1fMB\n", $fields[1], $fields[2]/(1024*1024), $fields[10]/(1024*1024));
    }
}

close($FH);
#close($OUT);
