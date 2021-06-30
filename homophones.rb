class Homophones
  @@homophones=File.readlines($LOAD_PATH.first + "/homophones.txt").delete_if { |line| line =~ /^#/ or line =~ /^[ ]*$/ }.join


  def self.dictionary
    setup unless defined?  @@dictionary
    @@dictionary
  end

  private
  
end