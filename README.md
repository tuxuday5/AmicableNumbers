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
