#!/usr/bin/env python3

import mido

from time import time
from pythonosc import udp_client
from pythonosc import osc_message_builder

client = udp_client.SimpleUDPClient("127.0.0.1", 6010)

# We want to avoid jamming the OSC channel with events, so we rate-limit them
# This map has the control as key and the timestamp of the last event as value,
# so we can decide if we should send an event or discard it if it's too often
last_times = {}

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

        k = prefix + key
        now = time()
        if k not in last_times or now - last_times[k] > 0.03:
            print([k, value])
            client.send_message("/ctrl", [k, value])
            last_times[k] = now
