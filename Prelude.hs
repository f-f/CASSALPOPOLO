import Control.Concurrent (threadDelay)
import Sound.Tidal.ParseBP (parseBP_E)

:set +m

import qualified Markov

setbpm bpm = setcps (bpm/60/4)

-- | Defining controls from pots on the MIDI board.
--   Assign them like `gain q1`, etc
maxgain = 1.3
maxrev = 1.0
maxlpf = 9000
ccVol idx = range 0 maxgain $ cF 0 ("vol" ++ show idx)

let ccLpf idx = selectF (segment 256 $ cF 0 ("toggle5_" ++ show idx))
                  [const $ rangex 20 maxlpf (cF maxlpf ("lpf" ++ show idx)), const 20000]
                  silence

let ccRevRoom idx = selectF (segment 256 $ cF 0 ("toggle3_" ++ show idx))
                    [const $ range 0 maxrev (cF 0 ("revRoom" ++ show idx)), const 0]
                    silence

let ccRevSize idx = selectF (segment 256 $ cF 0 ("toggle2_" ++ show idx))
                    [const $ range 0 maxrev (cF 0 ("revSize" ++ show idx)), const 0]
                    silence


-- | TODO: PR the change to SuperDirt
let reverbPan :: Pattern Double -> ControlPattern
    reverbPan = pF "reverbPan"

-- | Make a track mutable by the assigned pad button
mutable padButton = selectF (segment 256 $ cF 0 ("mute" ++ show padButton)) [id, const silence]

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
let syncvolca factor = do
      p "midiclock" $ midicmd (parseBP_E $ "midiClock*" ++ show (96 * factor)) # s "volca"
      threadDelay 100000
      once $ midicmd "stop" # s "volca"
      p "midictl" $ midicmd "start/4" # s "volca"
      threadDelay 1000000
      p "midictl" $ silence

let sendvolca pat = p "volcanotes" $ pat # s "volca" # midichan 0

let stopvolca = p "volcanotes" $ silence

-- | Fix the `hush` function so we resync the midi
let hush_ = hush >> (syncvolca 1)

-- | A better `p` that we can map to MIDI controls for volume and muting
let lp idx pat
      = mutable idx (pat
                     # gain (ccVol idx)
                     # lpf (ccLpf idx)
                     # room (ccRevRoom idx)
                     # size (ccRevSize idx)
                     # orbit (fromInteger idx))



let fill1 f = every 4 (const f)
    fill2 f = whenmod 8 6 (const f)
    fill3 f = whenmod 12 9 (const f)
    fill4 f = whenmod 16 12 (const f)


-- | Get a Markov-generated harmony of length len
harm len = fmap Markov.render (Markov.getHarmony len)
