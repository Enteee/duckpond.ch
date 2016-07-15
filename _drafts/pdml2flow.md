---
layout: post
keywords: [pdml, wireshark, flow, network]
categories: [security]
---

Quite a time ago I wrote a script as a replcement for a network flow generator called [tranalyzer]. In contrast to [tranalyzer] the script should:

* extract the same features as [wireshark]
* aggregates flows based on a configurable set of features
* use [JSON] as its default output
* be compatible with [UNIX pipes]

# Terminology

Before we start you might want to make yourself familiar with some terms:

## Network Flows

A network flow only vaguely defined and is quite a fuzzy term. Looking up [network flow in wikipedia](https://en.wikipedia.org/wiki/Traffic_flow_(computer_networking)) reflects this. Wikipedia quotes several RFCs[^1][^2][^3] and they all differ. But most of them share one aspect which is, that a network flow is a set of packets having a set of attributes in common. The term emerged from the mathematical definition of a [flow network](https://en.wikipedia.org/wiki/Flow_network). This is something routing-guys at universities [^4] were looking at in order to design efficient routing algorithms. I didn't live back then but among the 10 or 20 people capable of building such networks the Flow was likely a well defined term. Later, with more sophisticated networks in place, companies wanted to have more control over what kind of traffic they are routing and how much of it. So they started building walls of fire [^5] and started shaping traffic ([QoS](https://en.wikipedia.org/wiki/Quality_of_service)). For this purpose a lot of proprietary mechanisms were beeing developped in parallel. With the effect of washing out the term.

Given the definition of a frame $$ \vec{f} \in F $$ as a vector of attributes and a corressponding arrival time function $$ \tau $$ :

$$ \tau : F \rightarrow \mathbb{R} $$

we define a network flow $$ \Xi $$:

$$ \Xi(t, A) = \{ \vec{f} \in F, \vec{f}^{'} \in \Xi(t, A) \mid \forall_{a \in A}( \vec{f}_{a} = \vec{f}_{a}^{'}) \land | \tau(\vec{f}) - \tau(\vec{f}^{'}) | < t\} $$

## PDML - Packet Details Markup Language

[^1]: [RFC2722 Traffic Flow Measurement: Architecture](https://tools.ietf.org/html/rfc2722)
[^2]: [RFC3697 IPv6 Flow Label Specification](https://tools.ietf.org/html/rfc3697)
[^3]: [RFC3917 Requirements for IP Flow Information Export (IPFIX)](https://tools.ietf.org/html/rfc3917)
[^4]: The stereotype of the modern geek
[^5]: Zechariah 2:5

[tranalyzer]: https://tranalyzer.com/
[wireshark]: https://www.wireshark.org/
[JSON]: https://de.wikipedia.org/wiki/JavaScript_Object_Notation
[UNIX pipes]: https://en.wikipedia.org/wiki/Pipeline_(Unix)
[PDML]: http://ftp.tuwien.ac.at/.vhost/analyzer.polito.it/30alpha/docs/dissectors/PDMLSpec.htm
