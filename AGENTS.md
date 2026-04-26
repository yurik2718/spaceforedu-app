# Homologation App

Rails 8 application for international students seeking document-equivalence (homologación) recognition in Spain. Students submit requests, upload documents, and chat with a super admin who shepherds the case through Spanish bureaucracy.

- `homologation.es` — Astro.js landing page (separate repo)
- `app.homologation.es` — this Rails app

## Git rules for AI agents

**Never run `git commit`. Only the human owner commits.** Edit files, run `git status` / `git diff` / `git log`, and `git add` only when explicitly asked. Leave finished work in the working tree and report the diff.

## MVP Scope

Ship and validate the core homologation flow with real students before adding anything else.

**The flow, in order:**

1. Student registers, completes profile, accepts privacy policy
2. Student creates a `HomologationRequest`, fills in details, uploads documents
3. Super admin reviews, changes status, leaves internal notes
4. Student and admin exchange messages in the request's conversation
5. Admin records a Stripe invoice; student pays; admin confirms payment

**Hard rules until step 5 works end-to-end with real users:**

- No new models, tables, or domain concepts without explicit instruction
- No third-party integrations beyond Stripe and Telegram (no OAuth, analytics, S3)
- No roles beyond `super_admin` and `student`
- No Redis, no Sidekiq — Solid Queue is the only background system
- A thin slice that works beats a wide surface that doesn't

**Out of scope:** teachers, coordinators, lessons, study plans, multi-tenancy, organizations, public API, mobile app.

## Tech Stack

- **Rails 8.1** — full-stack, server-rendered (no API mode, no React, no Inertia)
- **Hotwire** — Turbo Drive + Frames + Streams + Stimulus
- **Tailwind CSS 4 + Daisy UI 5** — UI built from Daisy component classes (a deliberate choice on top of omakase Tailwind)
- **Propshaft** + **import maps** — no Sprockets, no webpack/Vite/esbuild
- **SQLite** — primary database; **Solid Queue** (jobs), **Solid Cable** (broadcasts), **Solid Cache** (cache); no Redis
- **Litestream** — continuous SQLite replication to off-box storage; the only backup mechanism. A single-node Docker host means a lost disk is a lost app — the replica is the recovery story.
- **Active Storage** — uploads on local disk, served through controllers
- **Authentication** — Rails 8 `bin/rails generate authentication` (no Devise, no OAuth)
- **Authorization** — Pundit, two roles only: `super_admin`, `student`
- **Pagination** — Pagy
- **Payments** — Stripe (`stripe` gem; admin records invoices, student pays, signed webhook confirms)
- **Notifications** — in-app Turbo Streams + email (Action Mailer; SMTP in production, `letter_opener` in development) + Telegram Bot API (raw HTTP)
- **i18n** — `es` (default), `en`, `ru`; translation keys in English; `rails-i18n` for locale data
- **Secrets** — Rails encrypted credentials (`config/credentials/<env>.yml.enc`), keyed per environment. No secrets in ENV in dev or prod beyond `RAILS_MASTER_KEY`.
- **Deployment** — Kamal + Thruster, single-node Docker
- **Safety nets** — `strong_migrations` (block dangerous migrations), `rack-attack` (auth + webhook rate limits), `bullet` (dev N+1), `bundler-audit` + `brakeman` (CI)
- **Testing** — Minitest + Capybara + Selenium + Rails fixtures + `webmock` for Stripe/Telegram

## Commands

```bash
bin/setup    # install gems, create DB, migrate, seed
bin/dev      # Puma + Tailwind watcher + hotwire-spark hot reload
bin/ci       # rubocop → bundler-audit → importmap audit → brakeman → tests → system tests
```

Run `bin/ci` before every commit. CI is wired through `config/ci.rb` (`ActiveSupport::ContinuousIntegration`).

```bash
bin/rails test test/path/file_test.rb
bin/rails test:system
bin/rails db:migrate
bin/rails db:seed         # creates super_admin admin@example.com (see db/seeds.rb)
bin/rails db:reset
```

Outbound mail in development opens in the browser via `letter_opener`.

## Architecture

### Authentication

Rails 8 built-in auth generator. Tables: `users`, `sessions`. `has_secure_password` on `User`. Login uses `email_address` (not `email`). Password reset via Action Mailer + signed token.

### Current attributes

`Current.session` is set per request by the `Authentication` concern; `Current.user` is delegated through it. Reach for `Current.user` in models that genuinely need actor context (audit columns, broadcasts). Don't pass `current_user` through five layers of method signatures.

### Roles

Single `role` string column on `users`, enforced by a DB check constraint.

| Role          | Root path     | Purpose                                                  |
|---------------|---------------|----------------------------------------------------------|
| `super_admin` | `/dashboard`  | Reviews requests, runs payments, manages users           |
| `student`     | `/requests`   | Submits requests, uploads documents, chats with admin    |

