require "test_helper"

class QuickReplyTest < ActiveSupport::TestCase
  teardown do
    QuickReply.config_path = nil
    QuickReply.reload!
  end

  test ".categories returns categories with QuickReply items for the given locale" do
    cats = QuickReply.categories(locale: :es)

    assert cats.any?
    assert cats.first.is_a?(Hash)
    assert cats.first[:label].present?
    assert cats.first[:items].first.is_a?(QuickReply)
  end

  test ".categories falls back to the default locale when the requested locale is missing" do
    with_fixture("missing_locale.yml") do
      cats = QuickReply.categories(locale: :ja)

      assert_empty cats
    end
  end

  test "#render interpolates {var} placeholders from the vars hash" do
    reply = QuickReply.new(id: "x", label: "X", body: "Hi {student}, your {plan} costs {amount}.")

    rendered = reply.render(student: "María", plan: "Integral", amount: "1.750 €")

    assert_equal "Hi María, your Integral costs 1.750 €.", rendered
  end

  test "#render leaves unknown placeholders as empty strings" do
    reply = QuickReply.new(id: "x", label: "X", body: "Hi {student} {missing}.")

    assert_equal "Hi María .", reply.render(student: "María")
  end

  test ".reload! drops the cache so the YAML can be edited at runtime" do
    QuickReply.categories(locale: :es) # warm cache
    QuickReply.reload!

    with_fixture("missing_locale.yml") do
      assert_empty QuickReply.categories(locale: :es)
    end
  end

  private
    def with_fixture(name)
      QuickReply.config_path = Rails.root.join("test/fixtures/files/#{name}")
      QuickReply.reload!
      yield
    ensure
      QuickReply.config_path = nil
      QuickReply.reload!
    end
end
