# Clinical and visual contract

## Locked defaults

Apply once if no profile exists; persist, hash, and reuse verbatim.

| Property | Default |
| --- | --- |
| Person | Same fictional 2D cartoon adult woman in every occupied panel; medium skin tone, average build |
| Face/hair | Same face; dark-brown hair in a low ponytail |
| Shirt | Plain muted coral-red short-sleeve crew-neck shirt |
| Pants | Plain navy-blue full-length exercise pants |
| Accessories | None; no branding |
| Feet | Barefoot unless the resolved clinical specification requires an approved exception |
| Mat when needed | Same pale-gray plain mat |
| Background | Opaque pure white; no scenery/decorations |
| Colorful style | Professional 2D cartoon clinical illustration; flat light colors, clean contours, anatomically plausible proportions, restrained soft shading; no photorealism |
| Pencil style | Matching cartoon character in thin light-gray continuous pencil contours; minimal shading; no colored fills; no photographic realism |
| Sheet dimensions | Request 1536 × 1024 if supported; otherwise lock supported dimensions before generation. Inspect and record actual output dimensions; a prompt does not guarantee pixel size. |
| Layout | 3 equal-width columns × 2 equal-height rows, white gutters, no drawn borders |
| Camera per panel | Clinically informative view with full body/equipment and comfortable margin |

Require professional cartoon rendering in EVERY panel and prompt. Never depict a real human model, photo, photorealistic person, realistic skin texture, live-action image, or photorealistic 3D figure. Reject either sheet if it appears photographic or realistically rendered. Keep mature, anatomically plausible proportions; avoid chibi proportions, caricature, or exaggerated joints. Use clean controlled contours, preserving curved anatomy and readable contrast. Reference editing can drift; reject drift rather than claiming guaranteed consistency. If a panel is too small to assess decisive anatomy, hold validation; do not silently create a higher-resolution generation.

## Ordered panel manifest

Keep the same input order and geometry for both sheets. Indices are metadata only, never rendered. These normalized rectangles define equal cells; leave white safety margins inside each cell for gutters.

| Panel | Position | Cell rectangle [x, y, width, height] |
| --- | --- | --- |
| 1 | Top left | [0, 0, 1/3, 1/2] |
| 2 | Top center | [1/3, 0, 1/3, 1/2] |
| 3 | Top right | [2/3, 0, 1/3, 1/2] |
| 4 | Bottom left | [0, 1/2, 1/3, 1/2] |
| 5 | Bottom center | [1/3, 1/2, 1/3, 1/2] |
| 6 | Bottom right | [2/3, 1/2, 1/3, 1/2] |

For six exercises occupy every cell. For fewer, leave only trailing cells blank. Save actual pixel dimensions and derive pixel cell bounds from them with consistent rounding if a consumer needs them. Do not claim equal-size standalone assets; the deliverables are two whole sheets. Do not crop or split them unless separately requested.

## Clinical specification (outside pixels)

Save original/resolved name, variant, side, phase, source URL/title/access date or clinician reference ID, body orientation, supports/contact points, joint positions, grip, equipment, camera, decisive visible features, errors to avoid, specification version, and unresolved questions for each exercise. Resolve ambiguous variants before batch reservation. Use primary clinical sources or clinician-provided references. Do not prescribe hold times or repetitions.

Each occupied panel must convey its own exercise with one informative static pose. Assign clinically necessary supports and equipment to that panel alone. Keep provenance, clinical notes, and exercise names outside pixels. A clinical specification is internal prompt data, not a request to render its name or instructions.

## Colorful full-sheet prompt template

Fill every occupied panel specification from the saved manifest:

> Create exactly ONE landscape image containing [occupied_count, normally SIX] distinct exercise illustrations in a fixed 3-column by 2-row grid. Read the following positions as composition instructions only: do not print names, numbers, or labels. Top-left: [exercise 1 specification]. Top-center: [exercise 2 specification]. Top-right: [exercise 3 specification]. Bottom-left: [exercise 4 specification]. Bottom-center: [exercise 5 specification]. Bottom-right: [exercise 6 specification]. [For a partial batch, explicitly mark trailing positions as blank white.] In each occupied cell show exactly ONE fictional 2D cartoon adult performing its assigned exercise in ONE clinically informative static pose, with correct side, phase, joints, grip, support contacts, required equipment, and specified camera. Avoid each specification's technique errors and substitutions. Use the SAME fictional cartoon woman in all cells: [full locked profile]. [When available: Use the attached collection anchor for identity, clothes, proportions, equipment design, and style, but replace its exercise poses with this manifest.] Professional cartoon clinical illustration, clean 2D contours and flat light colors, anatomically plausible adult proportions, restrained soft shading; strictly non-photorealistic, no real human model, no photographic skin texture, no live-action or photorealistic 3D rendering, opaque pure-white background. Each full body and its equipment must fit comfortably inside its own equal-sized cell with clear white gutters. No drawn grid borders. Request [locked sheet dimensions]. NO text, titles, exercise names, lettering, numbers, labels, captions, arrows, logos, watermarks, signatures, anatomy overlays, muscle highlights, motion ghosts, extra people within a cell, or additional panels. Return ONE complete sheet only.

Accept only compliant cartoon identity/style anchors; use a clinical photograph solely to resolve pose/equipment, never to copy a real person or photographic appearance. Without an existing anchor, omit the attachment clause and use locked written defaults for this first colorful sheet. It counts as request one of two; never generate an extra character exemplar. Promote the sheet to a collection anchor only after every occupied panel passes validation and its applicable review gate.

## Pencil full-sheet conversion prompt template

> Convert ONLY the rendering style of the entire attached validated colorful exercise sheet into delicate light-gray pencil contours on opaque pure white. Return exactly ONE complete sheet. Preserve its exact 3-column by 2-row grid, dimensions, occupied and blank cell positions, white gutters, exercise order, and every panel's subject and geometry. Preserve the same fictional cartoon character, simplified illustrated face, hair, clothing shapes, proportions, pose, camera, framing, joints, hand/foot placement, support contacts, and equipment in EACH occupied panel. Maintain professional 2D cartoon anatomy and the fictional illustrated identity. Clean thin readable continuous contours, minimal shading, no colored fills. No real human model, photograph, photorealistic shading, realistic skin texture, live-action figure, or photorealistic 3D rendering. Do not reinterpret exercise technique, rearrange panels, copy one exercise into another, crop, or add/remove anatomy/equipment. Exactly one person, one exercise, and one pose per occupied cell. NO text, names, lettering, numbering, labels, instructions, arrows, logos, watermarks, signatures, drawn grid borders, anatomy overlays, ghosts, additional people within cells, or extra panels.

Reference the actual whole colorful sheet with the tool's supported attachment mechanism; never use only a written description. Compare every pencil panel against the matching colorful panel, then verify full-sheet layout and dimensions. Any uncertain or failed panel rejects the entire pair. Do not regenerate or repair automatically.
