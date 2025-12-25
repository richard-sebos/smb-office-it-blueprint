<!-- branding/theme/dark-infra-modern.md -->

# 🎨 SMB IT Blueprint – Landing Page Theme Design Document

**Version:** 1.1  
**Author:** Richard Sebos  
**Theme Name:** `dark-infra-modern`  
**Purpose:** Define a reusable visual identity for the public-facing landing page of the SMB IT Blueprint, blending technical precision with business accessibility.

---

## 📐 1. Layout Structure

| Section           | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| **Header**        | Sticky top nav with logo, tagline, and role-based nav (Docs, Policies, etc.) |
| **Hero Section**  | Full-width graphic, tagline, and CTA (Call to Action)                        |
| **Why Linux**     | 3-column benefits block (Cost, Control, Security) with icons                 |
| **Use Case Grid** | 4–6 visual cards: Samba AD, Linux Desktop, Secure Vault, etc.                |
| **Quote Banner**  | Visual callout quote: “Linux sits at the grown-up table now.”                |
| **CTA Section**   | Strong CTA (e.g., “Explore the Blueprint”)                                   |
| **Footer**        | Dark footer with logo, nav links, version, contact info                     |

---

## 🎨 2. Color Palette

| Usage                         | Color Sample                                                    | Hex Code  |
| ----------------------------- | --------------------------------------------------------------- | --------- |
| **Background Base**           | ![#0A0F1A](https://via.placeholder.com/15/0A0F1A/000000?text=+) | `#0A0F1A` |
| **Card Background**           | ![#121826](https://via.placeholder.com/15/121826/000000?text=+) | `#121826` |
| **Hero Gradient**             | Linear Gradient: `#0A0F1A → #1E1B32`                             | —         |
| **Primary Accent (Cyan)**     | ![#00FFFF](https://via.placeholder.com/15/00FFFF/000000?text=+) | `#00FFFF` |
| **Secondary Accent (Violet)** | ![#A64EFF](https://via.placeholder.com/15/A64EFF/000000?text=+) | `#A64EFF` |
| **Success / Info**            | ![#3ED8D8](https://via.placeholder.com/15/3ED8D8/000000?text=+) | `#3ED8D8` |
| **Warning / Highlight**       | ![#FFB347](https://via.placeholder.com/15/FFB347/000000?text=+) | `#FFB347` |
| **Danger / Error**            | ![#FF4F64](https://via.placeholder.com/15/FF4F64/000000?text=+) | `#FF4F64` |
| **Text - Primary**            | ![#FFFFFF](https://via.placeholder.com/15/FFFFFF/000000?text=+) | `#FFFFFF` |
| **Text - Secondary**          | ![#CCCCCC](https://via.placeholder.com/15/CCCCCC/000000?text=+) | `#CCCCCC` |
| **Muted Gray**                | ![#888888](https://via.placeholder.com/15/888888/000000?text=+) | `#888888` |
| **Link Hover**                | ![#00CED1](https://via.placeholder.com/15/00CED1/000000?text=+) | `#00CED1` |

---

## 🔤 3. Typography

| Element            | Font Family                 | Style           | Color        | Notes                               |
| ------------------ | --------------------------- | --------------- | ------------ | ----------------------------------- |
| **Headings**       | IBM Plex Sans / Inter       | 600–700 Bold    | `#FFFFFF`    | Strong, uppercase or spaced         |
| **Body Text**      | Inter / Plex Sans           | 400–500 Normal  | `#CCCCCC`    | High contrast on dark background    |
| **Code Snippets**  | JetBrains Mono / Fira Mono  | Monospaced      | `#3ED8D8`    | CLI & config file emphasis          |
| **Links**          | Inter                       | Underlined      | `#00FFFF`    | Stands out from body text           |
| **Buttons (CTA)**  | Inter, Semi-bold            | Uppercase       | Inverted     | Cyan on dark or dark on cyan        |
| **Quotes**         | Inter Italic                | Italic          | `#A64EFF`    | Testimonial or editorial quotes     |

---

## 🧱 4. Component Visuals

### 🔹 Header

| Component     | Value                            |
| ------------- | -------------------------------- |
| Background    | `#0A0F1A`                         |
| Text Color    | `#FFFFFF`                         |
| Link Hover    | `border-bottom: 2px solid #00FFFF` |
| Logo          | Minimalist, White or Cyan         |

---

### 🔹 Hero Section

- Gradient background: `#0A0F1A → #1E1B32`
- Headline: Large, bold
- Button: Cyan background with dark hover

---

### 🔹 Feature Cards (Why Linux)

| Feature  | Color            | Notes                  |
| -------- | ---------------- | ---------------------- |
| Cost     | Cyan             | Highlight budget control |
| Control  | Amber            | Emphasizes ownership     |
| Security | Violet           | Security compliance       |

---

### 🔹 Use Case Cards

- Background: `#121826`
- Border glow on hover (Cyan or Violet)
- Neon-style icons

---

### 🔹 Quote Banner

- Background: Violet gradient
- Quote text: `#A64EFF` Italic
- Author: `#888888` muted small caps

---

### 🔹 CTA Section

- Background: `#00FFFF`
- Text: `#0A0F1A`
- Button: Inverted hover (Dark on Cyan)

---

### 🔹 Footer

| Property   | Value             |
| ---------- | ----------------- |
| Background | `#0A0F1A`         |
| Text       | `#888888`         |
| Links      | `#00CED1`         |
| Border     | `1px solid #1E1B32` |

---

## 📲 5. Responsive Breakpoints

| Viewport      | Layout                         |
| ------------- | ------------------------------ |
| ≤ 480px       | Single column, mobile nav      |
| 481–768px     | Two-column grid                |
| 769–1024px    | Side-by-side quote + CTA       |
| >1024px       | Full layout, max-width 1200px  |

---

## 🧩 6. Implementation Stack

| Component        | Tooling                   |
| ---------------- | ------------------------- |
| Build Framework  | [Astro](https://astro.build) |
| Styling          | Tailwind CSS (custom theme) |
| Icons            | Optimized SVG              |
| Fonts            | Hosted via Google Fonts    |
| Deployment       | GitHub Pages + Actions     |
| CDN              | GitHub Pages or Cloudflare |
| Favicon / Meta   | Custom icons + OG metadata |

---

## ✅ Theme Highlights

- ✅ Professional dark theme with neon security feel  
- ✅ Optimized for technical and business audiences  
- ✅ Responsive and mobile-first design  
- ✅ Ties into the branding of your article series  
- ✅ Accessible and readable on all devices  
- ✅ Ready to integrate with Astro + Starlight
