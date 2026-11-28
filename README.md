<div dir="rtl" lang="fa">

# unbar-server — راه‌اندازی سرور Soar برای Unbar

یک اسکریپت bash تکی و تعاملی که یک سرور Soar کامل راه می‌اندازد:
تانل DNS روی پورت 53 + سرتیفیکیت خودکار + فایل سابسکریپشن روی HTTPS.

فقط Soar. بدون روتر، بدون تانل دیگر، بدون مدیریت کاربر.

ریپو: https://github.com/viahamed/unbar-server

## فهرست

- [قبل از نصب — رکوردهای DNS](#dns-fa)
- [نصب](#install-fa)
- [آموزش گام‌به‌گام](#tutorial-fa)
- [دو حالت سرو فایل sub](#modes-fa)
- [تداخل نداشتن با بقیهٔ سرویس‌ها](#no-interference-fa)
- [خروجی‌ها](#outputs-fa)
- [به‌روز شدن خودکار فایل sub](#auto-regen-fa)
- [به‌روزرسانی](#update-fa)
- [دستورها](#commands-fa)
- [نکته‌ها](#notes-fa)
- [لایسنس / License](#license)

## <a name="dns-fa"></a>قبل از نصب — رکوردهای DNS

فرض: زون تانل `r.example.com` و ساب‌دامنهٔ فایل sub `sub.example.com` است
(اسکریپت هر دو را از تو می‌پرسد؛ این‌ها فقط مثال‌اند):

```
NS  r.example.com    -> ns.example.com
A   ns.example.com   -> <IP سرور>
A   sub.example.com  -> <IP سرور>
```

رکورد A برای ساب‌دامنه فقط وقتی لازم است که فایل sub همین سرور سرو شود
(حالت Caddy)؛ در حالت file فقط دو رکورد اول لازم‌اند. رکورد NS معمولاً
چند دقیقه تا چند ساعت طول می‌کشد تا دیده شود — setup فقط هشدار می‌دهد
و متوقف نمی‌شود.

## <a name="install-fa"></a>نصب

```bash
curl -fsSL https://raw.githubusercontent.com/viahamed/unbar-server/main/install.sh | sudo bash
```

نصب یک‌خطی بالا اسکریپت را می‌گیرد و منوی تعاملی را باز می‌کند؛ بعد از نصب، با تایپ `unbar` هم منو باز می‌شود. یا با git clone:

```bash
git clone https://github.com/viahamed/unbar-server.git
cd unbar-server
sudo bash unbar-server setup
```

`setup` خودش اسکریپت را در `/usr/local/bin/unbar-server` نصب می‌کند و
میان‌بر `unbar` را می‌سازد، پس بعد از آن دستورهای `unbar-server` و
`unbar` همه‌جا در دسترس‌اند — همهٔ دستورهای این راهنما با هر دو کار
می‌کنند. صفحهٔ اول ستاپ بنر «Unbar by Break The Barriers» را نشان
می‌دهد و بعد به‌ترتیب می‌پرسد: زون تانل، **آیا فایل sub همین سرور سرو
شود یا فقط ذخیره شود**، (در حالت Caddy:) ساب‌دامنهٔ فایل sub و **پورت
HTTPS** (پیش‌فرض 443، اگر اشغال باشد 8443 پیشنهاد می‌شود)، نام فایل
سابسکریپشن (پیش‌فرض `sub` — روی `https://<ساب‌دامنه>[:پورت]/<نام>` سرو
می‌شود)، نام نمایشی سرور و ایمیل Let's Encrypt (اختیاری، فقط در حالت
Caddy).

اسکریپت خودش انجام می‌دهد:

1. خودش را در `/usr/local/bin/unbar-server` نصب می‌کند و میان‌بر `unbar`
   را می‌سازد
2. بررسی root و systemd و آزاد بودن پورت 53؛ اگر stub مربوط به
   systemd-resolved آن را گرفته باشد، با تأیید تو خاموشش می‌کند
   (فایل `/etc/systemd/resolved.conf.d/unbar-dns.conf` با DNSهای عمومی 8.8.8.8 و 1.1.1.1، و
   `/etc/resolv.conf` یک بار پشتیبان‌گیری می‌شود و به `/run/systemd/resolve/resolv.conf` اشاره می‌کند
   تا DNS خود سرور کار کند؛ `uninstall` همه را برمی‌گرداند).
   هر DNS دیگری که 53 را گرفته باشد دست نمی‌خورد — setup همان‌جا
   می‌ایستد و اسمش را می‌گوید
3. نصب ابزارهای لازم (curl ،tar) و نصب Go از go.dev (اگر نسخهٔ 1.25+
   نباشد)
4. گرفتن آخرین نسخهٔ Soar از گیت‌هاب رسمی getlantern/soar و ساخت
   `soar-server` از سورس (ریلیز رسمی باینری آماده ندارد)
5. ساخت کلید Ed25519 سرور (خصوصی 600 در `/etc/unbar-server/key`) —
   فقط اگر نباشد؛ اجرای دوبارهٔ setup کلید قبلی را نگه می‌دارد
6. سرویس systemd برای `soar-server` روی `:53` (کاربر جدا، فقط `CAP_NET_BIND_SERVICE`)
7. در حالت Caddy: نصب Caddy از گیت‌هاب رسمی caddyserver/caddy و HTTPS
   خودکار (Let's Encrypt) که فقط فایل `sub` را سرو می‌کند
8. باز کردن پورت‌های لازم (فقط 53 در حالت file؛ 53 و 80 و پورت HTTPS در
   حالت Caddy) در ufw/firewalld اگر فعال باشند؛ وگرنه هشدار می‌دهد که
   خودت بازشان کنی
9. ساخت فایل sub، چاپ لینک‌ها و بررسی DNS (فقط هشدار می‌دهد)

## <a name="tutorial-fa"></a>آموزش گام‌به‌گام

این آموزش از صفر تا اتصال اپ را قدم‌به‌قدم می‌گوید. همهٔ مثال‌ها با
`example.com` هستند؛ آن‌ها را با دامنهٔ خودت عوض کن.

### ۱) پیش‌نیازها

- یک VPS با لینوکس و **systemd** (تقریباً همهٔ VPSها) و دسترسی **root**
  (یا sudo)؛ معماری amd64 ،arm64 یا armv7؛ و **bash 4+**.
- یک دامنه که به DNS آن دسترسی داری.
- این پورت‌ها در security group ابر (AWS و...) باز باشند: `53/udp` و
  `53/tcp`، و در حالت Caddy `80/tcp` و پورت HTTPS (پیش‌فرض 443).
  اسکریپت اگر ufw یا firewalld فعال باشد خودش بازشان می‌کند؛ وگرنه
  هشدار می‌دهد و خودت باید بازشان کنی.
- نیازی به تنظیم پورت‌های مجاز مقصد نیست — سرور Soar به‌صورت پیش‌فرض
  فقط به آدرس‌های عمومی و پورت‌های 80 و 443 وصل می‌شود.

### ۲) ساخت رکوردهای DNS

پیش از setup این رکوردها را در DNS دامنه بساز (زون `r.example.com` و
ساب‌دامنهٔ `sub.example.com` فقط مثال‌اند):

```
NS  r.example.com    -> ns.example.com
A   ns.example.com   -> <IP سرور>
A   sub.example.com  -> <IP سرور>
```

رکورد A برای ساب‌دامنه فقط در حالت Caddy لازم است. هاست `ns` از روی
زون ساخته می‌شود (`r.example.com` ← `ns.example.com`).

### ۳) نصب با یک خط

```bash
curl -fsSL https://raw.githubusercontent.com/viahamed/unbar-server/main/install.sh | sudo bash
```

نصب‌کننده اسکریپت را در `/usr/local/bin/unbar-server` می‌گذارد، میان‌بر
`unbar` را می‌سازد و منوی تعاملی را باز می‌کند.

### ۴) باز کردن منو

```bash
sudo unbar
```

(`sudo unbar-server` یا `sudo unbar-server menu` هم همان منوست.)

```
  1) Setup wizard
  2) Service status
  3) Show links
  4) Regenerate sub file
  5) Settings
  6) New key
  7) Update (script + server)
  8) Logs
  9) Restart services
  10) Uninstall
  0) Quit
```

بعد از هر دستور، با Enter به منو برمی‌گردی؛ با `0` یا Ctrl-C خارج
می‌شوی. اگر setup هنوز اجرا نشده باشد، گزینهٔ Settings هشدار می‌دهد
که اول گزینهٔ 1 را بزن.

### ۵) راه‌اندازی با Setup wizard

گزینهٔ `1` را بزن. ستاپ به‌ترتیب این‌ها را می‌پرسد (مقادیر داخل
`[...]` پیش‌فرض‌اند؛ Enter همان پیش‌فرض را می‌گیرد):

1. **Tunnel zone** — زون تانل، بدون پیش‌فرض: `r.example.com`
   (زون کوتاه‌تر مثل `t.ab.io` جای بیشتری برای داده در هر کوئری می‌گذارد
   و کمی سریع‌تر است.)
2. **Serve the sub file on this server with Caddy? [y]** — با `y`
   (Enter) فایل sub همین سرور با Caddy سرو می‌شود؛ با `n` فقط ذخیره
   می‌شود (حالت file).
3. **Subdomain for the sub file and certificate** (فقط Caddy) — بدون
   پیش‌فرض: `sub.example.com` (نباید با زون یکی باشد یا زیر زون باشد).
4. **HTTPS port for serving the sub file [443]** (فقط Caddy) —
   Enter برای 443؛ اگر 443 اشغال باشد 8443 پیشنهاد می‌شود.
5. **Subscription file name [sub]** — نام فایل سابسکریپشن: Enter
   برای `sub`.
6. **Server display name in the app [Break The Barriers]** — نامی که
   در اپ دیده می‌شود.
7. **Email for Let's Encrypt (optional)** (فقط Caddy) — برای اطلاع
   انقضا؛ Enter برای رد شدن.
8. ستاپ رکوردهای لازم را نشان می‌دهد؛ **I have created the records,
   continue? [y]** — اگر رکوردها را ساخته‌ای `y` بزن.

بعد از آن ستاپ خودش همه‌چیز را انجام می‌دهد و در پایان وضعیت سرویس‌ها
و لینک‌ها را چاپ می‌کند. اجرای دوبارهٔ setup مقادیر قبلی را به‌عنوان
پیش‌فرض نشان می‌دهد و کلید قبلی را نگه می‌دارد.

دو نکتهٔ مهم در همین مرحله:

- اگر پورت 80 اشغال باشد، ستاپ خودکار به حالت file می‌رود (سرتیفیکیت
  نمی‌تواند بگیرد) و هیچ سرویسی را متوقف نمی‌کند.
- اگر پورت 53 دست یک DNS دیگر باشد، ستاپ همان‌جا می‌ایستد و اسمش را
  می‌گوید؛ خودت باید آن سرویس را خاموش کنی یا سرور دیگری بگیری.

### ۶) وارد کردن لینک در اپ Unbar

در پایان setup دو لینک و محتوای JSON چاپ می‌شود:

- **Subscription link:** مثل `https://sub.example.com:443/sub` — آن را در
  اپ، در قسمت Subscription وارد کن.
- **Direct import link (`unbar://...`)** — برای ایمپورت مستقیم در اپ.
- **محتوای JSON سابسکریپشن** — همان JSON که از لینک خوانده می‌شود.

همان محتوا با پسوند `.txt` هم سرو می‌شود
(`https://sub.example.com:443/sub.txt`) ولی چاپ نمی‌شود — لینک بدون پسوند
کافی است. اگر سرتیفیکیت هنوز صادر نشده (DNS تازه ساخته شده)، چند دقیقه
صبر کن و با `status` دوباره چک کن. در حالت file لینکی روی این سرور
نیست؛ فایل را خودت روی یک هاست HTTPS می‌گذاری و همان لینک را در اپ
وارد می‌کنی.

### ۷) کارهای روزمره

همهٔ این‌ها هم از منو و هم با دستور مستقیم انجام می‌شوند:

| کار | منو | دستور مستقیم |
| --- | --- | --- |
| وضعیت سرویس‌ها و در دسترس بودن sub | 2 | `sudo unbar-server status` |
| نمایش دوبارهٔ لینک‌ها | 3 | `sudo unbar-server show` |
| بازسازی فایل sub | 4 | `sudo unbar-server regen` |
| تغییر یک تنظیم | 5 | `sudo unbar-server set <key> <value>` |
| کلید جدید | 6 | `sudo unbar-server rotate-key` |
| به‌روزرسانی کامل (اسکریپت + سرور) | 7 | `sudo unbar-server update` |
| لاگ | 8 | `sudo unbar-server logs [soar\|caddy]` |
| ری‌استارت سرویس‌ها | 9 | `sudo unbar-server restart` |
| حذف کامل | 10 | `sudo unbar-server uninstall` |

چند نکته:

- `set` این کلیدها را می‌گیرد: `name` (نام نمایشی)، `zone` (زون)،
  `sub` (ساب‌دامنه)، `email` (ایمیل Let's Encrypt)، `file` (نام فایل
  سابسکریپشن)، `https-port` (پورت HTTPS، فقط حالت Caddy). مثال:
  `sudo unbar-server set name "My Server"`.
- هر تغییری در پایان فایل sub را از نو می‌سازد؛ اپ با یک رفرش
  سابسکریپشن نسخهٔ جدید را می‌گیرد.
- تغییر `zone` رکورد NS جدید و تغییر `sub` رکورد A جدید می‌خواهد؛
  اسکریپت خودش هشدار می‌دهد.
- `rotate-key` همهٔ کانفیگ‌های قبلی را باطل می‌کند و اول تأیید
  می‌خواهد؛ فقط وقتی لازم است بزن.
- `logs` پیش‌فرض `soar` است و آخرین ۱۰۰ خط را نشان می‌دهد.

### ۸) عیب‌یابی

- **«If the certificate has not been issued yet (DNS just created)...»**
  — چند دقیقه صبر کن و `status` را دوباره بزن.
- **«NS record ... is not visible yet» / «A record ... is not visible
  yet»** — انتشار DNS طول می‌کشد؛ صبر کن و `status` را دوباره بزن.
  تانل تا وقتی NS دیده نشود کار نمی‌کند.
- **«No active firewall found; open these ports yourself»** — پورت‌ها
  را در کنسول ابر (security group) باز کن؛ فایروال داخل سرور کافی نیست.
- **«File ... is not served even on this server»** — لاگ Caddy را
  ببین: `sudo unbar-server logs caddy`.
- **«File ... did not open from the internet»** — اگر روی خود سرور
  سالم سرو می‌شود، DNS هنوز منتشر نشده؛ از گوشی یا مرورگر چک کن.
- **پورت 53 اشغال است** — اگر دست systemd-resolved باشد ستاپ با تأیید
  تو stub را خاموش می‌کند؛ اگر دست DNS دیگری باشد، ستاپ می‌ایستد و
  اسمش را می‌گوید.
- **«Link not built yet; run 'unbar-server regen'»** — با
  `sudo unbar-server regen` فایل را بساز.

### ۹) حذف کامل

منوی `10` یا:

```bash
sudo unbar-server uninstall
```

با تأیید تو همه‌چیز حذف می‌شود (سرویس‌ها، تنظیمات، کلید سرور، فایل
sub و میان‌بر `unbar`)؛ تنظیمات و کلید اول در
`/root/unbar-server-backup-<زمان>.tar.gz` پشتیبان گرفته می‌شوند.
باینری‌های Caddy و Go دست نمی‌خورند؛ اگر نمی‌خواهی‌شان خودت حذفشان کن.

## <a name="modes-fa"></a>دو حالت سرو فایل sub

لینک سابسکریپشن فقط یک فراخوان سادهٔ HTTPS است — یک فایل JSON ثابت که
اپ با یک GET می‌گیرد. پس سرو کردنش روی همین سرور اختیاری است:

- **Caddy (پیش‌فرض):** همین سرور با Caddy فایل را روی HTTPS سرو
  می‌کند. پورت HTTPS را خودت انتخاب می‌کنی (پیش‌فرض 443؛ اگر 443 اشغال
  باشد — مثلاً اینباند VLESS یک پنل دیگر — 8443 پیشنهاد می‌شود و لینک
  می‌شود `https://sub.example.com:8443/sub`). سرتیفیکیت با پورت 80
  گرفته می‌شود؛ اگر 80 هم اشغال باشد، setup خودکار به حالت file می‌رود.
- **file:** هیچ وب‌سروری نصب نمی‌شود و هیچ پورتی جز 53 لازم نیست.
  فایل در `/var/www/unbar-sub/<نام>` ذخیره می‌شود؛ خودت آن را روی هر
  هاست HTTPS دیگری می‌گذاری (مثلاً همان‌جایی که سایتت هست) و همان لینک
  را داخل اپ وارد می‌کنی. تغییر حالت فقط با اجرای دوبارهٔ `setup`
  انجام می‌شود.

## <a name="no-interference-fa"></a>تداخل نداشتن با بقیهٔ سرویس‌ها

اسکریپت طوری طراحی شده که کنار بقیهٔ سرویس‌های سرور بنشیند بدون اینکه
به آن‌ها دست بزند — **هیچ سرویسی را متوقف یا غیرفعال نمی‌کند:**

- **تانل فقط پورت 53 می‌خواهد** (`53/udp` و `53/tcp`). پورت 80 فقط
  برای گرفتن سرتیفیکیت لازم است و پورت HTTPS (پیش‌فرض 443) فقط برای
  سرو فایل sub — و هر دو فقط در حالت Caddy. در حالت file هیچ‌کدام
  لازم نیستند. اگر پورتی اشغال باشد (مثلاً 443 دست اینباند VLESS یک
  پنل دیگر باشد)، اسکریپت همان‌جا اسمش را می‌گوید و تو پورت دیگری
  انتخاب می‌کنی یا حالت file را می‌گیری؛ به سرویسِ مزاحم دست نمی‌زند.
- **کاربر و دایرکتوری جدا:** سرویس‌ها با کاربرهای سیستمی جدا (`unbar` و
  `caddy`) اجرا می‌شوند و فایل‌هایشان در `/etc/unbar-server`،
  `/var/www/unbar-sub` و `/var/lib/unbar-caddy` است — نه در مسیرهای
  سیستمی Caddy (`/etc/caddy`)، پس با یک Caddy یا وب‌سرور دیگر تداخل
  نمی‌کند.
- **Go و Caddy موجود دست نمی‌خورند:** اگر Go قدیمی در `/usr/local/go`
  باشد، نسخهٔ تازه در `/usr/local/unbar-go` نصب می‌شود؛ اگر Caddy نسخهٔ
  1 باشد، نسخهٔ 2 جدا با نام `unbar-caddy` نصب می‌شود؛ اگر Caddy نسخهٔ
  2 موجود باشد، از همان استفاده می‌شود.

## <a name="outputs-fa"></a>خروجی‌ها

- **سابسکریپشن:** `https://sub.example.com/sub` — یک آرایهٔ JSON با یک آبجکت
  `{"v":1,"name":...,"zone":"r.example.com","pubkey":"...","resolverMode":"DISCOVERY","resolvers":[],"country":"IR"}`
  که دقیقاً همان فرمتی است که Unbar (اندروید و iOS) می‌خواند. داخل اپ در
  قسمت Subscription وارد می‌شود. همان محتوا با پسوند txt هم سرو می‌شود:
  `https://sub.example.com/sub.txt` (برای مرورگرها/کلاینت‌هایی که با فایل
  بدون پسوند راحت نیستند) ولی چاپ نمی‌شود. اگر پورت HTTPS غیر از 443 باشد، پورت در لینک
  می‌آید (`https://sub.example.com:8443/sub` — اپ پورت را قبول می‌کند).
  در حالت file لینکی روی این سرور نیست؛ فایل را خودت هاست می‌کنی. نام
  فایل در `setup` انتخاب می‌شود (پیش‌فرض `sub`) و بعداً با
  `unbar-server set file <نام>` عوض می‌شود؛ فایل‌های قدیمی خودکار پاک
  می‌شوند.
- **لینک مستقیم:** `unbar://<base64url-json>` — برای ایمپورت مستقیم در اپ
  (همان JSON، به‌صورت base64url بدون padding).

## <a name="auto-regen-fa"></a>به‌روز شدن خودکار فایل sub

تنظیمات فقط در `/etc/unbar-server/settings` زندگی می‌کنند. هر دستوری که
تنظیمی را عوض کند (`set` ،`rotate-key` ،`update` ،`setup`) در پایان
`regen` را صدا می‌زند و فایل `sub` را از نو می‌سازد؛ Caddy هم همان فایل
را سرو می‌کند (بدون کش، `Cache-Control: no-store`)، پس اپ با یک رفرش
سابسکریپشن نسخهٔ جدید را می‌گیرد. اگر تنظیمات را دستی عوض کردی:

```bash
sudo unbar-server regen
```

## <a name="update-fa"></a>به‌روزرسانی

از نسخهٔ 2 اسکریپت، فقط با گزینهٔ **7** منو (یا `sudo unbar-server update`)
همهٔ تغییرات جدید روی سرور اعمال می‌شود:

1. آخرین نسخهٔ خود اسکریپت از GitHub گرفته و جایگزین می‌شود.
2. نسخهٔ جدید همه‌چیز را با تعریف خودش هماهنگ می‌کند: soar-server به آخرین
   نسخه، تیونینگ سیستم، سرویس‌های systemd و فایل sub. فقط سرویسی که
   واقعاً عوض شده ری‌استارت می‌شود.

تنظیمات و کلید سرور دست نمی‌خورند و لینک‌ها عوض نمی‌شوند.

**سرورهایی که با نسخهٔ 1 نصب شده‌اند** یک بار باید خط نصب را دوباره بزنند
(تنظیمات و کلید حفظ می‌شوند)، بعد از منو گزینهٔ 7 را بزنند:

```bash
curl -fsSL https://raw.githubusercontent.com/viahamed/unbar-server/main/install.sh | sudo bash
```

از آن به بعد همان گزینهٔ 7 کافی است.

**تیونینگ سیستم (از نسخهٔ 2):** بافرهای UDP کرنل بزرگ‌تر می‌شوند تا
وقتی کوئری‌های زیادی هم‌زمان از ریزالورها می‌رسند، کرنل بی‌صدا دورشان
نریزد (کاربر این را به‌شکل افت سرعت می‌بیند). تنظیمات در فایل جداگانهٔ
`/etc/sysctl.d/99-unbar-server.conf` نوشته می‌شوند و بعد از ری‌بوت هم
می‌مانند؛ اگر کرنل BBR داشته باشد، BBR هم برای مسیر سرور تا سایت‌ها فعال
می‌شود. سقف فایل‌های باز سرویس soar هم بالا می‌رود. روی بعضی VPSهای
کانتینری (OpenVZ/LXC) بعضی از این کلیدها مجاز نیستند؛ اسکریپت فقط هشدار
می‌دهد و ادامه می‌دهد. با `uninstall` این فایل هم حذف می‌شود.

## <a name="commands-fa"></a>دستورها

همهٔ دستورها با `unbar` و `unbar-server` هر دو کار می‌کنند:

```
sudo unbar-server                              # منوی تعاملی (بدون آرگومان؛ یا: sudo unbar-server menu)
sudo unbar-server setup                        # نصب تعاملی (بار اول)
sudo unbar-server status                       # وضعیت سرویس‌ها + در دسترس بودن sub
sudo unbar-server show                         # لینک sub، لینک unbar:// و JSON سابسکریپشن
sudo unbar-server regen                        # بازسازی فایل sub
sudo unbar-server set name "نام جدید"          # تغییر نام نمایشی
sudo unbar-server set zone r2.example.com      # تغییر زون (رکورد NS جدید هم لازم است)
sudo unbar-server set sub sub2.example.com     # تغییر ساب‌دامنه (رکورد A جدید هم لازم است)
sudo unbar-server set email admin@example.com  # تغییر ایمیل Let's Encrypt
sudo unbar-server set file subscription        # تغییر نام فایل سابسکریپشن
sudo unbar-server set https-port 8443         # تغییر پورت HTTPS سرو فایل sub (فقط حالت Caddy)
sudo unbar-server rotate-key                   # کلید جدید (کانفیگ‌های قبلی باطل می‌شوند!)
sudo unbar-server update                       # به‌روزرسانی کامل: اسکریپت، soar-server، تیونینگ و سرویس‌ها
sudo unbar-server logs [N]                     # N خط آخر لاگ هر دو سرویس (پیش‌فرض 20)
sudo unbar-server logs [soar|caddy] [N]        # لاگ یک سرویس (پیش‌فرض 100 خط)
sudo unbar-server restart
sudo unbar-server uninstall                    # حذف کامل (پشتیبان در /root ذخیره می‌شود)
sudo unbar-server help                         # راهنما
```

### <a name="subcommands-fa"></a>دستورهای غیرتعاملی (برای اتوماسیون و بات)

این دستورها هیچ سؤالی نمی‌پرسند و اگر کاری انجام نشود با کد خروج غیرصفر
تمام می‌شوند. منوی تعاملی و رفتار بدون آرگومان دست نخورده است.
[بات تلگرام Unbar-Server](https://t.me/UnbarServerBot) هم برای «مدیریت سرور» از همین‌ها استفاده می‌کند.

```
sudo unbar-server status --json        # یک JSON: فعال بودن سرویس‌ها، نسخهٔ اسکریپت و soar-server، زون، ساب‌دامنه، پورت HTTPS، حالت سرو، نام فایل sub، نام
sudo unbar-server links                # فقط لینک sub و لینک unbar:// (همان قالب show)
sudo unbar-server regen-sub            # همان regen
sudo unbar-server set https-port 8443  # بررسی آزاد بودن پورت (53 و 80 ممنوع)، باز کردن فایروال، بازسازی sub
sudo unbar-server set name "نام جدید"  # یک خط، حداکثر 64 نویسه
sudo unbar-server set zone t2.example.com  # ساب‌دامنهٔ sub نباید با زون یکی یا زیر آن باشد؛ ns.<والد> هم به‌روز می‌شود و رکوردهای NS/A لازم چاپ می‌شوند
sudo unbar-server set sub sub2.example.com # نباید با زون یکی یا زیر آن باشد؛ Caddy گواهی دامنهٔ تازه را خودکار می‌گیرد
sudo unbar-server set file feed        # در حالت فایل به Caddy دست نمی‌زند؛ فایل‌های قدیمی پاک می‌شوند
sudo unbar-server update               # همان گزینهٔ 7 منو؛ اگر بعدش سرویسی فعال نباشد کد خروج غیرصفر
sudo unbar-server restart
sudo unbar-server logs 20              # 20 خط آخر لاگ unbar-soar و unbar-caddy
sudo unbar-server uninstall --yes      # حذف کامل بدون پرسیدن تأیید
unbar-server version                   # «unbar-server <نسخه> (api <n>)»
```

## <a name="notes-fa"></a>نکته‌ها

- نیازمند لینوکس با **systemd** است (تقریباً همهٔ VPSها) و **bash 4+**.
  روی لینوکس‌های قدیمی و جدید با systemd کار می‌کند (Debian 7+،
  Ubuntu 14.04+، RHEL/CentOS 7+، Fedora، Arch، openSUSE). روی systemd
  قدیمی‌تر از 229 سرویس‌ها با کاربر root اجرا می‌شوند (چون
  AmbientCapabilities ندارد). اگر `ss` نباشد از `netstat` استفاده
  می‌کند و اگر `curl` قدیمی باشد (`--resolve` ندارد) تست محلی سرو فایل
  رد می‌شود.
- بقیهٔ ابزارها (Go و Caddy) به‌صورت باینری رسمی دانلود می‌شوند، پس وابسته به نسخهٔ
  توزیع نیست.
- معماری‌های پشتیبانی‌شده: amd64 ،arm64 ،armv7.
- سرور Soar به‌صورت پیش‌فرض فقط به آدرس‌های عمومی و پورت‌های 80 و 443
  وصل می‌شود (همان پیش‌فرض خود Soar).
- `rotate-key` همهٔ کانفیگ‌های قبلی را باطل می‌کند؛ فقط وقتی لازم است بزن.
- فایل `sub` فقط یک سرور دارد؛ اگر روزی خواستی چند سرور در یک فایل باشد،
  همان JSON را می‌شود به آرایه‌ای با چند آبجکت تبدیل کرد.

</div>

# unbar-server — Set up a Soar server for Unbar

A single interactive bash script that sets up a complete Soar server:
a DNS tunnel on port 53 + automatic certificates + a subscription file over HTTPS.

Only Soar. No router, no other tunnel, no user management.

Repo: https://github.com/viahamed/unbar-server

## Contents

- [Before installing — DNS records](#dns)
- [Installation](#install)
- [Step-by-step tutorial](#tutorial)
- [The two sub-file serving modes](#modes)
- [No interference with other services](#no-interference)
- [Outputs](#outputs)
- [Automatic sub-file regeneration](#auto-regen)
- [Updating](#update)
- [Commands](#commands)
- [Notes](#notes)
- [License](#license)

## <a name="dns"></a>Before installing — DNS records

Assume the tunnel zone is `r.example.com` and the sub-file subdomain is
`sub.example.com` (the script asks you for both; these are just examples):

```
NS  r.example.com    -> ns.example.com
A   ns.example.com   -> <server IP>
A   sub.example.com  -> <server IP>
```

The A record for the subdomain is only needed when this same server serves
the sub file (Caddy mode); in file mode only the first two records are needed.
The NS record usually takes a few minutes to a few hours to become visible —
setup only warns and does not stop.

## <a name="install"></a>Installation

```bash
curl -fsSL https://raw.githubusercontent.com/viahamed/unbar-server/main/install.sh | sudo bash
```

The one-liner above downloads the script and opens the interactive menu; after install, typing `unbar` opens the menu too. Or with git clone:

```bash
git clone https://github.com/viahamed/unbar-server.git
cd unbar-server
sudo bash unbar-server setup
```

`setup` installs the script itself at `/usr/local/bin/unbar-server` and
creates the `unbar` shortcut, so afterwards the `unbar-server` and `unbar`
commands are available everywhere — every command in this guide works with
either one. The first setup screen shows the "Unbar by Break The Barriers"
banner, then asks in order: the tunnel zone, **whether the sub file should
be served by this server or only saved**, (in Caddy mode:) the sub-file
subdomain and the **HTTPS port** (default 443, 8443 suggested if occupied),
the subscription file name (default `sub` — served at
`https://<subdomain>[:port]/<name>`), the server display name and the Let's
Encrypt email (optional, Caddy mode only).

What the script does itself:

1. Installs itself at `/usr/local/bin/unbar-server` and creates the `unbar`
   shortcut
2. Checks root and systemd and that port 53 is free; if the systemd-resolved
   stub holds it, it disables it with your confirmation (it writes
   `/etc/systemd/resolved.conf.d/unbar-dns.conf` with public DNS 8.8.8.8 and 1.1.1.1, backs up
   `/etc/resolv.conf` once and points it to `/run/systemd/resolve/resolv.conf` so the server itself
   keeps resolving; `uninstall` restores all of it). Any other DNS
   holding port 53 is left untouched — setup stops there and tells you its name
3. Installs the required tools (curl, tar) and Go from go.dev (if version
   1.25+ is not present)
4. Fetches the latest Soar from the official getlantern/soar GitHub and builds
   `soar-server` from source (the official release has no ready-made binary)
5. Creates the server Ed25519 key (private, 600, at `/etc/unbar-server/key`) —
   only if there is none; running setup again keeps the previous key
6. A systemd service for `soar-server` on `:53` (separate user, only `CAP_NET_BIND_SERVICE`)
7. In Caddy mode: installs Caddy from the official caddyserver/caddy GitHub
   and automatic HTTPS (Let's Encrypt) that serves only the `sub` file
8. Opens the required ports (only 53 in file mode; 53, 80 and the HTTPS port
   in Caddy mode) in ufw/firewalld if active; otherwise it warns you to open
   them yourself
9. Creates the sub file, prints the links and checks DNS (warns only)

## <a name="tutorial"></a>Step-by-step tutorial

This tutorial takes you from zero to a connected app, step by step. All
examples use `example.com`; replace them with your own domain.

### 1) Prerequisites

- A VPS with Linux and **systemd** (almost all VPSs) and **root** access
  (or sudo); architecture amd64, arm64 or armv7; and **bash 4+**.
- A domain whose DNS you control.
- These ports open in the cloud security group (AWS etc.): `53/udp` and
  `53/tcp`, and in Caddy mode `80/tcp` and the HTTPS port (default 443).
  The script opens them in ufw or firewalld if active; otherwise it warns
  and you open them yourself.
- No allowed-destination-ports setting is needed — the Soar server by
  default only connects to public addresses and ports 80 and 443.

### 2) Create the DNS records

Before setup, create these records in your domain's DNS (zone
`r.example.com` and subdomain `sub.example.com` are just examples):

```
NS  r.example.com    -> ns.example.com
A   ns.example.com   -> <server IP>
A   sub.example.com  -> <server IP>
```

The A record for the subdomain is only needed in Caddy mode. The `ns`
host is derived from the zone (`r.example.com` → `ns.example.com`).

### 3) Install with one line

```bash
curl -fsSL https://raw.githubusercontent.com/viahamed/unbar-server/main/install.sh | sudo bash
```

The installer puts the script at `/usr/local/bin/unbar-server`, creates
the `unbar` shortcut and opens the interactive menu.

### 4) Open the menu

```bash
sudo unbar
```

(`sudo unbar-server` or `sudo unbar-server menu` opens the same menu.)

```
  1) Setup wizard
  2) Service status
  3) Show links
  4) Regenerate sub file
  5) Settings
  6) New key
  7) Update (script + server)
  8) Logs
  9) Restart services
  10) Uninstall
  0) Quit
```

After each command, press Enter to return to the menu; `0` or Ctrl-C
quits. If setup has not run yet, the Settings option warns you to pick
option 1 first.

### 5) Run the Setup wizard

Press `1`. Setup asks, in order (values in `[...]` are defaults; Enter
takes the default):

1. **Tunnel zone** — the tunnel zone, no default: `r.example.com`
   (A shorter zone such as `t.ab.io` leaves more room for data in each
   query and is slightly faster.)
2. **Serve the sub file on this server with Caddy? [y]** — `y` (Enter)
   serves the sub file from this server with Caddy; `n` only saves it
   (file mode).
3. **Subdomain for the sub file and certificate** (Caddy only) — no
   default: `sub.example.com` (it must not equal the zone or be under it).
4. **HTTPS port for serving the sub file [443]** (Caddy only) — Enter
   for 443; if 443 is occupied, 8443 is suggested.
5. **Subscription file name [sub]** — the subscription file name: Enter
   for `sub`.
6. **Server display name in the app [Break The Barriers]** — the name
   shown in the app.
7. **Email for Let's Encrypt (optional)** (Caddy only) — for expiry
   notices; Enter to skip.
8. Setup shows the required records; **I have created the records,
   continue? [y]** — press `y` if you created them.

After that setup does everything itself and prints the service status and
the links at the end. Running setup again shows the previous values as
defaults and keeps the previous key.

Two things to know at this step:

- If port 80 is occupied, setup automatically falls back to file mode
  (it cannot get a certificate) and stops no service.
- If port 53 is held by another DNS service, setup stops right there and
  tells you its name; you stop that service yourself or use another server.

### 6) Enter the link in the Unbar app

Setup prints two links and the subscription JSON at the end:

- **Subscription link:** e.g. `https://sub.example.com:443/sub` — enter it in
  the app, under Subscription.
- **Direct import link (`unbar://...`)** — for direct import into the app.
- **Subscription JSON** — the JSON served at the link (what the app reads).

The same content is also served with a `.txt` suffix
(`https://sub.example.com:443/sub.txt`) but is not printed — the
extensionless link is enough. If the certificate has not been issued yet
(DNS just created), wait a few minutes and check status again. In file
mode there is no link on this server; you put the file on an HTTPS host
yourself and enter that link in the app.

### 7) Day-to-day use

All of these work from the menu and as direct commands:

| Task | Menu | Direct command |
| --- | --- | --- |
| Service status and sub availability | 2 | `sudo unbar-server status` |
| Show the links again | 3 | `sudo unbar-server show` |
| Rebuild the sub file | 4 | `sudo unbar-server regen` |
| Change a setting | 5 | `sudo unbar-server set <key> <value>` |
| New key | 6 | `sudo unbar-server rotate-key` |
| Full update (script + server) | 7 | `sudo unbar-server update` |
| Logs | 8 | `sudo unbar-server logs [soar\|caddy]` |
| Restart services | 9 | `sudo unbar-server restart` |
| Complete removal | 10 | `sudo unbar-server uninstall` |

A few notes:

- `set` takes these keys: `name` (display name), `zone` (zone), `sub`
  (subdomain), `email` (Let's Encrypt email), `file` (subscription file
  name), `https-port` (HTTPS port, Caddy mode only). Example:
  `sudo unbar-server set name "My Server"`.
- Every change rebuilds the sub file at the end; the app picks up the new
  version with a subscription refresh.
- Changing `zone` needs a new NS record and changing `sub` needs a new A
  record; the script warns you itself.
- `rotate-key` invalidates all previous configs and asks for confirmation
  first; use it only when needed.
- `logs` defaults to `soar` and shows the last 100 lines.

### 8) Troubleshooting

- **"If the certificate has not been issued yet (DNS just created)..."**
  — wait a few minutes and run `status` again.
- **"NS record ... is not visible yet" / "A record ... is not visible
  yet"** — DNS propagation takes time; wait and run `status` again.
  The tunnel does not work until the NS record is visible.
- **"No active firewall found; open these ports yourself"** — open the
  ports in the cloud console (security group); the in-server firewall is
  not enough.
- **"File ... is not served even on this server"** — see the Caddy log:
  `sudo unbar-server logs caddy`.
- **"File ... did not open from the internet"** — if it is served fine on
  the server itself, public DNS has not propagated yet; check from a phone
  or browser.
- **Port 53 is occupied** — if it is systemd-resolved, setup disables the
  stub with your confirmation; if it is another DNS service, setup stops
  and tells you its name.
- **"Link not built yet; run 'unbar-server regen'"** — rebuild the file
  with `sudo unbar-server regen`.

### 9) Complete removal

Menu `10`, or:

```bash
sudo unbar-server uninstall
```

With your confirmation everything is removed (services, settings, server
key, sub file and the `unbar` shortcut); settings and key are first backed
up to `/root/unbar-server-backup-<time>.tar.gz`. The Caddy and Go binaries
are untouched; remove them by hand if you do not want them.

## <a name="modes"></a>The two sub-file serving modes

The subscription link is just a simple HTTPS call — a static JSON file the
app fetches with one GET. So serving it on this same server is optional:

- **Caddy (default):** this server serves the file over HTTPS with Caddy.
  You choose the HTTPS port yourself (default 443; if 443 is occupied —
  e.g. by another panel's VLESS inbound — 8443 is suggested and the link
  becomes `https://sub.example.com:8443/sub`). The certificate is obtained
  over port 80; if 80 is also occupied, setup automatically falls back to
  file mode.
- **file:** no web server is installed and no port other than 53 is needed.
  The file is saved at `/var/www/unbar-sub/<name>`; you put it on any other
  HTTPS host yourself (e.g. where your site is) and enter that link in the
  app. The mode can only be changed by running `setup` again.

## <a name="no-interference"></a>No interference with other services

The script is designed to sit alongside the server's other services without
touching them — **it stops or disables no service:**

- **The tunnel only needs port 53** (`53/udp` and `53/tcp`). Port 80 is
  only needed to obtain the certificate, and the HTTPS port (default 443)
  only to serve the sub file — and both only in Caddy mode. In file mode
  neither is needed. If a port is occupied (e.g. 443 is held by another
  panel's VLESS inbound), the script tells you its name right there and you
  choose another port or take file mode; it does not touch the offending
  service.
- **Separate user and directories:** the services run as separate system
  users (`unbar` and `caddy`) and their files are in `/etc/unbar-server`,
  `/var/www/unbar-sub` and `/var/lib/unbar-caddy` — not in Caddy's system
  paths (`/etc/caddy`), so they do not conflict with another Caddy or web
  server.
- **Existing Go and Caddy are left untouched:** if an old Go is in
  `/usr/local/go`, the fresh one is installed in `/usr/local/unbar-go`;
  if Caddy version 1 exists, version 2 is installed separately as
  `unbar-caddy`; if Caddy version 2 already exists, that one is used.

## <a name="outputs"></a>Outputs

- **Subscription:** `https://sub.example.com/sub` — a JSON array with one object
  `{"v":1,"name":...,"zone":"r.example.com","pubkey":"...","resolverMode":"DISCOVERY","resolvers":[],"country":"IR"}`
  in exactly the format Unbar (Android and iOS) reads. It is entered in the
  app under Subscription. The same content is also served with a txt suffix:
  `https://sub.example.com/sub.txt` (for browsers/clients that are
  uncomfortable with extensionless files) but is not printed. If the HTTPS port is not 443, the
  port appears in the link (`https://sub.example.com:8443/sub` — the app
  accepts the port). In file mode there is no link on this server; you host
  the file yourself. The file name is chosen in `setup` (default `sub`) and
  later changed with `unbar-server set file <name>`; old files are deleted
  automatically.
- **Direct link:** `unbar://<base64url-json>` — for direct import in the app
  (the same JSON, base64url without padding).

## <a name="auto-regen"></a>Automatic sub-file regeneration

Settings live only in `/etc/unbar-server/settings`. Every command that
changes a setting (`set`, `rotate-key`, `update`, `setup`) calls `regen` at
the end and rebuilds the `sub` file; Caddy serves that same file (no cache,
`Cache-Control: no-store`), so the app picks up the new version with a
subscription refresh. If you changed the settings by hand:

```bash
sudo unbar-server regen
```

## <a name="update"></a>Updating

From script version 2, option **7** in the menu (or `sudo unbar-server update`)
applies every new change to the server:

1. The newest version of this script is fetched from GitHub and replaces the old one.
2. The new version brings everything in line with what it defines: soar-server
   at its latest version, system tuning, the systemd services and the sub file.
   Only a service that actually changed is restarted.

Settings and the server key are not touched, and the links stay the same.

**Servers installed with version 1** need to run the install line once more
(settings and key are kept), then option 7 from the menu:

```bash
curl -fsSL https://raw.githubusercontent.com/viahamed/unbar-server/main/install.sh | sudo bash
```

After that, option 7 is all you need.

**System tuning (from version 2):** the kernel's UDP buffers are enlarged so
that bursts of queries arriving from many resolvers at once are not silently
dropped by the kernel (users would see that as lower speed). The settings go
in their own file, `/etc/sysctl.d/99-unbar-server.conf`, and survive reboots;
if the kernel has BBR, BBR is also enabled for the server-to-website leg. The
soar service's open-file limit is raised too. Some container VPSes
(OpenVZ/LXC) do not allow some of these keys; the script only warns and
carries on. `uninstall` removes this file as well.

## <a name="commands"></a>Commands

All commands work with both `unbar` and `unbar-server`:

```
sudo unbar-server                              # interactive menu (no arguments; or: sudo unbar-server menu)
sudo unbar-server setup                        # interactive install (first time)
sudo unbar-server status                       # service status + sub availability
sudo unbar-server show                         # sub link, unbar:// link, and subscription JSON
sudo unbar-server regen                        # rebuild the sub file
sudo unbar-server set name "new name"          # change the display name
sudo unbar-server set zone r2.example.com      # change the zone (a new NS record is needed too)
sudo unbar-server set sub sub2.example.com     # change the subdomain (a new A record is needed too)
sudo unbar-server set email admin@example.com  # change the Let's Encrypt email
sudo unbar-server set file subscription        # change the subscription file name
sudo unbar-server set https-port 8443         # change the HTTPS port serving the sub file (Caddy mode only)
sudo unbar-server rotate-key                   # new key (previous configs are invalidated!)
sudo unbar-server update                       # full update: script, soar-server, tuning and services
sudo unbar-server logs [N]                     # last N log lines of both services (default 20)
sudo unbar-server logs [soar|caddy] [N]        # one service's logs (default 100 lines)
sudo unbar-server restart
sudo unbar-server uninstall                    # complete removal (backup saved in /root)
sudo unbar-server help                         # help
```

### <a name="subcommands"></a>Non-interactive subcommands (for automation and the bot)

These never prompt and exit non-zero when they fail. The interactive menu
and the no-argument behaviour are unchanged. The
[Unbar-Server Telegram bot](https://t.me/UnbarServerBot) uses them for "Manage server".

```
sudo unbar-server status --json        # one JSON object: services active?, script and soar-server versions, zone, subdomain, HTTPS port, serve mode, sub file name, name
sudo unbar-server links                # only the sub link and the unbar:// link (same layout as show)
sudo unbar-server regen-sub            # same as regen
sudo unbar-server set https-port 8443  # checks the port is free (53 and 80 refused), opens the firewall, rebuilds the sub
sudo unbar-server set name "new name"  # one line, at most 64 characters
sudo unbar-server set zone t2.example.com  # the sub subdomain must not equal or be under it; also updates ns.<parent> and prints the NS/A records needed
sudo unbar-server set sub sub2.example.com # must not equal or be under the zone; Caddy fetches the new domain's certificate itself
sudo unbar-server set file feed        # leaves Caddy alone in file mode; old files are removed
sudo unbar-server update               # same as menu 7; non-zero exit if a service is down afterwards
sudo unbar-server restart
sudo unbar-server logs 20              # last 20 lines of unbar-soar and unbar-caddy
sudo unbar-server uninstall --yes      # complete removal without the confirmation prompt
unbar-server version                   # "unbar-server <version> (api <n>)"
```

## <a name="notes"></a>Notes

- Requires Linux with **systemd** (almost all VPSs) and **bash 4+**.
  Works on old and new Linuxes with systemd (Debian 7+, Ubuntu 14.04+,
  RHEL/CentOS 7+, Fedora, Arch, openSUSE). On systemd older than 229 the
  services run as the root user (because it has no AmbientCapabilities).
  If `ss` is missing it uses `netstat`, and if `curl` is old (no `--resolve`)
  the local file-serving test is skipped.
- The other tools (Go and Caddy) are downloaded as official binaries, so they
  don't depend on the distro version.
- Supported architectures: amd64, arm64, armv7.
- The Soar server by default only connects to public addresses and ports 80
  and 443 (Soar's own default).
- `rotate-key` invalidates all previous configs; use it only when needed.
- The `sub` file holds only one server; if one day you want several servers
  in one file, the same JSON can be turned into an array with several objects.

## <a name="license"></a>لایسنس / License

این ریپو تحت «Unbar Source-Available License 1.0» است — همان لایسنسی که Unbar دارد.
کد منبع فقط برای مشاهده است؛ استفاده، کپی، تغییر، انتشار یا فروش آن ممنوع است،
مگر برای ارسال مشارکت به همین پروژه. نام‌ها و لوگوی «Unbar» و «Break The Barriers»
علامت تجاری‌اند. متن کامل در فایل [LICENSE](LICENSE).

This repo is under the "Unbar Source-Available License 1.0" — the same license as Unbar.
The source code is view-only; using, copying, modifying, publishing or selling it is
not allowed, except to submit a contribution to this project. The "Unbar" and
"Break The Barriers" names and logos are trademarks. Full text in [LICENSE](LICENSE).
