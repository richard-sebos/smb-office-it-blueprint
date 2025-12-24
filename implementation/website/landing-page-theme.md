# 🎨 SMB IT Blueprint – Landing Page Theme Design Document

**Version:** 1.1
**Author:** Richard Sebos
**Theme Name:** `dark-infra-modern`
**Purpose:** To define a reusable visual identity for the public-facing landing page of the SMB IT Blueprint, blending technical precision with business accessibility.

---

## 📐 1. Layout Structure

| Section           | Description                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| **Header**        | Sticky top nav with logo, tagline, and role-based nav options (Docs, Policies, Articles, etc.) |
| **Hero Section**  | Full-width graphic, tagline, and CTA. Emphasizes Linux's role in modern SMB infrastructure     |
| **Why Linux**     | 3-column benefits block (Cost, Control, Security) with icons and short explanations            |
| **Use Case Grid** | 4–6 visual cards: Samba AD, CUPS, Linux Desktop, Secure Vault, etc.                            |
| **Quote Banner**  | Full-width visual callout with a quote about Linux’s place at the “grown-up table”             |
| **CTA Section**   | Strong closing section with CTA button (e.g., “Explore the Blueprint”)                         |
| **Footer**        | Dark bar with logo, nav links, contact, version, and update date                               |

---

## 🎨 2. Color Palette

