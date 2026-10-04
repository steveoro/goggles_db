# frozen_string_literal: true

FactoryBot.define do
  factory :training, class: 'GogglesDb::Training' do
    before_create_validate_instance

    sequence(:training_date) { |n| (Date.current - n.days).beginning_of_day + 9.hours }
    training_by       { FFaker::Name.name }
    created_by        { FFaker::Name.name }
    swimmer           { [nil, FactoryBot.create(:swimmer)].sample }
    description       { [nil, FFaker::Lorem.paragraph].sample }

    # title is auto-built by the model on create (see GogglesDb::Training#build_title)

    factory :training_with_picture do
      after(:build) do |created_instance, _evaluator|
        created_instance.picture.attach(
          io: File.open(GogglesDb::Engine.root.join('spec', 'fixtures', 'files', 'test_creative_training.jpg')),
          filename: 'test_creative_training.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end
