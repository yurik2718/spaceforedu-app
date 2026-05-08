namespace :vapid do
  desc "Generate VAPID keys and print the credentials snippet"
  task generate: :environment do
    vapid = WebPush.generate_key
    puts <<~INSTRUCTIONS
      Add the following to your Rails credentials (run: bin/rails credentials:edit):

      vapid:
        public_key: #{vapid.public_key}
        private_key: #{vapid.private_key}
    INSTRUCTIONS
  end
end
