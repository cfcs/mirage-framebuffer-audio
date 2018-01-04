## experimental prototype, will hang sometimes. probably an issue in `mirage-crunch`, or my use of it.

## what is this

it's a unikernel that plays embedded sound in qubes, or on unix (through libSDL).

unix:
```shell
mirage configure -t unix
make
./main.native
```

qubes:
```shell
. yomake
```


## notes

Ideally we'd plug in some parsers for various sound formats.

For now, there is only stupid, raw playback of WAV files in the expected format (two-channel 44100 Hz, `pcm_s16le`).

We don't even parse the wav, but play the header as though it was sound.

## Converting your favorite music to WAV/RIFF:

```
# I couldn't figure out how to limit to two channels:
ffmpeg -i SOURCE.mp3 '-b:a' '44100' -codec pcm_s16le OUTPUT.wav
```
