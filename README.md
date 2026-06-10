# Seville

Seville is an experimental visualization project built with
[Flutter](https://flutter.dev/) and [Flame](https://flame-engine.org/).

The goal is to turn data from an [Obsidian](https://obsidian.md/) vault into an
interactive, visually expressive space. Instead of presenting notes as a
traditional list or graph, Seville will explore more playful ways to represent
their structure, relationships, and activity.

## Project status

Seville is at the beginning of development. The current codebase is a small
Flame prototype used to explore rendering, animation, and interaction.

Development is planned in two stages:

1. **Visualization only**  
   Seville will render predefined or locally supplied data. It will be an
   output-only experience, with no vault editing or data input from the
   interface.

2. **Obsidian integration**  
   A future backend will read and update data in an Obsidian vault. Once that
   backend is available, Seville will also provide ways to modify the connected
   data directly from its interface.

The exact visual language and data model are still being explored.

## Technology

- Flutter for the application and platform support
- Flame for the visualization, animation, and interaction layer
- Protocol Buffers for future structured communication with the backend

## Running locally

Install Flutter, fetch the dependencies, and run the application:

```sh
flutter pub get
flutter run
```

## Platforms

The project currently includes Flutter targets for Android, iOS, macOS, and
Linux. Platform support may change as the visualization develops.
