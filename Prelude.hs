import Control.Concurrent (threadDelay)

:set +m

import qualified Markov

setbpm bpm = setcps (bpm/60/4)

-- | Defining controls from pots on the MIDI board.
--   Assign them like `gain q1`, etc
maxgain = 1.3
q idx = range 0 maxgain $ cF 0 ("cc" ++ show idx)

-- | TODO: PR the change to SuperDirt
let reverbPan :: Pattern Double -> ControlPattern
    reverbPan = pF "reverbPan"

-- | Make a track mutable by the assigned pad button
mutable padButton = selectF (cF 0 ("t" ++ show padButton)) [id, const silence]

-- | If a sample has been assigned to a cut group, then we can
--   hack a way to stop it
let killSample sampleChannel cutGroup = do
      let killChannel = "cutsamples"
      -- Stop it first
      p sampleChannel silence
      -- Start a bogus sound with no volume. The important part is that the sample duration
      -- should be suuuper short, so we cut the sample asap.
      -- Note: the other important part is that this sample is assigned to the same cut group.
      p killChannel $ s "bd*80" # gain 0 # speed 20 # cut cutGroup
      -- Wait a sec so we actually play some of the samples
      threadDelay 100000
      -- Stop the bogus sound
      p killChannel silence

-- p "test" $ s "trump:4/4" # cut 10 # speed 0.5
-- killSample "test" 10

-- | Sync the tempo on the Volca with Tidal
let syncvolca = do
      p "midiclock" $ midicmd "midiClock*96" # s "volca"
      threadDelay 100000
      once $ midicmd "stop" # s "volca"
      p "midictl" $ midicmd "start/4" # s "volca"
      threadDelay 1000000
      p "midictl" $ silence

let sendvolca pat = p "volcanotes" $ n pat # s "volca" # midichan 0

let stopvolca = p "volcanotes" $ silence

-- | Fix the `hush` function so we resync the midi
let hush_ = hush >> syncvolca

-- | A better `p` that we can map to MIDI controls for volume and muting
p_ name idx pat = p name $ mutable idx (pat # gain (q idx) # orbit (fromInteger idx))

-- | Get a Markov-generated harmony of length len
harm len = fmap Markov.render (Markov.getHarmony len)
