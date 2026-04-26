class Session < ApplicationRecord
  belongs_to :user, strict_loading: false
end
