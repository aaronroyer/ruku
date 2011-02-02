require 'test/unit'
require 'rubygems'
require 'mocha'

begin
  require 'redgreen' unless ENV['TM_MODE']
rescue LoadError
end

require File.join(File.dirname(__FILE__), *%w[.. lib ruku])
include Ruku