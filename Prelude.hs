import Control.Concurrent (threadDelay)

:set +m

import qualified Markov

setbpm bpm = setcps (bpm/60/4)

-- | Defining controls from pots on the MIDI board.
--   Assign them like `gain q1`, etc
maxgain = 1.3
q1 = range 0 maxgain $ cF 0 "cc1"
q2 = range 0 maxgain $ cF 0 "cc2"
q3 = range 0 maxgain $ cF 0 "cc3"
q4 = range 0 maxgain $ cF 0 "cc4"
q5 = range 0 maxgain $ cF 0 "cc5"
q6 = range 0 maxgain $ cF 0 "cc6"
q7 = range 0 maxgain $ cF 0 "cc7"
q8 = range 0 maxgain $ cF 0 "cc8"

-- | TODO: PR the change to SuperDirt
let reverbPan :: Pattern Double -> ControlPattern
    reverbPan = pF "reverbPan"

-- | Make a track mutable by the assigned pad button
mutable padButton = selectF (cF 0 padButton) [id, const silence]

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


-- | Get a Markov-generated harmony of length len
harm len = fmap Markov.render (Markov.getHarmony len)
