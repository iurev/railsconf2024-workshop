require 'faraday'
require 'json'
require 'time'
require 'open3'

file_names = [
  "ai/prompt.txt",
  "ai/output.md",
]

file_names += Dir.glob('spec/models/hiring_requisition*_spec.rb')

name = "test-prof: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"

TOKEN = ""

specs = Dir.glob('spec/models/hiring_requisition*_spec.rb').sort
original = specs.pop
specs.each.with_index do |spec, index|
  path = "ai/patches/#{index + 1}.patch"
  file_names << path

  cmd = "git diff --no-index #{original} #{spec} > #{path}"
  stdout, stderr, status = Open3.capture3(cmd)

  original = spec
end

files = {}

file_names.each do |fn|
  files[fn.gsub("/", "__")] = {
    content: File.read(fn)
  }
end

response = Faraday.post('https://api.github.com/gists') do |req|
  req.headers['Accept'] = 'application/vnd.github+json'
  req.headers['Authorization'] = "Bearer #{TOKEN}"
  req.headers['X-GitHub-Api-Version'] = '2022-11-28'
  req.body = {
    description: name,
    public: false,
    files: files
  }.to_json
end

puts response.body
