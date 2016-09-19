---
layout: post
title: "Broken One-time pad 2"
categories: [security, math]
keywords: [one-time pad, challenge]
---

The [broken one-time pad] was solved. On reddit a user called svvw [claimed to be the one](https://www.reddit.com/r/cryptography/comments/52vktn/broken_onetime_pad_lets_implement_crypto_and/d7p6e1w) who did it.

> At least I was able to recover a QR code, and transfer some bitcoins to myself... I think, I'm very much a noob wrt. to this cryptocurrency stuff.
> The basic idea is this:
> * The cipher is essentially a Vigenerer cipher
> * The key length is provided (1024*100)
> * The plaintext space is very limited (only valid base64 chars)
> So what one can do, is split the ciphertext into 1024*100 blocks such that each character in block i was encrypted with key-byte i. This means we can simply look for each key-byte separately. When assessing whether or not some byte k could be a key-byte, one simply checks that only valid base64 characters is the result, when calculating "k xor c" for every c in some block.
> Putting it all together (obtaining the QR code and so on) was done with python + some command line tools.
> I'll try and write a little more detailed description later, a long with the code I wrote to solve it.

In this post I'll first try to reconstruct svvw's solution, then present my own. At the end we'll fix the found issues in the [broken one-time pad] and restart the challenge.

# Notation And Mental Image

A message, in our case the [base64] encoded [PNG] image, shall be denoted $$ m $$. The pad which acts as a key will be called $$ k $$, and the resulting ciphertext $$ c $$. The corresponging lengths $$ \vert m \vert = p $$, $$ \vert k \vert = q $$ and $$ \vert c \vert = l $$. The algorithm implements a periodic cipher, thus the following graphic will become handy:

![repeating pad](/static/posts/broken-one-time-pad-2/repeating_pad.png)
*Graphic to keep in mind*

# svvw's Solution

First things first, the implementation should reassemble a [one-time pad]. Due to It's broken nature it becomes somewhat similar to a [Vigenerer cipher], but it's not a [Vigenerer cipher]. Nevertheless cryptoanalysis techniques such as frequency analysis will work on the [broken one-time pad] in a similar fashion. [^1]

Let us reconstruct what svvw did. First we need an other definition:

> The plaintext space is very limited (only valid base64 chars)

Which means the set of valid message characters $$ M $$ can be defined as $$ M = \{ 'a', 'b', 'c', \dots, 'A', 'B', 'C', \dots, '+', '/' \} $$. Using this definition we can start working on the algorithm.

> So what one can do, is split the ciphertext into 1024*100 blocks ... 

because $$ \vert k \vert = 1024 * 100 $$ (from algorithm)

> ... such that each character in block i was encrypted with key-byte i. This means we can simply look for each key-byte separately.

For $$ i = 1 $$ this would correspond to the red lines in the following graphic:

![repeating pad](/static/posts/broken-one-time-pad-2/repeating_pad_ieq1.png)
*Image to keep in mind*

> When assessing whether or not some byte k could be a key-byte, one simply checks that only valid base64 characters is the result, when calculating "k xor c" for every c in some block.

Which means for a given $$ c, \vert k \vert $$ the following condition must hold

\begin{equation}
    \forall_{i \in \{1, \dots, \vert k \vert \}} \{ x \mid x = k_{i} \oplus c_{i * \vert k \vert} \} \subset M 
\end{equation}

# Key As a Service 

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

Now I can connect via TCP to [duckpond.ch:8888](duckpond.ch:8888) and retrieve my key. As safe as it gets! [^1][^2]

[^1]: That makes me wonder if somebody already sampled relative character frequencies of [base64] encoded [PNG] images.

[broken one-time pad]:https://duckpond.ch/security/math/2016/09/15/broken-one-time-pad.html
[one-time pad]:https://en.wikipedia.org/wiki/One-time_pad
[Vigenerer cipher]:https://en.wikipedia.org/wiki/Vigen%C3%A8re_cipher

[QR-Code]:https://de.wikipedia.org/wiki/QR-Code
[PNG]:https://en.wikipedia.org/wiki/Portable_Network_Graphics
[base64]:https://en.wikipedia.org/wiki/Base64
