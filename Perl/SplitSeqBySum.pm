package SplitSeqBySum;
#use Data::Dumper ;

sub GetEqualDistanceBySum($$);
sub GetSumTill($\%) ;

our $SumOfNos100Thousand = 5;
our $IncForEvery100Thousand = 10; ### 10+Prev100ThousandSum
our $StepFor = 100000;

#my $SplitDistance = GetEqualDistanceSum 3000000,3;
#print(Dumper($SplitDistance));

sub GetEqualDistanceBySum($$) {
  my ($Till,$SplitTo) = @_ ;
  my (@EqualDistance,$EqualDistance,$NextEqualDistance);
  my ($SumTillAmicable,%BlocksSum);
  my ($StartNo) ;

  $SumTillAmicable = GetSumTill $Till,%BlocksSum;
  $EqualDistance  = int($SumTillAmicable/$SplitTo);

  #print("GetEqualDistanceFor $Till,$SumTillAmicable,$EqualDistance\n");

  $NextEqualDistance = $EqualDistance;
  $StartNo = 1;
  
  my @Blocks = sort {$a <=> $b} keys %BlocksSum;
  my $Block;
  for (my $BlockNo = 1 ; $BlockNo < @Blocks-1 ; $BlockNo++){
    $Block = $Blocks[$BlockNo+1] ; ### we are getting the prev block, that is BlockNo
    if((exists $BlocksSum{$Block}) and ($BlocksSum{$Block} > $NextEqualDistance)) {
      push @EqualDistance, [ $StartNo, $Blocks[$BlockNo] ] ;
      $NextEqualDistance += $EqualDistance;
      $StartNo = $Blocks[$BlockNo]+1;
    }
  } 

  push @EqualDistance, [$StartNo,$Till] if $StartNo < $Till;

  return [@EqualDistance];
}

sub GetSumTill($\%) {
  my ($Till,$BlocksSum) = @_ ;
  my ($Sum,$CurStep,$PrevBlocksSum) ;
  my (%BlocksSum);

  $CurStep = $StepFor;
  $Sum = $PrevBlocksSum = $SumOfNos100Thousand;
  
  while($CurStep < $Till) {
    $BlocksSum->{$CurStep} = $Sum;
    $Sum += $PrevBlocksSum + $IncForEvery100Thousand;
    $CurStep += $StepFor;
    $PrevBlocksSum += $IncForEvery100Thousand;
  }
  $BlocksSum->{$CurStep} = $Sum;

  return $Sum;
}
