#!/usr/bin/perl -I.
use Amicable;
use CmdLineArgs;
use SplitSeqBySum;
use Sys::CpuAffinity;
use Time::HiRes;
use Data::Dumper;
use IO::Poll;
use threads (
  'stack_size' => 64*1024,
  'exit' => 'threads_only',
  'stringify'
);
use Thread::Queue;
sub LaunchThreads($$$\@\@) ;
sub ReadNos($\@\%) ;
sub FindAmicable($$$$);
sub PrintPairs(\%) ;
sub WaitForThreads(\@) ;
sub Main($) ;

Main(CmdLineArgs->new_with_options());

sub Main($) {
  my ($Args) = @_;
  my ($NumCpus,@Threads,$Queue,%Pairs);
  my (@Handles);
  my ($Thread,$PairCount,$SequenceSplits);
  my (@TimeStart) = Time::HiRes::gettimeofday();
  
  $NumCpus  = Sys::CpuAffinity::getNumCpus();
  $NumCpus--; ##starts from 0
  Sys::CpuAffinity::setAffinity($$,[$NumCpus]);
  
  $SequenceSplits = SplitSeqBySum::GetEqualDistanceBySum $Args->Amicable,$Args->Threads;

  LaunchThreads $SequenceSplits,$Args->Threads,$NumCpus,@Threads,@Handles ;
  ReadNos $Args->Threads,@Handles,%Pairs;
  
  $PairCount = WaitForThreads @Threads ;
  
  PrintPairs %Pairs;
  printf("Total Pairs Between (1,%d) is %d\n",$Args->Amicable,$PairCount);
  printf("Main thread took %.2f secs\n",Time::HiRes::tv_interval(\@TimeStart));
}

sub LaunchThreads($$$\@\@) {
  my ($SequenceList,$TotalThreads,$NumCpus,$Threads,$Handles) = @_ ;
  my (@Threads,$Core,$Thread,) ;
  my (@Handles);

  $Core   = $NumCpus-1;
  foreach my $SeqRange (@$SequenceList) {
    my($ReadHandle,$WriteHandle);
    pipe $ReadHandle,$WriteHandle or die "pipe: $!\n";

    #print "$ReadHandle,$WriteHandle\n";
    #printf( "%d,%d\n",fileno($ReadHandle),fileno($WriteHandle));
    $Thread = threads->create(
      'FindAmicable',$SeqRange->[0],$SeqRange->[1],$Core,$WriteHandle
    );
  
    push @$Threads,$Thread;
    push @$Handles,$ReadHandle;
  }
  continue {
    unless($Core) { ##0, reset
      $Core = $NumCpus;
    } else {
      $Core--;
    }
  }

  #return (@Threads,@Handles);
}


sub ReadNos($\@\%) {
  my ($TotalThreads,$Handles,$Pairs) = @_ ;
  my ($Pair,$Tid,$Num1,$Num2);
  my ($Cntrl);
  my ($PollObj,@Handles,$Handle);
  my ($PollEvents,$Line);

  @Handles = @$Handles;
  $PollObj = IO::Poll->new() or die "IO::Poll->new() : $!\n";
  $PollObj->mask($_ => POLLIN) foreach (@Handles);

  $Cntrl  = $TotalThreads;
  #select(STDOUT); $| = 1;
  while($Cntrl) {

    $PollObj->poll(1);
    for(my $Idx=0;$Idx < @Handles; $Idx++) {
      $Handle = $Handles[$Idx] ;
      $PollEvents = $PollObj->events($Handle);

      if( $PollEvents & POLLIN ) {
        chomp($Line = <$Handle>);

        ($Tid,$Num1,$Num2) = split ',',$Line;

        unless ((exists $Pairs->{$Num1}) or (exists $Pairs->{$Num2})) {
          ## if no isn't in pair
          $Pairs->{$Num1} = $Num2;
          #print("$Tid,$Num1,$Num2\n");
          #print "$Tid";
        } 
      } elsif ( $PollEvents & POLLHUP ) {
        printf("[P] Thread %d exited..\n",$Idx+1);
        $PollObj->mask($Handle,0); ## Remove the handle!
        $Cntrl--;
      } elsif ($PollEvents) { ##TODO: Deal this!
        print("[P] UnHandled poll Event ->$PollEvents<- in Handle ->$Handle<-\n");
      }
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
  my ($StartNo,$EndNo,$Core,$Handle) = @_ ;
  my ($Obj,$TotalPairs,%Pairs);
  my @TimeStart = Time::HiRes::gettimeofday();

  Sys::CpuAffinity::setAffinity($$,[$Core]);
  my $Tid = threads->tid();

  printf("[$Tid] Started with range $StartNo-$EndNo at @TimeStart\n");
  #printf("[%d] Started with range $StartNo-$EndNo\n",$Tid,$StartNo,$EndNo);

  select($Handle); $| = 1;
  foreach my $Number ($StartNo..$EndNo) {
    next if( exists $Pairs{$Number}) ;

    if(not defined $Obj) {
      $Obj  = Amicable->new('Number' => $Number);
    } else {
      $Obj->Number($Number);
    }
    
    if($Obj->IsAmicable) {
      unless( (exists $Pairs{$Number}) or (exists $Pairs{$Obj->MyPair}) ) {
        $Pairs{$Number} = $Obj->MyPair;
        $TotalPairs++;
        print "$Tid,$Number,$Pairs{$Number}\n";
      }
    }
  
    $Obj->ClearNumber;
  }

  close($Handle);
  select(STDOUT);
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
