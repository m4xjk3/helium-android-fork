# Сборка Helium для Android

Этот форк — **неофициальная Android-сборка Helium** на базе
[Titanium Browser for Android](https://github.com/jqssun/android-titanium-browser)
и [Vanadium](https://github.com/GrapheneOS/Vanadium). В отличие от десктопного
[imputnet/helium](https://github.com/imputnet/helium), здесь используется
Chromium-сборка `is_desktop_android = true` с полной поддержкой расширений.

> Helium (imputnet) не содержит Android-таргета. Прямой порт десктопных патчей
> на Android невозможен без переписывания UI, поэтому за основу взята готовая
> Android-база с уже реализованной поддержкой расширений.

## Почему расширения здесь работают

Ключевые патчи в `patch.sh` (секции `# ext:`):

| Что | Патч |
| --- | --- |
| Тулбар расширений на телефоне | `toolbar_phone.xml`, `ToolbarManager`, `ToolbarPhone` |
| Полноэкранные попапы | `ExtensionActionPopup`, `extension_action_popup_contents` |
| Manifest V2 | `g_allow_mv2_for_testing = true`, `browser_action.json` |
| Установка не из Chrome Web Store | allowlist Opera/Edge в `download_crx_util.cc` |
| Расширения в инкогнито | `process_manager.cc`, `IncognitoUtils` |
| Процесс расширения не выгружается | `ChildProcessLauncherHelperImpl` (`IMPORTANT`) |
| Load unpacked через SAF | `VirtualDocumentPath`, локали `content://` |
| Мобильный `chrome://extensions` | viewport + CSS |
| Обход багов апстрима | `tabs_api.cc`, `profile_destroyer.cc` и др. |

## Требования

Собрать Chromium для Android на Windows нативно нельзя. Варианты:

| Вариант | RAM | Диск | Время |
| --- | --- | --- | --- |
| Linux x86_64 (Ubuntu 22.04/24.04) | 16+ ГБ (32 лучше) | 120–150 ГБ | 3–8 ч |
| Self-hosted GitHub runner | 16+ ГБ | 120–150 ГБ | 3–8 ч |
| WSL2 на Windows | 32 ГБ | 150 ГБ | 5–10+ ч |
| `ubuntu-latest` (GitHub-hosted) | 16 ГБ | ~50 ГБ | **не хватит диска** |

> Важно: стандартный GitHub-hosted раннер даёт ~14 ГБ свободного места, а
> Chromium с зависимостями и артефактами требует 100+ ГБ. Бесплатный
> `ubuntu-latest` для полноценной сборки практически непригоден. Нужен
> self-hosted раннер (свой ПК/сервер) или платный larger runner
> (`ubuntu-latest-16-cores` и т.п.).

## Шаг 0. Исходники

Репозиторий уже инициализирован и все версии зафиксированы (см.
[`docs/VERSIONS.md`](VERSIONS.md)). Если проект ещё не на GitHub — опубликуй его
одной командой (нужен токен с правом `repo`):

```powershell
$env:GITHUB_TOKEN = "ghp_..."
./scripts/publish.ps1            # или -Public для публичного репозитория
```

Linux/macOS: `GITHUB_TOKEN=ghp_... ./scripts/publish.sh --public`.

После публикации клонируй уже с подмодулем:

```bash
git clone --recurse-submodules https://github.com/m4xjk3/helium-android-fork.git
cd helium-android-fork
```

Проверь, что подмодуль на месте:

```bash
git submodule update --init --recursive
ls vanadium/args.gn
```

## Шаг 1. Ключ подписи

APK/AAB нужно подписывать. Сгенерируй ключ один раз и сохрани его: при смене
ключа приложение нельзя будет обновить поверх старого.

Linux / macOS / Git Bash:

```bash
keytool -genkeypair -keystore helium.jks -alias helium \
  -keyalg RSA -keysize 2048 -validity 10000

cat > local.properties <<'EOF'
keyAlias=helium
keyPassword=ПАРОЛЬ_КЛЮЧА
storePassword=ПАРОЛЬ_ХРАНИЛИЩА
EOF

base64 -w0 helium.jks > helium.jks.b64
base64 -w0 local.properties > local.properties.b64
```

Windows PowerShell:

```powershell
./scripts/gen-keystore.ps1 -OutDir ./keys
```

## Шаг 2. Секреты репозитория

`LOCAL_TEST_JKS` — это base64 от `local.properties`, `STORE_TEST_JKS` — base64
от `helium.jks` (имена исторические, не путай).

В опубликованном репозитории `m4xjk3/helium-android-fork` оба секрета уже
добавлены, ключ лежит локально в `keys/` (каталог в `.gitignore`).

```bash
gh secret set LOCAL_TEST_JKS   < local.properties.b64
gh secret set STORE_TEST_JKS   < helium.jks.b64
```

Или вручную: **Settings → Secrets and variables → Actions → New repository
secret**.

Если секреты не заданы, `common.sh` сгенерирует временный ключ. APK соберётся и
установится, но обновлять его поверх следующей сборки не получится.

## Шаг 3. Запуск сборки

**Actions → Build → Run workflow**:

- `runner` — `self-hosted` (свой раннер) или метка hosted-раннера;
- `update_vanadium` — обновить Vanadium до последнего тега (по умолчанию нет,
  так сборка воспроизводимее);
- `release` — создать GitHub Release (по умолчанию да; артефакты всё равно
  выгружаются в Artifacts).

Готовые файлы: `156.x.x.x-arm64-v8a.apk`, `...-armeabi-v7a.apk`,
`...-arm64-v8a.aab`.

## Шаг 4. Проверка расширений

1. Установи APK на телефон.
2. Открой `https://chromewebstore.google.com/` — сайт должен открыться в
   десктопном виде (это включено патчем в `DesktopSiteUtils.java`).
3. Поставь **uBlock Origin** (MV2) — он должен установиться и работать.
4. Поставь **Dark Reader** и **Bitwarden** — проверка MV3 и service worker.
5. Открой `chrome://extensions`, включи **Developer mode** → **Load unpacked**
   и выбери папку расширения через SAF-пикер.
6. Для работы в инкогнито: `chrome://extensions` → **Details** расширения →
   **Allow in Incognito**.
7. Тулбар расширений: закрепи иконку в меню `⋮` → **Extensions**.

## Предустановленный uBlock Origin

По умолчанию в APK пакуется **uBlock Origin 1.75.0 (MV2)**:

- `.gclient` → хук `fetch_ublock_origin` скачивает CRX;
- `extensions/bundle.py` вычисляет id/версию, пишет `bundled.json` и
  дописывает CRX в `BUILD.gn`;
- `extensions/stage_bundled_extensions.inc` при старте распаковывает CRX в
  `DIR_EXTERNAL_EXTENSIONS` и регистрирует его через `external_pref_loader`;
- `patch.sh` копирует это в `titanium/dist` и подключает
  `//titanium/dist:extension_assets` к APK.

Обновить версию: замени URL в `.gclient` на нужный релиз
<https://github.com/gorhill/uBlock/releases> (файл
`uBlock0_<версия>.chromium.crx`).

Заменить на другое расширение: поменяй имя файла и URL в хуке — id и версия
определятся автоматически. Нужен подписанный **CRX3**, простой ZIP не подойдёт.

Убрать бандл совсем: удали хук из `.gclient` и строки про `titanium/dist` в
`patch.sh`, оставив в `extensions/dist` только `BUILD.gn` и `bundled.json` с
`{}`.

## Ребрендинг

Сейчас сделано:

- `args.gn` → `chrome_public_manifest_package = "computer.helium.android"`;
- `patch.sh` → секция `# brand: helium` заменяет пользовательские строки
  `Titanium` → `Helium` в `.grd`/`.grdp`/`.xtb` и в
  `chrome/android/java/res_titanium_base/values/channel_constants.xml`
  (имя приложения, заголовки виджетов);
- `res/` → иконки Helium (синий `#3450D1` + белая звезда), включая
  themed-иконку для Android 13+.

Внутреннее имя `titanium` намеренно сохранено: от него зависят GN-пути,
Java-пакеты и config app.

Если нужно поменять package id — только `args.gn`. Если нужен другой оттенок
иконки — `res/icon.svg`, `res/icon_fg.svg`, `res/icon_bg.svg`,
`res/drawable/themed_app_icon.xml`.

## Ограничения

- Native messaging (нативные хосты) на Android не поддерживается — часть
  функций некоторых менеджеров паролей будет недоступна.
- Некоторые расширения с desktop-only API (например, требующие окон ОС) не
  заработают.
- Chrome Web Store может показывать предупреждения о неподдерживаемом браузере;
  установка через `chrome://extensions` / CRX остаётся доступной.
- Предустановленный uBlock Origin — это MV2-сборка. Если Google окончательно
  выпилит MV2 из апстрима, понадобится переход на uBlock Origin Lite (MV3).
- Использование имени и логотипа Helium в неофициальной сборке может нарушать
  права на бренд проекта. Код при этом остаётся под GPL.
