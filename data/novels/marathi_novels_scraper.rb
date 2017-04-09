#!/usr/bin/env ruby

require 'rest-client'
require 'open-uri'
require 'nokogiri'
require 'pry'

class MarathiNovelsScraper
  def scrape
    books = urls.map do |url|
      puts "Doing url: #{url}"
      response = RestClient.get url
      elements = Nokogiri::HTML(response).css('div[dir="ltr"]').select { |element| element.css('a').count > 50 }
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
    [
      "http://www.marathinovels.net/2008/06/marathi-horror-suspense-thriller.html",
      "http://marathionlinenovel.blogspot.com/2008/03/complete-marathi-suspense-thriller.html",
      "http://www.marathinovels.net/2008/10/marathi-book-black-hole-novel-mystery.html",
      "http://www.marathinovels.net/2009/04/marathi-romantic-suspense-complete.html",
      "http://www.marathinovels.net/2009/11/story-of-femine-power-complete-novel.html",
      "http://www.marathinovels.net/2011/05/complete-psychological-thriller.html",
    ]
  end
end
