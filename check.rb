#!/usr/bin/env ruby
require 'xmlsimple'
require 'json'

# for the moment, we hardcoded the file name - see circle.yml
tick_file = "tick.json"

# hold the contents of the tick_file
tick_data = ""

# hold the internal structure of the tick_file
tick_parsed = {}

# a fake class name
class_name = "net.produxi.rj.wwv"

# exit code state
exit_state = 0

# state structure holding all the tests
state = {:testcase=>[]}

# create a node counting the tests
at_exit do
  res = XmlSimple.xml_out(state,{"RootName"=>"testsuite"})
  print res
  exit exit_state
end

# check one - is there a file // is the file readable?
test_name = "file read test"
begin
  tick_data = File.read(tick_file)
rescue Exception => e
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"fatal",:content=>e.message}]})
  exit_state+=1
  exit
end
state[:testcase].push({:classname=>class_name,:name=>test_name})

# check two - is this json?
test_name = "JSON parse test"
begin
  tick_parsed = JSON.parse(tick_data)
rescue Exception => e
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"fatal",:content=>e.message}]})
  exit_state+=1
  exit
end
state[:testcase].push({:classname=>class_name,:name=>test_name})

## required element tests
# is there a generator statement
test_name = "generator statement"
if tick_parsed.key?("GENERATOR")
  state[:testcase].push({:classname=>class_name,:name=>test_name})
else
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"fatal",:content=>"no GENERATOR key found"}]})
  exit_state+=1
end

# is there a calendar statement, and if so, is it gregorian?
test_name = "calendar statement"
if (tick_parsed.key?("CALENDAR") && tick_parsed["CALENDAR"] == "Gregorian")
  state[:testcase].push({:classname=>class_name,:name=>test_name})
else
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"fatal",:content=>"CALENDAR key missing or not Gregorian"}]})
  exit_state+=1
end

# is there an epoch statement, and if so can I parse it?
test_name = "epoch data"
if (tick_parsed.key?("EPOCH") && Time.at(tick_parsed["EPOCH"]))
  state[:testcase].push({:classname=>class_name,:name=>test_name})
else
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"fatal",:content=>"EPOCH data missing or malformed"}]})
  exit_state+=1
end

# everything in these top level keys, if they exist, should be integers.
integer_keys = ["LEAP_SECONDS", "HOUR", "YDAY", "MONTH", "MINUTE", "DAY", "WDAY", "SECOND", "YEAR"]
integer_keys.each{ |key|
  test_name = "integer key test - #{key}"
  if (tick_parsed.key?(key) && (tick_parsed[key].is_a? Integer))
    state[:testcase].push({:classname=>class_name,:name=>test_name})
  else
    state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"warning",:content=>"#{key} data malformed"}]})
  end
}

# if there *is* a TZ key, the LONG_NAME key must exist underneath and be a string.
test_name = "TZ->LONG_NAME test"
if (tick_parsed.key?("TZ") && (tick_parsed["TZ"].key?("LONG_NAME")) && (tick_parsed["TZ"]["LONG_NAME"].is_a? String))
  state[:testcase].push({:classname=>class_name,:name=>test_name})
else
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"warning",:content=>"TZ->LONG_NAME data missing/malformed"}]})
end

# if there is a IS_DST key, it must be boolean - NOTE: we're actually checking for JSON true|false strings...
test_name = "IS_DST type test"
if (tick_parsed.key?("IS_DST") && ([true,false].include? tick_parsed["IS_DST"]))
  state[:testcase].push({:classname=>class_name,:name=>test_name})
else
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"warning",:content=>"IS_DST data malformed"}]})
end

# WEEK _must_ be the compound YEAR_OF + NUMBER hash.
test_name = "WEEK structure test"
if (tick_parsed.key?("WEEK") && (tick_parsed["WEEK"].key?("NUMBER")) && (tick_parsed["WEEK"].key?("YEAR_OF")) &&
    (tick_parsed["WEEK"]["NUMBER"].is_a? Integer) && (tick_parsed["WEEK"]["YEAR_OF"].is_a? Integer))
  state[:testcase].push({:classname=>class_name,:name=>test_name})
else
  state[:testcase].push({:classname=>class_name,:name=>test_name,:failure=>[{:type=>"warning",:content=>"WEEK data malformed/missing"}]})
end

