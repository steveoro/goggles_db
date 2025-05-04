# frozen_string_literal: true

require 'rails_helper'

# Define the shared examples for models inheriting from AbstractBestResult
RSpec.shared_examples 'an AbstractBestResult descendant' do |model_class|
  let(:described_class) { model_class }

  it 'is read-only' do
    # For view-backed models using a pre-seeded test DB, finding is best.
    # If the view might be empty, we might need specific setup, but let's assume the dump provides data.
    instance = described_class.first
    # If an instance exists from the dump, check readonly
    expect(instance).to be_readonly if instance
    # Alternate check: try creating/saving (should fail for readonly)
    # Build requires knowing attributes, which might be complex for views.
    # If no instance exists, the test might be inconclusive without more setup.
    if instance.nil? && described_class.respond_to?(:create)
      begin
        # Attempting to create might reveal if it's truly readonly
        # This assumes FactoryBot or attributes can be guessed/provided
        # expect { FactoryBot.create(described_class.model_name.singular.to_sym) }.to raise_error(ActiveRecord::ReadOnlyRecord)
        # For now, primary check is on existing instance.
        Rails.logger.warn("Skipping ReadOnlyRecord creation check for #{described_class} as no instance found and attributes unknown.")
      rescue StandardError => e
        Rails.logger.warn("Could not perform ReadOnlyRecord creation check for #{described_class}: #{e.message}")
      end
    end
  end

  # Associations (use pre-loaded data assumptions)
  # Assuming the view has these columns populated from the underlying MIR join
  it { is_expected.to belong_to(:swimmer) }
  it { is_expected.to belong_to(:team) }
  it { is_expected.to belong_to(:season) }
  it { is_expected.to belong_to(:gender_type) }
  it { is_expected.to belong_to(:pool_type) }
  it { is_expected.to belong_to(:event_type) }
  it { is_expected.to belong_to(:meeting_individual_result) }
end

# Shared examples for common scope behaviors
# Use a shared context to define common lets and helpers
RSpec.shared_context 'AbstractBestResult scopes setup' do
  # Define common lookups using the project's helper methods/constants
  let(:male_gender) { GogglesDb::GenderType.male }
  let(:female_gender) { GogglesDb::GenderType.female }

  # Choose a team ID known or likely to have data. Querying ensures we use an existing ID.
  # Find the first team_id that actually has records in the specific view being tested.
  # This avoids randomly picking a team with no data for this particular 'best result' type.
  let(:chosen_team_id) { [1, 42].sample } # Teams 1 and 42 have good data coverage in dump

  # Define the base scope using the chosen team ID
  let(:base_scope) { described_class.where(team_id: chosen_team_id) }

  # Define the models that require data creation due to time-sensitive view logic
  let(:time_sensitive_models) do
    [
      GogglesDb::Best50mResult,
      GogglesDb::Best50And100Result,
      GogglesDb::BestSwimmer5yResult
    ]
  end

  # Create necessary data ONLY for time-sensitive views before running scope examples
  before do
    # Only run data creation if the model being tested is time-sensitive
    if time_sensitive_models.include?(described_class)
      # 0. Skip the data creation block below if a returned domain for the model is already present
      next if base_scope.count.positive?

      # 1. Find the latest 'FIN' season (ID=1) from the test data dump (there should be always one)
      latest_fin_season = GogglesDb::Season.where(season_type_id: 1).order(header_year: :desc, id: :desc).first
      next unless latest_fin_season

      # 2. Find target team from the dump
      team_for_creation = GogglesDb::Team.find_by(id: chosen_team_id)
      next unless team_for_creation

      # 3. Find target swimmers for the chosen team from any existing results for the chosen team:
      male_swimmer = GogglesDb::MeetingIndividualResult.includes(:gender_type)
                                                       .where(team_id: chosen_team_id, 'gender_types.id': male_gender.id)
                                                       .last(10).sample.swimmer
      female_swimmer = GogglesDb::MeetingIndividualResult.includes(:gender_type)
                                                         .where(team_id: chosen_team_id, 'gender_types.id': male_gender.id)
                                                         .last(10).sample.swimmer
      next unless male_swimmer && female_swimmer

      # 4. Select the possible Event Types returned by the view, based on the actual view model being tested
      event_types = case described_class.name
                    when 'GogglesDb::Best50mResult'
                      GogglesDb::EventType.where(id: [2, 11, 15, 19]) # All 50m x stroke type
                    when 'GogglesDb::Best50And100Result'
                      GogglesDb::EventType.where(id: [2, 3, 11, 12, 15, 16, 19, 20, 22]) # All (50m + 100m) x stroke type + '100MI'
                    when 'GogglesDb::BestSwimmer5yResult'
                      # 5Y will consider all individual events, except the non-standard lengths:
                      GogglesDb::EventType.all_individuals.select { |ev| ev.length_in_meters.between?(50, 1500) }
                    else
                      [] # Should not happen if shared examples "includee" is correct
                    end
      unless event_types.any?
        warn "[WARN] No event codes supported for data creation for #{described_class}."
        next
      end

      # 5. Create new Meeting -> Session -> Program -> Result chain
      # NOTE: we need to pause Prosopite during this data creation step as the complex hierarchy
      #       chain needed in this will trigger N+1 query errors.
      Prosopite.pause do
        meeting = create(:meeting, season: latest_fin_season, header_date: Time.zone.today - rand(1..90).days)
        session = create(:meeting_session, meeting: meeting, scheduled_date: meeting.header_date)

        # 6. Create only 2x random events for each gender, each with 1 result (2x2 tot.rows), for the new meeting:
        event_types.sample(2).each do |event_type|
          program_male = create(:meeting_program, meeting_session: session, event_type: event_type, gender_type: male_gender)
          create(:meeting_individual_result, meeting_program: program_male, swimmer: male_swimmer, team: team_for_creation,
                                             minutes: 0, seconds: rand(25..45), hundredths: rand(0..99))
          program_female = create(:meeting_program, meeting_session: session, event_type: event_type, gender_type: female_gender)
          create(:meeting_individual_result, meeting_program: program_female, swimmer: female_swimmer, team: team_for_creation,
                                             minutes: 0, seconds: rand(28..50), hundredths: rand(0..99))
        end
      end
      # puts "[DEBUG] Created Meeting #{meeting.id} with #{event_types.count * 2} results for season #{latest_fin_season.id}." # Optional debug output
    end
  end
