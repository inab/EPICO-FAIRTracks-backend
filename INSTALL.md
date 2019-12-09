# EPICO FAIRTracks backend Installation and usage instructions

You can install this module using `cpm` or `cpanm`, for instance:

```bash
cpanm --mirror-only --mirror https://gitlab.bsc.es/inb/darkpan/raw/master/ --mirror https://cpan.metacpan.org/ EPICO::REST::Backend::FAIRTracks
```

Also, you have to either create a .ini file in the `config` subdirectory, with the next structure:

```ini
[epico-api]
name=FAIRTracks endpoint
release=ft
backend=FAIRTracks
```

or copying the file `fairtracks.ini.template` (included in the distribution) with an `.ini` extension.

With previous configuration file, next endpoints will work:

* http://localhost:5000/FAIRTracks:ft/assemblies