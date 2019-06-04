package main

import (
	"fmt"
	"math"
  "reflect"
)

type ChanDataType struct {
  amicable1 int
  amicable2 int
}

var NumThreads int = 3
var Counter int =1000000
var Amicable = make(map[int](int))
var Channels = make([]chan ChanDataType,NumThreads,NumThreads)

func Log(where string, msg string) {
	fmt.Println(where + ": " + msg)
}

func GetMyAmicable(num int) int {
  var retVal int = 0
  var sqrt int =int(math.Sqrt(float64(num)))+1
  var i int

  for i=1;i<sqrt;i++ {
    if (num%i) == 0 {
      retVal += i + int(num/i)
    }
  }

  return retVal-num
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

func main() {
  var step = int(Counter/NumThreads)
  var i,j,openChans int

  i=1
  for j=0;j<NumThreads;j+=1 {
    //Channels = append(Channels, make(chan ChanDataType))
    Channels[j] = make(chan ChanDataType)
    //fmt.Printf("go FindAmicablePairsFromTo(%d,%d,%d,%#v))\n",i,i+step,j,Channels[j])
    go FindAmicablePairsFromTo(i,i+step,Channels[j])
    i+=step
  }

  selectableChans := make([]reflect.SelectCase, NumThreads)

  for i=0;i<NumThreads;i++ {
    selectableChans[i] = reflect.SelectCase{ 
      Dir: reflect.SelectRecv,
      Chan: reflect.ValueOf(Channels[i]),
    }
  }

  var amicableCount int=0
  for openChans=0; openChans < NumThreads; {
    dataAvailableIn, data, ok := reflect.Select(selectableChans)

    if !ok {
      //selectableChans[dataAvailableIn].Chan = reflect.ValueOf(nil)
      selectableChans = append(selectableChans[:dataAvailableIn],selectableChans[dataAvailableIn+1:]...)
      //fmt.Printf("%d channel closed\n",dataAvailableIn)
      openChans++
      continue
    }

    fmt.Printf("%v %v are amicable numbers\n",data.Field(0),data.Field(1))
    amicableCount++
  }

  fmt.Printf("%d amicable pairs\n",amicableCount)

}
