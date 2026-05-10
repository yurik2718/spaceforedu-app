require "test_helper"

class HomologationRequestCheckoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:student_es)
    @other = users(:student_other)
    @hr    = homologation_requests(:awaiting_payment) # owner: student_es, status: awaiting_payment, plan: completo (1750 €)

    @fake_session = Struct.new(:url).new("https://checkout.stripe.com/c/pay/cs_test_123")
  end

  test "owner with awaiting_payment status is redirected to the Stripe Checkout URL" do
    sign_in_as @owner

    stub_stripe_session(@fake_session) do
      post homologation_request_checkout_path(@hr)
    end

    assert_redirected_to @fake_session.url
  end

  test "non-owner is rejected" do
    sign_in_as @other

    post homologation_request_checkout_path(@hr)

    assert_redirected_to root_path
  end

  test "owner whose request is not in awaiting_payment is rejected" do
    sign_in_as @owner
    draft = @owner.homologation_requests.create!(
      subject: "draft", plan_key: "basico", status: "draft", privacy_accepted: true
    )

    post homologation_request_checkout_path(draft)

    assert_redirected_to root_path
  end

  test "unauthenticated request is redirected to sign in" do
    post homologation_request_checkout_path(@hr)
    assert_redirected_to new_session_path
  end

  test "owner whose request is already paid cannot start a new checkout" do
    sign_in_as @owner
    @hr.update_column(:status, "payment_confirmed")

    post homologation_request_checkout_path(@hr)

    assert_redirected_to root_path
  end

  test "discarded request is treated as not found" do
    sign_in_as @owner
    @hr.update_column(:discarded_at, Time.current)

    post homologation_request_checkout_path(@hr)

    assert_response :not_found
  end

  test "super admin cannot start a checkout on behalf of the owner" do
    sign_in_as users(:admin)

    post homologation_request_checkout_path(@hr)

    assert_redirected_to root_path
  end

  private
    def stub_stripe_session(fake)
      klass = Stripe::Checkout::Session
      klass.singleton_class.alias_method(:__orig_create, :create)
      klass.define_singleton_method(:create) { |*| fake }
      yield
    ensure
      klass.singleton_class.alias_method(:create, :__orig_create)
      klass.singleton_class.remove_method(:__orig_create)
    end
end
