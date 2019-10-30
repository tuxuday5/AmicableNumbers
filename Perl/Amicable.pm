package Amicable;
use Moose;

has Number => (
  'is' => 'rw',
  'isa' => 'Int',
  'clearer' => 'ClearNumber',
  'predicate' => 'HasNumber',
  'required' => 1,
  #'trigger' => sub {
  #  my ($Self,$New,$Old) = @_;

  #  print("After SetNumber , New=$New, Old=$Old\n");
  #},
);

has MyPair => (
  'is' => 'rw',
  'isa' => 'Int',
  'clearer' => 'ClearMyPair',
  'predicate' => 'IsMyPairSet',
  'init_arg' => undef,
  'builder' => '_FindMyPair',
  'writer' => '_SetMyPair',
  'lazy' => 1,
);

has IsAmicable => (
  'is' => 'rw',
  'isa' => 'Bool',
  'clearer' => 'ClearIsAmicable',
  'predicate' => 'IsAmicableSet',
  'init_arg' => undef,
  'builder' => '_FindIsAmicable',
  'writer' => '_SetIsAmicable',
  'lazy' => 1,
);

before 'Number' => sub {
  my ($Self) = @_;

  $Self->ClearIsAmicable if $Self->IsAmicableSet ;
  $Self->ClearMyPair if $Self->IsMyPairSet ;
};

#after 'ClearNumber' => sub {
#  my ($Self) = @_;
#
#  #print("In ClearNumber. No is ", ($Self->HasNumber ? 'defined' : 'not defined') , "\n");
#  $Self->ClearIsAmicable;
#  $Self->ClearMyPair;
#};

sub SumOfFactors($;$) {
  my ($Self,$No) = @_ ;
  my ($Sqrt,$SumOfFactors);
  my ($Number);

  $Number = defined $No ? $No: $Self->Number;
  $Sqrt   = int(sqrt($Number))+1;

  $SumOfFactors = 1;
  foreach my $i (2..$Sqrt) {
    if (($Number % $i)==0) {
      $SumOfFactors += $i;
      $SumOfFactors += int($Number/$i);
    }
  }

  return $SumOfFactors;
}

sub _FindIsAmicable() {
  my ($Self) = @_ ;
  my @Result = $Self->_FindAmicable;

  $Self->_SetMyPair($Result[1]);
  return $Result[0];
}

sub _FindMyPair() {
  my ($Self) = @_ ;
  my @Result = $Self->_FindAmicable;

  $Self->_SetIsAmicable($Result[0]);
  return $Result[1];
}

sub _FindAmicable() {
  my ($Self) = @_;

  #print("In _FindAmicable\n");
  return ($Self->IsAmicable,$Self->MyPair) if $Self->IsAmicableSet and $Self->IsMyPairSet;

  my ($SumOfFactors1,$SumOfFactors2) ;

  $SumOfFactors1 = $Self->SumOfFactors;

  if( $SumOfFactors1 == $Self->Number ) { #prime
    return (0,-1); 
  }

  $SumOfFactors2 = $Self->SumOfFactors($SumOfFactors1);
  if( $SumOfFactors2 != $Self->Number ) { #not amicable
    return (0,-1); 
  } else {
    return (1,$SumOfFactors1);
  }
}

1;
