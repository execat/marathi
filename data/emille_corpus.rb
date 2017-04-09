require_relative './corpus'

class EmilleCorpus < Corpus
  def execute
    bodies = file_list.map { |filename| extract_body(filename) }.compact
    texts = bodies.map(&:text).map do |text|
      text.gsub(/[\n\r]/, " ").gsub(/[ ]{2,}/, " ").strip
    end

    File.open("emille.txt", "w+") do |file|
      file.puts(texts)
    end
  end

  private
  def extract_body(filename)
    Nokogiri::XML(File.open file_list.first).xpath('//body')
  end

  def file_list
    Dir["emille.xml"]
  end
end
