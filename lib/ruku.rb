$:.unshift File.dirname(__FILE__)

%w[remote remotes storage].each do |lib|
  require "ruku/#{lib}"
end