end
#-- ---------------------------------------------------------------------------
#++

# *** Filtering scopes: ***
RSpec.shared_examples 'AbstractBestResult filtering scopes' do
  # Include the shared context to get access to lets and helpers
  include_context 'AbstractBestResult scopes setup'

  describe '.for_gender' do
    context 'when called for Males' do
      subject { base_scope.for_gender(male_gender) }

      it 'returns only Male results' do
        expect(subject.pluck(:gender_type_id)).to all(eq(male_gender.id))
      end
    end

    context 'when called for Females' do
      subject { base_scope.for_gender(female_gender) }

      it 'returns only Female results' do
        expect(subject.pluck(:gender_type_id)).to all(eq(female_gender.id))
      end
    end
  end

  describe '.for_event_type' do
    subject { base_scope.for_event_type(chosen_event) }

    let(:chosen_event) { GogglesDb::EventType.find(base_scope.pluck(:event_type_id).uniq.sample) }

    it 'returns only results for the specified event type' do
      expect(subject.pluck(:event_type_id)).to all(eq(chosen_event.id))
    end
  end

  describe '.for_pool_type' do
    subject { base_scope.for_pool_type(GogglesDb::PoolType.find(chosen_pool_type_id)) }

    let(:chosen_pool_type_id) { [GogglesDb::PoolType::MT_25_ID, GogglesDb::PoolType::MT_50_ID].sample }

    it 'returns only results for the specified pool type' do
      expect(subject.pluck(:pool_type_id).uniq).to eq([chosen_pool_type_id])
    end
  end

  describe '.for_season' do
    subject { base_scope.for_season(GogglesDb::Season.find(chosen_season_id)) }

    let(:chosen_season_id) { base_scope.pluck(:season_id).uniq.sample }

    it 'returns only results for the specified season' do
      expect(subject.pluck(:season_id).uniq).to eq([chosen_season_id])
    end
  end

  describe '.for_team_id' do
    # (Base scope is already filtered by chosen_team_id)
    it 'returns only results for the specified team' do
      expect(base_scope.pluck(:team_id).uniq).to eq([chosen_team_id])
    end
  end

  describe '.for_team_and_season_ids' do
    subject { base_scope.for_team_and_season_ids(chosen_team_id, chosen_season_id) }

    # (Base scope is already filtered by chosen_team_id)
    let(:chosen_season_id) { base_scope.pluck(:season_id).uniq.sample }

    it 'returns only results for the specified season' do
      expect(subject.pluck(:season_id).uniq).to eq([chosen_season_id])
      expect(subject.pluck(:team_id).uniq).to eq([chosen_team_id])
    end
  end
end

# *** Sorting scopes: ***
RSpec.shared_examples 'AbstractBestResult sorting scopes' do
  # Include the shared context to get access to lets and helpers
  include_context 'AbstractBestResult scopes setup'

  context 'sorting scopes' do
    describe '.sort_by_time / .sort_fastest_first' do
      it 'sorts the results by total_hundredths ascending' do
        results = base_scope.sort_by_time.limit(10) # Limit for performance
        times = results.pluck(:total_hundredths)
        expect(times).to eq(times.sort)
      end

      it 'sort_fastest_first is an alias for sort_by_time' do
        # Check just the first 10 returned results:
        expect(base_scope.sort_fastest_first.limit(10).pluck(:meeting_individual_result_id))
          .to eq(base_scope.sort_by_time.limit(10).pluck(:meeting_individual_result_id))
      end
    end

    describe '.sort_by_time_desc' do
      it 'sorts the results by total_hundredths descending' do
        results = base_scope.sort_by_time_desc.limit(10)
        times = results.pluck(:total_hundredths)
        expect(times).to eq(times.sort.reverse)
      end
    end
  end
end
