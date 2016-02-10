require "./foreman/version.cr"

module Foreman
  def self.runner
    File.expand_path("../../bin/foreman-runner", __FILE__)
  end
end
