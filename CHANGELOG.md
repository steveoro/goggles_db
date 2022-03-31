## Relevant Version History / current working features:

_Please, add the latest build info on top of the list; use Version::MAJOR only after gold release; keep semantic versioning in line with framework's_

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
