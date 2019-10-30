package SplitSeqBySum;
#use Data::Dumper ;

sub GetEqualDistanceBySum($$);
sub GetSumTill($\%) ;

#Math::Utils::fsum(0..100000)=Block-Sum=5.00B Total-Sum=5.00B
#Math::Utils::fsum(100000..200000)=Block-Sum=15.00B Total-Sum=20.00B
#Math::Utils::fsum(200000..300000)=Block-Sum=25.00B Total-Sum=45.00B
#Math::Utils::fsum(300000..400000)=Block-Sum=35.00B Total-Sum=80.00B
#Math::Utils::fsum(400000..500000)=Block-Sum=45.00B Total-Sum=125.00B
#Math::Utils::fsum(500000..600000)=Block-Sum=55.00B Total-Sum=180.00B
#Math::Utils::fsum(600000..700000)=Block-Sum=65.00B Total-Sum=245.00B
#Math::Utils::fsum(700000..800000)=Block-Sum=75.00B Total-Sum=320.00B
#Math::Utils::fsum(800000..900000)=Block-Sum=85.00B Total-Sum=405.00B
#Math::Utils::fsum(900000..1000000)=Block-Sum=95.00B Total-Sum=500.00B
#Math::Utils::fsum(1000000..1100000)=Block-Sum=105.00B Total-Sum=605.01B

$SplitSeqBySum::SumOfNos100k = 5;
$SplitSeqBySum::IncForEvery100k = 10; ### 10+Prev100ThousandSum
$SplitSeqBySum::aBlock = 100000;

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
  for (my $BlockNo = 0 ; $BlockNo < @Blocks-1 ; $BlockNo++){
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

  $CurStep = $SplitSeqBySum::aBlock;
  $Sum = $PrevBlocksSum = $SplitSeqBySum::SumOfNos100k;
  
  while($CurStep < $Till) {
    $BlocksSum->{$CurStep} = $Sum;
    $Sum += $PrevBlocksSum + $SplitSeqBySum::IncForEvery100k;
    $CurStep += $SplitSeqBySum::aBlock;
    $PrevBlocksSum += $SplitSeqBySum::IncForEvery100k;
  }
  $BlocksSum->{$CurStep} = $Sum;

  return $Sum;
}
