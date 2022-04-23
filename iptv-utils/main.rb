require "bundler/setup"
require "dry/cli"
require "json"
require 'time'

require_relative "./channels"
require_relative "./cli"

Dry::CLI.new(IPTV::CLI).call
