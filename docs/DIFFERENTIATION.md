# Buddy — differentiation lock

**Date:** 2026-09-23 (rev: delivery + companion AI)  
**Status:** Working lock

## Honest frame

We won’t out-feature MyFitnessPal on database, barcodes, or integrations.  
**We win on how the same jobs feel:** Plan → Log → talk to Buddy — with better UI/UX, onboarding, fun interactions, and a companion that actually *talks*.

Same jobs as the category: track energy, plan meals, learn about food/fitness.  
Different delivery: **companion-grade experience + on-device AI + RP-grounded food/fitness expertise.**

## What does *not* differentiate Buddy

Bigger food DB · barcode supremacy · more charts · “all-in-one health OS” feature count · AI food scan as the only story (others already claim it).

## What *does* (the wedge)

**Buddy is a marshmallow-ghost companion who delivers calorie Plan & Log with delightful UX — and talks with you as a shame-light food & fitness expert (calories first).**

| Pillar | Meaning | Competitor contrast |
|--------|---------|---------------------|
| **Companion AI** | Chat / reactions / check-ins — Buddy *communicates* | Silent trackers; generic coach bots |
| **Delivery craft** | Onboarding, motion, sheets, fun interactions | Utilitarian spreadsheet UX |
| **Plan & Log** | Plan ahead → snap/log when real | Log-only grind or plan-only apps |
| **RP food/fitness expert** | Calories > macros > timing; adherence-first advice | Macro theater; fad tips; shame |
| **Calories first UI** | Energy scoreboard; macros quiet | Macro cockpit home screens |
| **On-device FM** | Private plate estimates + talk | Cloud AI flex as headline |

## One sentence

*If Buddy didn’t exist, you’d use MFP — Buddy is for people who want the same tracking jobs delivered by a ghost companion that talks, feels good to use, and keeps advice calories-first.*

## Companion AI (must-ship capability)

Buddy is not a logo on a tracker. He **interacts**:

| Mode | Job | Grounding |
|------|-----|-----------|
| **Plate talk** | After snap: estimate + short Buddy line | Vision + FM (exists) |
| **Buddy chat** | Ask about today, hunger, plan, “what should I eat” | FM + RP beats (calories first; never diagnose) |
| **Check-in** | Morning / streak / empty dinner | FM templates (Mavy-style beats) |
| **Plan help** | Fill empty Plan & Log slots | FM + day calorie budget |

Voice lock: shame-light, brief, ghost-flavored — celebrate **logging**, not restriction. Prefer “log / with you” over “watch.”

## Delivery craft (how we win the same functionality)

1. **Onboarding** — phase + target calories in ≤60s; Buddy greets; no 12-step quiz walls.  
2. **Log path** — snap → estimate → edit → confirm in one sheet; interruptible, tactile.  
3. **Plan path** — Plan & Log cards; snap closes the loop.  
4. **Fun interactions** — press scale, ghost float, XP toast, streak moments (rare delight, not every tap).  
5. **Empty / error states** — Buddy speaks; never blank tables.

## RP expert rules (in-product)

Priority: **calories → macros → timing → composition → supplements.**  
Adherence is prerequisite — Buddy optimizes for *showing up*, not perfect macros.  
Never medical claims; never shame food.

## ASO draft (revolve around delivery + companion)

| Field | Draft |
|-------|--------|
| **Name** | Buddy |
| **Subtitle** | Food companion. Plan & Log. |
| **Hook** | A marshmallow ghost who talks you through plan, snap, and calories — feels good to open. |
| **Screenshot 1** | What’s up, bud? (chat / companion) |
| **Screenshot 2** | Plan the meal. Snap when it’s real. |
| **Screenshot 3** | Calories first. No shame. |

Keywords still include `calorie,tracker,meal,photo,food,log` for CEPs — subtitle/hook carry companion + delivery.

## Product implications

1. Today = log spine + Buddy presence.  
2. Plan = Plan & Log.  
3. **Buddy tab / sheet = chat + check-ins** (new primary differentiator).  
4. FM specialization = calorie/fitness/food expert beats (RP-compressed).  
5. Invest polish budget in onboarding + log sheet + chat — not feature sprawl.

## Skill stack (agent / build)

| Need | Use |
|------|-----|
| RP nutrition truth | Local `rp-diet` (already) |
| Photo → kcal pattern | `image-calorie-tracker` pattern (Buddy already implements on-device) |
| Onboarding craft | Local `onboarding` · optional: `npx skills add launchdarkly/ai-tooling@onboarding` (4.4K) |
| iOS onboarding ref | `npx skills add pd/pe@ios-onboarding` (verify fit; low installs) |
| Companion chat UX | Build in-app (Mavy CompanionBeats pattern) — no strong public skill required |

Avoid installing low-install “health coach” clones; keep **BuddyPeerBase + RP** as the expert voice.
