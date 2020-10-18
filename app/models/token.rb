require 'securerandom'

class Token < ApplicationRecord
  def self.gen_token
    Token.create(token: SecureRandom.hex(35))
  end
end
