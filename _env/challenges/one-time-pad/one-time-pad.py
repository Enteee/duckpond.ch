#!/usr/bin/env python3
# vim: set fenc=utf8 ts=4 sw=4 et :
import sys
import socket
import random

from threading import Thread
from math import gcd
from base64 import b64encode

def lcm(a, b):
    """Return lowest common multiple of a and b"""
    return a * b // gcd(a, b)

with open("key.png", "rb") as f:
    SECRET = b64encode(f.read())

PAD_LENGTH = 1024 * 100
REPEAT = lcm(PAD_LENGTH, len(SECRET))

def client_thread(clientsocket):
    random.seed()
    pad = [ random.getrandbits(8) for i in range(PAD_LENGTH) ]
    for i in range(REPEAT):
        s = SECRET[i % len(SECRET)]
        p = pad[i % len(pad)]
        b = bytes([s ^ p])
        if clientsocket.send(b) == 0:
            return
    clientsocket.close()

def main():
    serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serversocket.bind((socket.gethostname(), 8888))
    serversocket.listen()
    print('len(SECRET) = {} Bytes'.format(len(SECRET)))
    print('len(pad) = {} Bytes'.format(PAD_LENGTH))
    print('shift = {} Bytes'.format(PAD_LENGTH % len(SECRET)))
    print('Repeat after {} MiB'.format(REPEAT / 1024 ** 2))
    sys.stdout.flush()
    while True:
        # accept connections on socket
        (clientsocket, address) = serversocket.accept()
        print('Client connected {}'.format(address))
        sys.stdout.flush()
        thread = Thread(target = client_thread, args = (clientsocket, ))
        thread.start()

if __name__ == "__main__":
    main()

