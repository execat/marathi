require 'csv'
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

def logger(str)
  puts "#{Time.now} #{str}"
end

logger "Preparing counts"
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
  s = suffixes(array.map(&:reverse).sort).to_h
  s.map do |key, p|
    [key.reverse, p.map { |element| [element.first.reverse, element.last.reverse] } ]
  end.to_h
end

export_to_morfessor(counts) unless File.exists?(morfessor_file)

# 3.1
logger "Inducing candidate suffixes and prefixes"
keys = counts.keys.sort
candidate_suffixes = suffixes(keys)
candidate_prefixes = prefixes(keys)

def inverse_hash(input, options={})
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

def sum(array)
  array.inject(0, :+)
end

# 3.2
logger "Calculating affix scores"
inverse_hash_1 = inverse_hash(candidate_suffixes)
h1 = inverse_hash_1.map { |k, v| [k, v.count] }.to_h
l1 = candidate_suffixes.to_h.map { |k, v| [k, v.count] }.to_h
score_h1 = h1.map { |k, v| [k, [k.length, 5].min * v] }
  .to_h.sort_by { |_, v| v }.reverse
score_l1 = inverse_hash_1.map { |k, v| [k, [k.length, 5].min * v.map { |each_v| l1[each_v] }.sum] }
  .to_h.sort_by { |_, v| v }.reverse

inverse_hash_2 = inverse_hash(candidate_prefixes, { reverse: true })
h2 = inverse_hash_2.map { |k, v| [k, v.count] }.to_h
l2 = candidate_prefixes.to_h.map { |k, v| [k, v.count] }.to_h
score_h2 = h2.map { |k, v| [k, [k.length, 5].min * v] }
  .to_h.sort_by { |_, v| v }.reverse
score_l2 = inverse_hash_2.map { |k, v| [k, [k.length, 5].min * sum(v.map { |each_v| l2[each_v] })] }
  .to_h.sort_by { |_, v| v }.reverse

logger "Deriving affix lists after filtering low frequency affixes"
suffix_list = score_h1.to_h.select { |_, v| v > 160 }.keys
prefix_list = score_h2.to_h.select { |_, v| v > 120 }.keys

# 3.3
logger "Deriving candidate roots"
candidate_roots = []
data = counts.select { |k, v| v > 5 }.keys

binding.pry

puts "Total: #{data.count}"
x =
  data.each_with_index.map do |word, index|
    puts index
    possible_suffixes = suffix_list.map { |suffix| suffix if word =~ /#{suffix}\z/ }.compact
    possible_prefixes = prefix_list.map { |prefix| prefix if word =~ /\A"#{prefix}"/ }.compact
    [word, possible_suffixes, possible_prefixes]
  end

binding.pry
