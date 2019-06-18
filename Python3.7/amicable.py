#!/usr/bin/python3.7 -u

import argparse
import os

def SumFactors(n: int) -> int:
    sumFact=0
    end=int(n**0.5)+1
    for i in range(1, end):
        if (n%i) == 0:
            sumFact+=i
            sumFact+=(n//i)

    return sumFact-n

def FindAmicablePairs(start: int,end: int,name: str) -> int:
    totalPairs=0
    pairs = {}
    pageSize=8192
    pageSize=32
    actualDataSize=0
    actualData=''
    name += ('-' + str(os.getpid()))
    for i in range(start,end):
        if pairs.get(i):
            continue

        no1 = SumFactors(i)
        if no1==i: # prime
            continue
        elif SumFactors(no1)==i:
            if not pairs.get(no1):
                actualData=f'{name}->{i},{no1}'
                print(f'{actualData}',flush=True)
                pairs[i] = no1
                pairs[no1] = i
                totalPairs+=1

    return totalPairs

if __name__ == '__main__':
    argParser = argparse.ArgumentParser()
    argParser.add_argument('-s','--start',type=int,required=True)
    argParser.add_argument('-e','--end',type=int,required=True)
    argParser.add_argument('-n','--name',type=str,required=True)

    parsedArgs = vars(argParser.parse_args())

    FindAmicablePairs(start=parsedArgs['start'],end=parsedArgs['end'],name=parsedArgs['name'])
