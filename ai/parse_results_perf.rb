require 'csv'

def parse_file(filename)
  content = File.read(filename)
  test_results = content.strip.split(/--- ---\n/)

  parsed_data = test_results.map do |result|
    next if result.strip.empty?

    file_name = result.match(/Testing file: (.+)/)&.[](1)
    current_time = result.match(/Current version average time: ([\d.]+) seconds/)&.[](1)&.to_f
    previous_time = result.match(/Previous version average time: ([\d.]+) seconds/)&.[](1)&.to_f
    perf_diff = result.match(/Percentage difference: ([-\d.]+)%/)&.[](1)&.to_f

    if file_name && current_time && previous_time && perf_diff
      {
        file_name: file_name,
        current_time: current_time,
        previous_time: previous_time,
        perf_difference: perf_diff
      }
    end
  end.compact

  parsed_data.sort_by { |row| -row[:perf_difference] }
end

def print_table(data)
  # Print table header
  puts "#{' File Name'.ljust(70)} #{'Current Time'.ljust(15)} #{'Previous Time'.ljust(15)} #{'Perf Difference'.ljust(15)}"
  puts "-" * 115

  # Print table rows
  data.each do |row|
    puts "#{row[:file_name].ljust(70)} #{sprintf('%.2f', row[:current_time]).ljust(15)} #{sprintf('%.2f', row[:previous_time]).ljust(15)} #{sprintf('%.2f', row[:perf_difference]).ljust(15)}"
  end
end

# Usage
filename = 'ai/results_perf.txt'  # Replace with your actual file name
parsed_data = parse_file(filename)
print_table(parsed_data)