`authorize @record` in every controller action. `policy_scope` in every index. No role checks in views — call `policy(@record).action?`.

### Domain models

**User** — all roles in one table.
- `role` enforced by check constraint (`super_admin` or `student`)
- `discarded_at` for soft delete (always query through `.kept`)
- Encrypted PII (Active Record encryption): `phone`, `whatsapp`, `guardian_phone`, `guardian_whatsapp`
- Minor support: `is_minor`, `guardian_name`, `guardian_email`
- Telegram opt-in: `telegram_chat_id`, `telegram_link_token`, `notification_telegram`
- GDPR: `deletion_requested_at` flags a pending erasure; the row is kept, PII is nullified or re-encrypted, `discarded_at` is set.

**HomologationRequest** — core model. Status flow:

```
draft → submitted → in_review ⇄ awaiting_reply → awaiting_payment
       → payment_confirmed → in_progress → resolved | closed
```

The DB check constraint enforces the *set* of valid statuses. Allowed *transitions* are policed inside `transition_to!(new_status, changed_by:)` — that is the only sanctioned write path. Never `update(status: ...)` directly. Add a new edge in `transition_to!`, not at the call site. Audit columns `status_changed_by` / `status_changed_at` are written by the same method; `payment_confirmed_by` / `payment_confirmed_at` are written by `confirm_payment!`.

Soft delete via `discarded_at`. Always query through `.kept`.

Three Active Storage attachments:
- `application_file` — `has_one_attached`, the official application PDF
- `originals` — `has_many_attached`, original certificates/diplomas
- `documents` — `has_many_attached`, supporting paperwork

**Conversation** — one per `HomologationRequest`. `last_message_at` for ordering. `student_last_read_at` and `admin_last_read_at` columns drive unread counts (no join table).

**Message** — `belongs_to :conversation`, `belongs_to :user`, `has_many_attached :attachments`. Broadcasts via `after_create_commit`.

**Notification** — in-app, polymorphic on `notifiable` (`notifiable_type` / `notifiable_id`; today: `HomologationRequest`, `Message`). Broadcasts via Turbo Streams on create. Delivered async to email and Telegram via `NotificationDeliveryJob`. `read_at` and `emailed_at` track delivery.

### Real-time

No polling. No custom WebSocket code. Turbo Streams + Action Cable + Solid Cable.

```erb
<%= turbo_stream_from @conversation %>
<div id="messages"><%= render @messages %></div>
```

```ruby
class Message < ApplicationRecord
  after_create_commit -> { broadcast_append_to conversation }
end
```

### Background jobs

```
NotificationDeliveryJob   # email + Telegram fan-out
```

Solid Queue runs in-process; surfaced via Mission Control in production.

### File uploads

Local disk via Active Storage. All downloads go through a controller that calls `authorize` before serving the blob. Never expose `rails_blob_url` or `rails_blob_path` to authenticated users — those URLs leak access.

### Stripe

The `stripe` gem talks to Stripe directly. The webhook endpoint verifies the signature with `Stripe::Webhook.construct_event` against the secret in credentials; an unsigned, malformed, or replayed payload is dropped before any database write. Webhook handlers are idempotent — keyed on the event id — so retries are safe. `webmock` stubs Stripe in tests; the network is never hit.

### i18n

Locale priority: `current_user.locale` → `Accept-Language` → `:es`. All visible text via `t()`, all dates via `l()`. Translation keys are in English.

```ruby
redirect_to @request, notice: t("flash.request_submitted")
l @request.created_at, format: :long
```

### Deployment

Kamal deploys a single Docker image. Thruster fronts Puma for asset caching, compression, and X-Sendfile. SQLite, Solid Queue, Solid Cable, Solid Cache, and Active Storage all live on the same disk. Litestream replicates the SQLite files continuously off-box; the replica is the disaster-recovery story.

## Coding Patterns

### ERB + Daisy UI

Daisy classes directly in ERB. Extract a partial when something repeats — no view components, no presenters, no decorators. Logic belongs in models and controllers; views read like the page they render.

Helpers are reserved for view-only formatting that takes a value and returns a string (an icon name, a date band). Anything that needs the database, the current user, or a method chain longer than two stops belongs on the model. View-only data *about* a record (the CSS class for a status, a humanized label) lives on the model so views stay declarative.

**Page header:**
```erb
<%= render "shared/page_header", title: t("nav.requests") %>
```

