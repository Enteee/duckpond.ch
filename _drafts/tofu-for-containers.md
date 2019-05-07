---
layout: post
title: TOFU for Containers
categories: [tls-tofu, git-sync-mirror, kamikaze, security]
keywords: [TLS, SSL, TOFU, certificate, container]
---

Running containers behind a HTTPS scanning proxy can be tricky. The proxy will
send a certificate which is not trusted by the container with the effect of
breaking the internet.

![broken internet](/static/posts/tofu-for-containers/broken-internet.gif)

There are three possible ways to make the internet work again:

* Disable SSL/TLS certificate chain verification
* Forward and install the scanning certificate
* Implement Trust On First Use (TOFU)

In case you decide to disable certificate chain verification, I hope your code
reviewing fellow just silently gets up from his desk and punches you in the
face. Because you deserve it. **NEVER EVER DO THIS!**

On the other hand, doing the right thing means forwarding and installing the
certificate inside the container. In order to achieve this there are steps
needed by the image maintainer as well as the poor soul running the container.
Wouldn't it be nice if you didn't need to worry about certificates when
deploying a container?

TOFU can be a good trade-off between security and usability. The idea is simple:
Early on we try to reach out to the internet and simply trust every certificate
that we get in response. TOFU then caches those certificate and ensures that
subsequent connections are secure.

Well, yes, this is not perfectly secure as well. An attacker could make you
trust a certificate if they are able to intercept the very first connection
attempt made by TOFU. But in practice this deemed to be quite difficult.
Especially for long running containers. Also there are other protocols which
implement TOFU successful.

```sh
$ ssh duckpond.ch
The authenticity of host '[duckpond.ch]:7410 ([71.19.149.209]:7410)' can't be established.
ECDSA key fingerprint is SHA256:H28klEV+VMEwPst7POeHYzAGUrvfb15SRwZ/RnqhtDI.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[duckpond.ch]:7410,[71.19.149.209]:7410' (ECDSA) to the list of known hosts.
```

# TOFU Inside a Container

What we are trying to do is:

1. TLS handshake with the server (or a proxy) and download all certificates.
2. Install the certificates.

