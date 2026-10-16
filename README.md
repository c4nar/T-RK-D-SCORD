# TÜRK DİSCORD

GitHub Pages üzerinde çalışabilen, tek dosyalı ve tarayıcıda saklanan bir P2P sohbet arayüzü. `index.html` dışında uygulama sunucusu, Supabase projesi veya API anahtarı istemez.

## Özellikler

- Profil adı ve görseli, arkadaş listesi, arkadaş kodu ve sunucu listesi tarayıcıda hatırlanır.
- ＋ menüsünden arkadaş koduyla arkadaş eklenir, sunucu kurulur veya sunucu davet koduyla katılınır.
- Sunucu adı ve görseli belirlenir; metin ve ses kanalları oluşturulur.
- Ses kanalına tıklayınca ayrı ses odası sekmesi açılır; katılımcı profilleri kanalın altında görünür.
- Ses odasında mikrofon, kulaklık sesi, kamera ve arama kapatma kontrolleri bulunur; üç nokta menüsünden giriş/çıkış cihazı seçilir.
- Sunucu açıklaması ve başlangıç kanalları kurulumda seçilir; sahibi sonradan ad, açıklama ve görseli değiştirebilir.
- Özel mesajlar ve metin kanalı mesajları doğrudan eşler arasında iletilir.
- Görsel, ses ve dosyalar doğrudan paylaşılır; dosya boyutu 2 MB ile sınırlıdır.
- Profil ayarlarında mesaj ses efektleri ve mesaj animasyonları açılıp kapatılır.
- Ses kanalında mikrofonla konuşma ve kamera için HTTPS ile tarayıcı izinleri gerekir.

## Kullanım

1. `index.html` dosyasını GitHub deposuna yükleyip GitHub Pages'i etkinleştirin.
2. Uygulamayı açın, profil ayarlarından adınızı belirleyin.
3. ＋ → **Sunucu kur** ile bir sunucu açın ve **Davet kodu** düğmesiyle kodu arkadaşlarınıza iletin. Arkadaş eklemek için karşı tarafın çevrimiçi arkadaş kodunu kullanın.
4. Sunucu sahibi çevrimiçi kalmalıdır. Davetliler ＋ → **Sunucuya katıl** ile koda bağlanır.

## Sınırlar

Uygulamada e-posta/şifreyle hesap açma veya merkezi mesaj geçmişi yoktur; profil, arkadaşlar, sunucular ve metin geçmişi mevcut tarayıcının `localStorage` alanında saklanır. Arkadaş kodu bu tarayıcı profiline bağlıdır. Tarayıcı verileri silinirse yerel liste ve profil de silinir. Tarayıcı depolama alanı sınırlı olduğu için 350 KB üzerindeki dosyaların içeriği geçmişe yazılmaz; mesaj kaydı görünür, ancak ek dosyanın kendisi yenilemeden sonra saklanmaz.

PeerJS Cloud yalnızca bağlantıyı kurmaya yarayan sinyalleşmeyi sağlar; sohbet, dosya ve ses/görüntü normalde WebRTC üzerinden doğrudan aktarılır. Bazı ağlarda doğrudan bağlantı kurulamayabilir. Sunucuyu oluşturan kişi çevrimdışı olursa o sunucu kapanır. GitHub Pages için uygulamayı HTTPS üzerinden açın; mikrofon ve kamera güvenli bağlantı ister.

Bağlantıda `network` hatası alırsanız `file:///.../index.html` yerine GitHub Pages'in HTTPS adresini açın. PeerJS Cloud'un kullandığı `0.peerjs.com:443` bağlantısı VPN, okul/iş ağı veya güvenlik duvarı tarafından engelleniyorsa P2P kurulamaz. `peer-unavailable` hatasında sunucu sahibinin çevrimiçi olması ve davet kodunun doğru olması gerekir; sahibi sunucuyu açtıktan sonra sol taraftaki sunucu simgesine tekrar tıklayarak katılmayı yeniden deneyin. Başarısız ilk deneme artık sonraki bağlantı girişimini kilitlemez.

`index.html` PeerJS 1.5.5 istemci kitaplığını içerir (MIT lisansı); harici CDN yüklemesi gerekmez.
