#!/usr/bin/env ruby

require 'rest-client'
require 'open-uri'
require 'nokogiri'
require 'pry'

class MaayboliScraper
  def scrape
    books = urls.map do |url|
      puts "Doing url: #{url}"
      response = RestClient.get url
      elements = Nokogiri::HTML(response).css('table')
      raise 'Not the only table element' if elements.count != 1
      binding.pry
      elements.first.select { |element| element.css('a') }
      raise 'Too many complicated elements' if elements.count > 1
      raise 'No link div found' if elements.count < 1

      element = elements.first
      links = element.css('a').select { |x| x.text =~ /ch/i }.map { |node| node['href'] }
      visit_and_store(links)
    end

    File.open("marathi_novels.txt", "w+") do |f|
      books.each do |book|
        f.puts(book)
      end
    end
  end

  private
  def visit_and_store(links)
    links.map do |link|
      response = RestClient.get link
      page = Nokogiri::HTML(response)
      result = page.css(".post-body").text.gsub(/\n/, ' ').gsub(/[a-zA-Z]/, '').strip
      puts "  * #{result.size} #{link}"
      result
    end
  end

  def urls
    (0..163).map { |i| "http://www.maayboli.com/gulmohar/marathi-katha?page=#{i}" }
  end
end
