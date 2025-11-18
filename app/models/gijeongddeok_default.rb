class GijeongddeokDefault < ApplicationRecord
  # 단일 레코드만 존재하도록 보장
  def self.instance
    first_or_create!
  end
end
