---
layout: post
categories: [networking]
keywords: [ssl, tls, certificate, pinning, finger print]
---

Today I would like to introduce [xt_sslpin] an [iptables] extension which makes your firewall ready for SSL/TLS! [xt_sslpin] lets you match connections based on SSL/TLS certificate finger prints. I do assume you know how SSL/TLS works and why certificates are an important concept. If you need a refreshen on the topic I highly recommend reading the following pages:

* [TLS/SSL and SSL (X.509) Certificates](http://www.zytrax.com/tech/survival/ssl.html)
* [How does SSL/TLS work](https://security.stackexchange.com/questions/20803/how-does-ssl-tls-work)
* [TLS handshake](https://en.wikipedia.org/wiki/Transport_Layer_Security#TLS_handshake)

# Certificate pinning

For an introduction to SSL/TLS certificate pinning refer to the [OWASP pinning cheat sheet](https://www.owasp.org/index.php/Pinning_Cheat_Sheet). [xt_sslpin] lets you do certificate validation/pinning at the netfilter level. The section ["What Should Be Pinned"] introduces two different pinning methods namely public key pinning and certificate pinning.

[xt_sslpin] was forked from [fredburger/xt_sslpin]. The original project [fredburger/xt_sslpin] lets you do public key pinning. I started [xt_sslpin] because I needed certificate pinning capabilities. Note that neither [fredburger/xt_sslpin] nor [xt_sslpin] does certificate chain validation or signature checks! This remains the responsibility of the client. My personal goal is to merge both projects in the near future. Pros and cons of the two methods are nicely covered by the ["What Should Be Pinned"] - section [^1]. Thus the following two sections will only cover implementation details.

## Public key pinning: [fredburger/xt_sslpin]

As mentioned in the [fredburger/README.md] public keys are directly specified in the matching iptable rule:

> iptables -I <chain> .. -m sslpin [!] --pubkey <alg>:<pubkey-hex> [--debug] ..

In order to get a public key for a specific certificate you can use the following (bash-)command:

```shell
echo                                                                            \
| openssl s_client -connect github.com:443 -servername github.com 2>/dev/null   \
| tee                                                                           \
  >(                                                                            \
    openssl x509 -text                                                          \
    | grep 'Public Key Algorithm'                                               \
  )                                                                             \
  >(                                                                            \
    openssl x509 -pubkey -noout                                                 \
    | sed '1d; $d'                                                              \
    | base64 -d                                                                 \
    | hexdump -v -e '1/1 "%.2x"'                                                \
  )                                                                             \
&>/dev/null
```

Using the just fetched information you can now write a rule which should drop packets on the INPUT-chain matching the github public key:

```shell
KEY="30820122300d06092a864886f70d01010105000382010f003082010a0282010100e7885cf2965c97181cba98e203f17f399191c26fd996e7284064cd4ca98112036cae7fe6c619e05a63f06c0bd468b3fffd3efd25cfb5597329c4c8b3f4f2bac9945116e228d1dd9bc78db7340ea138bd914ed6e77ecfb2d0f152fd84e94127a54eeabe16ec2db39bfa680c1e37231c603d070726e491da2c1680dc70137327dd8073c2391150d47373abff88d2c99c33c6ef6476606507378732fb2a747f125fd98d6a15ed5f1469c199c18948f0dfa3e037eb3d18b586ada7ddd364f4bb1f58cdde5ece4331ba4a84010ec02882228ef6963c025b2bfe765cb848cb6be918dca5ca78bf0d00f5f1b04f4fe646d6ebf44103fd2ee63f8e83be14a0ce4e57abe30203010001"

iptables -I INPUT \
    -m conntrack --ctstate ESTABLISHED \
    -p tcp --sport 443 \
    -m sslpin --debug --pubkey "rsa:${KEY}" \
    -j DROP
```

## Finger print pinning: [xt_sslpin]

The following diagram shows a SSL/TLS handshake, with the important **server certificate** message marked in red. Based on the certificates transported within this message, [xt_sslpin] enables us to make decisions on an [iptables] firewall.

![tls handshake](/static/posts/xt_sslpin/handshake.png)
*SSL/TLS handshake*

![handshake xt_sslpin](/static/posts/xt_sslpin/handshake_xt_sslpin.png)
*[xt_sslpin] intercepted SSL/TLS handshake*

[^1]: seriously, read it!

[xt_sslpin]:https://github.com/Enteee/xt_sslpin
[README.md]:https://github.com/Enteee/xt_sslpin/blob/master/README.md

[fredburger/xt_sslpin]:https://github.com/fredburger/xt_sslpin
[fredburger/README.md]:https://github.com/fredburger/xt_sslpin/blob/master/README.md

[iptables]:https://www.netfilter.org/projects/iptables/index.html
["What Should Be Pinned"]:https://www.owasp.org/index.php/Pinning_Cheat_Sheet#What_Should_Be_Pinned.3F
