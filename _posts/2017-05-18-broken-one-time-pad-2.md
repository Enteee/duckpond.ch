---
layout: post
title: "Broken One-time pad 2"
featured-image: /static/posts/broken-one-time-pad-2/wallet.png
categories: [security, math]
keywords: [one-time pad, challenge]
---

The key to [my new bitcoin wallet](https://blockchain.info/address/15DLuxjMPhYwyHUSXR7APSAiaHBbCKfpsr) can be downloaded by a simple `nc duckpond.ch 8889`.

# Key as a service 2

![QR-Code wallet](/static/posts/broken-one-time-pad-2/wallet.png)
*My bitcoin wallet*

```python
#!/usr/bin/env python3
# vim: set fenc=utf8 ts=4 sw=4 et :
import sys
import socket
import random

from threading import Thread

with open("key.png", "rb") as f:
    SECRET = f.read()

def client_thread(clientsocket):
    clientsocket.send(bytes([
        SECRET[i] ^ random.getrandbits(8)
        for i in range(len(SECRET))
    ]))
    clientsocket.close()

def main():
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.bind((socket.gethostname(), 8889))
    serversocket.listen()
    print('len(SECRET) = {} Bytes'.format(len(SECRET)))
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

Can you break it?[^1]


[^1]:[All the challenges can be found on github](https://github.com/Enteee/duckpond.ch/tree/master/_env/challenges).
