---
layout: post
title: "Broken One-time pad 2"
categories: [security, math]
keywords: [one-time pad, challenge]
---

The key to [my new bitcoint wallet]() can be downloaded by a simple `duckpond.ch 8889`.

# Key as a service 2

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
    random.seed()
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

Can you break it?[^5]


[^1]:[All the challenges can be found on github](https://github.com/Enteee/duckpond.ch/tree/master/_env/challenges).

[broken one-time pad]:https://duckpond.ch/security/math/2016/09/15/broken-one-time-pad.html
[one-time pad]:https://en.wikipedia.org/wiki/One-time_pad
[Vigenerer cipher]:https://en.wikipedia.org/wiki/Vigen%C3%A8re_cipher

[QR-Code]:https://de.wikipedia.org/wiki/QR-Code
[PNG]:https://en.wikipedia.org/wiki/Portable_Network_Graphics
[base64]:https://en.wikipedia.org/wiki/Base64
