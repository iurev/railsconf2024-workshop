#!/usr/bin/env ruby

require 'open3'

def run_command(command)
  output, status = Open3.capture2e(command)
  [output, status.success?]
end

def average_runtime(file, runs = 10)
  times = runs.times.map do
    start_time = Time.now
    run_command("bin/rspec #{file} > /dev/null")
    Time.now - start_time
  end
  times.sum / runs
end

# Find the first changed _spec.rb file alphabetically
changed_files = File.read("./changed_4.txt").split("\n")
if changed_files.empty?
  puts "No changed _spec.rb files found."
  exit 1
end

changed_files.each do |first_spec_file|
  puts "--- ---"
  puts "Testing file: #{first_spec_file}"

  # Run the spec file once to check for failures
  output, success = run_command("bin/rspec #{first_spec_file}")
  unless success
    puts "Tests failed. Stopping execution."
    puts output
  end

  # Run the current version 10 times and calculate average
  current_avg = average_runtime(first_spec_file)
  puts "Current version average time: #{current_avg.round(2)} seconds"

  # Run the previous version 10 times and calculate average
  previous_avg = average_runtime(first_spec_file.gsub(/^spec/, "previous_spec"))
  puts "Previous version average time: #{previous_avg.round(2)} seconds"

  # Calculate the percentage difference
  diff_percent = ((current_avg - previous_avg) / previous_avg) * 100
  puts "Percentage difference: #{diff_percent.round(2)}%"

  # Check if the difference is less than 10%
  if diff_percent < 10
    puts "Performance degradation detected. Failing."
    File.open('to_stage.txt', 'a') do |file|
      file.puts first_spec_file
    end
  else
    File.open('to_remove.txt', 'a') do |file|
      file.puts first_spec_file
    end
    puts "Success! Performance is acceptable."
  end
end
