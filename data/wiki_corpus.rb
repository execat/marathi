require_relative './corpus'

class WikiCorpus < Corpus
  def execute
    bodies = file_list.map { |filename| extract_body(filename) }.compact
    texts = bodies.map(&:text).map do |text|
      text.gsub(/[\n\r]/, " ").gsub(/[ ]{2,}/, " ").strip
    end

    File.open("wikidata-mr.txt", "w+") do |file|
      file.puts(texts)
    end
  end

  private
  def extract_body(filename)
    # This step takes ~10 minutes to execute, 122239 entries
    Nokogiri::XML(File.open filename).css("page revision text")
  end

  def file_list
    Dir["wikidata-mr.xml"]
  end
end
