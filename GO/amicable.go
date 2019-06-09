package main

import (
	"fmt"
	"math"
  "time"
)

var Counter int =3000000
var Amicable = make(map[int](int))

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

func main() {
  var amicable,aNum,amicable1 int
  var sTime,eTime time.Time
  var ok bool

  sTime = time.Now()
  for aNum=200;aNum<Counter+1;aNum+=1 {
    _, ok = Amicable[aNum]
    if ok {
      continue
    }

    amicable = GetMyAmicable(aNum)
    _, ok = Amicable[amicable]
    if ok {
      continue
    }

    amicable1 = GetMyAmicable(amicable)

    if amicable1==aNum && amicable!=amicable1 {
      Amicable[aNum] = amicable
      Amicable[amicable] = aNum
      fmt.Printf("(%d) (%d) are amicable numbers\n",aNum,amicable)
    }
  }
  eTime = time.Now()
  fmt.Printf("%d amicable Pairs, taking %v time\n",len(Amicable)/2,eTime.Sub(sTime).Round(time.Millisecond))
}
