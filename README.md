# 🎵 Tuniverse - Müzik Evreni Uygulaması

Letterboxd'den ilham alan, müzik severler için modern bir müzik keşif ve paylaşım uygulaması. Tuniverse ile müzik dünyanızı keşfedin! Flutter ve Firebase ile geliştirildi.

## ✨ Özellikler

### 🎵 Müzik Özellikleri
- **Müzik Değerlendirme Sistemi** - Favori şarkılarını puanla ve yorumla
- **Gelişmiş Arama** - Sanatçı, albüm, şarkı ve kullanıcı bazında ara
- **Spotify Entegrasyonu** - Spotify hesabınla bağlan ve playlistlerini içe aktar
- **Discovery & Recommendations** - Spotify API ve Last.fm ile kişiselleştirilmiş öneriler
- **Playlist Yönetimi** - Kendi playlistlerini oluştur ve yönet
- **Akıllı Playlistler** - Ruh hali, tür, dönem ve aktivite bazlı otomatik playlistler
- **Playlist Etiketleri** - Playlistlerini kategorize et ve organize et
- **Playlist Keşfi** - Diğer kullanıcıların public playlistlerini keşfet
- **QR Kod Paylaşımı** - Playlistleri QR kod ile kolayca paylaş
- **Müzik Paylaşımı** - Şarkı, albüm ve playlist paylaş

### 👥 Sosyal Özellikler
- **Kullanıcı Profilleri** - Detaylı profil sayfaları (incelemeler, listeler, favoriler, aktivite)
- **Takip Sistemi** - Diğer kullanıcıları takip et/takipten çık
- **Sosyal Feed** - Takip ettiğin kullanıcıların aktivitelerini gör
- **Kullanıcı Arama** - Username, email veya isim ile kullanıcı ara
- **Profil İstatistikleri** - Takipçi, takip, inceleme ve liste sayıları

### 💬 Mesajlaşma (DM) Özellikleri
- **Gerçek Zamanlı Mesajlaşma** - Anlık mesajlaşma desteği
- **Müzik Paylaşımı** - Mesajlarda şarkı, albüm ve playlist paylaş
- **Yazıyor Göstergesi** - Karşı tarafın yazdığını gör
- **Online/Offline Durumu** - Kullanıcıların çevrimiçi durumunu takip et
- **Mesaj İşlemleri** - Mesajları kopyala, sil, yanıtla
- **Okundu Bilgisi** - Mesajların okunup okunmadığını gör
- **Kullanıcı Arama** - Kolayca kullanıcı bul ve sohbet başlat

### 🎨 Genel Özellikler
- **Modern UI/UX** - Karanlık/Aydınlık mod desteğiyle güzel arayüz
- **Profil Sistemi** - Kullanıcı profilleri ve playlist sayaçları
- **Responsive Tasarım** - Tüm ekran boyutlarında mükemmel çalışır
- **Firebase Backend** - Güvenli ve hızlı veri yönetimi

## 🚀 Başlangıç

### Gereksinimler

- Flutter SDK (3.9.2 veya üzeri)
- Dart SDK (3.9.2 veya üzeri)
- Android Studio / VS Code
- Firebase hesabı (Firestore + Realtime Database)
- Spotify Developer hesabı (opsiyonel)

### Kurulum

1. **Projeyi klonla:**
```bash
git clone https://github.com/yourusername/musicshare.git
cd musicshare
```

2. **Bağımlılıkları yükle:**
```bash
flutter pub get
```

3. **Firebase Kurulumu:**
- `FIREBASE_SETUP.md` dosyasındaki adımları takip et
- Firestore ve Realtime Database'i aktif et
- Security rules'ları deploy et

4. **Uygulamayı çalıştır:**
```bash
flutter run
```

## 🔧 Geliştirme

### Teknoloji Stack
- **Flutter** - Mobil uygulama framework'ü
- **Firebase Firestore** - NoSQL veritabanı
- **Firebase Realtime Database** - Online status takibi
- **Firebase Storage** - Resim ve medya depolama (Blaze Plan)
- **Firebase Auth** - Kullanıcı kimlik doğrulama
- **Riverpod** - State management
- **GoRouter** - Navigation
- **Spotify API** - Müzik verisi

### Mimari
- **Feature-based** klasör yapısı
- **Service Pattern** - Firebase servisleri için
- **Model-View** yapısı
- **Real-time listeners** - Firestore ve Realtime DB

### Kod Stili
- **Flutter Lints** kuralları uygulanıyor
- **Tutarlı isimlendirme** konvansiyonları
- **Kapsamlı dökümantasyon**

## 📸 Ekran Görüntüleri

*Yakında eklenecek...*

## 🗂️ Proje Yapısı

```
lib/
├── core/              # Tema, sabitler, yardımcılar
├── features/          # Özellik bazlı modüller
│   ├── auth/         # Kimlik doğrulama
│   ├── messaging/    # DM sistemi
│   ├── playlists/    # Playlist yönetimi
│   └── profile/      # Kullanıcı profili
├── shared/           # Paylaşılan bileşenler
│   ├── models/       # Veri modelleri
│   ├── services/     # Firebase servisleri
│   └── widgets/      # Ortak widgetlar
└── main.dart         # Uygulama giriş noktası
```

