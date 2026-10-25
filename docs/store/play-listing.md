# Google Play listing (draft for v1.0)

Status: draft for owner approval (#59). Default language tr-TR, plus en-US. Lengths are within Play
limits (app name 30, short description 80, full description 4000 characters; counted with Python
`len()`: names 24/22, short 80/77, full ~900/~830). Feature claims cover only v1.0 scope (ink engine,
notebooks and covers, PDF import/annotate/export, local storage); frozen features are not mentioned.

## Reference check
- GoodNotes (Android): name pairs brand with category keywords ("Notes, Docs, PDF"); short text leads
  with handwriting on tablets; full text is grouped feature bullets (write, annotate PDFs, organise).
- Flexcil: listing leads with PDF reading + note-taking in one app; bullets for pen tools, PDF
  annotation, organising; stylus/tablet focus.
- StarNote: short value line (handwriting notes), then feature list (pens, PDF, templates, offline).
- What we do: the converged pattern (brand + keywords in the name, one-line value prop, grouped
  bullets). Our differentiator stated plainly: works offline, no account, no ads, data stays on device
  (true for v1.0 because all networked features are flag-off). Own wording, no copied text.

## tr-TR

**App name (30):** `Elyanotes: Notlar ve PDF`

**Short description (80):** `Tablette el yazısıyla not alın, PDF'lere çizin. Çevrimdışı, hesapsız, reklamsız.`

**Full description:**
```
Elyanotes, kağıt defter hissini tabletinize ve telefonunuza getiren bir el yazısı not uygulamasıdır. Sayfa ön planda, araçlar sakin ve elinizin altında.

KALEMLER VE MÜREKKEP
• Dolma kalem, tükenmez kalem, fırça kalem, kurşun kalem ve fosforlu kalem
• Basınca duyarlı, akıcı ve gecikmesi düşük mürekkep
• Silgi, seçim aracı, şekiller ve metin
• Geri al / yinele

DEFTERLER
• Kapaklı defterler ve klasörlerle düzenli bir kitaplık
• Çizgili, kareli, noktalı, Cornell ve planlayıcı sayfa şablonları
• Sayfa ekleme, silme ve yeniden sıralama

PDF
• PDF içe aktarın; ders notlarını, makaleleri ve formları işaretleyin
• Vurgulayın, altını çizin, kenar notu yazın
• Notlarınızı PDF olarak dışa aktarıp istediğiniz yere kaydedin

GİZLİLİK
• Tamamen çevrimdışı çalışır, hesap gerekmez
• Notlarınız yalnızca cihazınızda saklanır
• Reklam, analiz veya izleme yok

Kalem destekli Android tabletler için tasarlandı; telefonlarda da çalışır.
```

## en-US

**App name (30):** `Elyanotes: Notes & PDF`

**Short description (80):** `Handwrite notes and mark up PDFs on your tablet. Offline, no account, no ads.`

**Full description:**
```
Elyanotes is a handwriting notes app that brings the feel of a paper notebook to your tablet and phone. The page comes first; the tools stay quiet and close at hand.

PENS AND INK
• Fountain pen, ballpoint, brush pen, pencil and highlighter
• Pressure-sensitive, smooth, low-latency ink
• Eraser, lasso selection, shapes and text
• Undo / redo

NOTEBOOKS
• A tidy library of notebooks with covers, and folders
• Lined, grid, dotted, Cornell and planner page templates
• Add, delete and reorder pages

PDF
• Import PDFs and mark up lecture notes, papers and forms
• Highlight, underline and write in the margins
• Export your notes as PDF and save them anywhere

PRIVACY
• Works fully offline, no account needed
• Your notes are stored only on your device
• No ads, analytics or tracking

Designed for Android tablets with a stylus; works on phones too.
```

## Data safety form (answers for v1.0)
- Does the app collect or share any of the required user data types? **No.** Files the user opens and
  creates are processed only on the device and never sent off it, which Play does not count as
  collection.
- Data encrypted in transit / deletion request: not applicable (no data collected).
- Revisit before any release with AI chat, cloud sync, premium (RevenueCat), audio or crash reporting.

## Category, tags, rating
- Category: Productivity. Tags: note taking, PDF, handwriting.
- Content rating questionnaire: no user-generated content shared with others, no ads → expected
  rating "Everyone" / PEGI 3.
- Ads: "No". Target audience: 13+ (owner may choose otherwise; under-13 triggers Families policy).

## Screenshot plan
Phone (1080x1920 or larger, 2-8 shots) and 10-inch tablet (landscape 2560x1600, at least 4) sets.
Same story in both, captured from a release build with sample content we create ourselves (no
third-party PDFs or copyrighted text). Caption strip at the top, serif title, BRIEF palette.
1. Library with the cover family — "Tüm defterleriniz tek rafta" / "All your notebooks on one shelf"
2. Handwritten page with fountain and brush pen — "Gerçek kalem hissi" / "Ink that feels real"
3. Annotated PDF (own sample lecture PDF) with highlighter — "PDF'lere doğrudan yazın" / "Write right on PDFs"
4. Pen picker with the five presets — "Beş kalem, sınırsız renk" / "Five pens, any colour"
5. Page templates sheet — "Çizgili, kareli, noktalı" / "Lined, grid, dotted"
6. Export sheet — "PDF olarak dışa aktarın" / "Export as PDF"
7. Dark UI with a light page — "Gece de rahat" / "Easy on the eyes at night"
8. Privacy card (offline, no account, no ads) — "Notlarınız cihazınızda kalır" / "Your notes stay on your device"

Feature graphic (1024x500): cover family on the warm paper background with the wordmark; wordmark
treatment is an open BRIEF question, so this waits for the owner.

## Release-blocking notes for the owner
- `example_app/android/app/src/main/AndroidManifest.xml` declares `com.android.vending.BILLING` (for the
  frozen premium feature). Play shows it and may ask about in-app purchases; remove it from the v1.0
  release build (or move it to a flavor) so the listing and Data safety answers stay consistent.
  Follow-up issue recommended.
- The privacy policy needs a public URL and contact email (see `privacy-policy.md`).
- Turkish strings use Title Case pen names as decided on #45 (Dolma Kalem, Fosforlu Kalem).
