#!/usr/bin/env ruby
# Ruby script to merge csv files
# License: MIT, Tazro Inutano Ohta, inutano@gmail.com
#
# Citation:
# Ohta T, Kawashima T, Shinozaki NO, Dobashi A, Hiraoka S, Hoshino T, Kanno K, Kataoka T, Kawashima S, Matsui M, Nemoto W, Nishijima S, Suganuma N, Suzuki H, Taguchi Y, Takenaka Y, Tanigawa Y, Tsuneyoshi M, Yoshitake K, Sato Y, Yamashita R, Arakawa K, Iwasaki W. Collaborative environmental DNA sampling from petal surfaces of flowering cherry Cerasus × yedoensis “Somei-yoshino” across the Japanese archipelago. Journal of Plant Research [Internet]. 2018 Feb 19;131(4):709–17. Available from: http://dx.doi.org/10.1007/s10265-018-1017-x
#
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
