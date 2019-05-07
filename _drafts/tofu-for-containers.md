---
layout: post
categories: []
keywords: []
---

Running containers behind a HTTPS scanning proxy can be tricky.
The proxy will send a certificate which is not trusted by the container, with the effect of breaking the internet for the container.

![broken internet](/static/posts/tofu-for-containers/broken-internet.gif)

There are three possible ways how to make the internet work again:
* Disable SSL/TLS certificate chain verification
* Forward and install the scanning certificate inside the container
* Implement Trust On First Use (TOFU)

In case you decide to disable certificate chain verification, I hope your code reviewing fellow just silently gets up from his desk and punches you in the face. Because you deserve it. **NEVER EVER DO THIS!**

On the other hand, doing the right thing, forwarding and installing the certificate inside the container can be tricky. Because in order to achivet this, there are steps needed by the image maintiner as well as the poor soul running the container. Woudln't it be nice if you don't need to worry about certificates when deploying a container?

TOFU can be a good trade-off between security and usability. The idea is simple: Early on we try to reach out to the internet and simply trust every certificate that we get in response. TOFU then caches those certificate and ensures that subsequent connections are secure.

Well, yes, this is not secure as well. An attacker could make you trust a certificate if they are able to intercept the very first connection attempt made by TOFU. But in practice this deemed to be quite difficult, especially for long running containers. Also, there are other protocols which implement TOFU successful.

```sh
$ ssh duckpond.ch
The authenticity of host '[duckpond.ch]:7410 ([71.19.149.209]:7410)' can't be established.
ECDSA key fingerprint is SHA256:H28klEV+VMEwPst7POeHYzAGUrvfb15SRwZ/RnqhtDI.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[duckpond.ch]:7410,[71.19.149.209]:7410' (ECDSA) to the list of known hosts.
```

# TOFU Inside a Container

Again, what we are trying to do is:

1. TLS handshake with the server (or a proxy) and download all certificates.
2. Install the certificates as trusted.

