#include <stdlib.h>
#include <stdio.h>

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

void errExit(const char* s) {
  perror(s);
  exit(EXIT_FAILURE);
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
  for(int i=0;i<c->last_stored_index;i++)
    if( (c->a[i]->amicable1==num) || (c->a[i]->amicable2==num) )
      return 1;

  return 0;
}

void ResetAmicableNumbers(struct AmicableArrayContainer *c) {
  for(int i=0;i<c->cap;i++)
    c->a[i]->amicable1 = c->a[i]->amicable2 = -1;
}

void PrintAmicableNumbers(struct AmicableArrayContainer *c) {
  for(int i=0;i<c->cap;i++)
    printf("array[%d]=(%d,%d) are amicable\n",i,c->a[i]->amicable1,c->a[i]->amicable2);
}


int main() {
  int COUNT=10;
  struct AmicableArrayContainer *c = CreateAmicableArrayContainer(COUNT);
  struct Amicable a;

  for(int i=0;i<COUNT;i++) {
    a.amicable1=i;
    a.amicable2=i*i;
    AddAmicable(c,&a);
  }

  PrintAmicableNumbers(c);

  FreeAmicableArrayContainer(c);
}
