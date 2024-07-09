### STEP 1

require 'octokit'
require 'base64'
require 'open3'

MAIN_BRANCH = "workshop"
# MODEL = "qwen/qwen-2-72b-instruct" # never returns full file :(
MODEL = "deepseek/deepseek-coder" # GOOD; GOOD;
# MODEL = "microsoft/wizardlm-2-8x22b" # GOOD; it can't really fix mistakes it makes (((
# MODEL = "databricks/dbrx-instruct" # nah;;; it tries to `let_it_be!!!`

issue_number = ARGV[0].to_i
@repo = ENV['GITHUB_REPOSITORY']

@client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

issue = @client.issue(@repo, issue_number)
issue_body = issue.body

path = issue_body.match(/### relative path to the spec file\n\n(.+)/)&.[](1)&.strip
agent_prompt = issue_body.match(/### prompt\n\n(.+)/m)&.[](1)&.strip

bn = MODEL.gsub(/[^a-zA-Z0-9]/, '_')
branch_name = "optimize-#{issue_number}-#{bn}"


# remove branch and PR if they exist
prs = @client.pull_requests(@repo, state: 'open', head: "#{@repo.split('/').first}:#{branch_name}")
prs.each do |pr|
  @client.update_pull_request(@repo, pr.number, state: 'closed')
end

# Delete the branch if it exists
begin
  @client.branch(@repo, branch_name)
  @client.delete_branch(@repo, branch_name)
  puts "Branch #{branch_name} deleted."
rescue Octokit::NotFound
  puts "Branch #{branch_name} does not exist, so cannot be deleted."
end


@client.create_ref(@repo, "refs/heads/#{branch_name}", @client.ref(@repo, "heads/#{MAIN_BRANCH}").object.sha)

# Edit the file
old_code = @client.contents(@repo, path: path, ref: branch_name)
decoded_content = Base64.decode64(old_code.content)
new_code = decoded_content.lines.insert(1, "# aiptimize started\n").join

@client.update_contents(
  @repo,
  path,
  "Add aiptimize comment",
  old_code.sha,
  new_code,
  branch: branch_name
)

old_code = new_code

# Create PR
@pr = @client.create_pull_request(
  @repo,
  MAIN_BRANCH,
  branch_name,
  "Optimize: #{issue.title}",
  "Optimizations for ##{issue_number} using #{MODEL}\n\nPath: #{path}\nRequests: #{agent_prompt}",
  draft: true
)

@client.add_labels_to_an_issue(@repo, @pr.number, ['optimize'])











### STEP 2


require "json/ext"
require "faraday"

API_KEY = ENV['CLAUDE_API_KEY']
PIPE_KEY = ENV['OPENPIPE_API_KEY']
ROUTER_KEY = ENV['OPENROUTER_KEY']

ROOT = File.expand_path('..', __dir__)
# MODEL = "anthropic/claude-3.5-sonnet"
MAX_TOKENS = 4096


example_original_files =
  %w[
    spec/controllers/statuses_controller_spec.rb
  ].reduce([]) do |acc, file|
    acc << "# #{file}\n\n" + File.read(File.join(ROOT, file))[0..5000]
  end.join("\n\n")

example_patch = File.read(File.join(ROOT, "ai", ENV.fetch("PATCH_EXAMPLE", "sample.patch")))

target_file_path = path
output = `FPROF=1 RD_PROF=1 bundle exec rspec #{target_file_path}`

prompt = agent_prompt % {example_rspec_files: example_original_files, example_git_diff: example_patch, fprof: output}
prompt = <<-EOS
  You're an excellent Ruby developer. Please, refactor the rspec file I send to you by using let_it_be

  let_it_be is a let alternative from the test-prof gem.
  It only creates a record ONCE. It uses before(:all) under the hood.
  So, it's basically a syntastic sugar for it.


  You MUST always respond with the full file!
EOS

messages = []


raise "Please provide a valid target file path" unless target_file_path && File.file?(target_file_path)

target_file = File.read(target_file_path)

messages << { role: "user", content: "#{prompt} \n\nOptimize this test file:\n\n #{target_file}" }

run_id = 0

source_file_too_long = false


def custom_print(text)
  @client.add_comment(@repo, @pr.number, text)
end

def save_request(response, messages)
  return # temp disable openpipe

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


RUNS_LIMIT = 4

loop do
  if run_id >= RUNS_LIMIT
    custom_print "Limit #{RUNS_LIMIT} has been reached. Optimization stops here"
    break
  end

  run_id += 1

  custom_print "RUN_ID: #{run_id}"

  # conn = Faraday.new(url: 'http://172.18.0.1:11434') do |conn|
  #   conn.options.open_timeout = 300 # Set the open timeout to 300 seconds (5 minutes)
  #   conn.options.timeout = 300      # Set the read timeout to 300 seconds (5 minutes)

  #   # Use default middleware stack or customize as needed
  #   conn.adapter Faraday.default_adapter
  # end

  # Define the request payload
  # payload = {
  #   model: 'eramax/nxcode-cq-7b-orpo:q6',
  #   messages: messages,
  #   stream: false
  # }.to_json

  # Send POST request to Ollama
  # response = conn.post('/api/chat', payload, { 'Content-Type' => 'application/json' })

  response = Faraday.post('https://openrouter.ai/api/v1/chat/completions') do |req|
    req.headers['Content-Type'] = 'application/json'
    req.headers['Authorization'] = "Bearer #{ENV['OPENROUTER_KEY']}"
    req.body = {
      model: MODEL,
      messages: messages,
      max_tokens: MAX_TOKENS,
    }.to_json
  end

  unless response.success?
    @client.add_labels_to_an_issue(@repo, @pr.number, ['failed'])
    custom_print("Something went wrong\n\n#{response.status}\n\n#{response.env.response_body}")

    return
  end

  result = nil
  begin
    result = JSON.parse(response.env.response_body)["choices"][0]["message"]["content"]
  rescue
    @client.add_labels_to_an_issue(@repo, @pr.number, ['failed'])
    custom_print("Something went wrong\n\n#{response.status}\n\n#{response.env.response_body}")

    return
  end

  messages << { role: "assistant", content: result }

  # save_request(JSON.parse(response.env.response_body), messages)

  lines = result.split("\n")

  # action_index = lines.find_index { _1 =~ /^Action: (\w+)$/ }
  action_index = 1

  if action_index
    action = "run_rspec"
    last_comment = ""
    custom_print "\n\nAction: #{action} (at line #{action_index + 1})\n#{last_comment}"

    if action == "run_rspec"
      binding.irb
      code_begin_index = lines.find_index { _1 =~ /```/ } + 1
      code_end_index = code_begin_index + lines[code_begin_index..].find_index { _1 =~ /```/ }

      source_file_too_long = false

      new_code = result.split("\n")[code_begin_index...code_end_index].join("\n")

      new_spec_path = target_file_path.sub(/_spec\.rb$/, "_ai_suggest_#{run_id}_spec.rb")

      File.write(new_spec_path, new_code)

      @client.update_contents(
        @repo,
        path,
        "RUN_ID: #{run_id}",
        Digest::SHA1.hexdigest("blob #{old_code.bytesize}\0#{old_code}"),
        new_code,
        branch: branch_name
      )
      old_code = new_code

      custom_print "\n\nNew spec file saved at #{new_spec_path}\n"

      # execute bundle exec rspec new_spec_path with clean bundle env and capture the output
      command = "FPROF=1 RD_PROF=1 bundle exec rspec #{new_spec_path}"

      stdout, stderr, status = Open3.capture3(command)

      if status.success?
        custom_print "Success: #{stdout}"
        break
      else
        custom_print "Errors:\n\n#{stdout}"
        messages << { role: "user", content: "I got these errors after running bundle exec rspec. Please fix them:\n\n#{stdout}" }
      end
    else
      custom_print "Unknown action: #{action}\n\n#{result}"
      break
    end
  else
    custom_print "No action found\n\n#{result}"
    break
  end
end
