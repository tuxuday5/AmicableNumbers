// Measuring thread switching time using a UNIX pipe.
//
// Eli Bendersky [http://eli.thegreenplace.net]
// This code is in the public domain.
#define _GNU_SOURCE
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#include <math.h>
#include <sched.h>

#define AMICABLE_ARRAY_SIZE 128
#define AMICABLE_TILL 3000000

#define THREADS 3
#define MAIN_THREAD_CORE 0
#define WORKER_THREAD_CORE 2

struct Amicable {
  int amicable1;
  int amicable2;
};

struct Amicable AmicableNumbers[AMICABLE_ARRAY_SIZE];

struct PipeInfo {
  int readfd;
  int writefd;
};


int stick_this_thread_to_core(int core_id) {
   int num_cores = sysconf(_SC_NPROCESSORS_ONLN);
   if (core_id < 0 || core_id >= num_cores)
      return -1;

  //return 0;
   cpu_set_t cpuset;
   CPU_ZERO(&cpuset);
   CPU_SET(core_id, &cpuset);

   pthread_t current_thread = pthread_self();    
  printf("num_cores is %d, setting affinity to %d core, for %u\n",num_cores,core_id,(unsigned int)current_thread);
   return pthread_setaffinity_np(current_thread, sizeof(cpu_set_t), &cpuset);
}

static inline long long unsigned time_ns() {
  struct timespec ts;
  if (clock_gettime(CLOCK_REALTIME, &ts)) {
    exit(1);
  }
  return ((long long unsigned)ts.tv_sec) * 1000000000LLU +
         (long long unsigned)ts.tv_nsec;
}

void errExit(const char* s) {
  perror(s);
  exit(EXIT_FAILURE);
}


int GetMyAmicable(int num) {
  int sqrt = ((int)sqrtf(num)) + 1;
  int retVal = 0;

  for(int i=1;i<sqrt;i++) {
    if((num%i) == 0){
      retVal += i ; 
      retVal += (int)num/i;
    }
  }

  return retVal-num;
}

int AddAmicable(struct Amicable *p) {
  static int LastAmicableIndex=0;

  if((LastAmicableIndex+1)==AMICABLE_ARRAY_SIZE)
    errExit("AMICABLE_ARRAY_SIZE exceded");

  AmicableNumbers[LastAmicableIndex].amicable1 = p->amicable1;
  AmicableNumbers[LastAmicableIndex].amicable2 = p->amicable2;

  return ++LastAmicableIndex;
}

int WasAmicableFound(int num) {
  for(int i=0;i<AMICABLE_ARRAY_SIZE;i++)
    if( (AmicableNumbers[i].amicable1==num) || (AmicableNumbers[i].amicable2==num) )
      return 1;

  return 0;
}

void ClearAmicableNumbers() {
  for(int i=0;i<AMICABLE_ARRAY_SIZE;i++)
    AmicableNumbers[i].amicable1 = AmicableNumbers[i].amicable2 = -1;
}

void FindAmicablePairsFromTo(int from,int to,void *p) {
  struct PipeInfo* pipe_info = (struct PipeInfo*)p;
  struct Amicable anAmicable;
  size_t amicableSize = sizeof(anAmicable);
  int amicable1,amicable2,aNum;

  for(aNum=from;aNum<to+1;aNum+=1){
    if( WasAmicableFound(aNum) )
        continue;

    amicable1 = GetMyAmicable(aNum);
    if( WasAmicableFound(amicable1))
        continue;

    amicable2 = GetMyAmicable(amicable1);

    if(amicable2==aNum && amicable2!=amicable1) {
      anAmicable.amicable1 = amicable1;
      anAmicable.amicable2 = amicable2;
      AddAmicable( &anAmicable );

      //printf("Wrote amicable pairs to parent. %d %d\n",anAmicable.amicable1,anAmicable.amicable2);

      if (write(pipe_info->writefd, &anAmicable, amicableSize) != amicableSize) {
        errExit("write");
      }
    }
  }

  printf("Routine with %d<->%d as args, done. Returning\n",from,to);
  close(pipe_info->writefd);
  return ;
}

void* threadfunc(void* p) {

  stick_this_thread_to_core(WORKER_THREAD_CORE);
  FindAmicablePairsFromTo(1,AMICABLE_TILL,p);

  return NULL;
}


int main(int argc, const char** argv) {
  size_t readSize;
  struct Amicable anAmicable;
  size_t amicableSize = sizeof(anAmicable);
  int amicablePairs=0;

  int main_to_child[2];
  if (pipe(main_to_child) == -1) {
    errExit("pipe");
  }

  int child_to_main[2];
  if (pipe(child_to_main) == -1) {
    errExit("pipe");
  }

  struct PipeInfo main_fds = {.writefd = main_to_child[1],
                              .readfd = child_to_main[0]};
  struct PipeInfo child_fds = {.writefd = child_to_main[1],
                               .readfd = main_to_child[0]};

  ClearAmicableNumbers();
  stick_this_thread_to_core(MAIN_THREAD_CORE);

  pthread_t childt;
  pthread_create(&childt, NULL, threadfunc, (void*)&child_fds);

  const long long unsigned t1 = time_ns();

  amicablePairs=0;
  while(1) {
    readSize = read(main_fds.readfd, &anAmicable, amicableSize);
    if (readSize == amicableSize) {
      printf("%d %d are amicable numbers\n",anAmicable.amicable1,anAmicable.amicable2);
      amicablePairs++;
    } else if (readSize == 0) { //eof
      break;
    } else {
      errExit("read");
    }
  }

  if (pthread_join(childt, NULL)) {
    errExit("pthread_join");
  }


  const long long unsigned elapsed = time_ns() - t1;

  const long long unsigned nano_second = 1000 * 1000 * 1000;
  printf("%.4f secs to find amicable numbers from %d-%d. Total pairs %d\n",
      ((float)elapsed/(float)nano_second),1,AMICABLE_TILL,amicablePairs);


  return 0;
}
