require 'octokit'
require 'base64'

SEARCH_TERM = 'auto_issue N2'
PATH_REGEX = /Path:(.*)/
REPO = ENV['GITHUB_REPOSITORY']
LABELS = ['optimize', 'success'].sort
LOCAL_BASE_PATH = File.expand_path('..', __dir__)

client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

# Search for PRs in the repository
prs = client.pull_requests(REPO, state: 'opened', per_page: 100)
  .select { |pr| pr.title.include?(SEARCH_TERM) }
  .select { |pr| LABELS == pr.labels.map(&:name).sort }

prs.each do |pr|
  # Retrieve the full PR information, including the body
  full_pr = client.pull_request(REPO, pr.number)
  description = full_pr.body

  # Extract the path from the description using regex
  match = description.match(PATH_REGEX)
  if match
    file_path = match[1].strip

    # Get the file content from the PR's branch
    pr_branch = full_pr.head.ref
    file_content = client.contents(REPO, path: file_path, query: { ref: pr_branch })

    # Decode the file content
    decoded_content = Base64.decode64(file_content.content)

    # Write the content to the local file
    local_file_path = File.join(LOCAL_BASE_PATH, file_path)
    # FileUtils.mkdir_p(File.dirname(local_file_path))
    File.write(local_file_path, decoded_content)

    puts "PR ##{full_pr.number}: #{file_path} has been updated in your local repository."
  else
    puts "PR ##{full_pr.number} does not contain the specified path."
  end
end
