#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class MemberList
  # details for an individual member
  class Member < Scraped::HTML
    PREFIXES = %w[Senator Dr The Hon].freeze

    REMAP = {
      'Minister of Energy and Energy Industries and Minister in the Office of the Prime Minister' => [
        'Minister of Energy and Energy Industries', 'Minister in the Office of the Prime Minister'
      ],
    }.freeze

    field :name do
      PREFIXES.reduce(full_name) { |current, prefix| current.sub(/#{prefix}\.? /i, '') }
    end

    field :position do
      REMAP.fetch(raw_position, raw_position)
    end

    private

    def full_name
      noko.text.tidy
    end

    def raw_position
      noko.xpath('following::*[contains(., "Minister")][1]').text.tidy
    end
  end

  # The page listing all the members
  class Members < Scraped::HTML
    field :members do
      member_container.flat_map do |member|
        data = fragment(member => Member).to_h
        [data.delete(:position)].flatten.map { |posn| data.merge(position: posn) }
      end
    end

    private

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

file = Pathname.new 'html/official.html'
puts EveryPoliticianScraper::FileData.new(file).csv
