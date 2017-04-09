require 'pry'

class Reader
  def initialize(files, options)
    @files = files.map do |file|
      File.read("data/#{file}").split
    end
    @options = options
  end

  def read_corpus
    remove_punctuation if @options[:remove_punctuation]
    keep_only_non_ascii_characters if @options[:keep_only_non_ascii_characters]
    keep_only_devanagari_characters if @options[:keep_only_devanagari_characters]
    @files
  end

  private
  def remove_punctuation
    @files = @files.map do |array_of_words|
      array_of_words.map { |w| w.gsub(/[!@#$%^&*()-=_+|;:",.<>?'{}\[\]]/, '') }
    end
  end

  def keep_only_non_ascii_characters
    @files = @files.map do |array_of_words|
      array_of_words.reject(&:empty?).select { |k| k =~ /\A\W*\z/ }
    end
  end

  def keep_only_devanagari_characters
    @files = @files.map do |array_of_words|
      array_of_words.select { |k| k =~ /\A\p{Devanagari}\z/ }
    end
  end
end
