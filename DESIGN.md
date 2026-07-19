<!-- SEED: re-run $impeccable document once there's code to capture the actual tokens and components. -->

---
name: Open Control
description: Local-network remote control for OBS Studio
---

# Design System: Open Control

## 1. Overview

**Creative North Star: "The Night Console"**

A calm instrument panel used in the dark, beside a monitor, mid-stream — closer to Apple Home or Sonos than to a mixing board or a SaaS dashboard. Charcoal surfaces recede so a single amber signal color can carry all the meaning: connected, live, attention-needed. Nothing here competes for a second glance; it's built to be read in under a second and put back down. Explicitly rejects the generic SaaS-dashboard look: no cards-everywhere grids, no gradient stat tiles, no admin-template chrome.

**Key Characteristics:**
- Dark, low-light-first surface
- One accent color (amber), spent sparingly
- Flat list rows over cards
- Restrained motion — state changes only

## 2. Colors

Charcoal/graphite neutrals carry the surface; one amber accent is reserved for connected/live signal states.

### Primary
- **Signal Amber** (`[hex to be resolved during implementation]`): reserved for the connected/live indicator and the primary connect action. Used sparingly — this is the one thing the eye should catch first.

### Neutral
- **Near-black Charcoal** (`[to be resolved]`): base background.
- **Graphite** (`[to be resolved]`): surface for list rows, one step up from the background.
- **Dim / Bright text** (`[to be resolved]`): body text pair, tuned for low-light contrast.

### Named Rules
**The One Signal Rule.** Amber appears only on connected/active state and the primary action. Every other control stays neutral.

## 3. Typography

**Display/Body Font:** Single sans, technical/geometric (`[specific family to be chosen at implementation]`)
**Character:** One family throughout; tabular/mono numerals for IP addresses, ports, and timestamps so status readouts don't jitter.

### Hierarchy
- **Title**: screen/section headers.
- **Body**: list rows, form labels.
- **Label**: status badges, timestamps — smaller, tabular figures.

## 4. Elevation

Flat by default, restrained motion. Depth comes from tonal steps (charcoal → graphite), not shadows — shadows read as glare in a low-light context.

### Named Rules
**The Flat-By-Default Rule.** Surfaces are flat at rest; elevation is expressed as a lighter tone step, not a shadow.

## 5. Components

Skipped in seed mode — no components exist yet. First real components will be documented on the next `$impeccable document` run once the connection screen ships.

## 6. Do's and Don'ts

### Do:
- **Do** keep the amber accent to the connected/live indicator and the primary action only (The One Signal Rule).
- **Do** default to flat list rows over cards for the saved-connections list.
- **Do** keep motion to state changes only — connect/disconnect, list add/remove — no orchestrated entrances.

### Don't:
- **Don't** build a generic SaaS dashboard — no cards-everywhere grids, no gradient stat tiles, no admin-template chrome.
- **Don't** use drop shadows for elevation; use tonal steps instead.
- **Don't** add choreographed/staggered entrance animations.