| Usage                         | Color Sample                                                    | Hex Code  | Notes                                      |
| ----------------------------- | --------------------------------------------------------------- | --------- | ------------------------------------------ |
| **Background Base**           | ![#0A0F1A](https://via.placeholder.com/15/0A0F1A/000000?text=+) | `#0A0F1A` | Site-wide background; deep navy blue       |
| **Card Background**           | ![#121826](https://via.placeholder.com/15/121826/000000?text=+) | `#121826` | Slight contrast against base background    |
| **Hero Accent Gradient**      | Linear: `#0A0F1A → #1E1B32`                                     | —         | Used subtly behind banner imagery          |
| **Primary Accent (Cyan)**     | ![#00FFFF](https://via.placeholder.com/15/00FFFF/000000?text=+) | `#00FFFF` | CTA buttons, links, active UI              |
| **Secondary Accent (Violet)** | ![#A64EFF](https://via.placeholder.com/15/A64EFF/000000?text=+) | `#A64EFF` | Used in quote banners or subtle highlights |
| **Success/Info**              | ![#3ED8D8](https://via.placeholder.com/15/3ED8D8/000000?text=+) | `#3ED8D8` | Status badges, info tags                   |
| **Highlight (Amber)**         | ![#FFB347](https://via.placeholder.com/15/FFB347/000000?text=+) | `#FFB347` | Callouts, hover highlights                 |
| **Danger/Warning**            | ![#FF4F64](https://via.placeholder.com/15/FF4F64/000000?text=+) | `#FF4F64` | Restricted access / root alerts            |
| **Primary Text (White)**      | ![#FFFFFF](https://via.placeholder.com/15/FFFFFF/000000?text=+) | `#FFFFFF` | Titles, headers, CTA copy                  |
| **Secondary Text (Gray)**     | ![#CCCCCC](https://via.placeholder.com/15/CCCCCC/000000?text=+) | `#CCCCCC` | Body text, descriptions                    |
| **Muted Gray**                | ![#888888](https://via.placeholder.com/15/888888/000000?text=+) | `#888888` | Timestamps, footers, legal                 |
| **Link Hover**                | ![#00CED1](https://via.placeholder.com/15/00CED1/000000?text=+) | `#00CED1` | Slightly deeper cyan for hover interaction |

---

## 🔤 3. Typography

| Element              | Font                       | Weight/Style     | Color                  | Notes                                          |
| -------------------- | -------------------------- | ---------------- | ---------------------- | ---------------------------------------------- |
| **Headings (h1–h3)** | IBM Plex Sans / Inter      | 600–700          | `#FFFFFF`              | Strong, bold, uppercase or wide letter spacing |
| **Body Text**        | Inter / Plex Sans          | 400–500          | `#CCCCCC`              | Highly readable on dark background             |
| **Code/CLI**         | JetBrains Mono / Fira Mono | 400              | `#3ED8D8`              | Monospaced for shell examples                  |
| **Link Text**        | Inter                      | 500 / Underlined | `#00FFFF`              | Bright cyan for all links                      |
| **CTA Buttons**      | Inter / Semi-bold          | 600 / Uppercase  | `#0A0F1A` on `#00FFFF` | Inverted, readable contrast                    |
| **Quote Italics**    | Inter Italic               | 400 / Italic     | `#A64EFF`              | Used in banners or testimonial overlays        |

---

## 🧱 4. Component Visuals

### 🔹 Header

| Component        | Value                              |
| ---------------- | ---------------------------------- |
| **BG Color**     | `#0A0F1A`                          |
| **Text Color**   | `#FFFFFF`                          |
| **Hover Effect** | `border-bottom: 2px solid #00FFFF` |
| **Logo Style**   | White or Cyan + minimalist icon    |

### 🔹 Hero Section

* Background: Dark gradient (`#0A0F1A` → `#1E1B32`)
* Neon wireframe or system icons
* CTA Button: Cyan (`#00FFFF`) with dark text on hover

### 🔹 Feature Cards (Why Linux)

| Feature    | Color                   | Notes                       |
| ---------- | ----------------------- | --------------------------- |
| Cost       | Cyan (`#00FFFF`) icon   | Simplifies budget           |
| Security   | Violet (`#A64EFF`) icon | Explains audit controls     |
| Control    | Amber (`#FFB347`) icon  | Customization & ownership   |
| Background | `#121826`               | Slight elevation via shadow |

### 🔹 Use Case Cards

* Card BG: `#121826`
* Neon Icon (cyan or violet)
* On hover: border glow (`#00FFFF` or `#A64EFF`)
* Example icons: folder, server, desktop, print queue

### 🔹 Quote Banner

* Background: Gradient overlay with deep violet
* Quote text: `#A64EFF` italicized
* Author: `#888888`

### 🔹 CTA Section

* Full-width `#00FFFF` background
* CTA Text: `#0A0F1A`
* Button: Inverted hover (`#0A0F1A` bg with `#00FFFF` border and text)

### 🔹 Footer

| Property   | Value                 |
| ---------- | --------------------- |
| Background | `#0A0F1A`             |
| Text       | `#888888` / `#CCCCCC` |
| Links      | `#00CED1`             |
| Borders    | `1px solid #1E1B32`   |

---

## 📲 5. Responsive Breakpoints

| Viewport Width | Layout Adjustment                                    |
| -------------- | ---------------------------------------------------- |
| `≤ 480px`      | Single-column, mobile nav, collapsible use cases     |
| `481–768px`    | 2-column grid for features, stacked CTA & quote      |
| `769–1024px`   | 3-column feature grid, side-by-side quote & CTA      |
| `>1024px`      | Max layout (e.g. 1200px width), full navbar & footer |

---

## 🧩 6. Implementation Tools

| Element          | Recommended Stack                                      |
| ---------------- | ------------------------------------------------------ |
| Astro Components | Tailwind CSS (custom theme)                            |
| Assets           | Optimized SVGs, WebP                                   |
| Deployment       | GitHub Pages via CI/CD                                 |
| CSS Variables    | `--color-bg`, `--color-accent`, etc. for theme control |

---

## ✅ Theme Highlights

* ✅ Modern, dark infosec-style interface
* ✅ Designed for both IT pros and business readers
* ✅ Brand-matched with previous AIDE, Samba, and file permission articles
* ✅ Clear hierarchy and visual storytelling
* ✅ Readable typography with strong color contrast
* ✅ Mobile-friendly and performance-optimized


