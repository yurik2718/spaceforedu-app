# Руководство по тестированию

Этот документ описывает принципы, которым мы следуем при написании тестов. Каждый принцип — следствие реальной ошибки или решения, принятого в этом проекте.

---

## Принцип 1. Тест проверяет контракт, а не внутренности кода

**Контракт** — это соглашение между двумя компонентами о том, в каком формате они обмениваются данными. Если тест нарушает этот формат, он даёт ложное чувство безопасности: тесты зелёные, в продакшне — падение.

### Конкретный случай: `direct_upload: true`

Когда форма использует `direct_upload: true`, браузерный JS загружает файл в хранилище *до* сабмита формы. В `params` контроллер получает **подписанный ID blob-а** (строку), а не объект файла.

```
# Что реально приходит в params[:files] при direct_upload: true
["eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19..."]
```

Тест, который посылает `Rack::Test::UploadedFile`, проверяет код, который в продакшне никогда не выполняется.

**Правило**: Если в форме стоит `direct_upload: true` — в тесте используй `signed_blob_id`. Если форма без `direct_upload` — `Rack::Test::UploadedFile`.

```ruby
# Неправильно: симулирует форму без direct_upload
pdf = Rack::Test::UploadedFile.new(StringIO.new("%PDF"), "application/pdf", original_filename: "ok.pdf")
post path, params: { files: [pdf] }

# Правильно: симулирует реальный direct_upload
post path, params: { files: [direct_upload_blob] }
```

При изменении `direct_upload:` в шаблоне — тесты контроллера должны меняться синхронно.

---

## Принцип 2. Хелперы документируют намерение

Имя хелпера должно объяснять *что симулируется*, а не *как устроено внутри*.

```ruby
# Плохо: говорит о реализации
def create_blob_and_get_signed_id(...)

# Хорошо: говорит о контракте
def direct_upload_blob(filename: "test.pdf", content: "%PDF-1.4 fake", content_type: "application/pdf")
  ActiveStorage::Blob.create_and_upload!(
    io: StringIO.new(content),
    filename: filename,
    content_type: content_type
  ).signed_id
end
```

Хелпер живёт в `test/test_helpers/active_storage_test_helper.rb` и подключается через `test_helper.rb`:

```ruby
# test/test_helpers/active_storage_test_helper.rb
module ActiveStorageTestHelper
  def direct_upload_blob(filename: "test.pdf", content: "%PDF-1.4 fake", content_type: "application/pdf")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(content),
      filename: filename,
      content_type: content_type
    ).signed_id
  end
end

ActiveSupport.on_load(:active_support_test_case) { include ActiveStorageTestHelper }
ActiveSupport.on_load(:action_dispatch_integration_test) { include ActiveStorageTestHelper }
```

---

## Принцип 3. Проверяй финальное состояние базы, а не только HTTP-статус

HTTP-статус говорит, что контроллер *решил*. Состояние базы говорит, что *произошло на самом деле*.

```ruby
# Слабый тест: знает только что вернул HTTP
assert_no_difference "ActiveStorage::Attachment.count" do
  post path, params: { files: [bad_blob] }
end
assert_response :unprocessable_entity

# Сильный тест: знает итоговое состояние
post path, params: { files: [bad_blob] }

assert_response :unprocessable_entity
assert_equal 0, @draft.reload.documents.attachments.count  # blob реально удалён
```

`assert_no_difference` с `ActiveStorage::Attachment.count` ненадёжен при `purge_later` — фоновая задача ещё не выполнилась. `.reload.count` — всегда честный ответ на момент проверки после завершения запроса.

---

## Принцип 4. Каждый контроллер проверяет полный набор веток

Минимальный набор тестов для контроллера с загрузкой файлов:

| Тест | Что проверяет |
|------|---------------|
| Валидный файл | Happy path: attach + redirect + notice |
| Неверный content_type | Валидация + файл не сохранился |
| Превышение размера | Валидация + файл не сохранился |
| Turbo Stream | Нужный `<turbo-stream action="replace" target="...">` |
| Побочный эффект (уведомление) | Создаётся в нужных статусах |
| Отсутствие побочного эффекта | Не создаётся в статусах, где не должно |
| Смешанный батч | Не трогает pre-existing вложения |

Статус-ответ и состояние БД — это разные утверждения. Проверяй оба.

---

## Принцип 5. Тест авторизации — три роли, один экшен

Каждый защищённый экшен должен иметь тест для трёх сценариев:

```ruby
test "owner can upload" do
  sign_in_as @student
  post path, params: { files: [direct_upload_blob] }
  assert_redirected_to ...
end

test "stranger cannot upload" do
  sign_in_as users(:other_student)
  post path, params: { files: [direct_upload_blob] }
  assert_redirected_to root_path
end

test "guest is redirected to sign in" do
  post path, params: { files: [direct_upload_blob] }
  assert_redirected_to new_session_path
end
```

Это поймает регрессию в политиках Pundit при любом рефакторинге авторизации.

---

## Принцип 6. Три вопроса перед написанием теста

Перед каждым тестом задай себе:

1. **Что именно я симулирую?** — `direct_upload_blob` или `UploadedFile`? Signed ID или реальный файл? Это должно совпадать с тем, что делает форма.

2. **Что я проверяю?** — HTTP-статус, состояние БД, побочный эффект, HTML в ответе? Каждое — отдельное утверждение.

3. **Что должно НЕ произойти?** — Файл не должен сохраниться при ошибке. Уведомление не должно уйти в черновике. Чужие вложения не должны исчезнуть.

---

## Быстрая проверка перед пушем

Перед коммитом с изменениями в контроллере загрузки файлов проверь:

```bash
bin/rails test test/controllers/homologation_request_documents_controller_test.rb
```

При изменении формы (добавление/удаление `direct_upload:`, смена имени поля) — найди соответствующий тест контроллера и убедись, что `params` в тесте совпадает с тем, что форма реально отправляет.
