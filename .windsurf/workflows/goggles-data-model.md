---
description: Goggles data model hierarchy — entities, associations, lookup types, Scenic views, and the enrollment model
auto_execution_mode: 2
---

# Goggles Data Model

Use this skill when you need to understand the database structure, entity relationships, or where a particular piece of data lives in the Goggles framework.

All models are namespaced under `GogglesDb::` and live in `/home/steve/Projects/goggles_db/app/models/goggles_db/`.

## Core Entity Hierarchy (Meeting Results)

The primary data flow follows a strict parent→child hierarchy:

```text
Season
  └── Meeting
        ├── Calendar (1:1 via meeting_id + season_id)
        └── MeetingSession (1:N, ordered by session_order)
              └── MeetingEvent (1:N, keyed by event_type_id + heat_type_id)
                    └── MeetingProgram (1:N, keyed by category_type_id + gender_type_id)
                          ├── MeetingIndividualResult (1:N, keyed by swimmer_id + team_id)
                          │     └── Lap (1:N, keyed by length_in_meters)
                          └── MeetingRelayResult (1:N, keyed by team_id)
                                ├── MeetingRelaySwimmer (1:N, keyed by swimmer_id)
                                └── RelayLap (1:N, sub-laps for 4x100/4x200)
```

## Key Entities

### Season & Federation

- **Season** — A competition season (e.g., "FIN 2024/2025"). Has `season_type_id`, `begin_date`, `end_date`.
- **SeasonType** — Lookup: "MASFIN", "MASCSI", etc. Links to `FederationType`.
- **FederationType** — Lookup: "FIN", "LEN", "FINA", "CSI", etc.

### Meeting Structure

- **Meeting** — A competition event (e.g., "18° Trofeo Città di Ravenna"). Has `season_id`, `header_date`, `code`, `edition`, `description`.
- **Calendar** — Schedule/manifest entry for a meeting. 1:1 with Meeting per season (keyed by `meeting_code` + `season_id`).
- **MeetingSession** — A session within a meeting (morning/afternoon). Has `session_order`, `scheduled_date`, `swimming_pool_id`.
- **MeetingEvent** — An event within a session (e.g., "100m Freestyle"). Has `event_type_id`, `heat_type_id`.
- **MeetingProgram** — A program (category + gender) within an event. Has `category_type_id`, `gender_type_id`.

### Results

- **MeetingIndividualResult** — One swimmer's result. Has `swimmer_id`, `team_id`, `badge_id`, timing fields (`minutes`, `seconds`, `hundredths`), `rank`, `meeting_points`, `standard_points`.
- **MeetingRelayResult** — A relay team's result. Has `team_id`, `team_affiliation_id`, timing fields, `rank`.
- **MeetingRelaySwimmer** — A swimmer within a relay. Has `swimmer_id`, `badge_id`, `relay_order`, timing fields.
- **Lap** — Split time for an individual result. Has `length_in_meters`, timing fields (both delta and absolute).
- **RelayLap** — Sub-lap for relay events (4x100m, 4x200m).

### Enrollment Model

- **Swimmer** — A physical person. Has `complete_name`, `first_name`, `last_name`, `year_of_birth`, `gender_type_id`.
- **Team** — A swimming club. Has `name`, `editable_name`, `city_id`.
- **Badge** — Season enrollment: links a Swimmer to a Team for a Season. Keyed by (`swimmer_id`, `team_id`, `season_id`). Has `number` (badge number), `category_type_id`, `entry_time_type_id`.
- **TeamAffiliation** — A Team's enrollment in a Season. Keyed by (`team_id`, `season_id`). Has `name` (as registered), `number`.
- **ManagedAffiliation** — Links a User to a TeamAffiliation they manage.

### Venues

- **City** — Has `name`, `area`, `country_code`, `latitude`, `longitude`, `plus_code`.
- **SwimmingPool** — Has `name`, `nick_name`, `lanes_number`, `pool_type_id`, `city_id`, `address`.

### Lookup Types (read-only reference tables)

- **CategoryType** — Age category (e.g., "M25", "M30"). Per season.
- **EventType** — Event definition (e.g., "50 SL", "100 FA"). Links to `StrokeType`.
- **GenderType** — "M" or "F".
- **PoolType** — "25" (short course) or "50" (long course).
- **HeatType** — "Finals", "Semifinals", "Heats".
- **StrokeType** — "Freestyle", "Backstroke", etc.
- **EditionType** — How edition numbering works.
- **EntryTimeType** — Type of entry time for a badge.
- **DayPartType** — Morning/Afternoon.
- **DisqualificationCodeType** — DSQ reason codes.

### User-Generated Content

- **UserWorkshop** — User-created "unofficial" meeting.
- **UserResult** — User-submitted individual result (for workshops).
- **UserLap** — User-submitted lap time (for user results).
- **Issue** — User-reported issue/request.

### Scoring & Records

- **IndividualRecord** — Personal or federation record.
- **ComputedSeasonRanking** — Aggregated season ranking.
- **GoggleCup** / **GoggleCupDefinition** / **GoggleCupStandard** — Custom cup competitions.
- **StandardTiming** — Reference standard times per event/category/pool.

### System

- **User** — Devise-managed user. Has `associated_swimmer_id`.
- **AdminGrant** — CRUD permission grant per entity per user.
- **AppParameter** — Application-wide settings (maintenance mode, etc.).
- **ApiDailyUse** — API usage tracking.
- **ImportQueue** — Queued import jobs with `request_data`, `solved_data`, `sql_batch`.

## Abstract Base Classes

- **AbstractMeeting** — Shared behavior for Meeting and UserWorkshop.
- **AbstractResult** — Shared behavior for MeetingIndividualResult, MeetingRelayResult, UserResult.
- **AbstractLap** — Shared behavior for Lap, RelayLap, UserLap.
- **AbstractBestResult** — Base for all Scenic view models (best results).
- **AbstractLookupEntity** — Base for all lookup/type tables.

## Scenic Database Views

Defined in `/home/steve/Projects/goggles_db/db/views/`, these are read-only aggregated views:

- **Best50mResult** — Best 50m times (latest version: `best_50m_results_v04.sql`)
- **Best50And100Result** — Best 50m and 100m times combined
- **Best50And100Result5y** — Same, last 5 years only
- **BestSwimmer3yResult** — Best swimmer results, last 3 years
- **BestSwimmer5yResult** — Best swimmer results, last 5 years
- **BestSwimmerAllTimeResult** — Best swimmer results, all time
- **LastSeasonId** — Utility view for latest season IDs

All inherit from `AbstractBestResult` and are backed by Scenic + `scenic-mysql_adapter`.

## Timing Fields Convention

Timing is stored as three separate integer columns across all result/lap models:

- `minutes` (integer)
- `seconds` (integer)
- `hundredths` (integer)

The `TimingManageable` concern (in `app/models/concerns/timing_manageable.rb`) provides conversion and formatting helpers.

## Key Scopes and Finders

Models typically provide:

- `.for_season(season)` / `.for_season_type(season_type)`
- `.for_meeting(meeting)` / `.for_event_type(event_type)`
- `.for_swimmer(swimmer)` / `.for_team(team)`
- `.for_category_type(cat)` / `.for_gender_type(gender)`
- `.for_pool_type(pool_type)`

Finders live in `/home/steve/Projects/goggles_db/app/strategies/goggles_db/db_finders/`.

## Schema File

The canonical schema is at `/home/steve/Projects/goggles_db/spec/dummy/db/schema.rb` (~1985 lines, 100+ tables).
