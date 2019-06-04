# AmicableNumbers
Implementation of Amicable Numbers if few programming languages.

[Amicable Numbers](https://en.wikipedia.org/wiki/Amicable_numbers) are special pair(x,y) of numbers. 
Sum(proper-divisors of x)=y, and
Sum(proper-divisors of y)=x

Example being 220 & 284

```
Proper Divisors of 220
sum([1, 2, 4, 5, 10, 11, 20, 22, 44, 55, 110])=284

Proper Divisors of 284
sum([1, 2, 4, 71, 142])=220
```

*Proper divisors are postivie factor of a number, than the number itself.*

Here we have implementations in 2 languages. C & Go.

### C

#### amicabe_st.c

  This is a single thread implementation. Given a number X, this program finds amicable pairs till that number.

```
$ make -f Makefile.amicable amicable_st
gcc -Wall -c -I. -ggdb amicable_st.c
gcc -o amicable_st amicable_st.o -pthread -lm

$ ./amicable_st 
num_cores is 4, setting affinity to 1 core, for 2973693760
num_cores is 4, setting affinity to 2 core, for 2961450752
284 220 are amicable numbers
1210 1184 are amicable numbers
....
1043096 998104 are amicable numbers
13518708659 ns to find amicable numbers from 1-1000000. Total pairs 42
```

#### amicable.c

  This is a multi-threaded implementation. The program launches 3 threads, since my system being 4 cores.

```
$ make -f Makefile.amicable amicable
gcc -Wall -c -I. -ggdb amicable.c
gcc -o amicable amicable.o -pthread -lm

$ ./amicable
num_cores is 4, setting affinity to 1 core, for 3921864512
num_cores is 4, setting affinity to 3 core, for 3901228800
num_cores is 4, setting affinity to 2 core, for 3909621504
284 220 are amicable numbers
1210 1184 are amicable numbers
...
1125765 947835 are amicable numbers
1043096 998104 are amicable numbers
25.8148 secs to find amicable numbers from 1-3000000. Total pairs 67
```

### GO
#### amicable.go

This is single thread implementation. No goroutines involved.

```
$ child_ru go run amicable.go 
220 284 are amicable numbers
1184 1210 are amicable numbers
....
+-------------+------------+-------------+------+--------+---------------+---------------+--------+---------+-----------+-------------+
|Usr CPU      |Sys CPU     |Elap Time    |CPU % |RSS Max |Soft PgFaults  |Hard PgFaults  |Read FS |Write FS |Vol Switch |InVol Switch |
+-------------+------------+-------------+------+--------+---------------+---------------+--------+---------+-----------+-------------+
|10(s).95(us) |0(s).13(us) |10(s).93(us) |101.4 |34396KB |14250          |0              |0       |2400     |2624       |974          |
+-------------+------------+-------------+------+--------+---------------+---------------+--------+---------+-----------+-------------+
```

#### amicable_co.go

This implementation uses go routine. My system has 4 cores(not exactly!), so it launches 3 go routines. Another core for the main thread.
Whatever is the configured no. upto which the program should find amicable numbers, is divided into 3. Each goroutine sharing the task of finding amicable pair till that number.

* if max no is 100. *
- coroutine 1 will find pairs from 1 till 33
- coroutine 2 will find pairs from 34 till 66
- coroutine 3 will find pairs from 67 till 100

All these routines will find amicable pairs till range given to them and will write to a channel. Now the main thread has to dynamcally listen for data in these N channels, N being 3 here. Since i did't want to hardcode 3 and there isn't a straight forward method to dynamically read from N channels, choose to launch another N aggregate coroutines. These N aggregate coroutines will read from N amicable thread channels and write to an aggregator channel. Once they are done they will write to a status channel, to indicate an amicabe thread is finished.

```
  for j=0;j<NumThreads;j++ {
    Channels[j] = make(chan ChanDataType)
    go FindAmicablePairsFromTo(i,i+step,Channels[j])
    go TransferToAggChannel(j,Channels[j],AggChannel,TaskDoneChannel)
    i+=step
  }
```

```
$ child_ru go run amicable_co.go 
220 284 are amicable numbers
1184 1210 are amicable numbers
...
998104 1043096 are amicable numbers
channel 2 closed
49 amicable Pairs
+--------------+-----------+-------------+------+--------+---------------+---------------+--------+---------+-----------+--------------+
|Usr CPU       |Sys CPU    |Elap Time    |CPU % |RSS Max |Soft PgFaults  |Hard PgFaults  |Read FS |Write FS |Vol Switch |InVol Switch  |
+--------------+-----------+-------------+------+--------+---------------+---------------+--------+---------+-----------+--------------+
|10(s).94(us)  |0(s).7(us) |5(s).22(us)  |211.0 |34108KB |16830          |0              |32      |2520     |2310       |1148          |
+--------------+-----------+-------------+------+--------+---------------+---------------+--------+---------+-----------+--------------+
```

You can see from the single thread implementation the elapsed time has halved.

#### amicable_co_sel_case.go

This is again N coroutine implementation. It uses [reflect.SelectCase](https://golang.org/pkg/reflect/#Select) to listen on N channels dyanmically.

```
$ child_ru go run amicable_co_sel_case.go 
220 284 are amicable numbers
1184 1210 are amicable numbers
...
998104 1043096 are amicable numbers
Routine with 666667<->1000000 as args, done. Returning
49 amicable pairs
+-------------+-----------+-------------+------+--------+---------------+---------------+--------+---------+-----------+--------------+
|Usr CPU      |Sys CPU    |Elap Time    |CPU % |RSS Max |Soft PgFaults  |Hard PgFaults  |Read FS |Write FS |Vol Switch |InVol Switch  |
+-------------+-----------+-------------+------+--------+---------------+---------------+--------+---------+-----------+--------------+
|11(s).4(us)  |0(s).9(us) |5(s).35(us)  |207.7 |34276KB |18178          |1              |424     |2536     |2594       |1205          |
+-------------+-----------+-------------+------+--------+---------------+---------------+--------+---------+-----------+--------------+
```

This implementation takes almost same time as Aggregator channel method, which is surprising. Because the aggregator channel has N more coroutines!
