---
layout: post
categories: [security, math]
keywords: [one time pad, broken, challenge]
---

There are many mistakes to be made when implementing crypto. So let's make some, abuse them and learn:

# Broken one time pad

I keep forgetting the key to [my bitcoin wallet](https://blockchain.info/address/1LdtdP1qHWU9hQbjAX3U64MxYV7ABDEyy5).

![QR-Code wallet](/static/posts/broken-one-time-pad/wallet.png){: .dontstretch }
*My bitcoin wallet*

So I saved my key as a [QR-Code]. Converted it to a [PNG]. [base64] encoded the [PNG], and set up the following service:

```python
#!/usr/bin/env python3
# vim: set fenc=utf8 ts=4 sw=4 et :
import sys
import socket
import random

from threading import Thread
from math import gcd
from base64 import b64encode

def lcm(a, b):
    """Return lowest common multiple of a and b"""
    return a * b // gcd(a, b)

with open("key.png", "rb") as f:
    SECRET = b64encode(f.read())

PAD_LENGTH = 1024 * 100
REPEAT = lcm(PAD_LENGTH, len(SECRET))

def client_thread(clientsocket):
    random.seed()
    pad = [ random.getrandbits(8) for i in range(PAD_LENGTH) ]
    for i in range(REPEAT):
        s = SECRET[i % len(SECRET)]
        p = pad[i % len(pad)]
        b = bytes([s ^ p])
        if clientsocket.send(b) == 0:
            return
    clientsocket.close()

def main():
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.bind((socket.gethostname(), 8888))
    serversocket.listen()
    print('len(SECRET) = {} Bytes'.format(len(SECRET)))
    print('len(pad) = {} Bytes'.format(PAD_LENGTH))
    print('shift = {} Bytes'.format(PAD_LENGTH % len(SECRET)))
    print('Repeat after {} MiB'.format(REPEAT / 1024 ** 2))
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

Now I can connect via TCP to [duckpond.ch:8888](duckpond.ch:8888) and retrieve my key. As safe as it gets! [^1]

[^1]: Feel free to Keep the money if you can break it.

[QR-Code]:https://de.wikipedia.org/wiki/QR-Code
[PNG]:https://en.wikipedia.org/wiki/Portable_Network_Graphics
[base64]:https://en.wikipedia.org/wiki/Base64
