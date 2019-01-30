#!/usr/bin/env ruby
# Usage:
#  $ ruby merge_csv.rb ./data/*csv > ./data/assembled.csv

phylum_list = [] # a uniq list of phylum name
phylum_data = [] # a list of hash, a hash has phylum => data array

ARGV.each do |path|
  csv = open(path).readlines
  phylum_reads = csv.map do |ln|
    d = ln.chomp.split(",")
    p = d.shift
    phylum_list.push(p)
    [p, d]
  end
  phylum_data.push(phylum_reads.to_h)
end

assembled = phylum_list.uniq.map do |p|
  data = phylum_data.map do |hash|
    hash[p] || hash.values[0].size.times.map{ "0" }
  end
  [p, data].flatten.join(",")
end

puts assembled
