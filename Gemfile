# frozen_string_literal: true

# Gemfile
source "https://rubygems.org"

gemspec

# The lockfile is generated on Ruby 4, while CI also verifies the Ruby 3.2
# minimum. parallel 2.x requires Ruby 3.3 and cannot be shared by that matrix.
gem "parallel", "~> 1.27"
gem "rbs", "~> 3.9"
