# Amicable Number Implementation in Python3.7

```
$ ls -1
Amicable.pm
CmdLineArgs.pm
README.md
SplitSeqBySum.pm
test
useAmicable.pl
useAmicableThrdPrint.pl
useAmicableThrdQ.pl
```

#### Amicable.pm
Perl Package to find an Amicable Pair. It uses Moose.

#### CmdLineArgs.pm
Another perl package to parse command line args. This again uses Moose.

#### SplitSeqBySum.pm
This is a perl package, to split given end/till number into equal parts.
It splits based on no. of iterations. 

Given end number as 3 Million and parts as 3. It will not give as 1Million each.
Rather it will calculate how many iterations are required to find Amicable for a given number. 
Ex to find an Amicable Pair for no 2_000_000 will take more no. of iterations than to find pair for 1 million.

For example this is the sample output for 3Mill and 3 splits. It might not give exactly N splits for certain number.

```
SplitSeqBySum::GetEqualDistanceBySum 3000000,3;
$VAR1 = [
          [
            1,
            1700000
          ],
          [
            1700001,
            2400000
          ],
          [
            2400001,
            3000000
          ]
        ];
```


#### test

Directory containing some test/learning scripts.

#### useAmicable.pl useAmicableThrdPrint.pl useAmicableThrdQ.pl

** useAmicable.pl **
This version uses pipes & threads to find amicable numbers and send to parent.
Version with better performance.

```
$ perl useAmicable.pl  -a 1000000 -t 3
[1] Started with range 1-500000 at 1561466227 407739
[2] Started with range 500001-800000 at 1561466227 503716
[3] Started with range 800001-900000 at 1561466227 615698
[4] Started with range 900001-1000000 at 1561466227 708923
[P] Thread 3 exited..
[3] took 32.23(s) for range 800001-900000, pairs 3 exiting
[P] Thread 4 exited..
[4] took 35.91(s) for range 900001-1000000, pairs 4 exiting
[P] Thread 2 exited..
[2] took 89.19(s) for range 500001-800000, pairs 9 exiting
[1] took 98.64(s) for range 1-500000, pairs 28 exiting
(220,284)
(1184,1210)
(2620,2924)
....
(998104,1043096)
Total Pairs Between (1,1000000) is 44
Main thread took 98.98 secs
```

** useAmicableThrdQ.pl **
This version uses Thread::Queue & threads to find amicable numbers and send to parent.

```
$ perl useAmicableThrdPrint.pl  -a 1000000 -t 3
[1] Started with range 1-500000 at 1561466431 239700
1 -> 220,284
1 -> 1184,1210
[2] Started with range 500001-800000 at 1561466431 331664
1 -> 2620,2924
[3] Started with range 800001-900000 at 1561466431 431683
[4] Started with range 900001-1000000 at 1561466431 529022
1 -> 5020,5564
...
3 -> 898216,980984
[3] took 34.19(s) for range 800001-900000, pairs 3 exiting
2 -> 624184,691256
4 -> 998104,1043096
[4] took 41.18(s) for range 900001-1000000, pairs 4 exiting
...
1 -> 437456,455344
[2] took 94.11(s) for range 500001-800000, pairs 9 exiting
[1] took 104.55(s) for range 1-500000, pairs 28 exiting
Total Pairs Between (1,1000000) is 44
Main thread took 104.89 secs
```

** useAmicableThrdPrint.pl **
This version uses threads. The threads themselves print the pairs to stdout.

```
$ perl useAmicableThrdQ.pl  -a 1000000 -t 3
[1] Started with range 1-500000 at 1561466566 231734
[2] Started with range 500001-800000 at 1561466566 319707
[3] Started with range 800001-900000 at 1561466566 419713
[4] Started with range 900001-1000000 at 1561466566 527070
[3] took 51.30(s) for range 800001-900000 exiting
[3] exited
[4] exited
[4] took 60.67(s) for range 900001-1000000 exiting
[2] exited
[2] took 111.23(s) for range 500001-800000 exiting
[1] took 118.40(s) for range 1-500000 exiting
(220,284)
(1184,1210)
(2620,2924)
...
(998104,1043096)
Total Pairs Between (1,1000000) is 41
Main thread took 118.74 secs
```