The first step is easy, [`openssl s_client`](https://www.openssl.org/docs/man1.0.2/man1/openssl-s_client.html)
does most of the heavy TLS lifting for us. I am not a massive fan of having
OpenSSL installed in containers. But in this case this is probably the right
approach. Most applications build on top of that library anyways. Using OpenSSL
we implement `tls-tofu.sh`:

```sh
#!/usr/bin/env sh
set -exuo pipefail
openssl s_client -showcerts ${@} 2>/dev/null < /dev/null \
| sed -n '/-----BEGIN/,/-----END/p'
```

Now we can easily print all the certificates sent to us either by the server or
a transparent proxy:

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

In order to make the system trust those certificates, we need to store them in
`/etc/ssl/certs/ca-certificates.crt`. But this file is only writable by root and
we hopefully don't have those permissions when running scripts inside a
container.

This problem is solvable with [`kamikaze`]. [`kamikaze`] is a simple setuid
binary which allows us to run a command as root once. Using the power of
[`kamikaze`] we can now add trusted certificates.

```sh
#!/usr/bin/env sh
set -exuo pipefail
openssl s_client -showcerts ${@} 2>/dev/null < /dev/null \
| sed -n '/-----BEGIN/,/-----END/p' \
| /kamikaze tee -a /etc/ssl/certs/ca-certificates.crt > /dev/null
```

## [enteee/tls-tofu] Container Image

Based on the `tls-tofu.sh`-idea, I did create the [tls-tofu GitHub project](https://github.com/Enteee/tls-tofu)
and published [enteee/tls-tofu] container images. Building and running your own
TLS-TOFU enabled image is as simple as:

```sh
$ docker build -t tls-tofu-enabled-image - <<EOF
  FROM enteee/tls-tofu
  # IMPORTANT: Drop privileges
  USER nobody

  # Run the application
  CMD ["echo", "Hello World!"]
EOF
$ docker run -ti tls-tofu-enabled-image
Hello World!
```

In a more elaborate example, we can use the just built image to run a container
which trusts the [self-signed BadSSL] certificate.

```sh
$ docker run \
  -ti \
  -e TLS_TOFU_HOST="self-signed.badssl.com" \
  tls-tofu-enabled-image \
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

And then the [self-signed BadSSL] page.

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

Let us make the last step, and simulate the HTTPS scanning proxy scenario. For
this we first start [mitmproxy/mitmproxy]:

```sh
$ docker run \
  -ti \
  --name mitmproxy \
  mitmproxy/mitmproxy mitmdump
Proxy server listening at http://*:8080
```

And then connect to [duckpond.ch] through the proxy:

```sh
$ docker run \
  -ti \
  --link mitmproxy \
  -e TLS_TOFU_HOST="mitmproxy" \
  -e TLS_TOFU_PORT="8080" \
  -e TLS_TOFU_S_CLIENT_ARGS="-servername duckpond.ch" \
  tls-tofu-enabled-image \
  curl -x http://mitmproxy:8080 https://duckpond.ch
CONNECTED(00000003)
---
Certificate chain
 0 s:
   i:CN = mitmproxy, O = mitmproxy
-----BEGIN CERTIFICATE-----
MIICwjCCAaqgAwIBAgIGDinF743TMA0GCSqGSIb3DQEBCwUAMCgxEjAQBgNVBAMM
CW1pdG1wcm94eTESMBAGA1UECgwJbWl0bXByb3h5MB4XDTE5MDUwNTE5MzUyNVoX
DTIxMDUwNjE5MzUyNVowADCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AJh4sql+hJEvAstUd+gxcWIxy+vN9MC78WbT5Ox2oB7YO0r+3CCkeki3SehEBtHj
5MolxsspJipxF3gHN9el36vcN9dbj1sIGGukT7az7u8M0al4cVnP3Dyt+Fhb1Y2K
7UEiA2WibWEzeAlNbxASdHt7xqHTQfHMDBr+l1odg7eRe2QquFuLI8PhhSw1XSXw
yxY+A6/xxwkMcqU9s9pgQhP51qzAlY86SgZqHtgzCn7K0p3gCO+H2jhQu5R45h3X
1mJY6iRHf5WnEAPe/kdyjkme+8TsgeiZ13y7o+K9a6XwHQD1jTZFE9GW27cyVst/
0RHt6R+50DRSDJ1onPHUCGcCAwEAAaMaMBgwFgYDVR0RBA8wDYILZHVja3BvbmQu
Y2gwDQYJKoZIhvcNAQELBQADggEBAC7XwulSPQPHmESiQWiWjuDtyHu85lsGBvxS
C31zJRva8NuPlzIi4w3wQXXkuH+skNvTZ81WJxfxw+WjwcglYfmKG6yQVtZ0tdVk
uYUVq2Okn8oBSAI57XNaKqCGTioQhk7Mk/P93Y49UuNF/AC47IvxOWkj9QFm/wtu
+zRfko5VC7W7f1ji5tgnJduD46lR2hen12Px3tWyRWc1ECFjXZ4lBT1xUZIloPjQ
5PGDEIrg0zTmr3ZqUBGBKEjF1zrzXC3myMStn5pn0mBHgH0Fgrooswad0UzLAoDL
ECDdplotyGL9Wc1/CzLHsvsw8lvGCimi0ul0QOn9VQtnLKF/w/0=
-----END CERTIFICATE-----
 1 s:CN = mitmproxy, O = mitmproxy
   i:CN = mitmproxy, O = mitmproxy
-----BEGIN CERTIFICATE-----
MIIDoTCCAomgAwIBAgIGDinFhnrGMA0GCSqGSIb3DQEBCwUAMCgxEjAQBgNVBAMM
CW1pdG1wcm94eTESMBAGA1UECgwJbWl0bXByb3h5MB4XDTE5MDUwNTE5MjM1N1oX
DTIyMDUwNjE5MjM1N1owKDESMBAGA1UEAwwJbWl0bXByb3h5MRIwEAYDVQQKDAlt
aXRtcHJveHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCYeLKpfoSR
LwLLVHfoMXFiMcvrzfTAu/Fm0+TsdqAe2DtK/twgpHpIt0noRAbR4+TKJcbLKSYq
cRd4BzfXpd+r3DfXW49bCBhrpE+2s+7vDNGpeHFZz9w8rfhYW9WNiu1BIgNlom1h
M3gJTW8QEnR7e8ah00HxzAwa/pdaHYO3kXtkKrhbiyPD4YUsNV0l8MsWPgOv8ccJ
DHKlPbPaYEIT+daswJWPOkoGah7YMwp+ytKd4Ajvh9o4ULuUeOYd19ZiWOokR3+V
pxAD3v5Hco5JnvvE7IHomdd8u6PivWul8B0A9Y02RRPRltu3MlbLf9ER7ekfudA0
UgydaJzx1AhnAgMBAAGjgdAwgc0wDwYDVR0TAQH/BAUwAwEB/zARBglghkgBhvhC
AQEEBAMCAgQweAYDVR0lBHEwbwYIKwYBBQUHAwEGCCsGAQUFBwMCBggrBgEFBQcD
BAYIKwYBBQUHAwgGCisGAQQBgjcCARUGCisGAQQBgjcCARYGCisGAQQBgjcKAwEG
CisGAQQBgjcKAwMGCisGAQQBgjcKAwQGCWCGSAGG+EIEATAOBgNVHQ8BAf8EBAMC
AQYwHQYDVR0OBBYEFAHmNa8e++bQ4Nr1XzdqPek/tp4eMA0GCSqGSIb3DQEBCwUA
A4IBAQAxC9SNuBLjVhSY2ilJRQc21bv/WoJAcmGtxLxhXn43RwnYsNxKDmS3bRwj
CbKOX2mhV7zqKRDvrA0iRoWndGwfQodnc9eairo3LSLCqg8+vFkwgaRQICyCkv18
6ElxxHVQinNrd4XyaStqrweqK+gbB1NymR/87nOiRXzK9utGjESifaUNl97fymTg
LL8BwQH5iHHlU5ud14AKkwr14QWrTzTbyP/McxLo/KfTjVCl30YO2onzMpwu2oW5
cRRfx96ajPoKwtVFBJTX/hdBoqkovNFvRSITMU3VHEKRfoIG2OJRsA1dl7ezb6Ao
Uf30567z+pXa2Dp8YOnUA3ARWBCu
-----END CERTIFICATE-----
---
Server certificate
subject=

issuer=CN = mitmproxy, O = mitmproxy

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 2316 bytes and written 439 bytes
Verification error: self signed certificate in certificate chain
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: D15B53E637A92CF86580E51B8053626F50F3256138E5F5A55BAD5B37A903CE67
    Session-ID-ctx: 
    Master-Key: 72C569F0C2C5A4EF5EB666DE0CF7B908411854010BA303F53DB9199E7872F68EE0E524E780DDF003819CA8DFBB3A1C3E
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    TLS session ticket lifetime hint: 300 (seconds)
    TLS session ticket:
    0000 - 24 fe cb 42 a8 12 eb b3-35 29 6a 12 11 79 af ba   $..B....5)j..y..
    0010 - 63 50 85 58 bc 6f a7 5a-c5 5f 9b 11 21 97 23 ed   cP.X.o.Z._..!.#.
    0020 - 54 9c 99 0c 5a 26 a8 75-21 06 b8 26 e1 57 f7 f0   T...Z&.u!..&.W..
    0030 - f1 a0 c1 5f a3 d8 25 36-4f de cc 6d 76 c2 d9 89   ..._..%6O..mv...
    0040 - 99 46 ec 64 8d d8 c1 41-04 58 4c 7a bf 8f 1c a8   .F.d...A.XLz....
    0050 - 8e b4 42 bd 2b 73 03 07-05 26 36 66 66 53 ac 63   ..B.+s...&6ffS.c
    0060 - 52 98 c9 31 cb ea 5d c4-b6 76 4a d7 c4 79 1c 4c   R..1..]..vJ..y.L
    0070 - f1 3b 76 04 ed 15 07 ff-d0 2d c7 92 6c d8 56 f9   .;v......-..l.V.
    0080 - 94 19 5a 61 9b 58 db 68-1d 2e 0c 87 fb f9 64 38   ..Za.X.h......d8
    0090 - 56 5a 8f 4e 2e a9 31 f6-ac db c9 30 51 5e 84 00   VZ.N..1....0Q^..
    00a0 - 29 fc 48 d9 70 f3 87 3f-07 b9 11 9b 2a 7a 72 ce   ).H.p..?....*zr.

    Start Time: 1557257748
    Timeout   : 7200 (sec)
    Verify return code: 19 (self signed certificate in certificate chain)
    Extended master secret: no
