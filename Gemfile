# frozen_string_literal: true

# Gemfile
source "https://rubygems.org"

gemspec

# The lockfile is generated on Ruby 4, while CI also verifies the Ruby 3.2
# minimum. parallel 2.1 requires Ruby 3.3 and cannot be shared by that matrix.
gem "parallel", "< 2.1"
gem "rbs", "~> 3.9"
