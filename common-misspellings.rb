#!/usr/bin/env ruby
# coding: utf-8

class CommonMisspellings

  $ENABLE_REVERSE_MISPELLING = true

  @@file_contents=File.readlines($LOAD_PATH.first + "/common-misspellings.txt").delete_if { |line| line =~ /^#/ or line =~ /^[ ]*$/ }.join

  def self.dictionary
    setup unless defined? @@dictionary
  end
  
end