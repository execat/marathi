require 'csv'
require 'trie'
require_relative 'data/reader'

# Roughly takes 7 minutes
def process_data
  corpus_files = %w(
    emille.txt
    marathi_corpus_unified.txt
    parallel_corpus.txt
    wikidata-mr.txt
  )

  options = {
    remove_punctuation: true,
    keep_only_non_ascii_characters: true,
    keep_only_devanagari: true,
  }

  data = Reader.new(corpus_files, options).read_corpus.flatten

  counts = Hash.new 0
  data.each { |word| counts[word] += 1 }

  puts "#{Time.now} Writing to file"
  CSV.open("pickle.csv", "wb") do |csv|
    counts.to_a.each { |elem| csv << elem }
  end
  counts
end

puts "#{Time.now} Preparing counts"
csv = CSV.read("pickle.csv").map { |word| [word[0], word[1].to_i] } rescue nil
counts = Hash[csv]
process_data unless counts.empty?

puts "#{Time.now} Creating tries"
trie = Trie.new
reverse_trie = Trie.new

binding.pry
counts.each do |word, frequency|
  trie.add(word, frequency)
  reverse_trie.add(word.reverse, frequency)
end
