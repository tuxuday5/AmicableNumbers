# Amicable Number Implementation in Python3.7

```
$ ls -1
amicableAsyncServer.py
amicableAsyncClient.py
amicable.py
amicableAsyncSubProcess.py
amicableAsyncio.py
amicableThreadPool.py
cmd
README.md
```

#### amicableThreadPool.py
Python program to find amicable pairs.
This uses concurrent.future module and launches N threads, N as per args.

```
$ python3.7 amicableThreadPool.py  -a 10000
{220: 284, 1184: 1210, 2620: 2924, 5020: 5564, 6232: 6368}
```

If you monitor the threads using the watch command in test/watch. 
Though one has N cores, the total CPU % of all threads doesn't cross 100%.
GIL at play?

#### amicableAsyncio.py
Python program to find amicable pairs.
This is a single process implemetation, without any threds/subprocesses. 
Captures usage of asyncio in single thread compute intensive task.

```
$ python3.7 amicableAsyncio.py -h
usage: amicableAsyncio.py [-h] [-a AMICABLE] [-t THREADS]

optional arguments:
  -h, --help            show this help message and exit
  -a AMICABLE, --amicable AMICABLE
  -t THREADS, --threads THREADS

```
-a NUM til the given num amicable pairs will be computed.
-t NUM this is actually the no. of co-routines to launch. 

#### amicableAsyncSubProcess.py
Python program to find amicable pairs.
Uses asyncio, so can be ran with python3.7 only.

```
$ python3.7 amicableAsyncSubProcess.py -h
usage: amicableAsyncSubProcess.py [-h] [-a AMICABLE] [-t THREADS]

optional arguments:
  -h, --help            show this help message and exit
  -a AMICABLE, --amicable AMICABLE
  -t THREADS, --threads THREADS
```

-a NUM til the given num amicable pairs will be computed.
-t NUM no. of subprocesses to launch, keep it to number of cores in your system-1.

#### amicable.py

Python program to find amicable pairs.
Find amicable paris between the given number range and prints to stdout.
This is used by ** amicableAsyncServer.py & amicableAsyncSubProcess.py **

```
$ ./amicable.py -h
usage: amicable.py [-h] -s START -e END -n NAME

optional arguments:
  -h, --help            show this help message and exit
  -s START, --start START
  -e END, --end END
  -n NAME, --name NAME
```

#### amicableAsyncClient.py amicableAsyncServer.py

These are asyncio Server & Client implementations using asyncio.Protocol.
The server uses asyncio.subprocess to find amicable pairs for every client, as these are cpu intensive tasks.
The python program amicable.py should be in the same directory as the server program.

** python3.7 amicableAsyncServer.py -p PORT **
** python3.7 amicableAsyncClient.py -p PORT -s FROM -e TILL -n NAME **

FROM/TILL are range between which the client should request server for amicable pairs. 
NAME is a string, so that server can use it to reference this client.
PORT is the tcp port, defaults to 9000. Apart from this all other are mandatory

```
$ /usr/bin/python3.7 -u amicableAsyncServer.py                         
Got hello from test1                                                      
Got hb from test1        
Got amicable from test1                     
Launching ('/usr/bin/python3.7', './amicable.py', '-s', '200', '-e', '1000200', '-n', 'test1')                                      
Sending hello to test1 
Sending hb to test1                                                                           
test1-21560->220,284                                                      
Sending amicable to test1
```

```
$ /usr/bin/python3.7 amicableAsyncClient.py -s 2000000 -e 3000000 -n test3
Got hello from server
Got hb from server
Got hb from server
Got amicable from server
(2062570, 1669910)
Got amicable from server
```
