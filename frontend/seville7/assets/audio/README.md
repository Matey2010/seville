# Interface audio

Short, repeatedly triggered interface sounds are loaded through
`flame_audio` `AudioPool` instances owned by `LandscapeXlLayoutGame`.

- `technology-select.wav` plays when a Node changes from inactive to selected.
- `stone-scrap.wav` plays once when the cursor enters a different rendered
  Node; movement inside the same Node does not retrigger it.

Keep filenames relative to FlameAudio's `assets/audio/` cache prefix.

## Background music

`BackgroundMusicController` reserves three optional soundtrack slots:

- `menu-lounge-vaporwave-01.m4a`
- `menu-lounge-vaporwave-02.m4a`
- `menu-lounge-vaporwave-03.m4a`

The first available slot starts automatically at zero volume and fades to a
quiet 0.12 volume over ten seconds. The selected track loops, pauses with the
application lifecycle, and is disposed with `LandscapeXlLayoutGame`. Missing
slots are skipped. To audition a licensed M4A file, place it here, add its
explicit path under Flutter's `assets` section in `pubspec.yaml`, and restart
the application.

Use a purchased or downloaded WAV file as the archival master, then export an
AAC-in-M4A release copy. M4A is supported by the native macOS audio stack;
Ogg Vorbis is deliberately not used for Seville's macOS production runtime.

Keep the source URL, author, exact license, purchase receipt when applicable,
and required credit text beside the release records. Royalty-free does not
necessarily mean free of charge or free of attribution requirements.
