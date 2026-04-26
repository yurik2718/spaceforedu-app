# Homologation App

A Rails 8 application for students seeking document equivalence recognition in Spain. Students submit requests, upload documents, and chat with a super admin.

- `homologation.es` — Astro.js landing page (separate repo)
- `app.homologation.es` — This Rails app

## Tech Stack

- **Rails 8.1.3** — canonical DHH style (no API mode, no React, no Inertia)
- **Hotwire** — Turbo Drive + Turbo Frames + Turbo Streams + Stimulus
- **Tailwind CSS 4 + Daisy UI 5** — all UI via Daisy UI component classes
- **Propshaft** — asset pipeline (no Sprockets)
- **Import maps** — no webpack, no Vite, no esbuild
- **SQLite3** — database (Solid Queue + Solid Cable + Solid Cache, no Redis)
- **Active Storage** — file uploads, local disk, no S3
- **Auth** — Rails 8 `generate authentication` (no Devise, no OAuth)
- **Authorization** — Pundit (2 roles: super_admin, student)
- **Payments** — Stripe (super_admin creates invoices)
- **Notifications** — in-app (Turbo Streams) + email + Telegram Bot API
- **Testing** — Minitest + Capybara (system tests) + Rails fixtures
- **i18n** — es (default), en, ru

## Commands

```bash
bin/setup    # Install gems, create DB, migrate, seed
bin/dev      # Start server (Puma + Tailwind watcher)
bin/ci       # Full quality check — run before every commit
```

`bin/ci` runs: rubocop → bundler-audit → importmap audit → brakeman → tests → system tests.

```bash
bin/rails test test/path/file_test.rb    # Single test file
bin/rails db:migrate                     # Run pending migrations
bin/rails db:seed                        # Seed super_admin + sample data
bin/rails db:reset                       # Drop, recreate, migrate, seed
```

Default super_admin in development: `admin@example.com` (see `db/seeds.rb`).

## Architecture

### Authentication

Rails 8 built-in auth generator. Tables: `users`, `sessions`. `has_secure_password` on User.
Password reset via email (Action Mailer + signed token).

### Roles

Single `role` string column on `users`.

| Role | Root path | Purpose |
|------|-----------|---------|
| `super_admin` | `/dashboard` | Full control: requests, payments, users, billing |
| `student` | `/requests` | Submits requests, uploads documents, chats with admin |

`authorize @record` in every controller action. `policy_scope` in every index action.

### Domain Models

**User** — all roles in one table. `role` string column. `discarded_at` for soft delete.
Encrypted PII: `phone`, `whatsapp`, `guardian_phone`, `guardian_whatsapp`.
Minor support: `is_minor`, `guardian_name`, `guardian_email`.
Telegram opt-in: `telegram_chat_id`, `notification_telegram`.

**HomologationRequest** — core model. Status flow:
```
draft → submitted → in_review ⇄ awaiting_reply → awaiting_payment → payment_confirmed → in_progress → resolved/closed
```
Enforced via `transition_to!(new_status, changed_by:)`. Never update status directly.
`discarded_at` for soft delete — always use `.kept` scope.
Three Active Storage attachment categories: `application` (one), `originals` (many), `documents` (many).

**Conversation** — one per HomologationRequest. `last_message_at` for ordering.

**Message** — `has_many_attached :attachments`. Broadcast via `after_create_commit`.

**ConversationParticipant** — join table user ↔ conversation. `last_read_at` drives unread counts.

**Notification** — in-app. Broadcast via Turbo Streams on create.

### Real-time

No polling. No custom WebSocket code. Turbo Streams + Action Cable + Solid Cable.

```erb
<%= turbo_stream_from @conversation %>
<div id="messages"><%= render @messages %></div>
```

```ruby
# Message model
after_create_commit -> { broadcast_append_to conversation }
```

### Background Jobs

```ruby
NotificationDeliveryJob   # email + Telegram delivery
```

### File Uploads

Local disk via Active Storage. Files served through controller — Pundit authorizes before serving.

### i18n

Locale priority: `current_user.locale` → `Accept-Language` header → `:es`.
All visible text via `t()`. All dates via `l()`. Translation keys always in English.

```ruby
redirect_to @request, notice: t("flash.request_submitted")
l @request.created_at, format: :long
```

## Coding Patterns

### ERB + Daisy UI

Daisy UI classes directly in ERB. Extract partials — not components, not helpers.
Views should be 5-15 lines. Logic belongs in models and controllers.

**Page structure:**
```erb
<%= render "shared/page_header", title: t("nav.requests") %>
<%# or with actions: %>
<%= render "shared/page_header", title: t("nav.requests"),
      actions: render("shared/new_button", path: new_request_path) %>
```

**Card:**
```erb
<div class="card bg-base-100 shadow">
  <div class="card-body">
    <h2 class="card-title"><%= @request.subject %></h2>
    <p class="text-base-content/70 text-sm"><%= l @request.created_at, format: :short %></p>
    <div class="card-actions justify-end">
      <%= link_to t("actions.view"), request_path(@request), class: "btn btn-primary btn-sm" %>
    </div>
  </div>
</div>
```

