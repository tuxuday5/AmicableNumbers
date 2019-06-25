#!/usr/bin/perl -I.
use SplitSeqBySum;
use Data::Dumper;

my $SplitDistance = SplitSeqBySum::GetEqualDistanceBySum 3000000,3;
print(Dumper($SplitDistance));
