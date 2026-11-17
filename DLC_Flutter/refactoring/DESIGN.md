---
name: Academic Clarity
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#45464d'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#006a61'
  on-secondary: '#ffffff'
  secondary-container: '#86f2e4'
  on-secondary-container: '#006f66'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#111c2d'
  on-tertiary-container: '#79849a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#89f5e7'
  secondary-fixed-dim: '#6bd8cb'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#005049'
  tertiary-fixed: '#d8e3fb'
  tertiary-fixed-dim: '#bcc7de'
  on-tertiary-fixed: '#111c2d'
  on-tertiary-fixed-variant: '#3c475a'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  display-lg:
    fontFamily: Newsreader
    fontSize: 44px
    fontWeight: '600'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Newsreader
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Newsreader
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Newsreader
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 30px
  headline-sm:
    fontFamily: Newsreader
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  title-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  title-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  title-sm:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Manrope
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an academic, focused, and scholarly environment tailored for university researchers, faculty, and students on Android. It bridges Material Design 3 guidelines with refined editorial curation, discarding commercial clutter in favor of quiet intellectual immersion.

### Personality & Values
- **Scholarly & Calm:** Cultivates deep concentration through neutral tones, generous breathing room, and structured order.
- **Institutional & Trustworthy:** Presents authoritative metadata, cataloging precision, and reliable borrowing availability.
- **Modern Scholastic:** Combines the timeless gravity of a physical archive with the velocity of digital retrieval.

### Design Movement
**Modern Academic Editorial with Material 3 Foundations.** The aesthetic avoids playful novelty or aggressive e-commerce prompts. Instead, it relies on structured surface hierarchy, hairline dividers (`#E2E8F0`), high-contrast typography, and purposeful contextual tokens for circulation statuses.

## Colors

The palette enforces a contemplative atmosphere using deep slates and grounding teals, deliberately avoiding commercial colors.

### Semantic Palette
- **Primary (`#0F172A` / `#1E293B`):** Deep Academic Navy/Indigo. Applied to key structural headers, prominent navigation bars, active tabs, and primary actions (e.g., "Mượn tài liệu", "Đặt trước").
- **Secondary (`#0D9488` / `#14B8A6`):** Intellectual Teal & Sage. Used for research category indicators, verified badge highlights, and interactive accents.
- **Neutral Surface (`#F8FAFC` to `#FFFFFF`):** High-readability surfaces that mimic archival paper without warm yellowing.
- **Dividers & Hairlines (`#E2E8F0`):** Precise sub-pixel boundaries framing catalog cards and metadata tables.

### Circulation & Availability States
Academic status tracking is functional, non-transactional:
- **Khả dụng / Còn sách (`#16A34A`):** Indicates on-shelf availability in physical or digital stacks. Accompanied by surface tint `#F0FDF4`.
- **Đang mượn hết / Hết tài liệu (`#DC2626`):** Indicates checked-out material, with secondary queue position badges. Accompanied by surface tint `#FEF2F2`.
- **Tài liệu tham khảo tại chỗ (`#D97706`):** Non-circulating reference collection. Surface tint `#FFFBEB`.

## Typography

Typography establishes scholarly authority by coupling an editorial serif for titles with a precise geometric sans-serif for bibliographies and metadata.

- **Newsreader (Display & Headlines):** Gives monograph titles, archive collections, and departmental sections a dignified, library-press character.
- **Manrope (Body & Technical Labels):** Renders call numbers (DDC/LCC), ISBNs, author attributions, and Vietnamese diacritics with extreme clarity across varying mobile viewports.
- **Call Numbers & Dewey System:** Rendered in `label-md` or `label-sm` with tabular numerals and slight letter-spacing to prevent visual confusion between numerical classifications and publication years.

## Layout & Spacing

The layout follows an Android-native fluid grid with strict compliance to 48dp minimum interactive touch targets.

### Rhythm & Density
- **Mobile Grid (4 columns):** 16dp (`1rem`) outer canvas margins and 16dp gutters. Density accommodates academic list views, full-text abstract previews, and callout shelves.
- **Tablet Grid (8-12 columns):** 24dp margins, transitioning into an interactive split-pane interface (Left pane: search filter facets and catalog hierarchy; Right pane: bibliographic record and holding inventory).
- **Touch Targets:** Buttons, chip filters, action overflows, and list items enforce a minimum interactive box of 48×48dp, even when visual icon indicators appear smaller.
- **Vertical Rhythm:** Content clusters use an 8dp baseline grid, separating structural metadata blocks by `space-lg` (24dp) and closely linked metadata (e.g., Tác giả next to Năm xuất bản) by `space-xs` (4dp) or `space-sm` (8dp).

