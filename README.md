# DualSense / DualSense Edge Firmwares

Official firmware `.bin` archive for PlayStation controllers. The firmware files are stored in `firmware/`, while device URL patterns and archived firmware metadata live in JSON files.

> This README is generated from `devices.json` and `firmwares.json`. Run `.\tools\generate-readme.ps1` after metadata changes.

## Adding firmware

Use the interactive helper:

```powershell
.\tools\add-firmware.ps1
```

The helper reads `devices.json`, asks for a device, variant, and version, builds the official Sony download URL, downloads the `.bin`, stores it under `firmware/<device>/<version>/`, updates `firmwares.json`, regenerates this README, and runs validation.

To add a new device or updater variant, add it to `devices.json`; the scripts will show it in the menu automatically.

## Checking for updates

Run a report-only check against Sony firmware updater metadata:

```powershell
.\tools\check-updates.ps1
```

Download and archive any missing latest firmware reported by Sony:

```powershell
.\tools\check-updates.ps1 -Apply
```

GitHub Actions also runs this check daily at 12:00 UTC and can be triggered manually. When updates are found, the workflow downloads them, updates metadata, regenerates this README, validates the repository, and opens a pull request.

## Device URL patterns

| Device | Variant | Updater path | Updater ID |
|---|---|---|---|
| DualSense | Type 0004 | `fwupdate0004` | `FWUPDATE0004` |
| DualSense | Type 000B | `fwupdate000B` | `FWUPDATE000B` |
| DualSense | Type 000E | `fwupdate000E` | `FWUPDATE000E` |
| DualSense Edge | Type 0044 | `fwupdate0044` | `FWUPDATE0044` |

## DualSense

| Version | Variant | Updater | Status | File | Official URL | SHA256 |
|---|---|---|---|---|---|---|
| `0x0641` | Type 000E | `FWUPDATE000E` | Latest | [FWUPDATE000E.bin](firmware/dualsense/0x0641/FWUPDATE000E.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate000E/0x0641/FWUPDATE000E.bin) | `B9C217D8DED5F09F03034E7E5037AF0C174C3C77A3CBD201EE5FD219EE448FC8` |
| `0x0633` | Type 000E | `FWUPDATE000E` | Archived | [FWUPDATE000E.bin](firmware/dualsense/0x0633/FWUPDATE000E.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate000E/0x0633/FWUPDATE000E.bin) | `EC5734DA8F4F658288CA45C51A19430C66DA89C797C7DF6C1372B6F5C5806CFF` |
| `0x0630` | Type 0004 | `FWUPDATE0004` | Latest | [FWUPDATE0004.bin](firmware/dualsense/0x0630/FWUPDATE0004.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0004/0x0630/FWUPDATE0004.bin) | `861AD95A99B16805FF20F5690372988662C4F69C6AD0B266E793D7FC2292315A` |
| `0x0630` | Type 000B | `FWUPDATE000B` | Latest | [FWUPDATE000B.bin](firmware/dualsense/0x0630/FWUPDATE000B.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate000B/0x0630/FWUPDATE000B.bin) | `B66528795683D214CA06FE4672D298DE75BF019BD5046442CBEC63FC02974F86` |
| `0x0520` | Type 0004 | `FWUPDATE0004` | Archived | [FWUPDATE0004.bin](firmware/dualsense/0x0520/FWUPDATE0004.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0004/0x0520/FWUPDATE0004.bin) | `5ECB23A0C6750C2026CB136A1D284AE5998833AB12138A5F144B53A9AA76CEF5` |
| `0x0520` | Type 000B | `FWUPDATE000B` | Archived | [FWUPDATE000B.bin](firmware/dualsense/0x0520/FWUPDATE000B.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate000B/0x0520/FWUPDATE000B.bin) | `79A20C4F58679CBF3876049E99254703014BBE8F368FD8BC601898A3F8BBB201` |
| `0x0458` | Type 0004 | `FWUPDATE0004` | Archived | [FWUPDATE0004.bin](firmware/dualsense/0x0458/FWUPDATE0004.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0004/0x0458/FWUPDATE0004.bin) | `499ED91E02D7408D0EA60D01AF81B30466EA1688E5B79F0A2C63C6521260EB2D` |
| `0x0402` | Type 0004 | `FWUPDATE0004` | Archived | [FWUPDATE0004.bin](firmware/dualsense/0x0402/FWUPDATE0004.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0004/0x0402/FWUPDATE0004.bin) | `23A0F6B3BBA9C6068BE279E2841799AF655EA8410226C2A0FD82AFD96B93C714` |
| `0x0356` | Type 0004 | `FWUPDATE0004` | Archived | [FWUPDATE0004.bin](firmware/dualsense/0x0356/FWUPDATE0004.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0004/0x0356/FWUPDATE0004.bin) | `C9A8EB7039B3DFCBEA877962656C6C99D1FC1199EE6215322B53112F6026AC81` |
| `0x0307` | Type 0004 | `FWUPDATE0004` | Archived | [FWUPDATE0004.bin](firmware/dualsense/0x0307/FWUPDATE0004.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0004/0x0307/FWUPDATE0004.bin) | `612E15D910D670897C442E4305AD4E5481907494B6CE8D63CE8CE82B9B42C879` |
| `0x0297` | Type 0004 | `FWUPDATE0004` | Archived | [FWUPDATE0004.bin](firmware/dualsense/0x0297/FWUPDATE0004.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0004/0x0297/FWUPDATE0004.bin) | `E4627D5E876ACADC60D52BDD8A8E48C15186D4BA50E1E0EEC760495F63220459` |

