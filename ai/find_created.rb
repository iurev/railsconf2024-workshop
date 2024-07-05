require 'octokit'

SEARCH_TERM = 'auto_issue N2'
PATH_REGEX = /Path:(.*)/
REPO = ENV['GITHUB_REPOSITORY']

client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

# Search for PRs in the repository
prs = client.pull_requests(REPO, state: 'opened').select { |pr| pr.title.include?(SEARCH_TERM) }

prs.each do |pr|
  # Retrieve the full PR information, including the body
  full_pr = client.pull_request(REPO, pr.number)
  description = full_pr.body

  # Extract the path from the description using regex
  match = description.match(PATH_REGEX)
  if match
    puts match[1]
  else
    puts "PR ##{full_pr.number} does not contain the specified path."
  end
end
