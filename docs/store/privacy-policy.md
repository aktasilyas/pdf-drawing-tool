# Elyanotes privacy policy (draft for v1.0)

Status: approved by the owner on 2026-10-25 (#59). Scope: the v1.0 Android release, built with all
feature flags off (`example_app/lib/core/config/feature_flags.dart`). Still to do before publishing:
host this page at a public URL (Play Console requires one).

The Turkish section is bundled in the app as `example_app/assets/legal/privacy_policy_tr.md`
(Settings → Gizlilik politikası); keep both in sync (a test in `example_app` checks it).

Must be revised before any release that turns on AI chat, cloud sync, premium or audio recording,
because each of those sends data off the device. Crash reporting (#60, Firebase Crashlytics) is
covered below; the owner pre-approved that section on #60.

---

## English

**Effective date:** 25 October 2026

Elyanotes ("the app") is a note-taking app published by İlyas Aktaş. This policy explains what
happens to your information when you use the app.

### Summary
Elyanotes works fully offline. Your notebooks, drawings, imported PDFs and images stay on your device.
We do not sell or share personal data, and the app contains no ads, analytics or tracking. The only
data that leaves your device is an optional, anonymous crash report (see "Crash reports"), which you
can turn off in Settings.

### Data stored on your device
- Notebooks, pages, handwriting, text, shapes and stickers you create.
- PDFs and images you import.
- App settings such as pen, colour and theme preferences.

This data is stored in the app's private storage on your device. We have no access to it. It is
deleted when you delete it in the app or uninstall the app. Android's own device backup may include
app data if you have enabled it in your system settings; that backup is governed by Google's policies.

### Permissions and device access
- **Files and photos:** used only when you choose a PDF or image to import, through the system file
  or photo picker. The app sees only the files you pick.
- **Camera (through the system camera app):** only if you choose to take a photo to insert into a page.
- **Saving to your gallery or files:** only when you export or save an image or PDF. On Android 9 and
  older this needs the storage permission; newer versions use scoped storage.
- **Clipboard:** only when you copy or paste content in the editor.

This release does not use the microphone, location or contacts. It uses the network only to send
crash reports (see below).

### Crash reports
If the app crashes, it can send a crash report to Google Firebase Crashlytics, a service provided by
Google, so we can find and fix the problem.
- **What is sent:** the technical error and stack trace, device model, Android version, app version,
  the time of the crash and a random installation identifier created by Crashlytics.
- **What is never sent:** your notes, drawings, PDFs, images, notebook titles, file names or paths,
  and no account or other personal identifier. File paths and quoted text are removed from error
  messages before a report is sent.
- **Purpose:** app stability only. Reports are not used for advertising or tracking.
- **Retention:** Crashlytics keeps crash reports for 90 days.
- **Turning it off:** Settings → Privacy → "Send crash reports". When you turn it off, no further
  reports are sent and reports not yet sent are deleted. It is on by default.

### Sharing and export
When you export or share a notebook, page or image, you choose the destination (for example another
app or a folder). What happens to the data there is governed by that destination.

### Children
The app collects no personal data from anyone, including children. The only data sent off the
device is the anonymous crash report described above.

### Changes
If a future version adds features that send data off the device, we will update this policy and the
app's store listing before releasing that version, and describe the change in the release notes.

### Contact
Questions about this policy: elyanotes2108@gmail.com.

---

## Türkçe

**Yürürlük tarihi:** 25 Ekim 2026

Elyanotes ("uygulama"), İlyas Aktaş tarafından yayınlanan bir not alma uygulamasıdır. Bu
politika, uygulamayı kullanırken bilgilerinize ne olduğunu açıklar.

### Özet
Elyanotes tamamen çevrimdışı çalışır. Defterleriniz, çizimleriniz, içe aktardığınız PDF'ler ve
görseller cihazınızda kalır. Kişisel veri satmayız veya paylaşmayız; uygulamada reklam, analiz veya
izleme yoktur. Cihazınızdan çıkan tek veri, Ayarlar'dan kapatabileceğiniz isteğe bağlı ve anonim çökme
raporudur ("Çökme raporları" bölümüne bakın).

### Cihazınızda saklanan veriler
- Oluşturduğunuz defterler, sayfalar, el yazısı, metin, şekiller ve çıkartmalar.
- İçe aktardığınız PDF'ler ve görseller.
- Kalem, renk ve tema tercihleri gibi uygulama ayarları.

Bu veriler cihazınızda uygulamanın özel depolama alanında tutulur; bizim erişimimiz yoktur. Uygulamada
sildiğinizde veya uygulamayı kaldırdığınızda silinir. Sistem ayarlarında Android yedeklemesini
açtıysanız, yedek uygulama verilerini içerebilir; bu yedek Google'ın politikalarına tabidir.

### İzinler ve cihaz erişimi
- **Dosyalar ve fotoğraflar:** yalnızca içe aktarmak için sistem dosya veya fotoğraf seçicisinden bir
  PDF ya da görsel seçtiğinizde. Uygulama yalnızca seçtiğiniz dosyaları görür.
- **Kamera (sistem kamera uygulaması üzerinden):** yalnızca sayfaya eklemek için fotoğraf çekmeyi
  seçerseniz.
- **Galeriye veya dosyalara kaydetme:** yalnızca bir görseli veya PDF'i dışa aktardığınızda. Android 9
  ve öncesinde depolama izni gerekir; yeni sürümler kapsamlı depolama kullanır.
- **Pano:** yalnızca düzenleyicide kopyalama veya yapıştırma yaptığınızda.

Bu sürüm mikrofonu, konumu veya kişileri kullanmaz. Ağı yalnızca çökme raporu göndermek için kullanır
(aşağıya bakın).

### Çökme raporları
Uygulama çökerse, sorunu bulup düzeltebilmemiz için Google'ın sunduğu Google Firebase Crashlytics
hizmetine bir çökme raporu gönderebilir.
- **Gönderilenler:** teknik hata ve yığın izi (stack trace), cihaz modeli, Android sürümü, uygulama
  sürümü, çökmenin zamanı ve Crashlytics'in oluşturduğu rastgele bir kurulum kimliği.
- **Asla gönderilmeyenler:** notlarınız, çizimleriniz, PDF'leriniz, görselleriniz, defter adları, dosya
  adları veya yolları; hesap ya da başka bir kişisel kimlik de gönderilmez. Rapor gönderilmeden önce
  hata mesajlarındaki dosya yolları ve tırnak içindeki metinler silinir.
- **Amaç:** yalnızca uygulamanın kararlılığı. Raporlar reklam veya izleme için kullanılmaz.
- **Saklama süresi:** Crashlytics çökme raporlarını 90 gün saklar.
- **Kapatma:** Ayarlar → Gizlilik → "Çökme raporlarını gönder". Kapattığınızda yeni rapor gönderilmez
  ve henüz gönderilmemiş raporlar silinir. Varsayılan olarak açıktır.

### Paylaşma ve dışa aktarma
Bir defteri, sayfayı veya görseli dışa aktardığınızda ya da paylaştığınızda hedefi siz seçersiniz
(örneğin başka bir uygulama veya klasör). Verinin orada işlenmesi o hedefin koşullarına tabidir.

### Çocuklar
Uygulama çocuklar dahil kimseden kişisel veri toplamaz. Cihaz dışına gönderilen tek veri, yukarıda
açıklanan anonim çökme raporudur.

### Değişiklikler
İleride veriyi cihaz dışına gönderen bir özellik eklenirse, o sürüm yayınlanmadan önce bu politikayı ve
mağaza sayfasını güncelleriz ve değişikliği sürüm notlarında belirtiriz.

### İletişim
Bu politikayla ilgili sorular: elyanotes2108@gmail.com.