## DualSense Edge

| Version | Variant | Updater | Status | File | Official URL | SHA256 |
|---|---|---|---|---|---|---|
| `0x0217` | Type 0044 | `FWUPDATE0044` | Latest | [FWUPDATE0044.bin](firmware/dualsense-edge/0x0217/FWUPDATE0044.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0044/0x0217/FWUPDATE0044.bin) | `C157EEC635F809232E06C255A0847E6B915B0032CA661B12AE35FB2E4EAC49DF` |
| `0x0213` | Type 0044 | `FWUPDATE0044` | Archived | [FWUPDATE0044.bin](firmware/dualsense-edge/0x0213/FWUPDATE0044.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0044/0x0213/FWUPDATE0044.bin) | `A91BF4CE5E17F5AA87FEA51BB7A910B5D7C42D5E122933D7F1F88D1402027A46` |
| `0x0200` | Type 0044 | `FWUPDATE0044` | Archived | [FWUPDATE0044.bin](firmware/dualsense-edge/0x0200/FWUPDATE0044.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0044/0x0200/FWUPDATE0044.bin) | `E5B20FFB4E5FA72B1100F32C175E65735EABE8DA4046444B7E936573D51D64DB` |
| `0x0180` | Type 0044 | `FWUPDATE0044` | Archived | [FWUPDATE0044.bin](firmware/dualsense-edge/0x0180/FWUPDATE0044.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0044/0x0180/FWUPDATE0044.bin) | `9763356B6049D47E8A4840DDEEDD4C201B2CA05B8A7D99ABD9E7E6901AB32165` |
| `0x0154` | Type 0044 | `FWUPDATE0044` | Archived | [FWUPDATE0044.bin](firmware/dualsense-edge/0x0154/FWUPDATE0044.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0044/0x0154/FWUPDATE0044.bin) | `E4E3CCFF981960AC41E0D65EB85EF3584F2430971C4A06C8840F319891EF3C75` |
| `0x0113` | Type 0044 | `FWUPDATE0044` | Archived | [FWUPDATE0044.bin](firmware/dualsense-edge/0x0113/FWUPDATE0044.bin) | [Download](https://fwupdater.dl.playstation.net/fwupdater/fwupdate0044/0x0113/FWUPDATE0044.bin) | `F936C6EC5A8AF88521772DA1943FFD554EA1F3B40D61E5C19F1E3A35BC037F48` |

## Metadata

- `devices.json` defines supported devices, variants, updater IDs, and URL patterns.
- `firmwares.json` lists every archived firmware file, source URL, SHA256 hash, size, and latest flag.
- `.\tools\validate.ps1` verifies metadata, files, hashes, sizes, generated URLs, and untracked `.bin` files under `firmware/`.

## PlayStation Accessories

[PlayStation Accessories firmware updater](https://controller.dl.playstation.net/controller/lang/en/fwupdater.html)

<img width="962" alt="Screenshot 2024-09-29 050231" src="https://github.com/user-attachments/assets/30cd8fc1-f34b-4d1a-ad2a-ea084edf4f0f">
