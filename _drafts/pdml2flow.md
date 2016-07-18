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

A network flow is quite a fuzzy term. Looking up [network flow in wikipedia](https://en.wikipedia.org/wiki/Traffic_flow_(computer_networking)) reflects this. Wikipedia quotes several RFCs[^1][^2][^3] and they all differ. But most of them share one aspect which is, that a network flow is a set of packets having a set of attributes in common. The term emerged from the mathematical definition of a [flow network](https://en.wikipedia.org/wiki/Flow_network). This is something routing-guys at universities [^4] were looking at in order to design efficient routing algorithms. I didn't live back then but among the 10 or 20 people capable of building such networks, the Flow was likely a well defined term. Later, with more sophisticated networks in place, companies wanted to have more control over what kind of traffic they are routing and how much of it. So they started building walls of fire [^5] and started shaping traffic ([QoS](https://en.wikipedia.org/wiki/Quality_of_service)). For this purpose a lot of proprietary mechanisms for flow control were developped in parallel. With the effect of washing out the term. In the pdml2flow context we use a slightly different and more generic definition of a flow:

> A flow $$ \Xi $$ (xi) is a set of all frames $$ f $$ which are equal for a set of attributes $$ A $$ and are all in a certain proximity $$ t $$ of each other.

Other than the definitions mentioned so far, pdml2flow operates on frames $$ f $$ instead of packets. Frames are maps of attributes to values. 

$$ f : \mathbb{U} \rightarrow \{\perp\} \cup \mathbb{U} $$

$$ \mathbb{U} $$ deontes the set of all possible unicode strings and $$ \perp $$ the response iff an attribute is not defined. The set of all possible frames is called $$ F $$, thus $$ f \in F $$. Using an arrival time function $$ \tau $$ (tau):

$$ \tau : F \rightarrow \mathbb{R} $$

we can order $$ F $$. When we combine all these definitions we can write an algorithm in python which constructs us a certain flow around a generating frame $$ f^{'} $$ (f0):

```python
def same_flow(f, xi, t, A):
  """ Returns True iff f belongs to xi in respect to t and A """
  for test in xi:
    if abs(tau(test) - tau(f)) < t and all([ test[a] == f[a] for a in A ]):
      return True
  return False

def get_flow(F, t, A, f0):
  """ Returns a set which contains all frames belonging to the flow xi(t, A, f0) """
  xi = [f0]
  while True:
    newXi = [ f for f in F if same_flow(f, xi, t, A) ]
    if len(newXi) == len(xi):
      return set(xi)
    xi = newXi
```

That's quite a lot of formalism. The following graphic shoud give a concrete example for a three flows scenario:

![flow visualization](/static/posts/pdml2flow/flows.svg)
*Visualization of four frames in three flows*

Note:

  * $$ f1 $$ is not in the same flow as $$ \{f2, f3\} $$ because $$ f1 $$ is not in proximity of one of the two others.
  * $$ f2 $$ is neither in  $$ \{f1\} $$ nor in $$ \{f2,f3\} $$ because they contain different values for the attribute 'port'

## PDML - Packet Details Markup Language

An XML schema for describing packets. For in depth information please refer to the [PDML-specification][PDML] or the [NetPDL-paper][NetPDL]. The [PDML-schema] as well as the [NetPDL-schema] provide a in deph implementation specification. The reason why I chose [PDML] as an input format is that wireshark / tshark does suport support the [PDML] format out of the box:

```shell
$ tshark -i eth0 -T pdml
```

# The script

## Download, Installation and Source Code

The newest version of the script should always be hosted in the [PyPI][pdml2flow]. This means intalling and updating the software using [pip] should be as simple as:

```
$ sudo pip install --upgrade pdml2flow
```

This will install the three components pdml2flow, pdml2json and pdml2xml systemwide. The source code is hosted @ [Github][pdml2flow-git] and automatically been built using [Travis CI][pdml2flow-travis] and [Coveralls][pdml2flow-coveralls].

## Running it

The script reads from stdin and writes to stdout, debug messages and warnings are reported to stderr. This allows for easy integration with [wireshark] as data generator and [jq] as postprocessor. Reading a `.pcap`-file is as simpe as:

```shell
$ tshark -r file.pcap -T pdml | pdml2flow
```

or you can even sniff live packets from a network interface:

```shell
$ tshark -i eth0 -T pdml | pdml2flow
```

For postprocessing, such as prettyprinting, you can further pipe stdout to [jq]:

```shell
$ tshark -i eth0 -T pdml | pdml2flow | jq
```

## Changing the Behaviour


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
[PDML-schema]: http://www.nbee.org/download/pdml-schema.xsd
[NetPDL]: http://www.sciencedirect.com/science/article/pii/S1389128605002008
[NetPDL-schema]: http://www.nbee.org/download/netpdl-schema.xsd
[pdml2flow]: https://pypi.python.org/pypi/pdml2flow/2.4
[pdml2flow-git]: https://github.com/Enteee/pdml2flow
[pdml2flow-travis]: https://travis-ci.org/Enteee/pdml2flow
[pdml2flow-coveralls]: https://coveralls.io/github/Enteee/pdml2flow
[pip]: https://pypi.python.org/pypi/pip
[jq]: https://stedolan.github.io/jq/
