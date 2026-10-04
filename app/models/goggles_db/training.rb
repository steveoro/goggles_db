# frozen_string_literal: true

module GogglesDb
  #
  # = Training model
  #
  #   - version:  7-0.10.53
  #   - author:   Devin for Steve A.
  #
  # Reuses the (previously unused) legacy `trainings` table to store "Creative trainings":
  # a photo gallery of training sheets/workout images uploaded by operators through the
  # remote API (typically by means of the Admin2 app).
  #
  # Each row binds an attached +picture+ (ActiveStorage) to the metadata that the
  # operator supplies at upload time:
  #
  # - +training_date+: actual session date picked by the operator (defaults to current date);
  # - +training_by+:   free text naming who ran the training;
  # - +created_by+:    free text naming the picture/workout author;
  # - +swimmer+:       optional Swimmer reference used by consumers to link the "created by"
  #                    label to the Swimmer page;
  # - +description+:   optional text content of the training itself;
  # - +title+:         auto-composed as "<iso_date> <created_by>" (+ " #n" dedupe suffix),
  #                    still constrained by the legacy unique index.
  #
  # No training_rows are ever created for these rows.
  #
  class Training < ApplicationRecord
    self.table_name = 'trainings'

    belongs_to :swimmer, optional: true
    validates_associated :swimmer

    has_one_attached :picture

    validates :training_date, presence: true
    validates :training_by, presence: true, length: { maximum: 100 }
    validates :created_by, presence: true, length: { maximum: 100 }
    validates :title, presence: true, uniqueness: true, length: { maximum: 100 }
    validate  :picture_content_type

    before_validation :build_title, on: :create

    # Sorting scope:
    scope :by_date, ->(dir = :asc) { order(training_date: dir) }

    # Filtering scopes:
    scope :for_date, ->(date) { where(training_date: date.all_day) }

    # Only rows actually having an attached picture (skips legacy rows):
    scope :with_picture, -> { joins(:picture_attachment) }
    #-- ------------------------------------------------------------------------
    #++

    # Allowed content types for attached pictures.
    ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

    # Maximum attachment size in bytes (20 MB).
    MAX_PICTURE_SIZE = 20.megabytes

    # Returns the stored filename of the attached picture (nil when not attached).
    # This is the original filename sent by the operator; it is preserved by
    # ActiveStorage blobs even when the backing file is missing from the storage
    # area, allowing manual re-uploads after a data restore.
    def picture_filename
      picture.attached? ? picture.filename.to_s : nil
    end

    # Returns +true+ when the attached picture's backing file is actually present
    # on the storage service, +false+ otherwise (missing blob or missing file).
    def picture_available?
      picture.attached? && picture.blob.service.exist?(picture.blob.key)
    rescue StandardError
      false
    end

    #-- ------------------------------------------------------------------------
    #++

    private

    # Auto-builds the required unique #title as "<iso_date> <created_by>",
    # appending a " #n" suffix whenever another row already uses the same title.
    def build_title
      iso_date = (training_date || Time.zone.now).to_date.iso8601
      base = "#{iso_date} #{created_by}".strip.first(95)
      candidate = base
      index = 1
      while self.class.where(title: candidate).where.not(id:).exists?
        index += 1
        candidate = "#{base.first(95 - index.to_s.length - 2)} ##{index}"
      end
      self.title = candidate
    end

    # Validates the content type & size of the attached picture, when present.
    def picture_content_type
      return unless picture.attached?

      errors.add(:picture, :invalid) unless picture.blob.content_type.in?(ALLOWED_IMAGE_TYPES)
      errors.add(:picture, :invalid) if picture.blob.byte_size > MAX_PICTURE_SIZE
    end
  end
end
