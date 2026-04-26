# bin/rails db:seed
# Fresh database assumed: bin/rails db:schema:load db:seed

# ─────────────────────────────────────────────────────────────
# Admin
# ─────────────────────────────────────────────────────────────

admin = User.find_or_create_by!(email_address: "admin@spaceforedu.com") do |u|
  u.name                = "Carlos Herrera"
  u.role                = "super_admin"
  u.locale              = "es"
  u.country             = "ES"
  u.privacy_accepted_at = 1.year.ago
  u.password            = "password"
end

# ─────────────────────────────────────────────────────────────
# Students
# ─────────────────────────────────────────────────────────────

maria = User.find_or_create_by!(email_address: "maria.gonzalez@gmail.com") do |u|
  u.name                = "María González"
  u.locale              = "es"
  u.country             = "AR"
  u.birthday            = Date.new(1995, 3, 12)
  u.phone               = "+54 9 11 2345-6789"
  u.whatsapp            = "+54 9 11 2345-6789"
  u.privacy_accepted_at = 3.months.ago
  u.password            = "password"
end

ivan = User.find_or_create_by!(email_address: "ivan.petrov@mail.ru") do |u|
  u.name                = "Ivan Petrov"
  u.locale              = "ru"
  u.country             = "RU"
  u.birthday            = Date.new(1990, 7, 24)
  u.phone               = "+7 916 123-45-67"
  u.whatsapp            = "+7 916 123-45-67"
  u.privacy_accepted_at = 6.weeks.ago
  u.password            = "password"
end

alejandro = User.find_or_create_by!(email_address: "alejandro.ruiz@hotmail.com") do |u|
  u.name                = "Alejandro Ruiz"
  u.locale              = "es"
  u.country             = "MX"
  u.birthday            = Date.new(1988, 11, 5)
  u.phone               = "+52 55 1234-5678"
  u.whatsapp            = "+52 55 1234-5678"
  u.privacy_accepted_at = 2.months.ago
  u.password            = "password"
end

# Minor — guardian fields required
lucia = User.find_or_create_by!(email_address: "lucia.fernandez@gmail.com") do |u|
  u.name                = "Lucía Fernández"
  u.locale              = "es"
  u.country             = "CO"
  u.birthday            = Date.new(2009, 2, 18)
  u.is_minor            = true
  u.guardian_name       = "Pedro Fernández"
  u.guardian_email      = "pedro.fernandez@gmail.com"
  u.guardian_phone      = "+57 310 987-6543"
  u.guardian_whatsapp   = "+57 310 987-6543"
  u.privacy_accepted_at = 1.month.ago
  u.password            = "password"
end

olga = User.find_or_create_by!(email_address: "olga.smirnova@yandex.ru") do |u|
  u.name                  = "Olga Smirnova"
  u.locale                = "ru"
  u.country               = "RU"
  u.birthday              = Date.new(1985, 9, 30)
  u.phone                 = "+7 495 987-65-43"
  u.privacy_accepted_at   = 4.months.ago
  u.notification_telegram = true
  u.password              = "password"
end

puts "Users: #{User.count}"

# ─────────────────────────────────────────────────────────────
# Homologation requests
# ─────────────────────────────────────────────────────────────

# Draft — María just started, hasn't submitted yet
HomologationRequest.find_or_create_by!(user: maria, subject: "Licenciatura en Psicología") do |r|
  r.service_type     = "homologation"
  r.description      = "Quiero homologar mi título de Licenciatura en Psicología obtenido en la Universidad de Buenos Aires."
  r.status           = "draft"
  r.education_system = "Argentina"
  r.university       = "Universidad de Buenos Aires"
  r.year             = 2018
  r.studies_finished = "yes"
  r.privacy_accepted = true
end

