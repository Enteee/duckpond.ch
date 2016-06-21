---
layout: post
title:  "Weak Diffie-Hellman Parameters - 2"
keywords: [diffie-hellman parameters, logjam]
categories: [security]
---

## Key derivation

This step is for verification purpose only. I want to derive the master secret $$ k $$ from the pre master secret $$ k_{0} $$ in order to check that I did everything right. The agreed master secret $$ k $$ is beeing printed when running s_client:

```python
In : k = 0x403247e9625be70e2ac4076297b48a18178696404fc7ffcd924ecaa5628fdba049dfbd4170f65acbc6a84aa18696144a
```

A good starting point is the TLS 1.2 finish described in [RFC 5246-8.1.2](https://tools.ietf.org/html/rfc5246#section-8.1.2). Note that in [ssl-handshake2] the client sends the Extended Master Secret Extension, thus the master secret $$ k $$ is computed according to [RFC 7627-4](https://tools.ietf.org/html/rfc7627#section-4)[^9].

## Solving DLOG

[^9]: The [introduction of RFC 7627](https://tools.ietf.org/html/rfc7627#section-1) describes the ["Triple Handshakes"](http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6956559)-Attack quite well.
[ssl-handshake2]:/static/posts/weak-dh-parameters/ssl_handshake2.pcap
