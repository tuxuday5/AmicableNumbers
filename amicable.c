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
#include <poll.h>

#define AMICABLE_ARRAY_SIZE 128
#define AMICABLE_TILL 3000000

#define THREADS 3
#define MAIN_THREAD_CORE 0

struct Amicable {
  int amicable1;
  int amicable2;
};

struct AmicableArrayContainer {
  struct Amicable **a;
  int cap;
  int last_stored_index;
  int created ;
};

struct ThreadData {
  int readfd;
  int writefd;
  int from;
  int to;
  int core_id;
};

void errExit(const char* s) {
  perror(s);
  exit(EXIT_FAILURE);
}

long long unsigned time_ns() {
  struct timespec ts;
  if (clock_gettime(CLOCK_REALTIME, &ts)) {
    exit(1);
  }
  return ((long long unsigned)ts.tv_sec) * 1000000000LLU +
         (long long unsigned)ts.tv_nsec;
}

int stick_this_thread_to_core(int core_id) {
	int num_cores = sysconf(_SC_NPROCESSORS_ONLN);
	if (core_id < 0 || core_id >= num_cores)
	 	return -1;
	
	cpu_set_t cpuset;
	CPU_ZERO(&cpuset);
	CPU_SET(core_id, &cpuset);
	
	pthread_t current_thread = pthread_self();    
	printf("num_cores is %d, setting affinity to %d core, for %u\n",num_cores,core_id,(unsigned int)current_thread);
	return pthread_setaffinity_np(current_thread, sizeof(cpu_set_t), &cpuset);
}

int AddAmicable(struct AmicableArrayContainer *c,struct Amicable *p) {
  int i;

  if( (c->last_stored_index+1) == c->cap) {
    printf("last_stored_index=%d,cap=%d,%d\n",c->last_stored_index,c->cap,p->amicable1);
    errExit("Amicable array capacity exceded");
  }

  c->last_stored_index++;
  i = c->last_stored_index;

  c->a[i]->amicable1 = p->amicable1;
  c->a[i]->amicable2 = p->amicable2;

  return i;
}

struct AmicableArrayContainer *CreateAmicableArrayContainer(int cap) {
  struct AmicableArrayContainer *c = malloc(sizeof(struct AmicableArrayContainer));

  if( !c)
      errExit("malloc");

  c->cap = cap;
  c->last_stored_index = -1;
  c->a = malloc(sizeof(struct Amicable *)*c->cap);

  if( !c->a)
      errExit("malloc");
  
  for( int i=0;i < c->cap; i++) {
    c->a[i] = malloc(sizeof(struct Amicable));

    if( ! c->a[i] )
      errExit("malloc");

    c->a[i]->amicable1 = c->a[i]->amicable2 = -1;
  }

  return c;
}


void FreeAmicableArrayContainer(struct AmicableArrayContainer *c ) {
  for( int i=0;i < c->cap; i++)
    free(c->a[i]);

  free(c->a);
  free(c);
}

int WasAmicableFound(struct AmicableArrayContainer *c,int num) {
  for(int i=0;i<=c->last_stored_index;i++) {
    if( (c->a[i]->amicable1==num) || (c->a[i]->amicable2==num) ) {
      //printf("num=%d,a[%d].amicable1=%d,a[%d].amicable2=%d\n",num,i,c->a[i]->amicable1,i,c->a[i]->amicable2);
      return 1;
    }
  }

  return 0;
}

void ResetAmicableNumbers(struct AmicableArrayContainer *c) {
  for(int i=0;i<c->cap;i++)
    c->a[i]->amicable1 = c->a[i]->amicable2 = -1;
}

