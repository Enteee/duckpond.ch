---
layout: post
title:  "Weak Diffie-Hellman Parameters"
date:   2016-01-30 00:00:00 +0100
keywords: [diffie-hellman, dh, parameters, logjam]
categories: [security]
---

```python
In : m = 0xbbbc2dcad84674907c43fcf580e9cfdbd958a3f568b42d4b08eed4eb0fb3504c6c030276e710800c5ccbbaa8922614c5beeca565a5fdf1d287a2bc049be6778060e91a92a757e3048f68b076f7d36cc8f29ba5df81dc2ca725ece66270cc9a5035d8ceceef9ea0274a63ab1e58fafd4988d0f65d146757da071df045cfe16b9b
In : log(m)/log(2)
Out: 1023.552554397631
```

https://www.openssl.org/docs/manmaster/crypto/pem.html
> The DHparams functions process DH parameters using a DH structure. The parameters are encoded using a PKCS#3 DHparameter structure.


DH-Pem encoding:
http://crypto.stackexchange.com/questions/29109/what-are-the-first-4-and-last-2-bytes-in-dh-parameter-files


[openssl-dh]:https://sandilands.info/sgordon/diffie-hellman-secret-key-exchange-with-openssl
[openssl-testing]:https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html

[32c3-logjam]:https://www.youtube.com/watch?v=TfK5tf3ScR4&t=1970
[weak-dh]:https://weakdh.org/
[openssl-pem-dh-param]:https://github.com/openssl/openssl/blob/60980390b1275fb236e98d5e618a86ecaab6f490/crypto/pem/pem_pkey.c#L115
[ber]:https://www.itu.int/ITU-T/studygroups/com17/languages/X.690-0207.pdf
[asn1-decoder]:https://lapo.it/asn1js/
[asn1-python]:http://pyasn1.sourceforge.net/
