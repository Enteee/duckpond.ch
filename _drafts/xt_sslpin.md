---
layout: post
categories: [networking, security]
keywords: [ssl, tls, certificate, pinning, finger print]
---

Today I would like to introduce [xt_sslpin] an [iptables] extension which makes your firewall ready for SSL/TLS! [xt_sslpin] lets you match connections based on SSL/TLS certificate finger prints. I do assume you know how SSL/TLS works and why certificates are an important concept. If you need a refreshen on the topic I can highly recommend reading the following pages:

* [TLS/SSL and SSL (X.509) Certificates](http://www.zytrax.com/tech/survival/ssl.html)
* [How does SSL/TLS work](https://security.stackexchange.com/questions/20803/how-does-ssl-tls-work)
* [TLS handshake](https://en.wikipedia.org/wiki/Transport_Layer_Security#TLS_handshake)

# Certificate pinning

from the [README.md]:
> For an introduction to SSL/TLS certificate pinning refer to the [OWASP pinning cheat sheet](https://www.owasp.org/index.php/Pinning_Cheat_Sheet). xt_sslpin lets you do certificate validation/pinning at the netfilter level. xt_sslpin will match certificate finger prints in SSL/TLS connections (with minimal performance impact). Applications are expected to do further certificate chain validation and signature checks (i.e. normal SSL/TLS processing).

# Certificate finger printing

The following diagram shows a SSL/TLS handshake, with the important **server certificate** message marked in red. Based on the certificates transported within this message, [xt_sslpin] enables us to make decisions on an [iptables] firewall.

![tls handshake](/static/posts/xt_sslpin/handshake.png)
*SSL/TLS handshake*

![handshake xt_sslpin](/static/posts/xt_sslpin/handshake_xt_sslpin.png)
*[xt_sslpin] intercepted TLS handshake*

[xt_sslpin]:https://github.com/Enteee/xt_sslpin
[iptables]:https://www.netfilter.org/projects/iptables/index.html
[README.md]:https://github.com/Enteee/xt_sslpin/blob/master/README.md