## ✅ Tamamlanan Özellikler

### Discovery & Recommendations (Keşif ve Öneriler)
- ✅ **Spotify Recommendations API** - Kişiselleştirilmiş şarkı önerileri
- ✅ **Last.fm Benzer Şarkılar** - Benzer şarkı keşfi
- ✅ **Track Detail Önerileri** - Her şarkı sayfasında ilgili öneriler

### Enhanced Artist & Album Pages (Gelişmiş Sanatçı ve Albüm Sayfaları)
- ✅ **Artist Detail Page** - 3 tab (Hakkında, Popüler Şarkılar, Diskografi)
- ✅ **Last.fm Entegrasyonu** - Sanatçı biyografisi ve benzer sanatçılar
- ✅ **Aylık Dinleyici** - Spotify follower verisi gösterimi
- ✅ **Album Detail Page** - İstatistikler, review/rating sistemi
- ✅ **Şarkı Listesi** - Tam track list ile entegre detay

### Social Features (Sosyal Özellikler)
- ✅ **User Profile Pages** - Detaylı kullanıcı profil sayfaları
- ✅ **Takip Sistemi** - Follow/Unfollow özelliği
- ✅ **Kullanıcı Arama** - Gelişmiş kullanıcı arama sistemi
- ✅ **Social Feed** - Aktivite feed (Tümü, Takip, Popüler)
- ✅ **Profil Tabları** - İncelemeler, Listeler, Favori, Aktivite

### Advanced Filtering & Sorting (Gelişmiş Filtreleme)
- ✅ **Genre Filtreleme** - 12+ müzik türü filtresi
- ✅ **Yıl Aralığı** - Min/max yıl seçimi
- ✅ **Popülerlik ve Rating** - Slider ile hassas filtreleme
- ✅ **Sıralama Seçenekleri** - En Yeni, En Popüler, En Yüksek Puan, Alfabetik
- ✅ **Modern Bottom Sheet** - Kullanıcı dostu arayüz

### Smart Playlists (Akıllı Playlistler)
- ✅ **Ruh Hali Bazlı** - Enerjik, Sakin, Mutlu, Konsantrasyon
- ✅ **Tür Bazlı** - Rock, Pop, Hip Hop koleksiyonları
- ✅ **Dönem Bazlı** - 90'lar, 2000'ler, 2010'lar nostalji listeleri
- ✅ **Aktivite Bazlı** - Spor, Parti için optimize listeler
- ✅ **Otomatik Oluşturma** - Kullanıcı kütüphanesine göre
- ✅ **Modern Gradient Cards** - Görsel olarak zengin tasarım

### Collaborative Playlists (Ortak Playlistler)
- ✅ **Rol Tabanlı İzinler** - Owner, Editor, Viewer rolleri
- ✅ **İşbirlikçi Yönetimi** - Kullanıcı ekleme/çıkarma, rol değiştirme
- ✅ **İzin Kontrolü** - canEdit(), canManage(), canView() metodları
- ✅ **Bildirim Sistemi** - Playlist'e eklendiğinde otomatik bildirim
- ✅ **Real-time Sync** - Firestore ile anlık güncelleme

### Playlist Sharing (QR Kod ile Paylaşım)
- ✅ **QR Kod Oluşturma** - Playlist için otomatik QR kod
- ✅ **Paylaşım Seçenekleri** - Link kopyalama, sosyal medya paylaşımı
- ✅ **Güzel UI** - Modern paylaşım bottom sheet

### In-App Notifications (Uygulama İçi Bildirimler)
- ✅ **Bildirim Tipleri** - Collaborator, like, comment, follow, message
- ✅ **Bildirim Yönetimi** - Okundu işaretleme, silme
- ✅ **Okunmamış Sayacı** - Real-time unread count

## 🔮 Yaklaşan Özellikler

- [ ] **QR Scanner** - Kamera ile QR kod okuma ✨ (Hazır, test edilecek)
- [ ] **Deep Linking** - QR koddan playlist açma
- [ ] **Playlist Analytics** - Detaylı istatistikler (toplam süre, en çok eklenen)
- [ ] **Playlist Comments & Ratings** - Sosyal özellikler
- [ ] **Multi-Platform Export** - Apple Music, YouTube Music desteği
- [ ] **Offline Mode** - Çevrimdışı kullanım
- [ ] **Version Control** - Playlist geçmişi
- [ ] **Push Notifications** - Cloud Functions ile bildirimler
- [ ] **Music Player** - Uygulama içi oynatıcı
- [ ] **Lyrics Integration** - Şarkı sözleri entegrasyonu

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Pull request göndermekten çekinmeyin.

1. Projeyi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request açın

## 👥 Ekip

- **Mert** - Geliştirici
- **Furkan** - Geliştirici

## 🙏 Teşekkürler

- Letterboxd'den ilham alındı
- Spotify'ın harika API'si için
- Flutter topluluğuna mükemmel paketler için

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır.

## 📞 İletişim

- Proje Linki: [https://github.com/yourusername/musicshare](https://github.com/yourusername/musicshare)
- Issues: [https://github.com/yourusername/musicshare/issues](https://github.com/yourusername/musicshare/issues)

---

⭐ Projeyi beğendiyseniz yıldız vermeyi unutmayın!
