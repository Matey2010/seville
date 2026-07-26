# Interface audio

Short, repeatedly triggered interface sounds are loaded through
`flame_audio` `AudioPool` instances owned by `LandscapeXlLayoutGame`.

- `technology-select.wav` plays when a Node changes from inactive to selected.
- `stone-scrap.wav` plays once when the cursor enters a different rendered
  Node; movement inside the same Node does not retrigger it.

Keep filenames relative to FlameAudio's `assets/audio/` cache prefix.
