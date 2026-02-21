<p align="center">
  <img src="assets/header.png" alt="WaxOff">
</p>


**Podcast Finalizer for macOS**

WaxOff prepares your final podcast mix for distribution. It applies EBU R128 loudness normalization, optional phase rotation, and encodes to 24-bit WAV and/or MP3 — ready for upload.

WaxOff assumes your mix is already balanced — it applies a single linear gain adjustment to hit the target loudness without changing dynamics, compression, or relative levels. If your mix sounds right, WaxOff just makes it loud enough.

## Design Philosophy

WaxOff is intentionally minimal. It does one thing — finalizes your podcast mix for distribution — and exposes only the controls that matter for that job. Sensible defaults handle the rest. Drop your mix in, hit Process, and deliver.

## Download

**[WaxOff v2.3 (DMG)](https://github.com/sevmorris/WaxOff/releases/latest/download/WaxOff-v2.3.dmg)**

> ⚠️ **Important — Read Before First Launch**
>
> macOS will block the app with a malware warning because it is not notarized with Apple. After mounting the DMG and dragging WaxOff to Applications, **you must run this command in Terminal:**
>
> ```
> xattr -cr /Applications/WaxOff.app
> ```
>
> Without this step, macOS will refuse to open the app.

## Features

- **Loudness Normalization**: Two-pass EBU R128 with linear gain — no dynamic compression, just transparent level matching. Target adjustable from -24 to -14 LUFS.
- **True Peak Limiting**: Configurable ceiling (-3.0 to -0.1 dBTP) to prevent inter-sample clipping
- **Phase Rotation**: Optional 150 Hz allpass filter to reduce crest factor and improve headroom
- **WAV + MP3 Output**: 24-bit WAV, CBR MP3 (128/160/192 kbps), or both. MP3 preserves source channel count (mono/stereo).
- **Sample Rate Conversion**: 44.1 kHz or 48 kHz output
- **Presets**: Built-in presets for common podcast workflows, plus custom presets
- **Drag & Drop**: Drop audio files onto the window to queue them
- **Batch Processing**: Sequential queue with per-file progress and status
- **File Selection**: Select and remove files from the queue before processing
- **Processing Log**: Detailed log of all operations at ~/Library/Logs/WaxOff.log

## System Requirements

- macOS 14.0 (Sonoma) or later
- FFmpeg (bundled or installed via Homebrew)

## Usage

1. Choose a preset or configure your target loudness, output format, and sample rate
2. Drag and drop your final mix files onto the window
3. Click "Process All"
4. Output files are saved alongside the originals

## Output Naming

```
{original-name}-lev-{target}LUFS.wav
{original-name}-lev-{target}LUFS.mp3
```

Example: `episode-01-lev--18LUFS.wav`

## Built-In Presets

| Preset | Target | Output | MP3 | Sample Rate | Phase Rotation |
|--------|--------|--------|-----|-------------|----------------|
| Podcast Standard | -18 LUFS | Both | 160 kbps | 44.1 kHz | On |
| Podcast Loud | -16 LUFS | Both | 160 kbps | 44.1 kHz | On |
| WAV Only (Mastering) | -18 LUFS | WAV | — | 48 kHz | On |

## Processing Pipeline

WaxOff uses FFmpeg with a multi-pass pipeline:

1. **Analysis** — measures integrated loudness, true peak, loudness range, and threshold using EBU R128 (with phase rotation if enabled)
2. **Normalization** — applies a single linear gain to match the target loudness. Output as 24-bit WAV
3. **MP3 encoding** (if selected) — encodes the normalized WAV using LAME at the chosen bitrate

## Companion App

[WaxOn](https://github.com/sevmorris/WaxOn) prepares raw podcast recordings for editing — high-pass filtering, loudness normalization, phase rotation, and brick-wall limiting.

**Workflow**: Raw recordings → **WaxOn** → Edit in DAW → **WaxOff** → Distribute

## License

Copyright © 2026. This app was designed and directed by Seven Morris, with code primarily generated through AI collaboration using [OpenClaw](https://openclaw.ai) and Claude (Anthropic).

This program is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License v3.0](LICENSE).
