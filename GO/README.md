# Amicable Number Implementation in GO

```
$ ls -1
amicable_co.go
amicable_co_sel_case.go
amicable.go
README.md
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
