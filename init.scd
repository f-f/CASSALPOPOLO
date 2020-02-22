
(
  // configure the sound server: here you could add hardware specific options
  // see http://doc.sccode.org/Classes/ServerOptions.html
  s.options.numBuffers = 1024 * 256; // increase this if you need to load more samples
  s.options.memSize = 8192 * 16 * 2; // increase this if you get "alloc failed" messages
  s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"

  // Focusrite 2i4 has 2 ins and 4 outs
  s.options.numOutputBusChannels = 2;
  s.options.numInputBusChannels = 2;

  // boot the server and start SuperDirt
  s.waitForBoot {
    // Every orbit should have 2 channels
    ~dirt = SuperDirt(2, s);
    // Load samples (path containing a wildcard can be passed in)
    ~dirt.loadSoundFiles("/Users/fabrizio/code/cassa-al-popolo/samples/*");
    // s.sync; // optionally: wait for samples to be read
    ~dirt.loadSoundFiles;
    // start listening on port 57120
    // We spawn several orbits on the first 2 channels (main outputs)
    // and just some on the others - as they are just monitors
    ~dirt.start(57120, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  };

s.latency = 0.125; // increase this if you get "late" messages
);

(
MIDIClient.init;
// ~midiOut = MIDIOut.newByName("Scarlett 2i4 USB", "Scarlett 2i4 USB");
~midiOut = MIDIOut.newByName("Neutron", "Neutron");
~dirt.soundLibrary.addMIDI(\volca, ~midiOut);
~midiOut.latency = 0;
);

~dirt.stop();


Server.default.record;

Server.default.stopRecording;


g =  ServerOptionsGui(s);