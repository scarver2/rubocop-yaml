# frozen_string_literal: true

# Gemfile
source "https://rubygems.org"

gemspec

# The lockfile is generated on Ruby 4, while CI also verifies the Ruby 3.2
# minimum. parallel releases after 2.0.0 require Ruby 3.3 and cannot be shared
# by that matrix.
gem "parallel", "2.0.0"
gem "rbs", "~> 3.9"