**Table:**
```erb
<div class="overflow-x-auto">
  <table class="table bg-base-100 rounded-box shadow">
    <thead>
      <tr>
        <th><%= t("requests.subject") %></th>
        <th><%= t("requests.status_label") %></th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <%= render @requests %>
    </tbody>
  </table>
</div>
```

**Status badge:**
```erb
<span class="badge <%= request_status_badge(@request.status) %>">
  <%= t("requests.status.#{@request.status}") %>
</span>
```

**Form:**
```erb
<div class="card bg-base-100 shadow max-w-2xl">
  <div class="card-body">
    <%= form_with model: @request do |f| %>
      <div class="form-control mb-4">
        <%= f.label :subject, class: "label" %>
        <%= f.text_field :subject, class: "input input-bordered w-full" %>
      </div>
      <div class="card-actions justify-end">
        <%= f.submit t("actions.save"), class: "btn btn-primary" %>
      </div>
    <% end %>
  </div>
</div>
```

### Forms

Standard `form_with`. Server-side validation. On failure: `render :new, status: :unprocessable_entity`.

```erb
<%= form_with model: @request do |f| %>
  <%= f.text_field :subject, class: "input input-bordered w-full" %>
  <%= f.submit t("actions.save"), class: "btn btn-primary" %>
<% end %>
```

### Mutations

`button_to` for state changes. No `fetch()`, no `axios`.

```erb
<%= button_to t("actions.submit"), submit_request_path(@request), method: :patch, class: "btn btn-primary" %>
```

### Turbo Frames

Use `dom_id` for all Turbo Frame ids — never hand-craft strings.

```erb
<%= turbo_frame_tag dom_id(@request, :status) do %>
  <span class="badge badge-warning"><%= t("requests.status.#{@request.status}") %></span>
<% end %>
```

### Turbo Stream responses

```ruby
def create
  @message = @conversation.messages.create!(message_params)

  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @conversation }
  end
end
```

### Turbo morphing

Add to application layout:

```erb
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
```

### Controllers

Thin controllers. Pundit on every action. `.kept` on every query.

```ruby
def show
  @request = HomologationRequest.kept.find(params[:id])
  authorize @request
end

def index
  @requests = policy_scope(HomologationRequest).kept.includes(:user).order(updated_at: :desc)
end
```

### CRUD routing

When an action doesn't map to CRUD, introduce a new resource — not a custom action.

```ruby
# Bad
resources :requests do
  post :confirm_payment
  post :archive
end

# Good
resources :requests do
  resource :payment_confirmation
  resource :archival
end
```

### DB constraints

Rails validations can be bypassed. DB constraints cannot. Every migration must have:

```ruby
add_column :users, :email, :string, null: false
add_index  :users, :email, unique: true
add_foreign_key :homologation_requests, :users
add_check_constraint :homologation_requests,
  "status IN ('draft','submitted','in_review','awaiting_reply','awaiting_payment','payment_confirmed','in_progress','resolved','closed')",
  name: "valid_status"
```

### Soft delete

```ruby
scope :kept, -> { where(discarded_at: nil) }
```

Never hard delete. GDPR deletion = encrypt or nullify PII, keep the record.

## Code Style

### Invocation order

Order private methods top-to-bottom by how they are called.

```ruby
def submit!
  validate_documents
  transition_to_submitted
end

private
  def validate_documents; end
  def transition_to_submitted; end
```

### Visibility modifiers

No newline under `private`. Indent methods beneath it.

```ruby
private
  def normalize_phone(number)
    number.gsub(/\D/, "")
  end
```

Exception: modules with only private methods — `private` at top, newline after, no indent.

```ruby
module User::Notifications
  private

  def notify_by_email(message) = ...
  def notify_by_telegram(message) = ...
end
```

### Bang methods

Only use `!` when a non-bang counterpart exists.

```ruby
def transition_to!(new_status, changed_by:)
  raise InvalidTransition unless valid_transition?(new_status)
  update!(status: new_status, last_changed_by: changed_by)
end
```

### Async jobs

Shallow jobs that delegate to the model. `_later` enqueues, `_now` runs synchronously.

```ruby
module HomologationRequest::StatusNotifications
  extend ActiveSupport::Concern

  included do
    after_update_commit :deliver_status_notification_later, if: :status_previously_changed?
  end

  def deliver_status_notification_later = NotificationDeliveryJob.perform_later(self)
  def deliver_status_notification_now
    NotificationMailer.status_changed(self).deliver_now
    TelegramNotifier.notify(self) if user.notification_telegram?
  end
end

class NotificationDeliveryJob < ApplicationJob
  def perform(request) = request.deliver_status_notification_now
end
```

## Banned

- `fetch()` / `axios` — use Turbo + `button_to` / `form_with`
- `render json:` — no API mode; use HTML or `turbo_stream`
- `window.location` — use `redirect_to` or Turbo
- Hardcoded strings in views — use `t()`
- Hardcoded URLs in views — use route helpers
- Role checks in views without Pundit — use `policy(@record).action?`
- Skipping `authorize` or `policy_scope`
- ViewComponent / Phlex — use ERB partials
- FactoryBot / Faker in tests — use Rails fixtures (YAML)
