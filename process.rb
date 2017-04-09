require 'trie'
require_relative 'data/reader'

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
data.each do |word|
  counts[word] += 1
end

trie = Trie.new
reverse_trie = Trie.new
binding.pry
counts.each do |word, frequency|
  trie.add(word, frequency)
  reverse_trie.add(word.reverse, frequency)
end

binding.pry
