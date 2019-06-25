#!/usr/bin/perl -I.
use Amicable;
use CmdLineArgs;

my $Args = CmdLineArgs->new_with_options();
my $Obj = undef;

foreach my $Number (200..$Args->Amicable) {
  if(not defined $Obj) {
    $Obj  = Amicable->new('Number' => $Number);
  } else {
    $Obj->Number($Number);
  }
  
  #print("$Number ", ($Obj->IsAmicable ? "is" : "isn't") , " Amicable.");
  printf("%d,%d\n",$Number,$Obj->MyPair) if $Obj->IsAmicable  ;

  $Obj->ClearNumber;
}