## Elevation & Depth

This system avoids deep drop shadows, favoring tonal layering and 1px borders to reflect clean academic discipline.

### Surface Tiers
- **Level 0 (Canvas):** `#F8FAFC` base background for reading feeds, catalog lists, and reader interfaces.
- **Level 1 (Card / Container):** Pure `#FFFFFF` elevated solely by a hairline border (`1px solid #E2E8F0`). Used for publication cards, user borrowing profiles, and bibliographic details.
- **Level 2 (Modal / Bottom Sheet):** `#FFFFFF` paired with an ambient, diffused shadow tinted with slate: `box-shadow: 0 8px 24px -4px rgba(15, 23, 42, 0.08)`. Used for stack locators, renewal confirmation sheets, and filter drawers.
- **Level 3 (Navigation / Snackbars):** Floating top app bars and bottom navigation bars utilize `#FFFFFF` with a bottom/top boundary border of `#E2E8F0` and zero ambient blur, preserving content crispness.

## Shapes

The shape vocabulary uses gentle, organic geometry to soften institutional severity while maintaining cataloging order.

- **Standard Elements (0.5rem / 8px):** Input fields, inline metadata chips, table rows, and call-number badges.
- **Cards & Sheets (1rem / 16px):** Catalog book cards, thesis preview panels, dialog containers, and standard bottom sheets (`rounded-t-[16px]`).
- **Pill Elements (Full rounded / 9999px):** Applied exclusively to category filters ("Toàn văn", "Luận án", "Sách in"), availability indicator pills, and the primary Android Floating Action Button / Quick Bar.

## Components

### Buttons & Actions
- **Primary Button ("Mượn tài liệu", "Đặt trước tài liệu"):** Filled `#0F172A` background, white label, 12px corner radius, height 48dp. No gradient or commercial shine.
- **Secondary Button ("Gia hạn mượn", "Đọc trực tuyến"):** Outlined with 1px `#CBD5E1`, text `#0F172A`, height 48dp.
- **Tertiary Action ("Trích dẫn APA/MLA", "Lưu vào danh mục"):** Low-profile text button with Teal `#0D9488` emphasis and an integrated scholarly icon.

### Chips & Filter Indicators
- **Category Filter Chips:** Horizontal scrolling row with 8px gaps. Selected state uses `#0F172A` fill with `#FFFFFF` text. Unselected state uses `#FFFFFF` fill, 1px `#E2E8F0` border, and `#334155` text.
- **Availability Pill:**
  - *Còn sách:* Background `#F0FDF4`, border `#BBF7D0`, text `#16A34A` with a leading 6px dot indicator.
  - *Đang mượn hết:* Background `#FEF2F2`, border `#FECACA`, text `#DC2626`.
  - *Chỉ đọc tại chỗ:* Background `#FFFBEB`, border `#FDE68A`, text `#B45309`.

### Catalog & Resource Cards
- Single 1px `#E2E8F0` border, pure white background, 16px radius, 16px internal padding.
- Displays book jacket or academic monogram thumbnail (aspect ratio 2:3, 8px radius) alongside authoritative metadata: Title (Newsreader, 16px), Author, Year, DDC Shelf Code (Manrope tabular 12px), and real-time circulation badge.

### Form Inputs & Catalog Search
- **Search Bar:** Prominent search anchor with placeholder: *"Tìm theo tên sách, tác giả, ISBN hoặc mã phân loại..."*. Height 52dp, background `#FFFFFF`, border 1px `#CBD5E1`, leading research icon and trailing barcode/camera scanner for library shelf codes.
- **Dropdowns & Pickers:** Clear selection for campus branches ("Cơ sở 1 - Thư viện Trung tâm", "Cơ sở 2 - Phòng đọc Chuyên ngành").

### Academic Domain Components
- **Callout Citation Box:** Dedicated component to export formatted bibliographic citations (APA 7th, Chicago, IEEE) with one-touch copy interaction.
- **Shelf Locator (Sơ đồ kệ sách):** Visual indicator showing floor, aisle, and shelf code (e.g., `Khu B3 • Kệ 14 • Ngăn 02`) rendered in a clean technical badge.
- **Loan Status Tracker:** Academic loan list showing return deadlines with urgency warnings (e.g., "Hạn trả: 15 ngày", "Cần trả trong 2 ngày"), entirely devoid of transactional late-fee language until past-due administration is triggered.