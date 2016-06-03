#!/usr/bin/env python
import sys
import base64
import textwrap
from math import *

from pyasn1.type import univ
from pyasn1.codec.ber import encoder

def usage():
    """print usage"""
    print(  """Usage: {} prime generator
    NOTE: Numbers in hexadecimal""".format(sys.argv[0]))
    sys.exit(-1)

PEM_LINE_LENGTH = 64 - 1 # -1 because of \n
def pem_lines(m):
    """Yield successive lines of PEM body for bytearray m"""
    m = base64.b64encode(m).decode('ascii')
    for i in range(0, len(m), PEM_LINE_LENGTH):
        yield m[i:i+PEM_LINE_LENGTH]

if len(sys.argv) != 3:
    usage()

(_, prime, generator) = sys.argv
prime = int(prime, 16)
generator = int(generator,16)

m = encoder.encode(
        univ.Sequence().setComponents(
            univ.Integer(prime),
            univ.Integer(generator)
        )
    )

print('-----BEGIN DH PARAMETERS-----')
[print(l) for l in pem_lines(m)]
print('-----END DH PARAMETERS-----')

