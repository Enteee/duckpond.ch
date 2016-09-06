---
layout: post
categories: [security, math]
keywords: [one time pad, otp]
---

There are many mistakes to be made when implementing crypto. So let's make a couple, abuse them and learn:

I keep forgetting the key to [my bitcoin wallet](https://blockchain.info/address/1LdtdP1qHWU9hQbjAX3U64MxYV7ABDEyy5). So I took a photo from my key, converted it to a [PNG], [base64] encoded it and set up the following service. 

```python
#!/usr/bin/env python3
# vim: set fenc=utf8 ts=4 sw=4 et :
import sys
import socket
import random
from threading import Thread

WELCOME = bytes(
"""
Hello this is one time pad protected, thus unbreakable!
Keep the money if you can break it.
""",'utf-8')

SECRET = bytes(
"""
*** BASE64 ENCODED PNG GOES HERE ***
""", 'utf-8')

PAD_LENGTH = 1024 * 100

def gcd(a, b):
    """Return greatest common divisor using Euclid's Algorithm"""
    while b:      
        a, b = b, a % b
    return a

def lcm(a, b):
    """Return lowest common multiple of a and b"""
    return a * b // gcd(a, b)

def client_thread(clientsocket):
    random.seed()
    pad = [ random.getrandbits(8) for i in range(PAD_LENGTH) ]
    if clientsocket.send(WELCOME) == 0:
        return
    i = 0
    while True:
        s = SECRET[i % len(SECRET)]
        p = pad[i % len(pad)]
        b = bytes([s ^ p])
        if clientsocket.send(b) == 0:
            return
        i+=1

def main():
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.bind((socket.gethostname(), 8888))
    serversocket.listen()
    print('len(SECRET) = {} Bytes'.format(len(SECRET)))
    print('len(pad) = {} Bytes'.format(PAD_LENGTH))
    print('shift = {} Bytes'.format(PAD_LENGTH % len(SECRET)))
    print('Repeat after {} MiB'.format(lcm(PAD_LENGTH,len(SECRET)) / 1024 ** 2))
    sys.stdout.flush()
    while True:
        # accept connections on socket
        (clientsocket, address) = serversocket.accept()
        print('Client connected {}'.format(address))
        sys.stdout.flush()
        thread = Thread(target = client_thread, args = (clientsocket, ))
        thread.start()

if __name__ == "__main__":
    main()
```

Now I can connect via TCP to [duckpond.ch:8888](duckpond.ch:8888) and retreive my key anytime. As save as it gets, or is it?

[PNG]:https://en.wikipedia.org/wiki/Portable_Network_Graphics
[base64]:https://en.wikipedia.org/wiki/Base64
