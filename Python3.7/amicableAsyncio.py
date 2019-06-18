#!/usr/bin/python3.7

import asyncio
import time
import argparse
import pprint

async def SumFactors(n: int) -> int:
    sumFact=0
    end=int(n**0.5)+1
    for i in range(1, end):
        if (n%i) == 0:
            sumFact+=i
            sumFact+=(n//i)

    return sumFact-n

async def FindAmicablePairs(start: int,end: int,q: asyncio.Queue) -> dict():
    totalPairs=0
    pairs = {}
    retPair = {}
    name = str(int) + '-' + str(end)
    for i in range(start,end):
        if pairs.get(i):
            continue

        no1 = await SumFactors(i)
        if no1==i: # prime
            continue
        elif await SumFactors(no1)==i:
            if not pairs.get(no1):
                await asyncio.sleep(0.001) ## co-op routine!
                pairs[i] = no1
                pairs[no1] = i
                retPair[i] = no1
                totalPairs+=1

    return retPair

async def main(till: int, threads: int):
    step = int(till/threads)
    qSize= int(int(till/1000000)*100)
    q    = asyncio.Queue(maxsize=qSize)

    tasks = []
    for i in range(200,till,step):
        tasks.append(
            asyncio.create_task(FindAmicablePairs(start=i,end=i+step,q=q)) 
        )

    totalPairs = await asyncio.gather(*tasks)
    uniquePairs = {}
    for x in totalPairs:
        uniquePairs.update(x)

    for t in tasks:
        t.cancel()

    pprint.pprint(uniquePairs)
    return None
    
if __name__ == '__main__':
    argParser = argparse.ArgumentParser()
    argParser.add_argument('-a','--amicable',type=int,default=3000000)
    argParser.add_argument('-t','--threads',type=int,default=3)

    parsedArgs = vars(argParser.parse_args())

    sTime = time.perf_counter()
    asyncio.run(
        main(till=parsedArgs['amicable'],threads=parsedArgs['threads']),
        debug=True
    )
    eTime = time.perf_counter() - sTime

    print(f"Main thread took {eTime:0.4f} seconds")
