# TÜRK DİSCORD

Türkçe, mobil uyumlu ve animasyonlu topluluk sohbeti. GitHub Pages arayüzü sunar; gerçek kullanıcı ve ortak veriler Supabase projesinde çalışır.

## Etkin özellikler

- Supabase Auth ile e-posta/şifre hesabı ve kalıcı oturum
- Sunucu ve metin kanalı oluşturma
- Arkadaşlık isteği gönderme ve kabul etme; arkadaşını sunucuya ekleme
- Supabase Realtime ile üyeler arasında ortak canlı mesajlaşma
- Sunucu üyelerine özel dosya paylaşımı (dosya başına 15 MB)
- WebRTC mikrofon görüşmesi (tarayıcı mikrofon izni gerekir)

## Supabase'i bağlama

1. Supabase'de yeni bir proje oluşturun. Project URL ve anon/publishable key değerlerini Project Settings → API bölümünden alın.
2. `config.js` içindeki `SUPABASE_PROJECT_URL` ve `SUPABASE_ANON_OR_PUBLISHABLE_KEY` değerlerini kendi bilgilerinizle değiştirin. Yalnızca anon/publishable key kullanın; `service_role` key'i asla siteye koymayın.
3. Supabase Dashboard → SQL Editor'da `schema.sql` dosyasının tamamını çalıştırın. Bu, tabloları, RLS erişim kurallarını, dosya bucket'ını ve Realtime mesaj yayınını hazırlar.
4. Supabase Authentication → URL Configuration'da Site URL ve Redirect URLs değerlerine GitHub Pages adresinizi ekleyin (ör. `https://KULLANICI.github.io/DEPO/`). E-posta doğrulamasını açık tutacaksanız signup sonrası e-postadaki bağlantıya tıklayın.
5. `index.html`, `app.js`, `config.js`, `schema.sql` ve `README.md` dosyalarını GitHub deposunun kök dizinine yükleyin. Settings → Pages → Deploy from a branch → `main` → `/ (root)` seçin.

## Sesli görüşme notu

Ses WebRTC üzerinden tarayıcılar arasında kurulur; sinyalleşme Supabase Realtime, ağ keşfi Google'ın herkese açık STUN servisiyle yapılır. GitHub Pages HTTPS sunduğu için mikrofon erişimi desteklenir. Bazı kurumsal ağlarda veya katı NAT arkasında STUN bağlantısı yetmeyebilir; bu durumda güvenilir TURN servisi ve ek yapılandırma gerekir. Sesli kanala katılmak için mikrofon izni verin ve aynı metin kanalını seçin.

## Güvenlik

`schema.sql` tablolar için Row Level Security kurallarını açar; mesajlar/dosyalar yalnızca sunucu üyelerine görünür. İstemcideki Supabase anon key public olarak tasarlanmıştır ve RLS ile sınırlıdır. Gerçek parolalar Supabase Auth tarafından yönetilir. Kullanıcı adı araması, kayıtlı profillerin kullanıcı adını giriş yapmış üyelere gösterir.
