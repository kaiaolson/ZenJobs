class User < ActiveRecord::Base
  has_secure_password
  acts_as_messageable
  before_create :generate_api_key

  has_many :info_requests
  has_many :submissions

  has_many :relationships, dependent: :destroy
  has_many :clients, through: :relationships, source: :relation
  has_many :inverse_relationships, class_name: "Relationship", foreign_key: "relation_id"
  has_many :consultants, through: :inverse_relationships, source: :user

  has_many :team_memberships, dependent: :nullify
  has_many :teams, through: :team_memberships

  validates :password, presence: true, length: {minimum: 6}, on: :create
  validates :first_name, presence: true, on: :create
  validates :last_name, presence: true, on: :create
  validates :email, presence: true, uniqueness: true,
            format:  /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  def full_name
    "#{first_name} #{last_name}"
  end

  def mailboxer_email(object)
    #Check if an email should be sent for that object
    #if true
    email
    #if false
    #return nil
  end

  def client_names
    clients.map do |client|
      client.full_name
    end
  end

  def consultant?
    role.downcase == "consultant" if role
  end

  def client?
    role.downcase == "client" if role
  end

  def info_requests
    if client?
      InfoRequest.includes(:relationship).where(relationships: {relation_id: self.id})
    else
      InfoRequest.where(user_id: self).order(:id)
    end
  end

  def submissions
    if consultant?
      Submission.includes(:relationship).where(relationships: {user_id: self.id})
    else
      Submission.where(user_id: self).order(:id)
    end
  end

  def pending_requests_count
    info_requests.where(completed: false).count
  end

  def pending_submissions_count
    submissions.where(completed: false).count
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  private

  def generate_api_key
    self.api_key = SecureRandom.hex(32)
    while User.exists?(api_key: self.api_key)
      self.api_key = SecureRandom.hex(32)
    end
  end
end