---
<!DOCTYPE html>
<html>
    <head>
...
```

From the [mitmproxy/mitmproxy] output we get that the request did actually go
through the proxy. All this without `curl` complaining about certificate
verification issues.

```
172.17.0.3:47120: clientconnect
172.17.0.3:47120: Client Handshake failed. The client may not trust the proxy's certificate for mitmproxy.
172.17.0.3:47120: clientdisconnect
172.17.0.3:47122: clientconnect
172.17.0.3:47122: Client Handshake failed. The client may not trust the proxy's certificate for mitmproxy.
172.17.0.3:47122: clientdisconnect
172.17.0.3:47124: clientconnect
172.17.0.3:47124: GET https://duckpond.ch/
               << 200 OK 20.86k
172.17.0.3:47124: clientdisconnect
```

Mission accomplished.

## A Real World Example: [enteee/git-sync-mirror]

[enteee/git-sync-mirror] is a simple container image for synchronizing a git
mirror. Inside the `Dockerfile` it installs a run script (`/run.sh`) and
overwrites the default command. The `ENTRYPOINT` is still provided by
[enteee/tls-tofu] which does all the TOFU magic.

```sh
FROM enteee/tls-tofu:alpine-latest

# Disable TLS-TOFU by default
ENV TLS_TOFU false

