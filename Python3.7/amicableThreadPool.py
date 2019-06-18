import concurrent.futures
import math
import time

def SumFactors(n: int) -> int:
    sumFact=0
    end=int(n**0.5)+1
    for i in range(1, end):
        if (n%i) == 0:
            sumFact+=i
            sumFact+=(n//i)

    return sumFact-n

def FindAmicablePairs(start: int,end: int,name: str) -> int:
    pairs = {}
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

    return pairs

def main(till: int, threads: int, tout: int=10.0):
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        step = int(till/threads)
    
        tasks = [ executor.submit(FindAmicablePairs(start=i,end=i+step)) for i in range(200,till,step)]

        while len(tasks) > 0:
            done, pending = concurrent.futures.wait(tasks,return_when=FIRST_COMPLETED)

            for d in done:
                print(d.result)

            tasks = pending

if __name__ == '__main__':
    argParser = argparse.ArgumentParser()
    tout = 1.0
    argParser.add_argument('-a','--amicable',type=int,default=3000000)
    argParser.add_argument('-t','--threads',type=int,default=3)

    parsedArgs = vars(argParser.parse_args())

    sTime = time.perf_counter()
    main(till=parsedArgs['amicable'],threads=parsedArgs['threads'],tout=tout),
    eTime = time.perf_counter() - sTime

    print(f"Main thread took {eTime-tout:0.4f} seconds")
