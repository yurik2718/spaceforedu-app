# frozen_string_literal: true

# Heroicons (https://heroicons.com) via the `heroicons` gem.
#
# Project convention:
#   • :solid (24×24, filled) — feature/hero icons inside larger circles or cards
#   • :mini  (20×20, filled) — default for buttons, list rows, inline UI
#   • :micro (16×16, filled) — tight UI (badges, dense table cells)
#   • :outline                — only when explicitly decorative
#
# Sizes are passed per-call as Tailwind classes (`w-5 h-5`, etc.) — no
# default_class so cascade order stays predictable when callers override.

Heroicon.configure do |config|
  config.variant = :mini
end
