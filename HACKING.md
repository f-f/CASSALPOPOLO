## Setup

Music is made from three components:

1. [TidalCycles](https://tidalcycles.org/)
2. Korg Minilogue XD
3. Samples

#### Setting up Tidal

- Install Supercollider, SuperDirt and its samples following [Tidal's install](https://tidalcycles.org/index.php/Installation)
- [Install stack](https://docs.haskellstack.org/en/stable/install_and_upgrade/)
- [Setup `emacs` with this config](https://github.com/f-f/home/blob/8b40d0559216f2f85f6cb5c369ebdf13dc9555f9/.spacemacs#L473-L477)
- Clone this repo
- From this folder, start `emacs` to start the editor
- Start Supercollider, load `init.scd` to get channels configured and a proper amount of orbits
- Start Tidal from Emacs with `C-c C-s`
- Launch `./launchpad.py`

#### Setting up the samples

> Note: the samples are not public because I don't want to deal with licensing mess, so please reach out if you'd like some of them and we'll figure something out

In this folder:
```
gsutil rsync -r gs://cassalpopolo samples
```

