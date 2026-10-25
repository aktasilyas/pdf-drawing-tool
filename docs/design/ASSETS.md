# Third-party design assets

All entries are CC0 1.0 (public domain dedication; ambientCG licence page: https://docs.ambientcg.com/license/).
No attribution is required; it is recorded here for provenance.

## Cover material tiles

Location: `packages/drawing_ui/assets/covers/textures/` (loaded by `CoverTextureStore`).
Processing: ambientCG 2048 px colour map -> grayscale -> resized to 512x512 (tileable, so tiling is
preserved) -> low-frequency colour removed with a wrap-around blur and detail contrast raised
(ImageMagick) -> WebP q82. The tiles are mid-grey detail; the renderer tints them with the cover colour.

| File | ambientCG asset | Source URL | Licence | Size |
|------|-----------------|------------|---------|------|
| `leather.webp` | Leather030 | https://ambientcg.com/a/Leather030 | CC0 1.0 | 65 KB |
| `linen.webp` | Fabric036 | https://ambientcg.com/a/Fabric036 | CC0 1.0 | 63 KB |
| `kraft.webp` | Cardboard002 | https://ambientcg.com/a/Cardboard002 | CC0 1.0 | 27 KB |
| `felt.webp` | Fabric034 | https://ambientcg.com/a/Fabric034 | CC0 1.0 | 77 KB |

Downloaded from `https://f003.backblazeb2.com/file/ambientCG-Web/media/surface-preview/<asset>/<asset>_SQ_Color.jpg`
(the zip host `acg-download.struffelproductions.com` is not reachable from the cloud session).
