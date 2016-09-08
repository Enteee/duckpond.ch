---
layout: post
categories: [networking]
keywords: [ssl, tls, certificate, pinning, finger print]
---

With [xt_sslpin] you can pin certificates at the netfilter level, thus keeping users save from malicious or untrusted certificates.

I do assume you know how SSL/TLS works and why certificates are an important concept. If you need a refreshen on the topic I highly recommend reading the following pages:

* [TLS/SSL and SSL (X.509) Certificates](http://www.zytrax.com/tech/survival/ssl.html)
* [How does SSL/TLS work](https://security.stackexchange.com/questions/20803/how-does-ssl-tls-work)
* [TLS handshake](https://en.wikipedia.org/wiki/Transport_Layer_Security#TLS_handshake)

# Certificate pinning

 For an introduction to SSL/TLS certificate pinning refer to the [OWASP pinning cheat sheet](https://www.owasp.org/index.php/Pinning_Cheat_Sheet). The section ["What Should Be Pinned"] introduces two different pinning methods namely public key pinning and certificate pinning. [fredburger/xt_sslpin] lets you do public key pinning. I started [xt_sslpin] because I needed certificate pinning capabilities. Pros and cons of the two methods are nicely covered by the ["What Should Be Pinned"] - section [^1]. The following two sections provide implementation details of the two modules.

## Public key pinning: [fredburger/xt_sslpin]

As mentioned in the [fredburger/README.md] public keys are directly specified in the matching iptable rule:

> iptables -I \<chain\> .. -m sslpin [!] --pubkey \<alg\>:\<pubkey-hex\> [--debug] ..

[fredburger/xt_sslpin] extracts public keys from a certificates transported in the server certificate message and matches rules on server change cipher spec.

![handshake fredburger_xt_sslpin](/static/posts/xt_sslpin/handshake_fredburger_xt_sslpin.png)
*[fredburger/xt_sslpin] intercepted SSL/TLS handshake*

### Example usage

In order to get the public key algorithm as well as the [subjectPublicKeyInfo] from a certificate you can use the following (bash-)command:

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

Using the just fetched information

```
Public Key Algorithm: rsaEncryption
30820122300d06092a864886f70d01010105000382010f003082010a0282010100e7885cf2965c97181cba98e203f17f399191c26fd996e7284064cd4ca98112036cae7fe6c619e05a63f06c0bd468b3fffd3efd25cfb5597329c4c8b3f4f2bac9945116e228d1dd9bc78db7340ea138bd914ed6e77ecfb2d0f152fd84e94127a54eeabe16ec2db39bfa680c1e37231c603d070726e491da2c1680dc70137327dd8073c2391150d47373abff88d2c99c33c6ef6476606507378732fb2a747f125fd98d6a15ed5f1469c199c18948f0dfa3e037eb3d18b586ada7ddd364f4bb1f58cdde5ece4331ba4a84010ec02882228ef6963c025b2bfe765cb848cb6be918dca5ca78bf0d00f5f1b04f4fe646d6ebf44103fd2ee63f8e83be14a0ce4e57abe30203010001
```

we can now write a rule which should drop packets on the INPUT-chain matching the github public key. Note that the retreived hex-bytes contain the public key preceded by the algorithm identifier. As a final step we've to translate the algorithm identifier to a representation string.

```shell
ALGORITHM_ID="30820122300d06092a864886f70d01010105000382010f00"
ALGORITHM="rsa"

KEY="3082010a0282010100e7885cf2965c97181cba98e203f17f399191c26fd996e7284064cd4ca98112036cae7fe6c619e05a63f06c0bd468b3fffd3efd25cfb5597329c4c8b3f4f2bac9945116e228d1dd9bc78db7340ea138bd914ed6e77ecfb2d0f152fd84e94127a54eeabe16ec2db39bfa680c1e37231c603d070726e491da2c1680dc70137327dd8073c2391150d47373abff88d2c99c33c6ef6476606507378732fb2a747f125fd98d6a15ed5f1469c199c18948f0dfa3e037eb3d18b586ada7ddd364f4bb1f58cdde5ece4331ba4a84010ec02882228ef6963c025b2bfe765cb848cb6be918dca5ca78bf0d00f5f1b04f4fe646d6ebf44103fd2ee63f8e83be14a0ce4e57abe30203010001"

iptables -I INPUT \
    -m conntrack --ctstate ESTABLISHED \
    -p tcp --sport 443 \
    -m sslpin --debug --pubkey "${ALGORITHM}:${KEY}" \
    -j DROP
```

Connecting to github using `curl -4 https://github.com` yields:

```
kernel: [903.845472] xt_sslpin: sslparser: ServerHello handshake message (len = 109)
kernel: [903.845480] xt_sslpin: sslparser: Certificate handshake message (len = 3136)
kernel: [903.845488] xt_sslpin: sslparser: cn = "github.com"
kernel: [903.845505] xt_sslpin: sslparser: pubkey_alg = { name:"rsa", oid_asn1_hex:[2a864886f70d0101] }
kernel: [903.845513] xt_sslpin: sslparser: pubkey = [3082010a0282010100e7885cf2965c97181cba98e203f17f399191c26fd996e7284064cd4ca98112036cae7fe6c619e05a63f06c0bd468b3fffd3efd25cfb5597329 c4c8b3f4f2bac9945116e228d1dd9bc78db7340ea138bd914ed6e77ecfb2d0f152fd84e94127a54eeabe16ec2db39bfa680c1e37231c603d070726e491da2c1680dc70137327dd8073c2391150d47373abff88d2c99c33c6ef6476606507378732fb2a747f125fd98d6a 15ed5f1469c199c18948f0dfa3e037eb3d18b586ada7ddd364f4bb1f58cdde5ece4331ba4a84010ec02882228ef6963c025b2bfe765cb848cb6be918dca5ca78bf0d00f5f1b04f4fe646d6ebf44103fd2ee63f8e83be14a0ce4e57abe30203010001]
kernel: [903.845639] xt_sslpin: sslparser: ServerKeyExchange handshake message (len = 329)
kernel: [903.845647] xt_sslpin: sslparser: ServerDone handshake message (len = 0)
kernel: [903.945050] xt_sslpin: sslparser: ChangeCipherSpec record
kernel: [903.945070] xt_sslpin: rule matched (cn = "github.com")
```

You might wonder why curl still prints the github page. A quick look into the [fredburger/README.md] explains why:

> Per connection, the incoming handshake data is parsed once across all -m sslpin iptables rules; upon receiving the SSL/TLS handshake ChangeCipherSpec message, the parsed certificate is checked by all rules.
> After this, the connection is marked as "finished", and xt_sslpin will not do any further checking.

This means we only block the **very first** change cipher spec message but TCP will retransmit this message and the connection will still succeed. Which is exactly what wireshark tells us:

![TCP retransmit of change cipher spec](/static/posts/xt_sslpin/retransmit.png) 
*Frame 89 is a retransmission of frame 67 which contains the change cipher spec message*

## Finger print pinning: [xt_sslpin]

[xt_sslpin] works based on finger prints. A finger print is a [SHA1] hash of a certificate. A collection of finger prints is called a finger print list. These lists are the key part when we specify an [iptables] rule:

> iptables -I \<chain\> .. -m sslpin [!] --fpl \<finger print list id\> ..

[xt_sslpin] extracts certificates transported in the server certificate message, generates finger prints and matches them agains finger print lists. Then it starts matching the rules. Other that the [fredburger/xt_sslpin] it won't wait for the change cipher spec message.

![handshake xt_sslpin](/static/posts/xt_sslpin/handshake_xt_sslpin.png)
*[xt_sslpin] intercepted SSL/TLS handshake*

### Example usage

You can retreive the finger print of the github.com certificate using the following command:

```shell
echo \
| openssl s_client -connect github.com:443 -servername github.com 2>/dev/null \
| openssl x509 -outform DER \
| sha1sum
```

For managing finger print lists the kernel exposes a user space API under `/sys/kernel/xt_sslpin/`. Using this API should be straigt forward:

{:.table}
| Operation | Command |
| --------- | ------- |
| ADD       | `echo finger-print-sha1 > /sys/kernel/xt_sslpin/<list id>_add` |
| REMOVE    | `echo finger-print-sha1 > /sys/kernel/xt_sslpin/<list id>_rm`  |
| LIST      | `ls /sys/kernel/xt_sslpin/<list id>` |

Addig the generated github.com finger print to list `0` is as simple as:

```shell
echo d79f076110b39293e349ac89845b0380c19e2f8b > /sys/kernel/xt_sslpin/0_add
```

The rule `iptables -I INPUT -m sslpin --fpl 0 ..` will match SSL/TLS handshakes containing a server certificate with a finger print found in the finger print list `0`. 

## Outlook

My personal goal is to merge both projects in the near future.

## Remarks

* Neither [fredburger/xt_sslpin] nor [xt_sslpin] does certificate chain validation or signature checks. This remains the responsibility of the client. 


[^1]: seriously, read it!

[xt_sslpin]:https://github.com/Enteee/xt_sslpin
[README.md]:https://github.com/Enteee/xt_sslpin/blob/master/README.md

[fredburger/xt_sslpin]:https://github.com/fredburger/xt_sslpin
[fredburger/README.md]:https://github.com/fredburger/xt_sslpin/blob/master/README.md

[iptables]:https://www.netfilter.org/projects/iptables/index.html
["What Should Be Pinned"]:https://www.owasp.org/index.php/Pinning_Cheat_Sheet#What_Should_Be_Pinned.3F
[subjectPublicKeyInfo]:https://tools.ietf.org/html/rfc5280#section-4.1.2.7

[mozilla public key pinning]:https://developer.mozilla.org/en/docs/Web/Security/Public_Key_Pinning
[SHA1]:https://de.wikipedia.org/wiki/Secure_Hash_Algorithm
