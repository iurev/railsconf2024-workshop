require 'octokit'
require 'base64'

issue_number = ARGV[0].to_i
repo = ENV['GITHUB_REPOSITORY']

client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

issue = client.issue(repo, issue_number)
issue_body = issue.body

path = issue_body.match(/### relative path to the spec file\n\n(.+)/)&.[](1)&.strip
requests = issue_body.match(/### Additional requests for AI\n\n(.+)/m)&.[](1)&.strip

branch_name = "optimize-#{issue_number}"
client.create_ref(repo, "refs/heads/#{branch_name}", client.ref(repo, "heads/master").object.sha)

# Edit the file
file_content = client.contents(repo, path: path, ref: branch_name)
decoded_content = Base64.decode64(file_content.content)
new_content = decoded_content.lines.insert(1, "# aiptimize started\n").join

client.update_contents(
  repo,
  path,
  "Add aiptimize comment",
  file_content.sha,
  new_content,
  branch: branch_name
)

# Create PR
pr = client.create_pull_request(
  repo,
  'master',
  branch_name,
  "Optimize: #{issue.title}",
  "Optimizations for ##{issue_number}\n\nPath: #{path}\nRequests: #{requests}",
  draft: true
)

client.add_labels_to_an_issue(repo, pr.number, ['optimize'])