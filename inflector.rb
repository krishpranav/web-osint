require 'singleton'

module ActiveSupport

  module Inflector

    class Inflections
      include Singleton

      attr_reader :plurals, :singulars, :uncountables

      def initialize
        @plurals, @singulars, @uncountables = [], [], []
      end

      # Specifies a new pluralization rule and its replacement. The rule can either be a string or a regular expression.
      # The replacement should always be a string that may include references to the matched data from the rule.
      def plural(rule, replacement)
        @plurals.insert(0, [rule, replacement])
      end

      # Specifies a new singularization rule and its replacement. The rule can either be a string or a regular expression.
      # The replacement should always be a string that may include references to the matched data from the rule.
      def singular(rule, replacement)
        @singulars.insert(0, [rule, replacement])
      end

      # Specifies a new irregular that applies to both pluralization and singularization at the same time. This can only be used
      # for strings, not regular expressions. You simply pass the irregular in singular and plural form.
      #
      # Examples:
      #   irregular 'octopus', 'octopi'
      #   irregular 'person', 'people'
      def irregular(singular, plural)
        if singular[0,1].upcase == plural[0,1].upcase
          plural(Regexp.new("(#{singular[0,1]})#{singular[1..-1]}$", "i"), '\1' + plural[1..-1])
          singular(Regexp.new("(#{plural[0,1]})#{plural[1..-1]}$", "i"), '\1' + singular[1..-1])
        else
          plural(Regexp.new("#{singular[0,1].upcase}(?i)#{singular[1..-1]}$"), plural[0,1].upcase + plural[1..-1])
          plural(Regexp.new("#{singular[0,1].downcase}(?i)#{singular[1..-1]}$"), plural[0,1].downcase + plural[1..-1])
          singular(Regexp.new("#{plural[0,1].upcase}(?i)#{plural[1..-1]}$"), singular[0,1].upcase + singular[1..-1])
          singular(Regexp.new("#{plural[0,1].downcase}(?i)#{plural[1..-1]}$"), singular[0,1].downcase + singular[1..-1])
        end
      end

      # Add uncountable words that shouldn't be attempted inflected.
      #
      # Examples:
      #   uncountable "money"
      #   uncountable "money", "information"
      #   uncountable %w( money information rice )
      def uncountable(*words)
        (@uncountables << words).flatten!
      end

      # Clears the loaded inflections within a given scope (default is <tt>:all</tt>).
      # Give the scope as a symbol of the inflection type, the options are: <tt>:plurals</tt>,
      # <tt>:singulars</tt>, <tt>:uncountables</tt>.
      #
      # Examples:
      #   clear :all
      #   clear :plurals
      def clear(scope = :all)
        case scope
        when :all
          @plurals, @singulars, @uncountables = [], [], []
        else
          instance_variable_set "@#{scope}", []
        end
      end
    end

    extend self

    # Yields a singleton instance of Inflector::Inflections so you can specify additional
    # inflector rules.
    #
    # Example:
    #   Inflector.inflections do |inflect|
    #     inflect.uncountable "rails"
    #   end
    def inflections
      if block_given?
        yield Inflections.instance
      else
        Inflections.instance
      end
    end

    # Returns the plural form of the word in the string.
    #
    # Examples:
    #   "post".pluralize             # => "posts"
    #   "octopus".pluralize          # => "octopi"
    #   "sheep".pluralize            # => "sheep"
    #   "words".pluralize            # => "words"
    #   "the blue mailman".pluralize # => "the blue mailmen"
    #   "CamelOctopus".pluralize     # => "CamelOctopi"
    def pluralize(word)
      result = word.to_s.dup

      if word.empty? || inflections.uncountables.include?(result.downcase)
        result
      else
        inflections.plurals.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
        result
      end
    end

    # The reverse of +pluralize+, returns the singular form of a word in a string.
    #
    # Examples:
    #   "posts".singularize            # => "post"
    #   "octopi".singularize           # => "octopus"
    #   "sheep".singluarize            # => "sheep"
    #   "word".singluarize             # => "word"
    #   "the blue mailmen".singularize # => "the blue mailman"
    #   "CamelOctopi".singularize      # => "CamelOctopus"
    def singularize(word)
      result = word.to_s.dup

      if inflections.uncountables.include?(result.downcase)
        result
      else
        inflections.singulars.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
        result
      end
    end

    # By default, +camelize+ converts strings to UpperCamelCase. If the argument to +camelize+
    # is set to <tt>:lower</tt> then +camelize+ produces lowerCamelCase.
    #
    # +camelize+ will also convert '/' to '::' which is useful for converting paths to namespaces.
    #
    # Examples:
    #   "active_record".camelize                # => "ActiveRecord"
    #   "active_record".camelize(:lower)        # => "activeRecord"
    #   "active_record/errors".camelize         # => "ActiveRecord::Errors"
    #   "active_record/errors".camelize(:lower) # => "activeRecord::Errors"
    def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        lower_case_and_underscored_word.first + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end

    # Capitalizes all the words and replaces some characters in the string to create
    # a nicer looking title. +titleize+ is meant for creating pretty output. It is not
    # used in the Rails internals.
    #
    # +titleize+ is also aliased as as +titlecase+.
    #
    # Examples:
    #   "man from the boondocks".titleize # => "Man From The Boondocks"
    #   "x-men: the last stand".titleize  # => "X Men: The Last Stand"
    def titleize(word)
      humanize(underscore(word)).gsub(/\b('?[a-z])/) { $1.capitalize }
    end

    # The reverse of +camelize+. Makes an underscored, lowercase form from the expression in the string.
    #
    # Changes '::' to '/' to convert namespaces to paths.
    #
    # Examples:
    #   "ActiveRecord".underscore         # => "active_record"
    #   "ActiveRecord::Errors".underscore # => active_record/errors
    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    # Replaces underscores with dashes in the string.
    #
    # Example:
    #   "puni_puni" # => "puni-puni"
    def dasherize(underscored_word)
      underscored_word.gsub(/_/, '-')
    end

    # Capitalizes the first word and turns underscores into spaces and strips a
    # trailing "_id", if any. Like +titleize+, this is meant for creating pretty output.
    #
    # Examples:
    #   "employee_salary" # => "Employee salary"
    #   "author_id"       # => "Author"
    def humanize(lower_case_and_underscored_word)
      lower_case_and_underscored_word.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
    end

    # Removes the module part from the expression in the string.
    #
    # Examples:
    #   "ActiveRecord::CoreExtensions::String::Inflections".demodulize # => "Inflections"
    #   "Inflections".demodulize                                       # => "Inflections"
    def demodulize(class_name_in_module)
      class_name_in_module.to_s.gsub(/^.*::/, '')
    end

    # Create the name of a table like Rails does for models to table names. This method
    # uses the +pluralize+ method on the last word in the string.
    #
    # Examples
    #   "RawScaledScorer".tableize # => "raw_scaled_scorers"
    #   "egg_and_ham".tableize     # => "egg_and_hams"
    #   "fancyCategory".tableize   # => "fancy_categories"
    def tableize(class_name)
      pluralize(underscore(class_name))
    end

    # Create a class name from a plural table name like Rails does for table names to models.
    # Note that this returns a string and not a Class. (To convert to an actual class
    # follow +classify+ with +constantize+.)
    #
    # Examples:
    #   "egg_and_hams".classify # => "EggAndHam"
    #   "posts".classify        # => "Post"
    #
    # Singular names are not handled correctly:
    #   "business".classify     # => "Busines"
    def classify(table_name)
      # strip out any leading schema name
      camelize(singularize(table_name.to_s.sub(/.*\./, '')))
    end

    # Creates a foreign key name from a class name.
    # +separate_class_name_and_id_with_underscore+ sets whether
    # the method should put '_' between the name and 'id'.
    #
    # Examples:
    #   "Message".foreign_key        # => "message_id"
    #   "Message".foreign_key(false) # => "messageid"
    #   "Admin::Post".foreign_key    # => "post_id"
    def foreign_key(class_name, separate_class_name_and_id_with_underscore = true)
      underscore(demodulize(class_name)) + (separate_class_name_and_id_with_underscore ? "_id" : "id")
    end

    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end

    def ordinalize(number)
      if (11..13).include?(number.to_i % 100)
        "#{number}th"
      else
        case number.to_i % 10
        when 1; "#{number}st"
        when 2; "#{number}nd"
        when 3; "#{number}rd"
        else    "#{number}th"
        end
      end
    end
  end
end

require File.dirname(__FILE__) + '/inflections'
