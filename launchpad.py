#!/usr/bin/env python3

import mido
import threading
import queue

from time import time
from pythonosc import udp_client
from pythonosc import osc_message_builder

client = udp_client.SimpleUDPClient("127.0.0.1", 6010)

port = mido.open_output('Launchpad MK2')

mode = 7

colors = {
    0: 3,  # white
    1: 13, # yellow
    2: 21, # green
    3: 29, # aqua
    4: 37, # light blue
    5: 45, # blue
    6: 53, # pink
    7: 5,  # red
}

mixers = [[0 for i in range(8)] for m in range(8)]

muted = [[False for i in range(8)] for m in range(8)]

def select_control(new_mode):
    """Selects the mode and lights its light, shutting all the others"""
    global mode
    mode = new_mode
    sync_grid()
    for i in range(104, 112):
        if i == mode + 104:
            port.send(mido.Message('control_change', control=i, value=colors[mode]))
        else:
            port.send(mido.Message('control_change', control=i, value=0))

def note_from_coords(x, y):
    return ((x + 1) * 10) - y + 8

def note_to_coords(note):
    x = (note // 10) - 1
    y = abs((note % 10) - 8)
    return (x, y)

def sync_channel_light(channel):
    """Lights the channel up according to its mixer value"""
    global mode

    val = mixers[mode][channel]

    # Muted
    muted_note = ((channel + 1) * 10) + 9
    if muted[mode][channel]:
        port.send(mido.Message('note_on', note=muted_note, velocity=5))
    else:
        port.send(mido.Message('note_on', note=muted_note, velocity=0))
    port.send(mido.Message('note_on', channel=1, note=muted_note, velocity=0))

    # Volume
    for i in range(8):
        note = note_from_coords(channel, i)
        if i <= val:
            port.send(mido.Message('note_on', note=note, velocity=colors[mode]))
        else:
            port.send(mido.Message('note_on', note=note, velocity=0))

def sync_grid():
    """Sync the grid lights with the state of the mixer"""
    for i in range(8):
        sync_channel_light(i)

def set_channel_val(channel, new_val):
    global mode

    # Save the new value in the mixer
    mixers[mode][channel] = new_val

    # Then take care of the lights
    sync_channel_light(channel)

    # Send OSC
    if mode == 7:
        osc_k = "vol" + str(channel)
    elif mode == 6:
        osc_k = "vol" + str(channel + 8)
    # TODO: define what other modes do
    else:
        osc_k = "cc" + str(mode) + "_" + str(channel)
    osc_value = new_val / 7
    print([osc_k, osc_value])
    client.send_message("/ctrl", [osc_k, osc_value])

def toggle_channel_mute(channel):
    global mode

    new_val = not(muted[mode][channel])

    muted[mode][channel] = new_val

    sync_channel_light(channel)

    if mode == 7:
        osc_k = "mute" + str(channel)
    elif mode == 6:
        osc_k = "mute" + str(channel + 8)
    else:
        osc_k = "toggle" + str(mode) + "_" + str(channel)
    osc_value = 0.0
    if new_val:
        osc_value = 1.0

    print([osc_k, osc_value])
    client.send_message("/ctrl", [osc_k, osc_value])



with mido.open_input('Launchpad MK2') as inport:
    select_control(mode)

    for msg in inport:
        # print(msg)

        # Select the mode we're in, resetting the grid to the mixer
        if msg.type == "control_change" and msg.value == 127:
            mixer = msg.control - 104
            select_control(mixer)

        # Mute buttons
        elif msg.type == "note_on" and msg.velocity == 127 and (msg.note % 10 == 9):
            channel = (msg.note // 10) - 1
            toggle_channel_mute(channel)

        # Value buttons
        elif msg.type == "note_on" and msg.velocity == 127:
            (channel, new_val) = note_to_coords(msg.note)
            set_channel_val(channel, new_val)