RUN set -exuo pipefail \
  && apk add \
    git \
  && addgroup -g 1000 -S git \
  && adduser -u 1000 -S git -G git

USER git:git

COPY run.sh /run.sh
CMD ["/run.sh"]
```

When running this container with `-e TLS_TOFU=true` [enteee/git-sync-mirror]
silently does TLS-TOFU. And if we additionally specify `-e TLS_TOFU_DEBUG=true`,
we can see what is happening under to hood.

```sh
$ docker run \
  -e TLS_TOFU=true \
  -e TLS_TOFU_DEBUG=true \
  git-sync-mirror
+ '[' true '=' true ]
+ openssl s_client -verify_return_error -connect google.com:443 -servername google.com
+ destroy_kamikaze
+ '[' -x /kamikaze ]
+ /kamikaze true
+ exec sh -c /run.sh
/run.sh: line 5: SRC_REPO: Missing source repository
```

This fails because we didn't specify the mandatory `SRC_REPO` for [enteee/git-sync-mirror].
Nevertheless, we can still see [enteee/tls-tofu] connecting to google.com. But
since all certificates are valid it does not add any new trusted ones. After
this [`kamikaze`] is destroyed and control is being handed over to [enteee/git-sync-mirror].

## Caveat: Restart Policies

If an attacker is in control of your network, it is very likely that they can
also crash applications you are running in containers. If you restart the
container in this case, your application will re-TOFU. This means an attacker
can make the container trust every certificate they want. This is very, very
bad. Always disable automatic container restart with TLS-TOFU exactly for this
reason.

## Final Thoughts

[enteee/tls-tofu] implements a simple, yet powerful base image which allows
containers to run in environments where something is tampering with the
Internet's public key infrastructure. I generally disagree that HTTPS scanning
proxies are leveraging security in a network. They create a single point of
failure, and considerably weaken a secure protocol design to protect privacy
and confidentiality.

[`kamikaze`]:https://github.com/Enteee/kamikaze#readme
[self-signed BadSSL]:https://self-signed.badssl.com
[enteee/tls-tofu]:https://hub.docker.com/r/enteee/tls-tofu
[enteee/git-sync-mirror]:https://hub.docker.com/r/enteee/git-sync-mirror
[mitmproxy/mitmproxy]:https://hub.docker.com/r/mitmproxy/mitmproxy
[duckpond.ch]:https://duckpond.ch
