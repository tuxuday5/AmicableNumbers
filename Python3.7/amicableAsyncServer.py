#!/usr/bin/python3.7

import asyncio
import time
import json
import argparse
import sys
import pprint


class AmicableServer(asyncio.Protocol):
    _amicableProgram = './amicable.py'

    def __init__(self):
        self.transport = self._peer = ''
        self.end_time = self.start_time = ''
        self._from = self.to = ''
        self.alive = False
        self.subpro = None
        self.total_amicable_pairs = 0
        self.name = ''
        self.msg_id = 0

    def __del__(self):
        d=int(self.end_time-self.start_time)
        mins=int(d/60)
        secs=int(d%60)
        print(f'Served client {self.name} with pairs={self.total_amicable_pairs} in {mins:02d}m:{secs:02d}s')

    def connection_made(self,trans):
        self.alive = True
        self.transport = trans
        self.peer = trans.get_extra_info('peername')
        self.start_time =  time.perf_counter()
    
    def connection_lost(self,e):
        print('in connection_lost')
        self.transport.close()
        self.alive = False
        self.end_time =  time.perf_counter()

    def data_received(self,data): # from=no,to=no
        try:
            for msg in self.split_requests(data.decode()):
                #self.handle_client_request(msg)
                #asyncio.get_running_loop().call_soon(self.handle_client_request,msg)
                asyncio.get_running_loop().create_task(self.handle_client_request(msg))
        except TypeError as e:
            asyncio.get_running_loop().call_soon(self.close_connection)
            raise e

    def get_msg_id(self):
        self.msg_id+=1
        return self.msg_id

    def split_requests(self,requests):
        old_pos = 0
        msg = ''
        while old_pos<len(requests):
            try:
                msg,old_pos = json.JSONDecoder().raw_decode(requests,old_pos)
                yield msg
            except json.JSONDecodeError as e: ###TODO: What to do here
                asyncio.get_running_loop().call_soon(self.close_connection)

    async def handle_client_request(self,request):
        print(f'Got {request["type"]} from {request["name"]}')
        if request['type'] == 'hello':
            asyncio.get_running_loop().call_soon(self.handle_hello,request)
        elif request['type'] == 'amicable':
            #asyncio.get_running_loop().call_soon(self.handle_amicable,request)
            await self.handle_amicable(request)
        elif request['type'] == 'hb':
            asyncio.get_running_loop().call_soon(self.handle_hb,request)

    def get_response_defaults(self,resp_type,request):
        reply = {
            'sent_on' : time.ctime(),
            'type' : resp_type,
            'in_response_to' : request['msg_id'],
            'msg_id' : self.get_msg_id(),
            'iam' : 'server',
            'your' : self.name,
            'record' : [{}]
        }

        return reply

    def send_response(self,resp_type,response):
        print(f'Sending {resp_type} to {self.name}')
        asyncio.get_running_loop().call_soon(self.transport.write,response)

    def handle_hb(self,request):
        #reply = {
        #    'type' : 'hb',
        #    'sent_on' : time.ctime(),
        #    'record' : [{
        #        'response' : True
        #    }]
        #}
        reply = self.get_response_defaults('hb',request)
        reply['record'][0]['response'] = True

        asyncio.get_running_loop().call_soon(self.send_response,'hb',json.dumps(reply).encode())

    def set_name(self,request):
        if len(self.name) == 0:
            self.name = request['name']

    def handle_hello(self,request):
        #reply = {
        #    'type' : 'hello',
        #    'sent_on' : time.ctime(),
        #    'record' : [{
        #        'response' : 'hello'
        #    }]
        #}
        self.set_name(request)
        reply = self.get_response_defaults('hello',request)
        reply['record'][0]['response'] = 'hello'

        #self.transport.write(json.dumps(reply).encode())
        #asyncio.get_running_loop().call_soon(self.transport.write,json.dumps(reply).encode())
        asyncio.get_running_loop().call_soon(self.send_response,'hello',json.dumps(reply).encode())

    async def handle_amicable(self,request):
        self._from  = request['record'][0]['from']
        self.to     = request['record'][0]['to']
        self.set_name(request)
        self.sub_pro = await self.launch_subprocess(self.name)
        while self.alive:
            aLine 	= await self.sub_pro.stdout.readline()
            amicable 	= aLine.decode().lstrip().rstrip()
            if (len(amicable) == 0) and self.alive: ## eof
                #self.close_connection()
                asyncio.get_running_loop().call_soon(self.close_connection)
                break
            else:
                ###{name}->{i},{no1}
                self.total_amicable_pairs+=1
                #print(amicable)
                asyncio.get_running_loop().call_soon(print,amicable)
                (no1,no2) = [int(x) for x in amicable.split('->')[1].split(',')]
                reply = self.get_response_defaults('amicable',request)
                reply['record'][0]['number1'] = no1
                reply['record'][0]['number2'] = no2
                #reply = {
                #    'type' : 'amicable',
                #    'sent_on' : time.ctime(),
                #    'record' : [{
                #        'number1' : no1,
                #        'number2' : no2,
                #    }]
                #}
                #self.transport.write(bytes(json.dumps(reply).encode()))
                #asyncio.get_running_loop().call_soon(self.transport.write,bytes(json.dumps(reply).encode()))
                asyncio.get_running_loop().call_soon(self.send_response,'amicable',bytes(json.dumps(reply).encode()))

    async def launch_subprocess(self,name):
        print(f'Launching {sys.executable,AmicableServer._amicableProgram,"-s",str(self._from),"-e",str(self.to),"-n",name}')
        return await asyncio.create_subprocess_exec(
                      sys.executable, '-u', AmicableServer._amicableProgram,
                      '-s', str(self._from), '-e', str(self.to), '-n', name,
                      stdout=asyncio.subprocess.PIPE,
                      stderr=asyncio.subprocess.PIPE,
                      stdin=None)

    def close_connection(self):
        self.alive = False
        self.transport.close()

    def eof_received(self):
        self.close_connection()

async def main(port):
    loop = asyncio.get_running_loop()

    server = await loop.create_server(lambda: AmicableServer(), '127.0.0.1', port)

    async with server:
        await server.serve_forever()


if __name__ == '__main__':
    argParser = argparse.ArgumentParser()
    argParser.add_argument('-p','--port',type=int,default=9000)

    parsedArgs = vars(argParser.parse_args())

    sTime = time.perf_counter()
    try:
        asyncio.run(
            main(port=parsedArgs['port']),
            debug=True
        )
    except KeyboardInterrupt as e:
        pass

    eTime = time.perf_counter() - sTime

    print(f"Main thread took {eTime:0.4f} seconds")
