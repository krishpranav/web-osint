#!/usr/bin/env ruby

require 'singleton'

module ActiveSupport
  module Inflector

    class Inflections
      include Singleton

      attr_reader :plurals, :singulars, :uncountables

      def initialize
        @plurals, @singulars, @uncountables = [], [], []
      end

      def plural(rule, replacement)
        @plurals.insert()
      end
    end
  end
end