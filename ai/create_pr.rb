### STEP 1

require 'octokit'
require 'base64'

issue_number = ARGV[0].to_i
@repo = ENV['GITHUB_REPOSITORY']

@client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

issue = @client.issue(@repo, issue_number)
issue_body = issue.body

path = issue_body.match(/### relative path to the spec file\n\n(.+)/)&.[](1)&.strip
requests = issue_body.match(/### Additional requests for AI\n\n(.+)/m)&.[](1)&.strip

branch_name = "optimize-#{issue_number}"
@client.create_ref(@repo, "refs/heads/#{branch_name}", @client.ref(@repo, "heads/master").object.sha)

# Edit the file
file_content = @client.contents(@repo, path: path, ref: branch_name)
decoded_content = Base64.decode64(file_content.content)
new_content = decoded_content.lines.insert(1, "# aiptimize started\n").join

@client.update_contents(
  @repo,
  path,
  "Add aiptimize comment",
  file_content.sha,
  new_content,
  branch: branch_name
)

# Create PR
@pr = @client.create_pull_request(
  @repo,
  'master',
  branch_name,
  "Optimize: #{issue.title}",
  "Optimizations for ##{issue_number}\n\nPath: #{path}\nRequests: #{requests}",
  draft: true
)

@client.add_labels_to_an_issue(@repo, @pr.number, ['optimize'])











### STEP 2


require "json/ext"
require "faraday"

API_KEY = ENV['CLAUDE_API_KEY']
PIPE_KEY = ENV['OPENPIPE_API_KEY']

ROOT = File.expand_path('..', __dir__)
MODEL = "anthropic/claude-3.5-sonnet"
MAX_TOKENS = 4096
agent_prompt = File.read(File.join(ROOT, "ai", "prompt.txt"))


example_original_files =
  %w[
    spec/controllers/statuses_controller_spec.rb
  ].reduce([]) do |acc, file|
    acc << "# #{file}\n\n" + File.read(File.join(ROOT, file))[0..5000]
  end.join("\n\n")

example_patch = File.read(File.join(ROOT, "ai", ENV.fetch("PATCH_EXAMPLE", "sample.patch")))

prompt = agent_prompt % {example_rspec_files: example_original_files, example_git_diff: example_patch}

messages = []

target_file_path = path

raise "Please provide a valid target file path" unless target_file_path && File.file?(target_file_path)

target_file = File.read(target_file_path)


messages << { role: "user", content: "#{prompt} \n\nOptimize this test file:\n\n #{target_file}" }

run_id = 0

source_file_too_long = false


def custom_print(text)
  @client.add_comment(@repo, @pr.number, text)
end

def save_request(response, messages)
  url = "https://app.openpipe.ai/api/v1/report-anthropic"

  payload = {
    requestedAt: Time.now.to_i,
    receivedAt: Time.now.to_i,
    reqPayload: {
      messages: messages,
      model: MODEL,
      stream: false,
      max_tokens: MAX_TOKENS,
    },
    respPayload: JSON.parse(response.to_json),
    statusCode: 200,
    tags: { aaa: "123" }
  }

  headers = {
    "Authorization" => "Bearer #{PIPE_KEY}",
    "Content-Type" => "application/json"
  }

  Faraday.post(url) do |req|
    req.headers = headers
    req.body = payload.to_json
  end
end

last_response = nil

loop do
  run_id += 1

  custom_print "RUN_ID: #{run_id}"

  url = 'https://api.anthropic.com/v1/messages'

  payload = {
    model: 'claude-3-5-sonnet-20240620',
    max_tokens: MAX_TOKENS,
    messages: messages,
  }

  headers = {
    "x-api-key" => API_KEY,
    "anthropic-version" => "2023-06-01",
    "content-type" => "application/json"
  }

  response = Faraday.post(url) do |req|
    req.headers = headers
    req.body = payload.to_json
  end

  last_response = response

  result = JSON.parse(response.env.response_body)["content"][0]["text"]
  messages << { role: "assistant", content: result }

  save_request(JSON.parse(response.env.response_body), messages)

  custom_print result

  lines = result.split("\n")

  action_index = lines.find_index { _1 =~ /^Action: (\w+)$/ }

  if action_index
    action = Regexp.last_match[1]
    custom_print "\n\nAction: #{action} (at line #{action_index + 1})\n"

    if action == "run_rspec"
      code_end_index = lines[action_index..].find_index { _1 =~ /__END__/ }

      unless code_end_index
        puts "\n\nNo code end found, looks like a partial file...\n\n"
        return custom_print(" Stopping.") if source_file_too_long

        messages << { role: "user", content: "Observation: This doesn't look like a full Ruby/RSpec file, you must provide a full version" }
        source_file_too_long = true
        next
      end

      source_file_too_long = false

      new_code = lines[action_index + 1..action_index + code_end_index - 1].join("\n")

      new_spec_path = target_file_path.sub(/_spec\.rb$/, "_ai_suggest_#{run_id}_spec.rb")

      File.write(new_spec_path, new_code)

      @client.update_contents(
        @repo,
        path,
        "Add aiptimize comment",
        Digest::SHA1.hexdigest("blob #{new_content.bytesize}\0#{new_content}"),
        new_code,
        branch: branch_name
      )

      custom_print "\n\nNew spec file saved at #{new_spec_path}\n"

      # execute bundle exec rspec new_spec_path with clean bundle env and capture the output
      output = `FPROF=1 RD_PROF=1 bundle exec rspec #{new_spec_path}`

      custom_print output

      messages << { role: "user", content: "Observation:\n\n#{output}" }
    else
      puts "Unknown action: #{action}"
      break
    end
  else
    puts "No action found"
    break
  end
end
