#!/usr/bin/env python3

import mido

from pythonosc import udp_client
from pythonosc import osc_message_builder

client = udp_client.SimpleUDPClient("127.0.0.1", 6010)


with mido.open_input('LPD8') as inport:
    for msg in inport:
        prefix = None
        value = None
        key = None

        if msg.type == "control_change":
            prefix = "cc"
            value = (msg.value + 1) / 128
            key = str(msg.control)
        elif msg.type == "note_on":
            prefix = "t"
            value = 1.0
            key = str(msg.note)
        elif msg.type == "note_off":
            prefix = "t"
            value = 0.0
            key = str(msg.note)
        elif msg.type == "program_change":
            prefix = "p"
            value = 1.0
            key = str(msg.program)
        else:
            print(msg)
            continue

        print([prefix + key, value])
        client.send_message("/ctrl", [prefix + key, value])