# Awaiting payment — Ivan reviewed, budget sent, waiting on wire transfer
ivan_request = HomologationRequest.find_or_create_by!(user: ivan, subject: "Диплом инженера-механика") do |r|
  r.service_type       = "homologation"
  r.description        = "Diploma de Ingeniería Mecánica expedido por la Universidad Técnica Estatal de Moscú (BMSTU)."
  r.status             = "awaiting_payment"
  r.status_changed_at  = 2.days.ago
  r.status_changed_by  = admin.id
  r.payment_amount     = 350.00
  r.education_system   = "Russia"
  r.university         = "Bauman Moscow State Technical University"
  r.year               = 2012
  r.studies_finished   = "yes"
  r.language_knowledge = "B2"
  r.privacy_accepted   = true
end

ivan_conv = Conversation.find_or_create_by!(homologation_request: ivan_request)
if ivan_conv.messages.none?
  ivan_conv.messages.create!(user: admin, body: "Buenos días Ivan. Hemos revisado tu expediente. El presupuesto para la homologación de tu título de Ingeniería Mecánica asciende a 350 €. Por favor realiza el pago en los próximos cinco días hábiles.", created_at: 2.days.ago)
  ivan_conv.messages.create!(user: ivan,  body: "Muchas gracias. Haré el pago esta semana.", created_at: 1.day.ago)
  ivan_conv.update!(last_message_at: 1.day.ago)

  ivan.notifications.create!(notifiable: ivan_request, title: "Presupuesto listo — 350 €", body: "Hemos revisado tu solicitud. Realiza el pago para continuar.", created_at: 2.days.ago)
end

# In progress — Alejandro paid, pipeline at redsara, one stage retreated earlier
alejandro_request = HomologationRequest.find_or_create_by!(user: alejandro, subject: "Licenciatura en Administración de Empresas") do |r|
  r.service_type         = "homologation"
  r.description          = "Título universitario en Administración de Empresas expedido por el Tecnológico de Monterrey, Campus Ciudad de México."
  r.status               = "in_progress"
  r.status_changed_at    = 3.weeks.ago
  r.status_changed_by    = admin.id
  r.pipeline_stage       = "redsara"
  r.pipeline_changed_at  = 4.days.ago
  r.pipeline_changed_by  = admin.id
  r.pipeline_notes       = "Retrocedemos a tasas_volantes: el modelo 790 estaba sin firmar. Corregido y avanzamos de nuevo."
  r.payment_amount       = 420.00
  r.payment_confirmed_at = 3.weeks.ago
  r.payment_confirmed_by = admin.id
  r.education_system     = "Mexico"
  r.university           = "Tecnológico de Monterrey"
  r.year                 = 2015
  r.studies_finished     = "yes"
  r.language_knowledge   = "C1"
  r.document_checklist   = { "sol" => true, "vol" => true, "tas" => true, "cer" => true, "tit" => false }
  r.privacy_accepted     = true
end

alejandro_conv = Conversation.find_or_create_by!(homologation_request: alejandro_request)
if alejandro_conv.messages.none?
  alejandro_conv.messages.create!(user: admin,    body: "Alejandro, hemos confirmado tu pago. Arrancamos con la tramitación. Te iremos informando de cada avance.", created_at: 3.weeks.ago)
  alejandro_conv.messages.create!(user: alejandro, body: "Perfecto, muchas gracias. Quedo atento.", created_at: 3.weeks.ago + 4.hours)
  alejandro_conv.messages.create!(user: admin,    body: "Tu solicitud ya ha sido presentada en RedSARA. El plazo ministerial es de cuatro a ocho meses; te avisamos en cuanto haya resolución.", created_at: 4.days.ago)
  alejandro_conv.update!(last_message_at: 4.days.ago, admin_last_read_at: 4.days.ago)

  alejandro.notifications.create!(notifiable: alejandro_request, title: "Solicitud presentada en RedSARA", body: "Tu expediente ha sido presentado ante el Ministerio.", read_at: 3.days.ago, created_at: 4.days.ago)
end

