#!/usr/bin/python3.7

import asyncio
import time
import argparse
import sys


async def main(till: int, threads: int, tout: int=10.0):
    amicableProgram = 'amicable.py'
    step = int(till/threads)

    subProcesses = []
    streams = []
    name = ''
    j=1
    for i in range(200,till,step):
        name = f'P{j:0d}'
        subpro = await asyncio.create_subprocess_exec(
                         sys.executable, '-u', amicableProgram,
                         '-s', str(i), '-e', str(i+step),
                         '-n', name,
                         stdout=asyncio.subprocess.PIPE,
                         stderr=asyncio.subprocess.PIPE,
                         stdin=None)

        subProcesses.append(subpro)
        streams.append(subpro.stdout)
        j+=1

    coRoutines = threads
    done = pending = totalPairs=0
    while coRoutines:
        try:
            readStreams  = [streams[i].readline() for i in range(len(streams))]
            done,pending = await asyncio.wait(readStreams,return_when=asyncio.FIRST_COMPLETED)
            for result in pending:
                result.cancel()
            for result in done:
                aLine = result.result().decode().lstrip().rstrip()
                if len(aLine) == 0:
                    #streams = [*streams[:i],*streams[i+1:]]
                    coRoutines-=1
                    break
                else:
                    print(aLine)
                totalPairs+=1
                i+=1
        except Exception as e:
            raise e

    for p in subProcesses:
        await p.wait()

    print(f'Numbers {1,till} has {totalPairs} of amicable pairs')
    return None
    
if __name__ == '__main__':
    argParser = argparse.ArgumentParser()
    tout = 0.0
    argParser.add_argument('-a','--amicable',type=int,default=3000000)
    argParser.add_argument('-t','--threads',type=int,default=3)

    parsedArgs = vars(argParser.parse_args())

    sTime = time.perf_counter()
    asyncio.run(
        main(till=parsedArgs['amicable'],threads=parsedArgs['threads'],tout=tout),
        debug=True
    )
    eTime = time.perf_counter() - sTime
    eTime -= (tout*parsedArgs['threads'])

    print(f"Main thread took {eTime:0.4f} seconds")
