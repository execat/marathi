require_relative './corpus'

class AbhangaCorpus < Corpus
  def execute
    bodies = file_list.map { |filename| extract_body(filename) }.compact
    texts = bodies.map(&:text).map do |text|
      text.gsub(/[\n\r]/, " ").gsub(/[ ]{2,}/, " ").strip
    end

    File.open("abhanga.txt", "w+") do |file|
      file.puts(texts)
    end
  end

  private
  def extract_body(filename)
    Nokogiri::HTML(File.open filename).css("body > div[align='center']").first
  end

  def file_list
    Dir["abhanga/*.html"]
  end
end