The first step is easy, [`openssl s_client`](https://www.openssl.org/docs/man1.0.2/man1/openssl-s_client.html) does most of the heavy TLS lifting for us. I am not a massive fan `openssl` installed in containers. But since most applications build on top of openssl, this is probably the right approch. Using openssl we implement `tls-tofu.sh`:

```sh
#!/usr/bin/env sh
set -exuo pipefail
openssl s_client -showcerts ${@} 2>/dev/null < /dev/null \
| sed -n '/-----BEGIN/,/-----END/p'
```

Using this, we can easily optain all the certificates sent to us either by the server or a transparent proxy:

```sh
$ ./tls-tofu.sh -connect duckpond.ch:443 -servername duckpond.ch
+ openssl s_client -showcerts -connect duckpond.ch:443 -servername duckpond.ch
+ sed -n /-----BEGIN/,/-----END/p
-----BEGIN CERTIFICATE-----
MIIGcjCCBVqgAwIBAgISA5P3qUe9JqxFqESJKhzHY/neMA0GCSqGSIb3DQEBCwUA
...
QraNjGOLb8+mDxQItPL5EymbmdPrdA==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/
...
KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg==
-----END CERTIFICATE-----
```

In order to make the system trust those certificates, we need to store them in `/etc/ssl/certs/ca-certificates.crt`. But the `ca-certificates.crt` file is only writable by root and we hopefully don't have those permissions when running scripts inside a container. 

This problem is solvable with [`kamikaze`]. [`kamikaze`] is a simple setuid binary which allows us to run a command as root once. Using the power of [`kamikaze`] we can now append the certificates to our tursted list of certificates ugint `tee`:

```sh
#!/usr/bin/env sh
set -exuo pipefail
openssl s_client -showcerts ${@} 2>/dev/null < /dev/null \
| sed -n '/-----BEGIN/,/-----END/p' \
| /kamikaze tee -a /etc/ssl/certs/ca-certificates.crt > /dev/null
```

## `tls-tofu.sh` in a Container

Based on the `tls-tofu.sh`-idea, I did create the [tls-tofu github project](https://github.com/Enteee/tls-tofu) and published [tls-tofu containers](https://hub.docker.com/r/enteee/tls-tofu). Building your own tls-tofu enabled container image is as simple as:

```sh
$ docker build -t tls-tofu-enabled-image - <<EOF
  FROM enteee/tls-tofu
  # IMPORTANT: Drop privileges
  USER nobody
EOF
$ docker run -ti tls-tofu-enabled-image
~ $
```

Using this image could now run a container which trusts the [self-signed badssl] certificate:

```sh
$ docker run \
  -e TLS_TOFU="-connect self-signed.badssl.com:443" \
  -ti tls-tofu-enabled-image \
  curl https://self-signed.badssl.com/
```

This should first print certificate information:
```
CONNECTED(00000003)
---
Certificate chain
 0 s:C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com
   i:C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com
-----BEGIN CERTIFICATE-----
MIIDeTCCAmGgAwIBAgIJAPlgiuOcJ/T1MA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNp
c2NvMQ8wDQYDVQQKDAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTAeFw0x
ODA4MTUxNTIxNTNaFw0yMDA4MTQxNTIxNTNaMGIxCzAJBgNVBAYTAlVTMRMwEQYD
VQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQK
DAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2
PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMW
hyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3A
xPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqve
ww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SY
QCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaMyMDAwCQYDVR0T
BAIwADAjBgNVHREEHDAaggwqLmJhZHNzbC5jb22CCmJhZHNzbC5jb20wDQYJKoZI
hvcNAQELBQADggEBAKr7JtZHTDuYs8/vGDFrtXb+dkjdNsZEIgyVh4vWZtLOANtO
39wM/LwGXUSjonEsYJabJgYpRdRSex41f78QfnARJona7fkcc1aHci7jdrzsxaNJ
iCc4G49ahgJ1NEIFmRNeEYlKYNNFeyGT6wxkLaV9AnC45MHlaumQyrRJwuXCQH/i
16Wk/qDtsu2nw6t+13OqwGfxR9krxDikVFO0YqgSMhqPmufz/6nY6uaXuOqzGv+P
rjJZDqCoRmVMqrISIUALWGCF3yasrViM6owIEhtN71UwrFZYYOeZ9nw2wvRK210z
c8LlWjgG56wRkLrq/mSINsQ3xmChO1PsBAeSHDU=
-----END CERTIFICATE-----
---
Server certificate
subject=C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com

issuer=C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 1599 bytes and written 450 bytes
Verification error: self signed certificate
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 315114D851A9EE6B159B59BE5CF639C36FD4F6F40F8F53B8601FE9305E3DF8F1
    Session-ID-ctx: 
    Master-Key: A5C589C7A5739E39046574BA5AEC4D130F44E489DF77C7D627F35DF91A75E37FBFC3C5F20907A816692F8E46A765A775
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    TLS session ticket lifetime hint: 300 (seconds)
    TLS session ticket:
    0000 - 8a a2 1a 77 48 87 f2 35-55 9c a0 3f 71 4d 37 a7   ...wH..5U..?qM7.
    0010 - 64 49 98 47 22 64 dc 00-99 89 2d ed 98 41 49 09   dI.G"d....-..AI.
    0020 - fc b8 1c f2 6e 08 5e 0d-28 9e 44 2f 3e df 34 9e   ....n.^.(.D/>.4.
    0030 - fa a5 f0 ca 1e dc b5 af-c0 54 cc 63 e8 1a a2 6d   .........T.c...m
    0040 - 41 61 e5 21 f9 82 68 39-4e 2f d6 9f 5e 21 7b 8f   Aa.!..h9N/..^!{.
    0050 - 06 9e 16 76 38 b6 08 12-ab ed ee 5b e5 e7 a5 eb   ...v8......[....
    0060 - 66 97 8b a8 fa fc d0 1f-aa 4d 53 6a 6f d6 07 df   f........MSjo...
    0070 - 5e 70 fe 72 18 82 38 c8-c8 c4 10 e5 05 b5 5f c6   ^p.r..8......._.
    0080 - ff cb d0 01 18 a8 66 9f-01 1c bd 2c 99 1c cc 14   ......f....,....
    0090 - 3d 37 c9 bb 4b 1d 1b 1a-ba 7d fd 15 19 e2 3a b5   =7..K....}....:.
    00a0 - 33 e9 68 d9 fa 20 55 ff-2f f1 10 a1 1c 88 e7 8f   3.h.. U./.......
    00b0 - 6c 72 e9 b6 bc 12 45 36-a7 d4 80 92 ea 82 34 b6   lr....E6......4.
    00c0 - fc bd ab 91 b8 8f aa 5a-a6 55 95 ae 23 5b b5 7b   .......Z.U..#[.{

    Start Time: 1557231372
    Timeout   : 7200 (sec)
    Verify return code: 18 (self signed certificate)
    Extended master secret: no
---
```

And then the [self-signed badssl] page.

```html
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="shortcut icon" href="/icons/favicon-red.ico"/>
  <link rel="apple-touch-icon" href="/icons/icon-red.png"/>
  <title>self-signed.badssl.com</title>
  <link rel="stylesheet" href="/style.css">
  <style>body { background: red; }</style>
</head>
<body>
<div id="content">
  <h1 style="font-size: 12vw;">
    self-signed.<br>badssl.com
  </h1>
</div>

</body>
</html>
```

## Does it work?

## Don'ts: Restart Policies

There is one obvious big mistake you can make when implemetning TOFU on container startup: Restart policies! Consider what happens if an attacker crash the application running in the container. If you restart the container and re-TOFU, they can make the container trust any certificate. This is very, very bad.

Therefore, disable automatic container restart when implemnting TOFU or store certificates trusted by TOFU in a persistent volume.


[`kamikaze`]:https://github.com/Enteee/kamikaze#readme
[self-signed badssl]:https://self-signed.badssl.com
