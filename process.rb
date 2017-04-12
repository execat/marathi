require 'csv'
require 'trie'
require_relative 'data/reader'

morfessor_file = "comparison/morfessor/morfessor.txt"
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
    keep_only_devanagari_characters: true,
  }

  puts "#{Time.now} Reading corpuses"
  data = Reader.new(corpus_files, options).read_corpus.flatten

  counts = Hash.new 0
  data.each { |word| counts[word] += 1 }

  puts "#{Time.now} Writing to file"
  CSV.open("pickle.csv", "wb") do |csv|
    counts.to_a.each { |elem| csv << elem }
  end
  counts
end

def export_to_morfessor(counts)
  strings = counts.to_a.map { |entry| "#{entry.last} #{entry.first}" }
  File.open(morfessor_file, "w+") do |file|
    file.puts(strings)
  end
end

puts "#{Time.now} Preparing counts"
csv = CSV.read("pickle.csv").map { |word| [word[0], word[1].to_i] } rescue []
counts = csv.empty? ? process_data : Hash[csv]

counts = counts.reject { |k, _| k =~ /[१२३४५६७८९०]/ }

def suffixes(array)
  array.each_with_index.map do |word, i|
    x = []
    i += 1
    while array[i] && array[i].include?(word)
      source = array[i]
      suffix = array[i].sub(word, '')
      x << [source, suffix]
      i += 1
    end
    x.empty? ? nil : [word, x]
  end.compact
end

def prefixes(array)
  suffixes(array.map(&:reverse).sort).map do |key, p|
    p = p.first
    [key.reverse, [p[0].reverse, p[1].reverse]]
  end
end

export_to_morfessor(counts) unless File.exists?(morfessor_file)

# 3.1
keys = counts.keys.sort
candidate_suffixes = suffixes(keys)
candidate_prefixes = prefixes(keys)

def inverse_hash(input)
  h = Hash.new([])
  i = 0
  puts "#{input.count}"
  input.to_h.each do |k, v|
    i += 1
    puts i if i % 10000 == 0
    v.each { |obj| h[obj[1]] = h[obj[1]] + [k] }
  end
  h
end

# 3.2
inverse_hash_1 = inverse_hash(candidate_suffixes)
h1 = inverse_hash_1.map { |k, v| [k, v.count] }.to_h
l1 = candidate_suffixes.to_h.map { |k, v| [k, v.count] }.to_h
score_h1 = h1.map { |k, v| [k, [k.length, 5].min * v] }
  .to_h.sort_by { |_, v| v }.reverse
score_l1 = inverse_hash_1.map { |k, v| [k, v.map { |each_v| l1[each_v] }.sum] }
  .to_h.sort_by { |_, v| v }.reverse

binding.pry

inverse_hash_2 = inverse_hash(candidate_prefixes)
h2 = inverse_hash_2.map { |k, v| [k, v.count] }.to_h
l2 = candidate_prefixes.to_h.map { |k, v| [k, v.count] }.to_h
binding.pry
score_h2 = h2.map { |k, v| [k, [k.length, 5].min * v] }
  .to_h.sort_by { |_, v| v }.reverse
score_l2 = inverse_hash_2.map { |k, v| [k, v.map { |each_v| l2[each_v] }.sum] }
  .to_h.sort_by { |_, v| v }.reverse

