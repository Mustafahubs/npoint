class Document < ActiveRecord::Base
  before_validation :create_unique_identifier, on: :create
  after_update :purge_cloudflare_cache

  validate :contents_must_match_schema
  validates :token, presence: true, uniqueness: true

  belongs_to :user, optional: true

  # 5 years to guess a specific token at 10k attempts/second:
  # log(16, 10000 * 60 * 60 * 24 * 365 * 5) ~= 10.13
  #
  # That's not actually right, because we want something like "number of
  # attempts between guesses which produce ANY document" - you shouldn't be
  # able to brute force and get interesting documents quickly.
  #
  # But it's ok for now. Token-based security is only so strong anyway,
  # since URLs show up in logs and can't be rolled back if leaked.
  TOKEN_LENGTH = 10

  def create_unique_identifier
    begin
      self.token = SecureRandom.hex(TOKEN_LENGTH)
    end while self.class.exists?(:token => token)
  end

  def editable_by_user?(u)
    return true unless user.present?
    u == user
  end

  private

  def contents_must_match_schema
    if schema.present? &&
        schema != [] &&
        !JSON::Validator.validate(schema, contents)
      errors.add(:contents, "does not match schema")
    end
  end

  def purge_cloudflare_cache
    # Only purge if contents changed
    return unless saved_change_to_contents?
    return unless ENV['HOST'].present?

    CloudflareCache.purge_by_prefix("https://api.#{ENV['HOST']}/#{token}")
  end
end
