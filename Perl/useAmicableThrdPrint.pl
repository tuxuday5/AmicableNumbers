#!/usr/bin/perl -I.
use Amicable;
use CmdLineArgs;
use SplitSeqBySum;
use Sys::CpuAffinity;
use Time::HiRes;
use Data::Dumper;
use threads (
  'stack_size' => 64*1024,
  'exit' => 'threads_only',
  'stringify'
);
use Thread::Queue;
sub LaunchThreads($$$) ;
sub DeQueueNos($$\%);
sub FindAmicable($$$$);
sub PrintPairs(\%) ;
sub WaitForThreads(\@) ;
sub Main($) ;

Main(CmdLineArgs->new_with_options());

sub Main($) {
  my ($Args) = @_;
  my ($NumCpus,@Threads,$Queue,%Pairs);
  my ($Thread,$PairCount,$SequenceSplits);
  my (@TimeStart) = Time::HiRes::gettimeofday();
  
  $NumCpus  = Sys::CpuAffinity::getNumCpus();
  $NumCpus--; ##starts from 0
  Sys::CpuAffinity::setAffinity($$,[$NumCpus]);
  
  $SequenceSplits = SplitSeqBySum::GetEqualDistanceBySum $Args->Amicable,$Args->Threads;

  @Threads = LaunchThreads $SequenceSplits,$Args->Threads,$NumCpus ;
  
  $PairCount = WaitForThreads @Threads ;
  
  PrintPairs %Pairs;
  printf("Total Pairs Between (1,%d) is %d\n",$Args->Amicable,$PairCount);
  printf("Main thread took %.2f secs\n",Time::HiRes::tv_interval(\@TimeStart));
}

sub LaunchThreads($$$) {
  my ($SequenceList,$TotalThreads,$NumCpus) = @_ ;
  my (@Threads,$Core,$Thread) ;

  $Core   = $NumCpus-1;
  foreach my $SeqRange (@$SequenceList) {
    $Thread = threads->create(
      'FindAmicable',$SeqRange->[0],$SeqRange->[1],$Core
    );
  
    push @Threads,$Thread;
  }
  continue {
    unless($Core) { ##0, reset
      $Core = $NumCpus;
    } else {
      $Core--;
    }
  }

  return (@Threads);
}


sub DeQueueNos($$\%) {
  my ($Queue,$TotalThreads,$Pairs) = @_ ;
  my ($Pair,$Tid,$Num1,$Num2);
  my ($Cntrl);

  $Cntrl  = $TotalThreads;
  while($Cntrl) {
    #print "Waiting for data in Q\n";
    $Pair = $Queue->dequeue(); ##will block
    ($Tid,$Num1,$Num2) = @$Pair;
  
    if(defined $Pair) {
      if( ($Num1==0) and ($Num2==0) ) { 
        ##Thread signaled that its done
        printf("[%d] exited\n",$Tid);
        $Cntrl--;
      } else {
        #print join ",", @$Pair;
        #print "\n";
        unless ((exists $Pairs->{$Num1}) or (exists $Pairs->{$Num2})) {
          $Pairs->{$Num1} = $Num2;
        }
      }
    } else { ###TODO: when this condition will kick?
      printf("Queue returned undefined data....\n");
      CORE::break;
    }
  }
}

sub PrintPairs(\%) {
  my ($Pairs) = @_;

  foreach my $Key (sort {$a<=>$b} keys %$Pairs) {
    printf("(%d,%d)\n",$Key,$Pairs->{$Key});
  }
}

sub WaitForThreads(\@) {
  my ($Threads) = @_;
  my $PairCount  = 0;

  foreach my $Thread (@$Threads) {
    $PairCount += $Thread->join();
  }
  return $PairCount;
}

sub FindAmicable($$$$) {
  my ($StartNo,$EndNo,$Core) = @_ ;
  my ($Obj,$TotalPairs,%Pairs);
  my @TimeStart = Time::HiRes::gettimeofday();

  Sys::CpuAffinity::setAffinity($$,[$Core]);
  my $Tid = threads->tid();

  printf("[$Tid] Started with range $StartNo-$EndNo at @TimeStart\n");
  #printf("[%d] Started with range $StartNo-$EndNo\n",$Tid,$StartNo,$EndNo);

  foreach my $Number ($StartNo..$EndNo) {
    next if( exists $Pairs{$Number}) ;

    if(not defined $Obj) {
      $Obj  = Amicable->new('Number' => $Number);
    } else {
      $Obj->Number($Number);
    }
    
    #printf("$Tid -> %d,%d\n",$Number,$Obj->MyPair) if $Obj->IsAmicable  ;
    if($Obj->IsAmicable) {
      unless( (exists $Pairs{$Number}) or (exists $Pairs{$Obj->MyPair}) ) {
        $Pairs{$Number} = $Obj->MyPair;
        $TotalPairs++;
        print("$Tid -> $Number,$Pairs{$Number}\n");
      }
    }
  
    $Obj->ClearNumber;
  }

  printf("[$Tid] took %.2f(s) for range $StartNo-$EndNo, pairs $TotalPairs exiting\n",Time::HiRes::tv_interval(\@TimeStart));
  return $TotalPairs; #as we find amicable for both nos in a pair
}
__END__
step=amicable/threads
core=getNumCpus
start=200
end=step
while threads
 thread = create_thread start end q core
 push thread
continue
  threads--
  start=end,end=start+step
  core++
  if core==maxcores
    core=0

while threads
  d = q.get_data
  if d==thread_exiting
    threads--
  else
    h[d.1] = d.2
    h[d.2] = d.1

while threads
  thread.join

pairs=0
while k,v = h
  print k,v
  pairs++
