# frozen_string_literal: true

require 'singleton'

module GogglesDb
  module Normalizers
    #
    # = CodedName
    #
    #   - version:  7-0.4.01
    #   - author:   Steve A.
    #   - build:    20220823
    #
    # Wrapper for parsing helper methods for misc entities (mainly: Meetings & SwimmingPool).
    # Refactored from the original Parsers::CodedName in Admin2 project (which now uses this class).
    #
    class CodedName
      include Singleton

      # Computes the "official" coded name for a Meeting given the parameters.
      #
      # == Params
      # - <tt>description</tt> => Meeting#description
      # - <tt>city_name</tt>   => City#name
      #
      # == Returns
      # the coded String name for the meeting, which usually includes the city name.
      #
      # rubocop:disable Metrics/CyclomaticComplexity
      def self.for_meeting(description, city_name)
        # == Code usage examples:
        #
        # codes = GogglesDb::Meeting.unscoped.select(:code).order(:code).distinct(:code).map(&:code)
        # list = {}

        # codes.each do |code|
        #   m = GogglesDb::Meeting.includes(meeting_sessions: { swimming_pool: [:city, :pool_type] }).find_by(code: code)
        #   city = m.swimming_pools&.first&.city&.name
        #   desc = m.description
        #   new_code = GogglesDb::Normalizers::CodedName.for_meeting(desc, city)
        #   list[code] = { description: desc, city: city, new_code: new_code }

        #   # ASSERT for specs: all new codes are 1) strings, 2) present, 3) length < 50:
        #   binding.pry unless new_code.is_a?(String) && new_code.present? && new_code.length < 50
        # end
        #
        # list.each { |curr_code, hash| puts "'#{curr_code}' \t => #{hash[:new_code]}"} ; nil
        #
        # # -- Create output file to check coded names result: --
        # File.write('tmp/meeting-db.yml', list.to_yaml, mode: 'w')
        #
        # # -- Data-fix Migration for Meeting codes: --
        # list.each do |curr_code, hash|
        #   new_code = hash[:new_code]
        #   puts "'#{curr_code}' \t=> '#{new_code}'"
        #   # Update all existing codes with the new code:
        #   if curr_code != new_code
        #     GogglesDb::Meeting.where(code: curr_code).update(code: new_code)
        #   end
        # end
        # -- ------------------------------------------------------------------
        # ++

        # Handle all special code cases (including recurring regional meetings):
        case description.to_s
        # CSI-only:
        when /^([IXVLMCD]+|\d{1,2}[°^oa]?|fin.+)\s(prova\s)?(fin.+)?(camp.+\s)?(reg.+\s)?csi\b/ui
          edition, _name = edition_split_from(description)
          edition.positive? && (description =~ /\bfin.+\s/ui).nil? ? "csiprova#{edition}" : 'csifinale'

        when /dist(anze|\.)?\s+spec(iali|\.)?/i
          region = normalize(description.to_s.split(/speciali\s+/i).last).gsub(/\W/iu, '')
          "spec#{region}"

        when /regional.\s+/i
          region = normalize(description.to_s.split(/regional.\s+/i).last).gsub(/\W/iu, '')
          "reg#{region}"

        when /provincial.\s+/i
          "prov#{normalize(city_name).gsub(/\W/iu, '')}"

        else
          norm_city = normalize(city_name).gsub(/\W/iu, '')
          norm_title = normalize(description).gsub(/\W/iu, '')
          # Avoid the repetition of the name in the coded result:
          if norm_city == norm_title
            norm_city
          else
            "#{norm_city}#{norm_title}"
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # Computes the "official" nickname for a SwimmingPool given the parameters.
      #
      # == Params
      # - <tt>name</tt>           => SwimmingPool#name
      # - <tt>city_name</tt>      => City#name
      # - <tt>pool_type_code</tt> => SwimmingPool#pool_type#code
      #
      # == Returns
      # the coded String nick name for the swimming pool, which usually should include
      # the city name and the pool length in meters.
      #
      def self.for_pool(name, city_name, pool_type_code)
        # == Note:
        # To recreate 'venues-db.yml', use the console and type:
        #
        # > list = GogglesDb::SwimmingPool.order(:nick_name).all.map{ |r| { r.nick_name => { pool: r.name, city: r.city&.name, len: r.pool_type.code } } }
        # > File.write('tmp/venues-db.yml', list.to_yaml, mode: 'w')
        #
        norm_city = normalize(city_name).gsub(/\W/iu, '')
        norm_name = normalize(name).split(/\s/)
                                   .reject { |token| token =~ /#{norm_city}/i }
                                   .map { |token| token.gsub(/\W/iu, '') }
                                   .reject(&:empty?)
                                   .join
        "#{norm_city}#{norm_name}#{pool_type_code}"
      end
      #-- -----------------------------------------------------------------------
      #++

      # Returns a normalized text by converting any UTF-8/special characters into
      # plain ASCII vowels and removing any individual punctuation characters.
      # Spaces are *NOT* affected.
      #
      # The method strips away any typical recurring prefixes for names, like
      # "Meeting", "Trofeo", "Citta' di ", any ordinal numbering or year references
      # and so on.
      #
      # == Params:
      # - <tt>name</tt> => the String name or description to be normalized.
      #
      # == Returns:
      # a donwcased, normalized String.
      #
      # rubocop: disable Metrics/AbcSize
      def self.normalize(name)
        # NOTE: [Steve, 20170426]: The "non-word" char code ("\W") for Regexp works best as
        # most generic separator, even when SHIFT-SPACEs or other UNICODE chars are present
        # (with these, "\s" is not enough).
        name.to_s
            .gsub(/\b\d{4}/iu, '')
            .gsub(%r{[\-_'`\\/:.,;]}, '')
            .gsub(/à/iu, 'a').gsub(/[èé]/iu, 'e').gsub(/ì/iu, 'i')
            .gsub(/ò/iu, 'o').gsub(/ù/iu, 'u').gsub(/ç/iu, 'c')
            .gsub(/\*|\^/iu, '°')
            .gsub(/\d+°?\b/iu, '')
            .gsub(/\bmeeting\b|\bmtng\b|\bmemorial\b|\braduno\b|\bfesta\b|\bmaster\b/iu, '')
            .gsub(/\bnuoto\b|\bcoppa\b|\bcampionat.\b|\btrofeo\b+|\brepubblica\b|\bfinali\b|\btr.?\b/iu, '')
            .gsub(/\b[dn][ae]l?(lo|la|l)?\b/iu, ' ')
            .gsub(/\bcircolo\b|\bcittadella\b|\bcomplesso\b|\bcentro\b|\bcenter\b|\bclub\b/ui, 'c')
            .gsub(/\bcitt[aà]\'?\b|\bdi\b|\bcomunal[ei]\b|\bs?coperta\b|\bimpiant.\b|\bpiscin.\b|\bpolisportiv.\b|\bnatatori\b/iu, '')
            .gsub(/\balbert[oa]?\b|\banna\b|\bandrea\b|\bachille\b|\barmando\b|\barnoldo\b/ui, 'a')
            .gsub(/\bcarl[ao]?\b|\bcarmen\b|\bcelio\b|\bcorrado\b|\bch?ristiano?\b/ui, 'c')
            .gsub(/\bdaniel[ae]\b|\bdari[ao]\b/ui, 'd')
            .gsub(/\bfederale\b/ui, 'f')
            .gsub(/\binterna.+\b/iu, 'int')
            .gsub(/\bmaria\b|\bmarco\b|\bmichel[ae]\b|\bmassimo\b|\bmatteo\b|\bmattia\b/ui, 'm')
            .gsub(/\bnatatorio\b/ui, 'n')
            .gsub(/\bolimpic.*\b/iu, 'olimp')
            .gsub(/\bpolo\b|\bpaol.\b|\bpalazzo\b|\bparco\b|\bpalazzetto\b|\bpalasport\b/ui, 'p')
            .gsub(/\brolando\b|\brobert.\b|\briccardo\b|\bremo\b/ui, 'r')
            .gsub(/\bsport(ivo|ing)?\b|\bsant[aoi]\b|\bsergio\b|\b(ales)?sandr[ao]\b/ui, 's')
            .gsub(/\bstadio\b(nuoto\b)?/iu, 'stadio')
            .gsub(/\bs\.?marino\b/iu, 'sanmarino')
            .gsub(/\bvinicio\b|\bveronica\b|\vittori.+\b|\bvillaggio\b/ui, 'v')
            .gsub(/\bnazional.\b/iu, 'naz')
            .gsub(/\buniversit.*\b/iu, 'univ')
            .gsub(/\bd.\b?(primavera|autunno|inverno)/iu, '')
            .gsub(/\bteam\basi\b|\bacsi\b|\bsnp\b|\bdna\b/iu, '')
            .downcase.strip
      end
      # rubocop: enable Metrics/AbcSize
      #-- -----------------------------------------------------------------------
      #++

      # Regexp used to discriminate between any edition number included inside any Meeting descriptions
      REGEXP_EDITION = /(^[IXVLMCD]+[°^oa]?\W)|(^\d{1,2}[°^oa]?\W)/ui.freeze unless defined?(REGEXP_EDITION)

      # Regexp used to discriminate between any edition number OR year included inside any Meeting descriptions
      REGEXP_EDITION_OR_YEAR = /(^[IXVLMCD]+[°^oa]?\W)|(^\d{1,2}[°^oa]?\W)|(\b\d{2}\b|\b\d{4}\b)/ui.freeze unless defined?(REGEXP_EDITION_OR_YEAR)

      # Tries to extract (or parse) the value of an edition number from a meeting descripion.
      # Assumes the edition is in the front part of the description.
      #
      # == Examples:
      # - "15^ Trofeo Regionale CSI" => [15, "Trofeo Regionale CSI"]
      # - "XII Trofeo Vattelapesca" => [12, "Trofeo Vattelapesca"]
      # - "Trofeo Gianni Pinotto 2021" => [2021, "Trofeo Gianni Pinotto"]
      # - "VI Meeting Generico 2021" => [6, "Meeting Generico"]
      #
      # == Params
      # - <tt>meeting_description</tt> => any Meeting#description which, allegedly, contains an edition number
      #   to be extracted.
      #
      # == Returns
      # A couple of results; in order:
      #
      # 1. the integer edition or year number (converted if it's from a Roman number);
      #    returns an unparsed edition only when the whole description is just an edition number;
      #
      # 2. the remainder part of the description, stripped of the edition or year number.
      #    returns an empty string only when the whole description is just an edition number.
      #
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def self.edition_split_from(meeting_description)
        return [0, meeting_description] unless meeting_description =~ REGEXP_EDITION_OR_YEAR

        tokens = meeting_description.to_s.split(REGEXP_EDITION_OR_YEAR).reject(&:blank?)
        if tokens.instance_of?(Array) && tokens.length > 1
          # Make sure the first result token is always the edition number (priority 1);
          # use the year number at the end only if there's no edition at the beginning (priority 2):
          tokens.reverse! if (tokens.first =~ REGEXP_EDITION).nil? &&
                             (tokens.last =~ REGEXP_EDITION_OR_YEAR).present?

          reg = Regexp.new(/(^[IXVLMCD]+)[°^oa]?\W/ui)
          edition = tokens.first.match(reg)&.captures&.first
          edition = edition.blank? ? tokens.first.to_i : Integer.from_roman(edition)
          [edition, tokens.last.strip]
        else
          # 1 token only when the description is just an edition number or a year
          [tokens.first, '']
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      #-- -----------------------------------------------------------------------
      #++
    end
  end
end
