import concurrent.futures
import time
import argparse
import pprint

def SumFactors(n: int) -> int:
    sumFact=0
    end=int(n**0.5)+1
    for i in range(1, end):
        if (n%i) == 0:
            sumFact+=i
            sumFact+=(n//i)

    return sumFact-n

def FindAmicablePairs(start: int,end: int) -> {}:
    pairs = {}
    retPair = {}
    for i in range(start,end):
        if pairs.get(i):
            continue

        no1 = SumFactors(i)
        if no1==i: # prime
            continue
        elif SumFactors(no1)==i:
            if not pairs.get(no1):
                pairs[i] = no1
                pairs[no1] = i
                retPair[i] = no1

    return retPair

def main(till: int, threads: int):
    with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
        step = int(till/threads)
    
        tasks = [ executor.submit(FindAmicablePairs,i,i+step) for i in range(200,till,step)]

        pairs = {}
        while len(tasks) > 0:
            done, pending = concurrent.futures.wait(tasks,return_when=concurrent.futures.FIRST_COMPLETED)

            for d in done:
                pairs.update(d.result())

            tasks = pending

        pprint.pprint(pairs)

if __name__ == '__main__':
    argParser = argparse.ArgumentParser()
    argParser.add_argument('-a','--amicable',type=int,required=True)
    argParser.add_argument('-t','--threads',type=int,default=3)

    parsedArgs = vars(argParser.parse_args())

    sTime = time.perf_counter()
    main(till=parsedArgs['amicable'],threads=parsedArgs['threads'])
    eTime = time.perf_counter() - sTime

    print(f"Main thread took {eTime:0.4f} seconds")
