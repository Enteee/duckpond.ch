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

A more detailed writeup can be found on [github](https://github.com/potater/broken-one-time-pad).

In this post I'll first try to reconstruct svvw's solution, then present my own. At the end we'll fix the found issues in the [broken one-time pad] and restart the challenge.

# Notation and visualization

The message stream $$ m $$ equals the repeated [base64] encoded [PNG] image. The pad stream $$ k $$ reassembles a key stream. The XOR of both streams is the resulting ciphertext stream $$ c = m \oplus p $$. The streams are all chunked and indexed in bytes, e.g. $$ m_{3} $$ is the third byte in the message stream. The streams repeat themselves after $$ \vert m \vert $$, respectively $$ \vert k \vert $$ bytes. In general $$ \vert m \vert \neq \vert k \vert $$ which means after every repetition of the shorter, they are shifted by $$ \DeclareMathOperator{\abs}{abs} s = abs( \vert m \vert - \vert k \vert ) $$ bytes. Important to notice is that the two streams always line up after $$ \DeclareMathOperator{\lcm}{lcm} \vert c \vert = \lcm(\vert m \vert, \vert k \vert) $$ bytes.

Variants of the following graphic are used to visualize the two streams. The outer ring represents the key stream $$ k $$. The inner the message stream $$ m $$. The upper right corner magnifies a section of the two strings.

![repeating pad](/static/posts/broken-one-time-pad-2/repeating_pad.svg)
*The two streams aligned*

# svvw's solution

First things first, [broken one-time pad] should implement an [one-time pad]. [^1] Due to the broken nature of the implementation it becomes similar to a [Vigenerer cipher]. Cryptoanalysis techniques working on [Vigenerer cipher]s will mostly work on the [broken one-time pad]. [^2]

But now let's get started reconstructing svvw's solution. First we've to find out $$ \vert c \vert $$. From the visualization we can derive that $$ \DeclareMathOperator{\lcm}{lcm} \vert c \vert = \lcm(\vert m \vert, \vert k \vert) $$, which is excatly as many bytes as we'll get from the server. [^3] Thus, obtaining $$ \vert c \vert $$ is as simple as:

```
$ nc duckpond.ch 8888 | wc -c
```

Which yields 14028800 Bytes (13.37890625 MiB), so $$ \vert c \vert = 14028800 $$. 

> So what one can do, is split the ciphertext into 1024*100 blocks ... 

We can get this number directly from the [broken one-time pad], so $$ \vert k \vert = 1024 \cdot 100 $$.

![repeating pad](/static/posts/broken-one-time-pad-2/repeating_pad_k_known.svg)
*Known $$ \vert k \vert $$*

> ... such that each character in block i was encrypted with key-byte i. This means we can simply look for each key-byte separately.

For $$ i = 1 $$ this would correspond to the red lines in the following visualization:

![repeating pad](/static/posts/broken-one-time-pad-2/repeating_pad_ieq1.svg)
*e.g. $$ i = 1 $$*

> When assessing whether or not some byte k could be a key-byte, one simply checks that only valid base64 characters ...

With $$ M $$ as the set of valid base64 characters,

$$ M = \{ \text{'a'}, \text{'b'}, \text{'c'}, \dots, \text{'A'}, \text{'B'}, \text{'C'}, \dots, \text{'+'}, \text{'/'}, \text{'='}\} $$

every byte in $$ m $$ has to be a character from $$ M $$. 

$$ \forall_{j \in \mathbb{N}} m_{j} \in M $$

> ... is the result, when calculating "k xor c" for every c in some block.

Which means for a given $$ c $$ and $$ k $$ the following condition must hold:

$$ \forall_{i \in \{1, \dots, \vert k \vert \}} \forall_{j \in \{1, \dots, \vert c \vert \}}\{ x \mid x = k_{i} \oplus c_{i + j \vert k \vert} \} \subset M $$

$$ M $$ contains few elements, so this comes in handy.

With all this information it is straight forward to write a guessing algorithm for $$ k_{i} $$.

```python
with open('data', 'rb') as fd:
    C = fd.read()

M = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+/=')
K_REPEAT = 1024 * 100
C_REPEAT = 14028800

def guess_k_i(i):
    for candidate in range(256):
        if all(
            [ 
                chr(candidate ^ C[i + j * K_REPEAT]) in M
                for j in range(int(C_REPEAT / K_REPEAT))
            ]
        ):
            yield candidate
```

We could now get $$ k $$

```python
K = [ [ k_i for k_i in guess_k_i(i) ] for i in range(K_REPEAT) ]
```

but this takes ages to complete. So we've to parallelize the algorithm.

```python
from multiprocessing import Pool

def k_i(i):
    return [ k for k in guess_k_i(i) ]

K = Pool().map(k_i, range(K_REPEAT))
```

It can happen that this finds multiple possible solutions for a certain $$ k_{i} $$. So we verify that this is not the case.

```python
all([
    len(k_i) == 1 
    for k_i in K
])
```

Finally, we decrypt the whole $$ m $$.

```python
M = ''.join([
    chr(K[i % len(K)][0] ^ C[i]) 
    for i in range(len(C))
])
```

And what we'll get is our [base64] encoded [PNG] repeated several times.

```
iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFew3nPiS65O7umPFMGLbO6Nrry4O9EInddFrQVbPVWZAVOytM1fosk5MqXlYvz+ldghNE3cKVqmdUpimZKtH/Oe02fA1pCy1USuWGhxE2rFpLJeUenFixP3UFnd+Biqnou8ppcQzN6GJIVyeNoWt4jIJHcsTOaKZqAMo/zi8cGVdfByIdRPR2cN4PEQHnCsmEXj8MeywM6SC1Ebhi1a5mc9+byELm9SeSf3cC/xg8F2SwBTVbQQwAAAABJRU5ErkJggg==iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFew3nPiS65O7umPFMGLbO6Nrry4O9EInddFrQVbPVWZAVOytM1fosk5MqXlYvz+ldghNE3cKVqmdUpimZKtH/Oe02fA1pCy1USuWGhxE2rFpLJeUenFixP3UFnd+Biqnou8ppcQzN6GJIVyeNoWt4jIJHcsTOaKZqAMo/zi8cGVdfByIdRPR2cN4PEQHnCsmEXj8MeywM6SC1Ebhi1a5mc9+byELm9SeSf3cC/xg8F2SwBTVbQQwAAAABJRU5ErkJggg==iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFew3nPiS65O7umPFMGLbO6Nrry4O9EInddFrQVbPVWZAVOytM1fosk5MqXlYvz+ldghNE3cKVqmdUpimZKtH/Oe02fA1pCy1USuWGhxE2rFpLJeUenFixP3UFnd+Biqnou8ppcQzN6GJIVyeNoWt4jIJHcsTOaKZqAMo/zi8cGVdfByIdRPR2cN4PEQHnCsmEXj8MeywM6SC1Ebhi1a5mc9+byELm9SeSf3cC/xg8F2SwBTVbQQwAAAABJRU5ErkJggg==iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFe ...
```

In order to isolate the image we can either look for the [base64] padding `==`, or the string `iVBORw0KGgo` which stands for the [base64] encoded [PNG] magic bytes.

## Discussion

A brute-force attack on the keystream $$ k $$ is possible because $$ M $$ contains only $$ 65 $$ out of $$ 2^8 = 256 $$ possible elements. This means with every $$ c_{i+j \vert k \vert} $$ tested, we can exclude $$ 1 - \frac{65}{256} = 0.74609375 \rightarrow ~ 74.6 \% $$ of the possible $$ k_{i} $$. The huge amount of data $$ \vert c \vert = 14028800 $$ allows for a total of $$ \frac{\vert c \vert}{\vert k \vert} = 137 $$ tests, which reduces the chance for an ambiguity of a certain $$ k_{i} $$ down to $$ (\frac{65}{256})^{137} = 2.7558438890447563 \cdot 10^{-82} $$.

![probability for an ambiguity](/static/posts/broken-one-time-pad-2/probability_ambiguity.svg)

Thank you for sharing the idea to your solution svvw. 

# Ente's solution

```python
#!/usr/bin/python3 
import sys
import re
import binascii

from itertools import *
from operator import mul
from functools import reduce
from math import floor, gcd
from collections import deque
from base64 import b64encode, b64decode

FACTORS = [ 1024 * 100 ]

#PNG magic bytes
WORD = bytearray(b64encode(b"\x89PNG\r\n\x1a\n").rstrip(b"="))

def powerset(iterable):
    """powerset([1,2,3]) --> () (1,) (2,) (3,) (1,2) (1,3) (2,3) (1,2,3)"""
    s = list(iterable)
    return chain.from_iterable(combinations(s, r) for r in range(len(s)+1))

def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        ret = l[i:i+n]
        if(len(ret) == n):
            yield ret

def same(ll):
    """Checks if all the lists in ll are the same. same([[1], [1]]) == True ; same([[1], [1,2]]) == False"""
    return ll.count(ll[0]) == len(ll)

def sublists(l):
    """Yields all repeating sublists of l: [1,2,3,1,2,3,1,2,3,1,2,3] -> [ [1,2,3], [1,2,3,1,2,3] ]"""
    for i in range(1, floor(len(l) / 2) + 1):
        if same(list(chunks(l, i))):
            yield l[:i]

with open("data", "rb") as f:
    data = f.read()

for c in [c for c in powerset(FACTORS) if len(c) > 0]:
    l = reduce(mul, c)
    if l < len(WORD):
        continue 
    c = [v[0] ^ v[1] for v in zip(*list(chunks(data, l))[:2])]
    # all ascii ?
    if all([i < 128 for i in c]):
        l_m = [len(i) for i in sublists(c)][0]
        shift = l % l_m
        # skip message lengths which we can not reconstruct
        if(gcd(shift, l_m) > len(WORD)):
            continue
        print("Candidate lengths: {} bytes, {} bytes, {} bytes".format(l, l_m, shift))
        for start in range(l_m):
            m = deque(list(WORD) + [0] * (l_m - len(WORD)))
            m.rotate(start)
            o = ( start - shift ) % l_m
            while o != start:
                for i in range(o, o + len(WORD)):
                    m[i % l_m] = c[i % l_m] ^ m[(i + shift) % l_m]
                o = ( o - shift ) % l_m

            # ascii && base64?
            try:
                m = bytearray(m).decode("ascii")
                m = b64decode(m, validate=True)
                print("Working solution: {} {} {}".format(l, l_m, start))
                with open("out_{}_{}_{}".format(l, l_m, start), "wb") as f:
                    f.write(m)
            except (binascii.Error, UnicodeDecodeError):
                continue

```

[^1]:Captain obvious speaking
[^2]:That makes me wonder if somebody already sampled relative character frequencies of [base64] encoded [PNG] images.
[^3]:See [broken one-time pad]

[broken one-time pad]:https://duckpond.ch/security/math/2016/09/15/broken-one-time-pad.html
[one-time pad]:https://en.wikipedia.org/wiki/One-time_pad
[Vigenerer cipher]:https://en.wikipedia.org/wiki/Vigen%C3%A8re_cipher

[QR-Code]:https://de.wikipedia.org/wiki/QR-Code
[PNG]:https://en.wikipedia.org/wiki/Portable_Network_Graphics
[base64]:https://en.wikipedia.org/wiki/Base64