void PrintAmicableNumbers(struct AmicableArrayContainer *c) {
  for(int i=0;i<c->last_stored_index;i++)
    printf("array[%d]=(%d,%d) are amicable\n",i,c->a[i]->amicable1,c->a[i]->amicable2);
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

void FindAmicablePairsFromTo(struct ThreadData *t,struct AmicableArrayContainer *c) {
  struct Amicable anAmicable;
  size_t amicableSize = sizeof(anAmicable);
  int amicable1,amicable2,aNum;

  for(aNum=t->from;aNum<=t->to;aNum++) {
    if( WasAmicableFound(c,aNum) )
        continue;

    amicable1 = GetMyAmicable(aNum);
    if( WasAmicableFound(c,amicable1))
        continue;

    amicable2 = GetMyAmicable(amicable1);

    if(amicable2==aNum && amicable2!=amicable1) {
      anAmicable.amicable1 = amicable1;
      anAmicable.amicable2 = amicable2;
      AddAmicable( c,&anAmicable );
      //PrintAmicableNumbers(c);

      if (write(t->writefd, &anAmicable, amicableSize) != amicableSize) {
        errExit("write");
      }
    }
  }

  printf("Routine with %d<->%d as args, done. Returning\n",t->from,t->to);
  return ;
}

void* threadfunc(void* d) {
  struct ThreadData *p=(struct ThreadData *)d;
  struct AmicableArrayContainer *c = CreateAmicableArrayContainer(AMICABLE_ARRAY_SIZE);

  stick_this_thread_to_core(p->core_id);
  FindAmicablePairsFromTo(p,c);
  FreeAmicableArrayContainer(c);
  close(p->writefd);

  return NULL;
}


int main(int argc, const char** argv) {
  size_t readSize;
  struct Amicable anAmicable;

  int pipe_fds[THREADS][2] ;
  pthread_t childt[THREADS];
  struct ThreadData thread_data[THREADS] ;
  struct pollfd poll_thread_pipes[THREADS];

  size_t amicableSize = sizeof(anAmicable);
  int amicablePairs=0;
  int i,step,start_no,end_no;
  int remainingThreads;

  const long long unsigned t1 = time_ns();

  memset(poll_thread_pipes,'\0',sizeof(poll_thread_pipes));
  stick_this_thread_to_core(MAIN_THREAD_CORE);

  start_no = 1;
  step=(int)AMICABLE_TILL/THREADS;
  end_no = start_no+step;

  for(i=0;i<THREADS;i++) {
    if (pipe(pipe_fds[i]) == -1)
      errExit("pipe");

    thread_data[i].readfd = pipe_fds[i][0];
    thread_data[i].writefd= pipe_fds[i][1];
    thread_data[i].core_id= MAIN_THREAD_CORE+1+i;
    thread_data[i].from   = start_no;
    thread_data[i].to     = end_no;

    poll_thread_pipes[i].fd     = pipe_fds[i][0] ;
    poll_thread_pipes[i].events = POLLIN;

    if(pthread_create(&childt[i], NULL, threadfunc, (void*)&thread_data[i]))
      errExit("pthread_create");

    start_no = end_no+1 ;
    end_no += step ;
  }

  amicablePairs=0;
  remainingThreads=THREADS;

  struct AmicableArrayContainer *c = CreateAmicableArrayContainer(AMICABLE_ARRAY_SIZE);

  while(remainingThreads>0) {
    if(poll(poll_thread_pipes,THREADS,-1)<0) {
      errExit("poll");
    }

    for(i=0;i<THREADS;i++) {
      if(poll_thread_pipes[i].revents & POLLIN) {
        readSize = read(poll_thread_pipes[i].fd, &anAmicable, amicableSize);
        if (readSize == amicableSize) {

          if(WasAmicableFound(c,anAmicable.amicable1) || WasAmicableFound(c,anAmicable.amicable2))
            continue;

          printf("%d %d are amicable numbers\n",anAmicable.amicable1,anAmicable.amicable2);
          AddAmicable(c,&anAmicable);
          amicablePairs++;
        } else if (readSize == 0) { //eof
          printf("read() returned 0 on thread id %d\n",i);
          poll_thread_pipes[i].fd = -1;
          continue;
        } else {
          printf("read() returned error on thread id %d\n",i);
        }
      } else if(poll_thread_pipes[i].revents & POLLHUP) { // eof
        remainingThreads--;
        poll_thread_pipes[i].fd = -1;
        //printf("thread id %d, got POLLHUP, dec remainingThreads %d",i,remainingThreads);
      } else if(poll_thread_pipes[i].revents & POLLNVAL) { // invalid file descriptor
        printf("poll() returned POLLNVAL on thread id %d\n",i);
        poll_thread_pipes[i].fd = -1;
      }
    }
  }

  FreeAmicableArrayContainer(c);

  const long long unsigned elapsed = time_ns() - t1;

  const long long unsigned nano_second = 1000 * 1000 * 1000;
  printf("%.4f secs to find amicable numbers from %d-%d. Total pairs %d\n",
      ((float)elapsed/(float)nano_second),1,AMICABLE_TILL,amicablePairs);

  /*
  if (pthread_join(childt, NULL)) {
    errExit("pthread_join");
  }
  */

  return 0;
}
