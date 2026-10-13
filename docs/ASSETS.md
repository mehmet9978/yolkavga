# Hazır varlık kaynakları

Tüm modeller, karakter animasyonları, düğme görselleri, darbe efektlerinin dokuları ve sesler internetten indirilen hazır varlıklardır. Bu projede SVG çizimi, procedurally generated mesh/texture, sentezlenmiş ses veya yapay zekâ ile oluşturulmuş görsel kullanılmaz. Godot betikleri mevcut varlıkları sahneye yerleştirir, hareket ettirir ve oyun davranışını yönetir. Düz renkli standart UI panelleri ve metinler Godot kontrolleridir.

İndirme tarihi: **2026-10-13**. Paketlerin oyun için kullanılan alt kümesi eklenmiştir. Kenney modellerinin özgün `Textures/colormap.png` bağımlılıkları korunur. GLB dosyaları ve hazır animasyonları değiştirilmeden kullanılır.

| Paket | Kullanım / klasör | Üretici kaynağı | Lisans |
| --- | --- | --- | --- |
| Car Kit | Açık kasalı truck-flat, trafik araçları, araç prop'ları; `assets/vehicles/` | [Kenney Car Kit](https://kenney.nl/assets/car-kit) | CC0 1.0 |
| City Kit Roads | Yol, zemin, aydınlatma modelleri; `assets/roads/` | [Kenney City Kit Roads](https://kenney.nl/assets/city-kit-roads) | CC0 1.0 |
| City Kit Suburban | Binalar, ağaçlar; `assets/city/` | [Kenney City Kit Suburban](https://kenney.nl/assets/city-kit-suburban) | CC0 1.0 |
| Nature Kit | Çim zemin, ağaçlar, çalılar, otlar, çiçekler, kayalar ve tepe olarak kullanılan hazır kaya modelleri; `assets/nature/*.glb` | [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 |
| Racing Kit | Çevre yolu metal bariyerleri; `assets/highway/` | [Kenney Racing Kit](https://kenney.nl/assets/racing-kit) | CC0 1.0 |
| Kloofendal 48d Partly Cloudy — Pure Sky | Hazır 1K bulutlu gökyüzü HDR panoraması; `assets/sky/` | [Poly Haven, Greg Zaal ve Jarod Guest](https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky) | CC0 1.0 |
| Leafy Grass | Hazır 1K çim diffuse dokusu; `assets/nature/Textures/leafy_grass_diff_1k.jpg` | [Poly Haven, Charlotte Baglioni](https://polyhaven.com/a/leafy_grass) | CC0 1.0 |
| UI Pack | Hazır düğme ve bar dokuları, yıldız uygulama simgesi; `assets/ui/` | [Kenney UI Pack](https://kenney.nl/assets/ui-pack) | CC0 1.0 |
| Particle Pack | Darbe sırasında gösterilen hazır yıldız ve kıvılcım dokuları; `assets/fx/` | [Kenney Particle Pack](https://kenney.nl/assets/particle-pack) | CC0 1.0 |
| Impact Sounds | Yumruk, tekme ve savunma sesleri; `assets/audio/impact*.ogg` | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | CC0 1.0 |
| Interface Sounds | Menü tıklaması ve maç sonucu sesleri; `assets/audio/click*, confirmation*, error*` | [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) | CC0 1.0 |
| Ultimate Modular Men | Casual Character ve Worker, 24 hazır animasyon; `assets/characters/` | [Quaternius Ultimate Modular Men](https://quaternius.com/packs/ultimatemodularcharacters.html) | CC0 1.0 |
| Barlow Condensed | Türkçe metinler; `assets/fonts/` | [Google Fonts kaynakları](https://github.com/google/fonts/tree/main/ofl/barlowcondensed) | SIL OFL 1.1 |

## Karakterlerin indirme yolu

Quaternius'un resmi sayfasındaki Google Drive klasörü bu oturumda indirme kotası hatası verdi. Aynı hazır karakterlerin CC0 kopyaları [fatal-funnel-public](https://github.com/euuuuuuan/fatal-funnel-public/tree/main/packages/renderer/assets/models/quaternius-men) reposundan alındı. Üretici ve lisans bilgisi [bu reponun CREDITS.md dosyasında](https://github.com/euuuuuuan/fatal-funnel-public/blob/main/CREDITS.md) belgelenir. [Poly Pizza'daki aynı paket](https://poly.pizza/bundle/Ultimate-Modular-Men-Pack-ZiH8muWqwQ) de Quaternius'u ve CC0 lisansını gösterir.

İndirilen dosyaların SHA-256 değerleri:

- `casual-character.glb`: `fea7e71271203e7073f1a073fa1208de7402df276f87f80e149bf7589b5d46b4`
- `worker.glb`: `9c28614f465b7dc105f908c20c22fc045f4b07caf8c5ef0e9f8049eceb6dd38d`

Bu kopyalar orijinal modelleri ve `Idle`, `Walk`, `Punch_Left/Right`, `Kick_Left/Right`, `HitRecieve`, `Death`, `Sword_Slash`, `Wave` dahil hazır animasyonları içerir. Animasyonlar kodla çizilmez veya yeniden üretilmez.

## Lisanslar

0.2.0 çevre güncellemesinde kaynak GLB, JPG ve HDR dosyaları değiştirilmeden kullanılır. Kenney'nin turkuaz varsayılan doğa malzemeleri Godot sahnesinde meşe, çam, çim ve toprak için ortak doğal renk malzemelerine bağlanır. Tepeler hazır kaya modellerinin sahnede ölçeklenmesiyle kurulur; yeni mesh üretilmez. Zemin hazır çim dokusunu tekrarlar ve trafik hızıyla kaydırır. Yol çizgileri özgün Kenney colormap dokusundan gelir. Bu ayarlar `scenes/arena.tscn` içindeki standart Godot malzemeleridir.

Poly Haven'ın [lisans sayfası](https://polyhaven.com/license), indirilen panorama ve çim dokusunun CC0 kullanım ve yeniden dağıtım koşullarını açıklar. Bildirim ve CC0 metni `assets/licenses/poly-haven-CC0.txt` ile APK içine de eklenir.

CC0 paketleri ücretsiz kullanım ve yeniden dağıtım için kamu malı beyanıyla sunulur; zorunlu atıf olmasa da üreticiler oyun içindeki **Emeği Geçenler** ekranında belirtilir. Yazı tipinin OFL metni de korunur. Bu, royalty-free hazır varlık kullanımıdır; tüm içeriklerin aynı lisanslı olduğu anlamına gelmez.

Özgün paket lisansları `assets/licenses/` klasöründedir. `docs/asset-manifest.json`, her varlığı kaynak paketi, lisansı ve SHA-256 değeriyle eşler. Oyun kodu için kökteki `LICENSE` geçerlidir.

## Referans fotoğraf

Kullanıcının fotoğrafı açık kasalı araçta yan yana dövüş kompozisyonuna referans oldu. Fotoğrafın kendisi oyun asset'i olarak dağıtılmaz. Gerçek kişi adı, watermark ve gerçek plaka oyuna taşınmadı; oyun plakası `41 KVG 001`.
