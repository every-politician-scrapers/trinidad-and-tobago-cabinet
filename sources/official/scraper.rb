#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class MemberList
  # details for an individual member
  class Member
    REMAP = {
      'Minister of Energy and Energy Industries and Minister in the Office of the Prime Minister' => [
        'Minister of Energy and Energy Industries', 'Minister in the Office of the Prime Minister'
      ],
    }.freeze

    def name
      Name.new(full: noko.text.tidy, prefixes: %w[Senator Dr The Hon]).short
    end

    def position
      REMAP.fetch(raw_position, raw_position)
    end

    private

    def raw_position
      noko.xpath('following::*[contains(., "Minister")][1]').text.tidy
    end
  end

  # The page listing all the members
  class Members
    def member_container
      # There's no real structure here. Everything seems to be in one of
      # <h1>, <h2>, or <p><strong>
      # but that also includes some other things
      noko.css('.page-content-container').css('h1,h2,p.strong').reject do |node|
        node.text.to_s.empty? || node.text.include?('Minister')
      end
    end
  end
end

file = Pathname.new 'official.html'
puts EveryPoliticianScraper::FileData.new(file).csv
