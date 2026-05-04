module AvatarHelper
  # Soft pastel base + saturated accent + dark ink — all warm-cream-friendly
  # tones that live next to the SFE coral without clashing.
  AVATAR_PALETTES = [
    { bg: "#FDE6E4", blob: "#E8453C", ink: "#5C0F0A" },  # coral
    { bg: "#FBE9D6", blob: "#E89B3C", ink: "#5C2E0A" },  # amber
    { bg: "#E1ECFD", blob: "#2D7FF9", ink: "#0A2E5C" },  # blue
    { bg: "#E5DDF5", blob: "#7E238B", ink: "#3A0A5C" },  # purple
    { bg: "#D7EBD7", blob: "#3FA86A", ink: "#103C25" },  # green
    { bg: "#F4EFD9", blob: "#B76B00", ink: "#3D2200" },  # ochre
    { bg: "#EFE8E2", blob: "#62625B", ink: "#211922" }   # warm grey
  ].freeze

  AVATAR_SIZES = {
    xs: { px: 28, font: 12 },
    sm: { px: 36, font: 14 },
    md: { px: 48, font: 18 },
    lg: { px: 72, font: 26 },
    xl: { px: 128, font: 44 }
  }.freeze

  def avatar_svg(user, size: :md, extra_class: nil)
    return "".html_safe unless user

    sz       = AVATAR_SIZES.fetch(size.to_sym, AVATAR_SIZES[:md])
    seed     = user.id.to_i.abs
    palette  = AVATAR_PALETTES[seed % AVATAR_PALETTES.size]
    initials = user.initials.to_s.upcase
    label    = user.name.presence || initials

    # Place the decorative blob deterministically around the circle. Golden-angle
    # spacing gives well-distributed positions across the user base.
    angle   = ((seed * 137) + 30) * Math::PI / 180.0
    blob_cx = (24 + 16 * Math.cos(angle)).round(2)
    blob_cy = (24 + 16 * Math.sin(angle)).round(2)

    classes = "rounded-full shrink-0 select-none block #{extra_class}".strip

    (<<~SVG).html_safe
      <svg viewBox="0 0 48 48" width="#{sz[:px]}" height="#{sz[:px]}"
           role="img" aria-label="#{ERB::Util.html_escape(label)}"
           class="#{classes}" xmlns="http://www.w3.org/2000/svg">
        <circle cx="24" cy="24" r="24" fill="#{palette[:bg]}"/>
        <circle cx="#{blob_cx}" cy="#{blob_cy}" r="14" fill="#{palette[:blob]}" opacity="0.32"/>
        <text x="24" y="24" dy="0.35em"
              font-family="Inter Tight, Inter, system-ui, sans-serif"
              font-weight="700" font-size="#{sz[:font]}"
              letter-spacing="-0.4" fill="#{palette[:ink]}"
              text-anchor="middle">#{ERB::Util.html_escape(initials)}</text>
      </svg>
    SVG
  end
end
