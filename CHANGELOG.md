## Relevant Version History / current working features:

_Please, add the latest build info on top of the list; use Version::MAJOR only after gold release; keep semantic versioning in line with framework's_

- **0.8.06** [Steve A.] added more "Best Result" views; DB vers. 2.08.06; vers. 0.8.06
- **0.8.05** [Steve A.] updated all "Best Result" views common abstract base; improved specs; added db:dump_remove_sandbox task; DB vers. 2.08.05; vers. 0.8.05
- **0.8.04** [Steve A.] added "Best Result" family of views with models and abstract base; DB vers. 2.08.03
- **0.8.03** [Steve A.] applied patch for ActiveSupport logger; bundle updated
- **0.8.01** [Steve A.] added Best50mResult Scenic view with dedicated model and specs; DB vers. 2.08.01
- **0.8.00** [Steve A.] safe navigation in SwimmerDecorator#display_label when gender is not defined; added bias parameter in CmdFindDBEntity <- DbFinders::FuzzySwimmer because sometimes the default 0.8 doesn't fit the case; refactored Swimmer#age_for_category_range from [Admin2]PdfResults::L2Converter; bundle update
- **0.7.25** [Steve A.] amend dumb idea of aliasing #present? to positive? in all TimingManageable sibling classes
- **0.7.24** [Steve A.] bundle updates & rubocop updates; moved zero?, positive? & present? helpers directly into TimingManageable; specs updates
- **0.7.23** [Steve A.] bundle updates
- **0.7.20** [Steve A.] bundle updates; added a missing/new EventType used for Coopernuoto meetings ('6X50SL')
- **0.7.19** [Steve A.] bundle updates; added new Seasons & categories for 2024-2025
- **0.7.18** [Steve A.] bundle updates & misc specs adjustments; removed Patreon links for sponsorship
- **0.7.14** [Steve A.] handle nil search values in DbFinders::BaseStrategy
- **0.7.12** [Steve A.] fixed MariaDB required version for CircleCI build
- **0.7.11** [Steve A.] bundle update & minor rubocop adjustments; added missing catch-all U100 relay categories for seasons 182, 192, 202, 212, 222, 232;
- **0.7.10** [Steve A.] added IndividualRecord with specs; improved skeleton models for future GoggleCups implementation;
- **0.7.09** [Steve A.] SwimmerStat query fix: wasn't getting the proper min FIN score right; split fulltext indexes for Meeting, UserWorkshop & Team: search individual columns instead of groups to yield better results
- **0.7.08** [Steve A.] added some delegation helpers to Badge; added triggers and events to MariaDB dump file generated by "db:dump" (even if not currently used); minor rubocop fixes & bundle updates
- **0.7.06** [Steve A.] query fix for SwimmerStat
- **0.7.00** [Steve A.] update to Rails 6.1; specs adjustments
- **0.6.30** [Steve A.] counter_cache for MRR-MRS-RL chain association; added Prosopite gem for additional query checks; improved default scopes for all AR Models; added GrantChecker helpers for the instance in case of multiple consequent checks for the same user; data-fix migration for existing MRS with zero timing "from_start" & length_in_meters; added delegation for length_in_meters for MRR & MRS & alias for MRS#meeting_relay_result as #parent_result
- **0.6.21** [Steve A.] minor data-fix: removed some null ranks in MRRs; improvements to default scopes due to missing includes() & MRR factories; added missing helpers to MRR-MRS-RelayLap association chain
- **0.6.10** [Steve A.] added RelayLaps, support for absolute timings in MRS, plus improved helpers for TimingManageable
- **0.6.00** [Steve A.] upgrade to Ruby 3.1.4
- **0.5.22** [Steve A.] fixes & refactorings for AbstractLap; amend upgrade to Rubocop 2.20 which is currently having issues
- **0.5.21** [Steve A.] fixes for TimingManageable & Timing; bundle update
- **0.5.20** [Steve A.] re-added timestamps to #minimal_attributes output; added issue type #5; bundle update
- **0.5.12** [Steve A.] added LastSeasonId view; DB vers. 2.00.0
- **0.5.11** [Steve A.] added #by_swimmer to AbstractResult; specs fixes & update
- **0.5.10** [Steve A.] added #active? to Users; refactored all to_hash methods using ancestor AbstractRecord class; specs & bundle update
- **0.5.05** [Steve A.] added to_hash methods as middlemen in between to_json output
- **0.5.03** [Steve A.] slight change in ImportQueueDecorator so that #chrono_delta_label can be called also on master chrono rows
- **0.5.02** [Steve A.] minor DB structure update with some missing default values for boolean columns;
- **0.5.01** [Steve A.] added Issue model, ManagerChecker#for_team? & #for_swimmer?; additional Timing & ImportQueue helpers and more specs; bundle security update
- **0.4.25** [Steve A.] added ManagerChecker.any_for?();
- **0.4.23** [Steve A.] additional task: db:check:tas
- **0.4.21** [Steve A.] fixed default scopes for Team and Calendar (which may now require 'unscoped' when selecting individual fields)
- **0.4.20** [Steve A.] some security updates; increased duration of JWTs to 10 hours; removed unconfirmed new user access possibility; added a default scope for Team
- **0.4.10** [Steve A.] forced UTF-8 encoding for downloaded script files in ImportQueues
- **0.4.09** [Steve A.] using proper download method for attachments in ImportQueue instead of low-level file access; improved stability in ImportQueue specs
- **0.4.07** [Steve A.] tweaked AbstractMeeting name helpers to better reflect descriptions for seasonal & ordinal meetings; updated specs & re-normalized DB dumps
- **0.4.06** [Steve A.] improved meeting edition normalizer with additional specs; changed a bit how the common AbstractMeeting edition helpers work w/ updated specs
- **0.4.05** [Steve A.] improved clean-up after ActiveStorage tests + minor factories adjustments
- **0.4.01** [Steve A.] support push batch SQL import data to dedicated API endpoint directly into ImportQueues as file attachments; improvements to for_name scopes & GogglesDb::DbFinders::BaseStrategy; refactored & moved name Parser::CodedName normalizer from Admin2 so that it can be shared among projects; several data-fix migrations & additional strategy classes; improved fuzzy finders & ISO city finder with refactored code and data normalization tasks; DB normalized & re-dumped.
- **0.3.53** [Steve A.] bump Rails to 6.0.5 + minor security fixes for Nokogiri & Rack; added db finder command with custom (fuzzy) strategies for swimmer, team, meeting, pool & city
- **0.3.51** [Steve A.] removed titleize from AbstractMeeting#condensed_name
- **0.3.50** [Steve A.] bump Rails to 6.0.4.7 for security fixes
- **0.3.48** [Steve A.] removed wrong 'dependent' parameter in MeetingProgram
- **0.3.47** [Steve A.] removed wrong 'dependent' parameter in MeetingEvent
- **0.3.45** [Steve A.] added 'payed' to meeting reservations; renamed fin_calendars to simply 'calendars', with basic implementation & decorator; minor data-fix for existing reservations
- **0.3.44** [Steve A.] updated country gem; improved AbstractMeeting helper methods; added eager loading for Swimmer, Meeting, UserWorkshop and others as default scopes
- **0.3.42** [Steve A.] upgrade to Rails 6.0.4.6 due to security fixes
- **0.3.38** [Steve A.] improved to_json output & specs for all models with a decorator
- **0.3.36** [Steve A.] score calculator strategies, with dedicated factory & selector command
- **0.3.35** [Steve A.] migrations from standard_timings in MeetingProgram & UserResult
- **0.3.33** [Steve A.] additional decorators
- **0.3.30** [Steve A.] improved flexibility of #for_year(s) filtering scope for badges & team_affiliations
- **0.3.29** [Steve A.] upgrade to Rails 6.0.4.1 due to security fixes
- **0.3.27** [Steve A.] moved here ImportQueueDecorator from Main
- **0.3.25** [Steve A.] improved GrantChecker a bit + added the list of supported settings group keys to AppParameter
- **0.3.20** [Steve A.] major data clean-up: laps normalization & old user purge: saying goodbye to 671 old chaps and related reservations; DB vers. 1.92.3
- **0.3.06** [Steve A.] swimming_pool association in UserResult is no longer optional; minor refactorings
- **0.3.01** [Steve A.] improved structure for import_queues & helpers; data migrations & misc fixes
- **0.2.18** [Steve A.] upgraded gem set due to security fixes; additional long_label output for #to_json is some models; added User Results (partially modified from legacy structure), User Laps & User Workshop
- **0.2.09** [Steve A.] added timing.to_s in minimal_attributes for reservations
- **0.2.01** [Steve A.] bump versioning according to main application
- **0.1.89** [Steve A.] improved user spec stability & validations
- **0.1.87** [Steve A.] amend Twitter OAuth2 sign-in; improved stability for user specs
- **0.1.82** [Steve A.] removed unused legacy columns from users; support for future Twitter OAuth2 sign-in; auto-select associated swimmer finder for Users
- **0.1.80** [Steve A.] added OAuth2 support for Google & Facebook direct login
- **0.1.78** [Steve A.] fix for inverse association between User <=> Swimmer
- **0.1.76** [Steve A.] improved build setup
- **0.1.74** [Steve A.] upgrade to Ruby 2.7.2
- **0.1.73** [Steve A.] minor bundle update; misc configuration tweaks
- **0.1.72** [Steve A.] additional structure refactoring
- **0.1.54** [Steve A.] improved to_json output for parent entities; added most of minimal required associations to minimal_attributes
- **0.1.36** [Steve A.] Rewrote all main & secondary Entities, minus GoggleCup & exercise/workout-related
- **0.1.21** [Steve A.] Main Entities halfway through (missing: all Meeting entities)
