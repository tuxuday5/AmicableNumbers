package main

import (
	"fmt"
	"math"
  "time"
  "sort"
  _ "reflect"
)

type ChanDataType struct {
  amicable1 int
  amicable2 int
}

var NumThreads int = 3
var Counter int =3000000
var Amicable = make(map[int](int))
var Channels = make([]chan ChanDataType,NumThreads,NumThreads)
var AggChannel = make(chan ChanDataType)
var TaskDoneChannel = make(chan int)

func Log(where string, msg string) {
	fmt.Println(where + ": " + msg)
}

func GetMyAmicable(num int) int {
  var retVal int = 1
  var sqrt int =int(math.Sqrt(float64(num)))+1
  var i int

  for i=2;i<sqrt;i++ {
    if (num%i) == 0 {
      retVal += i + int(num/i)
    }
  }

  return retVal
}

func FindAmicablePairsFromTo(from int,to int,myChan chan<- ChanDataType) {
  var amicable,aNum,amicable1 int
  var ok bool
  var amicablePairs = make(map[int](int))

  //fmt.Printf("In FindAmicablePairsFromTo(%d,%d,%T)\n",from,to,myChan)
  for aNum=from;aNum<to+1;aNum+=1 {
    _, ok = amicablePairs[aNum]
    if ok {
      continue
    }

    amicable = GetMyAmicable(aNum)
    _, ok = amicablePairs[amicable]
    if ok {
      continue
    }

    amicable1 = GetMyAmicable(amicable)

    if amicable1==aNum && amicable!=amicable1 {
      amicablePairs[aNum] = amicable
      amicablePairs[amicable] = aNum
      myChan <- ChanDataType{aNum,amicable}
      //fmt.Printf("%d %d are amicable numbers\n",aNum,amicable)
    }
  }

  fmt.Printf("Routine with %d<->%d as args, done. Returning\n",from,to)
  close(myChan)
  return
}

func TransferToAggChannel(chnNo int,r chan ChanDataType,w chan ChanDataType,s chan int) {
  for d := range r {
    w <- d
  }

  s <- chnNo
} 

func GetSortedKeys(m map[int]int) []int {
  var i int = 0
  mapKeys := make([]int,len(m)) 

  for num1,_ := range m {
    mapKeys[i] = num1
    i++
  }

  sort.Ints(mapKeys)
  return mapKeys
}

func main() {
  var step = int(Counter/NumThreads)
  var i,j,openChans int
  var anAmicable ChanDataType
  var chnNo int
  var amicableCount int=0
  var sTime,eTime time.Time
  var amicablePairs = make(map[int](int))
  var ok1,ok2 bool

  i=0
  sTime = time.Now()
  for j=0;j<NumThreads;j++ {
    //Channels = append(Channels, make(chan ChanDataType))
    Channels[j] = make(chan ChanDataType)
    //fmt.Printf("go FindAmicablePairsFromTo(%d,%d,%d,%#v))\n",i,i+step,j,Channels[j])
    go FindAmicablePairsFromTo(i+1,i+step,Channels[j])
    go TransferToAggChannel(j,Channels[j],AggChannel,TaskDoneChannel)
    i+=step
  }

  for openChans=NumThreads; openChans > 0; {
    select {
    case anAmicable = <-AggChannel: {
      _, ok1 = amicablePairs[anAmicable.amicable1]
      _, ok2 = amicablePairs[anAmicable.amicable2]

      if !ok1  && !ok2 {
        amicablePairs[anAmicable.amicable1] = anAmicable.amicable2
        amicableCount++
      }
    }
    case chnNo = <-TaskDoneChannel: {
        fmt.Printf("channel %d closed\n",chnNo)
        openChans--
      }
    }
  }

  eTime = time.Now()

  for _,num1 := range GetSortedKeys(amicablePairs) {
    fmt.Printf("(%v) (%v) are amicable numbers\n",num1,amicablePairs[num1])
  }

  fmt.Printf("%d amicable Pairs, taking %v time\n",amicableCount,eTime.Sub(sTime).Round(time.Millisecond))
}
