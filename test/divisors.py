import sys

def divisor(x,r,d=1):
    if d == x:
        #r.append(d)
        return
    elif (x%d)==0:
        r.append(d)

    divisor(d=d+1,x=x,r=r)


x = int(sys.argv[1])
r = []

divisor(x=x,r=r)

print(r)
x=sum(r)
print(x)

r = []
divisor(x=x,r=r)

print(r)
print(sum(r));
