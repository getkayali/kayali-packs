# KAYALI region pack kit

Builds a downloadable map region (Saudi Arabia by default) with the same pipeline as KAYALI's built-in Syria data.

## Machine (one-time)
Linux (Ubuntu 22.04 or 24.04). As a starting point: 16 GB memory and 60 GB free disk (estimates; Saudi Arabia is far larger than Syria).

```
sudo apt install -y osmium-tool zip curl openjdk-21-jre-headless python3-pip
pip install pyvalhalla==3.6.3 duckdb osmium
```

## Build Saudi Arabia
```
PACK_URL="https://your-host/saudi.zip" ./build_region_pack.sh
```
Other regions: set `ID`, `NAME_AR`, `NAME_EN`, `BBOX` (west,south,east,north) and `PBF_URL` (a Geofabrik extract that contains the region).

## Publish
1. Upload `saudi.zip` to a host that gives a direct download link (it must support resumed downloads), and make sure that link is the `PACK_URL` you built with.
2. Share the link to `saudi.json` (Telegram, website, WhatsApp).
3. In KAYALI Pro Max: Regions → add a region from a link → paste it. The app downloads (resuming if interrupted), checks the SHA-256, installs, and lets you switch between Syria and Saudi Arabia.

The Saudi bounding box also covers bordering areas; that is expected and harmless.

## Foursquare Open Source Places (optional, Apache 2.0)
`tools/pull_fsq.py` pulls the newest monthly release for your bounding box (open places only, closed ones are skipped).
It needs your own READ-ONLY Hugging Face token (accept the dataset terms first; approval is automatic). Run it on your machine, never share the token, revoke it afterwards.
The pulled file is the input for the next step, the fusion merge (matching against the existing index by name, phone and distance), which is the next KAYALI update.

## One-tap catalogue in the app
1. Build each pack with `build_region_pack.sh` (IDs must match: `saudi`, `lebanon`, `jordan`, `iraq`, `turkey_south`).
2. Upload each `<id>.zip` and `<id>.json`, then copy `catalog.example.json` to `catalog.json`, put the real links and sizes in it, and upload it too.
3. In KAYALI (admin): Map regions → Advanced → paste the catalogue link → Save. Every phone that has opened the Regions screen with internet then shows **⬇ Download** next to each published pack; unpublished ones show "Coming soon".
