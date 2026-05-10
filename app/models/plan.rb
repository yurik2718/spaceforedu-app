# Source of truth for plan pricing. Mirrors spaceforedu-astra's pricing.astro.
# Price changes here = deploy. No admin UI, no DB row.
class Plan
  PRICES = {
    "basico"   => 500,
    "completo" => 1750,
    "premium"  => 2250
  }.freeze

  KEYS = PRICES.keys.freeze

  attr_reader :key

  def initialize(key)
    raise ArgumentError, "Unknown plan: #{key.inspect}" unless PRICES.key?(key.to_s)
    @key = key.to_s
  end

  def self.all          = KEYS.map { new(_1) }
  def self.find(key)    = new(key)

  def amount     = PRICES.fetch(key)
  def title      = I18n.t("plans.#{key}.title")
  def short_desc = I18n.t("plans.#{key}.short_desc", default: "")
end
