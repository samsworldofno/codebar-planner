class Event < ActiveRecord::Base
  include Listable
  include Invitable

  attr_accessor :begins_at
  resourcify :permissions, role_cname: 'Permission', role_table_name: :permission

  belongs_to :venue, class_name: 'Sponsor'
  has_many :sponsorships
  has_many :sponsors, through: :sponsorships
  has_many :organisers, -> { where("permissions.name" => "organiser") }, through: :permissions, source: :members

  has_and_belongs_to_many :chapters

  has_many :invitations

  validates :name, :slug, :info, :schedule, :description, :coach_description, presence: true

  validate :invitability, if: :invitable?

  attr_accessor :publish_day, :publish_time

  before_save do
    begins_at = Time.parse(self.begins_at)
    self.date_and_time = self.date_and_time.change(hour: begins_at.hour, minute: begins_at.min)
  end

  def to_s
    self.name
  end

  def to_param
    self.slug
  end

  def verified_coaches
    invitations.coaches.accepted.verified.map(&:member)
  end

  def verified_students
    invitations.students.accepted.verified.map(&:member)
  end

  def coach_spaces?
    coach_spaces > attending_coaches.count
  end

  def student_spaces?
    student_spaces > attending_students.count
  end

  def date
    I18n.l(date_and_time, format: :dashboard)
  end

  def update_date_and_time
    self.date_and_time = date_and_time.change(hour: time.hour, min: time.min)
  end

  def invitability
      errors.add(:coach_questionnaire, "must be set") unless self.coach_questionnaire.present?
      errors.add(:student_questionnaire, "must be set") unless self.student_questionnaire.present?
      errors.add(:coach_spaces, "must be set") unless self.coach_spaces.present?
      errors.add(:student_space, "must be set") unless self.student_spaces.present?
      errors.add(:chapters, "at least one must be selected") unless self.chapters.any?
      errors.add(:invitable, "Fill in all invitations details to make the event invitable") unless self.coach_questionnaire.present? and self.student_questionnaire.present? and self.coach_spaces.present? and self.student_spaces.present? and self.chapters.any?
  end

end