**Card:**
```erb
<div class="card bg-base-100 shadow">
  <div class="card-body">
    <h2 class="card-title"><%= @request.subject %></h2>
    <p class="text-base-content/70 text-sm"><%= l @request.created_at, format: :short %></p>
    <div class="card-actions justify-end">
      <%= link_to t("actions.view"), @request, class: "btn btn-primary btn-sm" %>
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

**Status badge** — CSS class lives on the model:
```erb
<span class="badge <%= @request.status_badge_class %>">
  <%= t("requests.status.#{@request.status}") %>
</span>
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

`button_to` for state changes. Never `fetch()`, never `axios`.

```erb
<%= button_to t("actions.submit"), submit_request_path(@request),
      method: :patch, class: "btn btn-primary" %>
```

### Turbo frames

Always use `dom_id` for frame ids — never hand-roll strings.

```erb
<%= turbo_frame_tag dom_id(@request, :status) do %>
  <span class="badge"><%= t("requests.status.#{@request.status}") %></span>
<% end %>
```

### Turbo stream responses

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

In the application layout:

```erb
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
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
  resource :payment_confirmation, only: %i[create]
  resource :archival,             only: %i[create destroy]
end
```

### Controllers

Thin. Pundit on every action. `.kept` on every query. Pagy on every index that can grow.

```ruby
def show
  @request = HomologationRequest.kept.find(params[:id])
  authorize @request
end

def index
  scope = policy_scope(HomologationRequest).kept.includes(:user).order(updated_at: :desc)
  @pagy, @requests = pagy(scope)
end
```

### DB constraints

Rails validations can be bypassed. DB constraints cannot. Every migration ships with the right `null:`, indexes, foreign keys, and check constraints. `strong_migrations` blocks anything dangerous in CI.

```ruby
add_column :users, :email_address, :string, null: false
add_index  :users, :email_address, unique: true
add_foreign_key :homologation_requests, :users
add_check_constraint :homologation_requests,
  "status IN ('draft','submitted','in_review','awaiting_reply','awaiting_payment','payment_confirmed','in_progress','resolved','closed')",
  name: "valid_status"
```

### Soft delete

```ruby
scope :kept, -> { where(discarded_at: nil) }
```

Never hard-delete records that have downstream history (users, requests, messages, payments). GDPR deletion = nullify or re-encrypt PII, set `discarded_at`, keep the row.

### Rate limiting

`Rack::Attack` throttles login, password reset, registration, and the Stripe webhook endpoint. Rules live in `config/initializers/rack_attack.rb`. Every new authentication-adjacent endpoint gets a throttle.

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

Exception: modules where everything is private — `private` at top, blank line, no indent.

```ruby
module User::Notifications
  private

  def notify_by_email(message) = ...
  def notify_by_telegram(message) = ...
end
```

### Bang methods

Use `!` only when (a) a non-bang counterpart exists, or (b) the method is a stricter version of a Rails idiom that follows the convention itself (`update!`, `save!`, `find_by!`). Don't decorate methods with `!` for emphasis.

### Concerns

Break large models into concerns under `app/models/<model>/`. One concern, one behavior — `HomologationRequest::StatusNotifications`, not `HomologationRequest::Helpers`. Wire them in with `include` at the top of the model.

### Async jobs

Jobs are shallow and delegate to the model. `_later` enqueues, `_now` runs synchronously.

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

## Testing

- Minitest for unit, controller, integration, and mailer tests
- Capybara + Selenium for system tests covering the 5 MVP flow steps
- Rails fixtures (YAML) — no FactoryBot, no Faker
- `webmock` stubs Stripe and Telegram in tests; never hit the network
- Tests run in parallel by default; fixtures are written to be parallel-safe
- `bin/rails test` for unit/controller; `bin/rails test:system` for system; `bin/ci` runs everything

Every controller action gets a controller test. Every Pundit policy gets a policy test. Every Turbo Stream broadcast gets a system test that watches the DOM update.

## Banned

- `fetch()` / `axios` — use Turbo + `button_to` / `form_with`
- `render json:` outside the Stripe webhook controller — no API mode; respond with HTML or `turbo_stream`
- `window.location` — use `redirect_to` or Turbo
- Hardcoded strings in views — use `t()`
- Hardcoded URLs in views — use route helpers (`@request`, `request_path`)
- Role checks in views without Pundit — use `policy(@record).action?`
- Skipping `authorize` or `policy_scope` in any controller action
- ViewComponent / Phlex — use ERB partials
- Service objects, presenters, decorators, query objects, form objects — put it on the model
- FactoryBot / Faker — use Rails fixtures
- `update_column` / `update_columns` / `update_all` / `delete_all` — bypasses callbacks, validations, and soft delete
- Hard-deleting `User`, `HomologationRequest`, `Message`, or payment rows
- Writing `status` directly — go through `transition_to!`
- New `app/javascript/` files for behavior expressible as a Stimulus controller
- Secrets in ENV beyond `RAILS_MASTER_KEY` — use Rails encrypted credentials
