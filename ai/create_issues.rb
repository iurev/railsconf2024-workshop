require 'octokit'
require 'yaml'

REPO = ENV['GITHUB_REPOSITORY']

client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

ROOT = File.expand_path('..', __dir__)

# Read the YAML file

filepath = File.join(ROOT, '.github/ISSUE_TEMPLATE/1.optimize_spec.yml')
file = File.read(filepath)
data = YAML.load(file)
prompt = data.dig("body", 1, "attributes", "value")



spec_file_regex = /\((\.\/spec\/.*?\/.*?)\)/


already_created = File.read(File.join(ROOT, 'ai/rd_prof_top.txt')) + File.read(File.join(ROOT, 'ai/rd_prof_top_2.txt'))
already_created = already_created.scan(spec_file_regex).flatten
already_created.map! { |fm| fm.split(":").first }
already_created.uniq!

file_matches = File.read(File.join(ROOT, 'ai/rd_prof_top_3.txt'))
file_matches = file_matches.scan(spec_file_regex).flatten
file_matches.map! { |fm| fm.split(":").first }
file_matches.reject! { |fm| fm.include? "ai_suggest" }
file_matches.reject! { |fm| fm.include? "maintenance_spec" }
file_matches.reject! { |fm| fm.include? "sidekiq_process_check_spec" }
file_matches.uniq!
file_matches.reject! do |fm|
  already_created.include? fm
end

file_matches.each.with_index do |file_match, index|
  puts "#{index} / #{file_matches.length}"
  next if index <= 79

  issue_title = "auto_issue N2: #{File.basename(file_match)}"
  issue_body = "### relative path to the spec file\n\n#{file_match}\n\n### prompt\n\n#{prompt}"
  issue = client.create_issue(REPO, issue_title, issue_body)

  # client.add_labels_to_an_issue(REPO, issue.number, ['optimize'])

  begin
    result = `ruby ai/create_pr.rb #{issue.number}`
  rescue => e
    puts e
  end

  sleep 30
end
