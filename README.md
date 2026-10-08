# Wordle

Русская игра Wordle на Flutter. Ответы выбираются из локального частотного
словаря существительных. Groq создаёт только короткие и расплывчатые
подсказки.

## Локальный запуск

```powershell
flutter pub get
flutter run -d edge
```

Для локальных подсказок запустите `./tool/start_groq_proxy.ps1`. При первом
запуске ключ можно сохранить для текущего пользователя Windows:

```powershell
.\tool\start_groq_proxy.ps1 -SaveKey
```

Ключ запрашивается в скрытом поле и не добавляется в код, EXE или Git.

## Облачный прокси для EXE и APK

Для распространяемых EXE и APK нельзя использовать `127.0.0.1`: на устройстве
пользователя там нет прокси. Вместо этого разверните Worker из папки
`cloudflare`. Он хранит ключ Groq как секрет на сервере, а приложения получают
только публичный HTTPS-адрес Worker.

1. Отзовите ключи, которые были опубликованы, и создайте новый ключ Groq.
2. Установите Node.js, затем в PowerShell выполните:

```powershell
cd cloudflare
npx wrangler login
npx wrangler deploy
npx wrangler secret put GROQ_API_KEY
```

3. Скопируйте HTTPS-адрес из результата `wrangler deploy`.
4. Вернитесь в корень проекта и создайте сборки, передав только этот адрес:

```powershell
.\tool\build_with_cloud.ps1 -Target windows -ProxyEndpoint 'https://YOUR-WORKER.workers.dev'
.\tool\build_with_cloud.ps1 -Target apk -ProxyEndpoint 'https://YOUR-WORKER.workers.dev'
```

Собранные приложения будут запрашивать подсказки через Worker. API-ключ остаётся
в секрете Cloudflare и не может быть извлечён из EXE или APK. Worker принимает
только слово из 3–10 русских букв и не принимает произвольные запросы к модели.

Прокси использует `qwen/qwen3.8-27b`. На бесплатном плане Groq действуют
изменяемые лимиты, поэтому проверяйте их в консоли Groq.

Чтобы удалить локально сохранённый ключ Windows, выполните:

```powershell
[Environment]::SetEnvironmentVariable('GROQ_API_KEY', $null, 'User')
```
