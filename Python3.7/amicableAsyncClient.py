#!/usr/bin/python3.7

import asyncio
import time
import json
import pprint
import argparse

class AmicableClient(asyncio.Protocol):
    def __init__(self, name, on_connection_lost, loop,start,end):
        self.name = name
        self.on_connection_lost = on_connection_lost
        self.loop = loop
        self.start = start
        self.to = end
        self.msg_id = 0

    def connection_made(self,trans):
        self._transport = trans
        #self._transport.write("Sending this to server".encode())
        self.send_hello()
        asyncio.get_running_loop().call_soon(self.send_hb)
        asyncio.get_running_loop().call_soon(self.send_amicable)

    def connection_lost(self,e):
        print('Connection Lost to server')
        self.close_connection()
        self.on_connection_lost.set_result(True)

    def eof_received(self):
        self.close_connection()
    
    def get_msg_id(self):
        self.msg_id+=1
        return self.msg_id

    def send_hb(self):
        request = {
            'type' : 'hb',
            'sent_on' : time.ctime(),
            'msg_id' : self.get_msg_id(),
            'name' : self.name,
            'record' : [{
                'request' : True,
            }]
        }

        self._transport.write(json.dumps(request).encode())
        asyncio.get_running_loop().call_later(20,self.send_hb)

    def send_hello(self):
        request = {
            'type' : 'hello',
            'sent_on' : time.ctime(),
            'msg_id' : self.get_msg_id(),
            'name' : self.name,
            'record' : [{
                'request' : 'hello'
            }]
        }

        self._transport.write(json.dumps(request).encode())

    def send_amicable(self):
        request = {
            'type' : 'amicable',
            'sent_on' : time.ctime(),
            'msg_id' : self.get_msg_id(),
            'name' : self.name,
            'record' : [{
                'from' : self.start,
                'to' : self.to,
            }]
        }

        self._transport.write(json.dumps(request).encode())

    def data_received(self,data): # from=no,to=no
        try:
            #print(data.decode())
            for msg in self.split_response(data.decode()):
                asyncio.get_running_loop().call_soon(self.handle_server_response,msg)
                #print(msg)
        except TypeError as e:
            self._alive = False
            self.close_connection()
            raise e

    def handle_server_response(self,response):
        if response['type'] == 'hello':
            asyncio.get_running_loop().call_soon(self.handle_hello,response)
        elif response['type'] == 'amicable':
            asyncio.get_running_loop().call_soon(self.handle_amicable,response)
        elif response['type'] == 'hb':
            asyncio.get_running_loop().call_soon(self.handle_hb,response)

    def handle_response(self,resp_type,response):
        print(f'Got {resp_type} from server')
        #pprint.pprint(response)

    def handle_hello(self,response):
        self.handle_response('hello',response)

    def handle_hb(self,response):
        self.handle_response('hb',response)

    def handle_amicable(self,response):
        self.handle_response('amicable',response)
        print(f'{response["record"][0]["number1"],response["record"][0]["number2"]}')

    def close_connection(self):
        self._transport.close()

    def split_response(self,requests):
        old_pos = 0
        msg = ''
        while old_pos<len(requests):
            try:
                msg,old_pos = json.JSONDecoder().raw_decode(requests,old_pos)
                yield msg
            except json.JSONDecodeError as e: ###TODO: What to do here
                self._alive = False
                self.close_connection()

async def main(start:int,end:int,name:str,port:int,host:str):
    loop = asyncio.get_running_loop()

    fut = loop.create_future()
    transport, protocol = await loop.create_connection( 
        lambda: AmicableClient(name, fut, loop,start,end), 
        host,
        port)

    try:
        await fut
    finally:
        transport.close()

if __name__ == '__main__':
    argParser = argparse.ArgumentParser()
    argParser.add_argument('-s','--start',type=int,required=True)
    argParser.add_argument('-e','--end',type=int,required=True)
    argParser.add_argument('-n','--name',type=str,required=True)
    argParser.add_argument('-p','--port',type=int,required=False,default=9000)
    argParser.add_argument('-i','--ip',type=str,required=False,default='127.0.0.1')

    parsedArgs = vars(argParser.parse_args())

    asyncio.run(main(start=parsedArgs['start'],
                     end=parsedArgs['end'],
                     name=parsedArgs['name'],
                     host=parsedArgs['ip'],
                     port=parsedArgs['port']))
