# Design System Document

## 1. Overview & Creative North Star
**Creative North Star: "The Archivist’s Grimoire"**

This design system moves away from the sterile, cold nature of modern fintech. Instead, it treats financial tracking as a personal investigation—a curated collection of life’s data captured within a weathered, living journal. In this light-themed iteration, the "Grimoire" takes on a classic scholarly character, resembling an open ledger on a sunlit desk where crisp parchment and ink-black details prioritize readability and tactile history.

The aesthetic logic follows a "70/30" split: 70% of the experience is governed by rigorous editorial clarity (structured data and legible sans-serifs), while 30% is infused with "analog soul" (hand-drawn imperfections and tactile depth). We break the "standard app" mold by rejecting rigid grids in favor of **Intentional Asymmetry**.

---

## 2. Colors: The Alchemical Palette
Our palette avoids neon vibrancy, favoring pigments derived from ink, organic dyes, and aged minerals. The light mode utilizes warm, parchment-based neutrals for the canvas to provide a comfortable reading experience without the sterile glare of pure white.

### Primary Roles
*   **Primary (`#D4AF37`):** The "Gold Standard." Used for high-value insights, rewards, and critical call-to-actions. This acts as the precious metal gilding the edges of the UI.
*   **Secondary (`#2E5A1C`):** The "Growth Green." A deep, forest-toned green used for income and positive financial trends, reminiscent of classic library table felt.
*   **Tertiary (`#A52A2A`):** The "Iron Gall." A muted, oxblood red used for expenses and alerts, inspired by historical wax seals.
*   **Neutral/Background (`#F5F5DC`):** The "Vellum Base." A rich, creamy neutral that provides the organic texture of high-quality paper.

### The "No-Line" Rule
**Explicit Instruction:** Prohibit the use of 1px solid digital strokes for sectioning. Boundaries must be defined through:
1.  **Tonal Shifts:** Placing a `surface_container_high` card against a `surface` background.
2.  **Edge Treatment:** Using the "Ghost Border" or the hand-drawn primitive assets.
3.  **Negative Space:** Compact intervals of whitespace to denote group transitions.

---

## 3. Typography: The Scribal Contrast
The typographic system relies on the tension between the personal (Epilogue) and the functional (Manrope/Space Grotesk).

*   **The Display Scale (Epilogue):** These are the "Journal Entries." Large, expressive, and slightly idiosyncratic. Use these for headers that tell a story.
*   **The Body Scale (Manrope):** This is the "Clarity Layer." All transactional data and numbers must use Manrope to ensure "money" utility is never compromised.
*   **The Label Scale (Space Grotesk):** Used for metadata and technical tags. Its slightly mechanical feel provides a "filed and indexed" look.

---

## 4. Elevation & Depth: Tonal Layering
Depth is "material stacking," not just shadows.

### The Layering Principle
*   **Base:** `surface` (The heavy vellum page).
*   **Middle:** `surface_container_low` (Inlaid paper slips).
*   **Top:** `surface_container_highest` (Pinned receipts or sticky notes).

### Ambient Shadows
For floating elements, use an **Ambient Shadow**:
*   **Color:** `on_surface` at 8% opacity (optimized for the light parchment background).
*   **Blur:** 24px - 40px.
*   **Offset:** 8px downward.

---

## 5. Components

### Layout & Spacing
The system uses a **Compact (2)** spacing logic. The "Grimoire" is densely packed with information, resembling a researcher's crowded desk where every inch of paper is valuable.

### Buttons
*   **Primary:** A solid `primary` fill with a subtle 2px "sketched" outer stroke. Use `on_primary` for text.
*   **Secondary:** No background fill. A "Ghost Border" perimeter with a 1-degree rotation to simulate a hand-cut paper strip.

### Roundedness
Corner treatment is **Subtle (1)**. UI elements should feel like hand-cut paper or bound ledger books—mostly rectangular and architectural with only the slightest softening of the edges to prevent a purely digital "sharpness."

### Input Fields
*   **The "Ledger Line":** Use a single `outline` bottom-border. The line should have a slightly irregular width (0.5px to 1.5px) to mimic a hand-drawn quill stroke.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** embrace the compact density. Information should feel "filed" and substantial.
*   **Do** use "Paper-on-Paper" nesting with subtle tonal shifts.
*   **Do** ensure high contrast for typography (Manrope) against the parchment background.

### Don’t:
*   **Don’t** use high-contrast dividers. Use the `spacing: 2` gaps to define rhythm.
*   **Don’t** use pill-shaped containers for cards; stick to the `roundedness: 1` constraint.
*   **Don’t** use pure #FFFFFF. Use the parchment neutrals provided to maintain the organic, "analog" quality of the light mode.