# Awaiting reply — pipeline retreated to documentos, missing apostille on Lucia's certificate
lucia_request = HomologationRequest.find_or_create_by!(user: lucia, subject: "Bachillerato Internacional") do |r|
  r.service_type         = "homologation"
  r.description          = "Homologación de Bachillerato Internacional para acceso a estudios universitarios en España."
  r.status               = "awaiting_reply"
  r.status_changed_at    = 1.week.ago
  r.status_changed_by    = admin.id
  r.pipeline_stage       = "documentos"
  r.pipeline_changed_at  = 1.week.ago
  r.pipeline_changed_by  = admin.id
  r.pipeline_notes       = "Retrocedemos a documentos: el certificado de notas carece de apostilla. Pendiente de que el tutor lo gestione desde Colombia."
  r.payment_amount       = 250.00
  r.payment_confirmed_at = 2.weeks.ago
  r.payment_confirmed_by = admin.id
  r.education_system     = "Colombia"
  r.university           = "Colegio Anglo Colombiano"
  r.year                 = 2024
  r.studies_finished     = "yes"
  r.privacy_accepted     = true
end

lucia_conv = Conversation.find_or_create_by!(homologation_request: lucia_request)
if lucia_conv.messages.none?
  lucia_conv.messages.create!(user: admin, body: "Hola Pedro (tutor de Lucía). El certificado de notas que habéis enviado no está apostillado. Sin la apostilla no podemos continuar. Por favor, gestionadlo y reenviadlo cuando lo tengáis.", created_at: 1.week.ago)
  lucia_conv.messages.create!(user: lucia, body: "Mi padre ya está gestionando la apostilla. Nos han dicho que tardará unos diez días.", created_at: 1.week.ago + 6.hours)
  lucia_conv.update!(last_message_at: 1.week.ago + 6.hours, admin_last_read_at: 1.week.ago + 1.day)

  lucia.notifications.create!(notifiable: lucia_request, title: "Documento pendiente", body: "Necesitamos el certificado de notas apostillado para continuar.", created_at: 1.week.ago)
end

# Resolved — Olga's homologation successfully completed after a full pipeline run
olga_request = HomologationRequest.find_or_create_by!(user: olga, subject: "Licenciatura en Filología Española") do |r|
  r.service_type         = "homologation"
  r.description          = "Título de Filología Española y Latinoamericana expedido por la Universidad Estatal de Moscú (MSU)."
  r.status               = "resolved"
  r.status_changed_at    = 2.months.ago
  r.status_changed_by    = admin.id
  r.pipeline_stage       = "completado"
  r.pipeline_changed_at  = 2.months.ago
  r.pipeline_changed_by  = admin.id
  r.payment_amount       = 380.00
  r.payment_confirmed_at = 9.months.ago
  r.payment_confirmed_by = admin.id
  r.education_system     = "Russia"
  r.university           = "Moscow State University"
  r.year                 = 2007
  r.studies_finished     = "yes"
  r.language_knowledge   = "C2"
  r.language_certificate = "DELE C2"
  r.document_checklist   = { "sol" => true, "vol" => true, "tas" => true, "cer" => true, "tit" => true }
  r.privacy_accepted     = true
end

olga_conv = Conversation.find_or_create_by!(homologation_request: olga_request)
if olga_conv.messages.none?
  olga_conv.messages.create!(user: admin, body: "Buenas noticias, Olga. El Ministerio ha resuelto favorablemente tu solicitud. Recibirás la resolución oficial en los próximos días.", created_at: 2.months.ago)
  olga_conv.messages.create!(user: olga,  body: "Muchísimas gracias a todo el equipo. Ha sido un proceso largo pero ha valido la pena.", created_at: 2.months.ago + 3.hours)
  olga_conv.update!(last_message_at: 2.months.ago + 3.hours, admin_last_read_at: 2.months.ago + 1.day, student_last_read_at: 2.months.ago + 3.hours)

  olga.notifications.create!(notifiable: olga_request, title: "Homologación resuelta favorablemente", body: "El Ministerio ha resuelto tu homologación. Enhorabuena.", read_at: 2.months.ago + 3.hours, created_at: 2.months.ago)
end

puts "Requests:      #{HomologationRequest.count}"
puts "Conversations: #{Conversation.count}"
puts "Messages:      #{Message.count}"
puts "Notifications: #{Notification.count}"
puts "Done."
