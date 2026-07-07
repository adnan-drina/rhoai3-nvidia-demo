#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
SKILLS_DIR = File.join(ROOT, ".agents", "skills")
RULES_DIR = File.join(ROOT, ".agents", "rules")
AGENT_GUIDANCE = File.join(ROOT, ".agents", "skills", "project-agent-guidance", "SKILL.md")

ALLOWED_SKILL_GROUPS = Set[
  "Project Structure",
  "Demo Environment",
  "RHOAI Platform",
  "OpenShift Platform",
  "OpenShift Data Foundation",
  "NVIDIA Integration",
  "Assets & Miscellaneous"
].freeze

@errors = []
@warnings = []

def rel(path)
  path.sub("#{ROOT}/", "")
end

def error(message)
  @errors << message
end

def warn_check(message)
  @warnings << message
end

def frontmatter(path)
  text = File.read(path)
  unless text.start_with?("---\n")
    error("#{rel(path)} is missing YAML frontmatter")
    return [{}, text]
  end

  parts = text.split(/^---\s*$/, 3)
  if parts.length < 3
    error("#{rel(path)} has malformed YAML frontmatter")
    return [{}, text]
  end

  [YAML.safe_load(parts[1], permitted_classes: [Symbol], aliases: true) || {}, text]
rescue Psych::SyntaxError => e
  error("#{rel(path)} has invalid YAML frontmatter: #{e.message}")
  [{}, File.read(path)]
end

def skill_files
  Dir[File.join(SKILLS_DIR, "*", "SKILL.md")].sort
end

def validate_skills
  skills = {}

  skill_files.each do |path|
    metadata, = frontmatter(path)
    dir_name = File.basename(File.dirname(path))
    skill_name = metadata["name"]
    skills[dir_name] = path

    error("#{rel(path)} frontmatter name #{skill_name.inspect} does not match folder #{dir_name.inspect}") unless skill_name == dir_name

    required = %w[version platform-family platform-baseline ocp-baseline skill-group]
    missing = required.reject { |key| metadata.dig("metadata", key) }
    error("#{rel(path)} metadata is missing #{missing.join(', ')}") unless missing.empty?

    group = metadata.dig("metadata", "skill-group")
    error("#{rel(path)} has unknown skill group #{group.inspect}") if group && !ALLOWED_SKILL_GROUPS.include?(group)
  end

  skills
end

def validate_rules(skills)
  Dir[File.join(RULES_DIR, "*.md")].sort.each do |path|
    next if File.basename(path) == "README.md"

    metadata, text = frontmatter(path)
    error("#{rel(path)} frontmatter name #{metadata['name'].inspect} should match filename") unless metadata["name"] == File.basename(path, ".md")

    prefix = metadata["skill-prefix"]
    if prefix
      expected = skills.keys.select { |name| name.start_with?(prefix) }.sort
      referenced = text.scan(%r{\.agents/skills/([^/\s`]+)/SKILL\.md}).flatten.uniq.sort
      missing = expected - referenced
      error("#{rel(path)} does not reference #{missing.join(', ')}") unless missing.empty?
    end

    text.scan(%r{\.agents/skills/([^/\s`]+)/SKILL\.md}).flatten.each do |skill|
      next if skill.include?("*") || skill.include?("<") || skill.include?(">")

      error("#{rel(path)} references missing skill #{skill}") unless skills.key?(skill)
    end
  end
end

def validate_guidance_inventory(skill_count)
  text = File.read(AGENT_GUIDANCE)
  match = text.match(/\| Shared skills \| (?<count>\d+) \|/)
  if match
    expected = match[:count].to_i
    error("#{rel(AGENT_GUIDANCE)} shared skill count is #{expected}, expected #{skill_count}") unless expected == skill_count
  else
    error("#{rel(AGENT_GUIDANCE)} does not contain shared skill count row")
  end
end

def validate_referenced_skill_paths(skills)
  files = Dir[
    File.join(ROOT, "AGENTS.md"),
    File.join(ROOT, ".agents", "rules", "*.md"),
    File.join(ROOT, ".agents", "skills", "project-structure", "SKILL.md"),
    File.join(ROOT, ".agents", "skills", "project-agent-guidance", "SKILL.md")
  ]

  files.each do |path|
    text = File.read(path)
    text.scan(%r{\.agents/skills/([^/\s`]+)/SKILL\.md}).flatten.each do |skill|
      next if skill.include?("*") || skill.include?("<") || skill.include?(">")

      error("#{rel(path)} references missing skill #{skill}") unless skills.key?(skill)
    end
  end
end

skills = validate_skills
validate_rules(skills)
validate_referenced_skill_paths(skills)
validate_guidance_inventory(skills.length)

puts "Agent guidance validation"
puts "  skills: #{skills.length}"

unless @warnings.empty?
  puts "\nWarnings:"
  @warnings.each { |message| puts "  - #{message}" }
end

if @errors.empty?
  puts "  result: ok"
else
  puts "\nErrors:"
  @errors.each { |message| puts "  - #{message}" }
  exit 1
end
