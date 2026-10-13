# Android APK üretme

Godot 4.6.3 Standard ve aynı sürümün export template'leri gerekir. GDScript kullanılır; .NET kurulumu gerekmez.

## Gerekli araçlar

- OpenJDK 17 veya daha yenisi.
- Android SDK command-line tools.
- Android SDK `platform-tools`, `build-tools;35.0.1`, `platforms;android-35`.
- Godot 4.6.3 Android export template'leri: `android_debug.apk`, `android_release.apk`.

Bu projede Gradle kullanılmaz. Godot'un hazır Android 4.6.3 template'i Android 24 minimum / Android 36 target bilgilerini içerir. Hazır template dışa aktarımı için yerel platform 35 ve Build Tools 35.0.1 yeterlidir; SDK sürümünü override etmek için Gradle build gerekir. AAB için Gradle build açılmalıdır.

Godot **Editor → Editor Settings → Export → Android** altında `Android SDK Path` ve `Java SDK Path` alanlarını ayarla. `Project → Install Android Build Template` normal debug APK için gerekmez.

## Debug APK

Godot bir debug anahtarı oluşturabilir. Kendin oluşturmak istersen:

```bash
keytool -genkeypair -keystore /tmp/yolkavga-debug.keystore \
  -alias androiddebugkey -storepass android -keypass android \
  -dname 'CN=Android Debug,O=Android,C=US' \
  -keyalg RSA -keysize 2048 -validity 10000

godot --headless --editor --path . --import --quit

GODOT_ANDROID_KEYSTORE_DEBUG_PATH=/tmp/yolkavga-debug.keystore \
GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey \
GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android \
godot --headless --path . --export-debug Android builds/YolKavga-debug.apk
```

`android` parolası yalnızca standart deneme anahtarı örneğidir. Yayın anahtarında kullanma.

İmzayı kontrol etmek için:

```bash
"$ANDROID_SDK_ROOT/build-tools/35.0.1/apksigner" verify --verbose builds/YolKavga-debug.apk
```

## GitHub Actions

`.github/workflows/android.yml` Godot ve Android araçlarını kurar, kaynak varlıkları içe aktarır, oynanış kontrolünü çalıştırır, debug APK üretir, imzayı doğrular ve APK'yi artifact olarak saklar. Kaynak repoya APK veya anahtar eklemez. Yeni bir CI çalışmasında yeni debug anahtarı üretilir; farklı anahtarla imzalanmış eski APK telefonda yüklüyse yeni paket için önce eskisini kaldırman gerekebilir.

Bir APK'yi Releases'a eklemek için önce GitHub'da ilgili sürüm için bir **draft release** hazırla. **Actions → Android APK → Run workflow** ekranında `release_tag` alanına sürüm etiketini, örneğin `v0.1.0`, yaz. Tüm kontroller ve imza doğrulaması başarılı olunca ayrı release işi APK ve checksum dosyasını taslağa yükler, ardından sürümü yayınlar. Alan boş bırakılırsa yalnızca build artifact'i oluşur.

## Telefonda kontrol

1. APK'yi kur ve yatay ekran açılışını kontrol et.
2. **Kavgayı Başlat** ile geri sayımı tamamla.
3. Aynı anda hareket + savunma ve hareket + yumruk dene; parmak bırakılınca hareketin durduğunu doğrula.
4. İki raund, sonuç ve rövanş akışlarını oyna.
5. Ana menüde ayar değiştir; uygulamayı kapatıp açarak ayarın korunduğunu kontrol et.
6. Maç sırasında geri tuşuna bas veya başka uygulamaya geç; maçın duraklamasını kontrol et.
7. Ses, titreşim, büyük düğmeler ve üç zorluk seviyesini cihaz üzerinde dene.

Bu adımlar cihaz testi için yönergedir; fiziksel telefon testi yapılmış olduğunu ifade etmez.

## Play Store sürümü

Kendi release keystore'unu güvenli bir yerde oluştur, Godot export ekranında release alanlarını ayarla, Gradle build ve AAB export aç. Paket adı `com.mehmet9978.yolkavga`. Her güncellemede `version/code` değerini artır. Play Store'a yükleme bu çalışmada yapılmadı.

Kaynak: [Godot Android export belgesi](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
