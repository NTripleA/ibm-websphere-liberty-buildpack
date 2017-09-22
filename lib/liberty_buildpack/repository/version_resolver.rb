# Encoding: utf-8
# IBM WebSphere Application Server Liberty Buildpack
# Copyright 2013-2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'liberty_buildpack/repository'
require 'liberty_buildpack/util/tokenized_version'
require 'liberty_buildpack/diagnostics/logger_factory'

module LibertyBuildpack
  module Repository

    # A resolver that selects values from a collection based on a set of rules governing wildcards
    class VersionResolver

      private_class_method :new

      class << self

        # Resolves a version from a collection of versions.  The +candidate_version+ must be structured like:
        #   * up to three numeric components, followed by an optional string component
        #   * the final component may be a +
        # The resolution returns the maximum of the versions that match the candidate version
        #
        # @param [TokenizedVersion] candidate_version the version, possibly containing a wildcard, to resolve.  If
        #                                             +nil+, substituted with +.
        # @param [Array<String>] versions the collection of versions to resolve against
        # @return [TokenizedVersion] the resolved version or nil if no matching version is found
        def resolve(candidate_version, versions)
          tokenized_candidate_version = safe_candidate_version candidate_version
          tokenized_versions          = versions.map { |version| create_token(version) }.compact

          version = tokenized_versions
                    .select { |tokenized_version| matches? tokenized_candidate_version, tokenized_version }
                    .max { |a, b| a <=> b }
          puts "Let's see what we have: #{version}"
          version
        end

        private

        TOKENIZED_WILDCARD = LibertyBuildpack::Util::TokenizedVersion.new('+').freeze

        private_constant :TOKENIZED_WILDCARD

        def create_token(version)
          LibertyBuildpack::Util::TokenizedVersion.new(version, false)
        rescue StandardError => e
          logger = LibertyBuildpack::Diagnostics::LoggerFactory.get_logger
          logger.warn { "Discarding illegal version #{version}: #{e.message}" }
          nil
        end

        def safe_candidate_version(candidate_version)
          if candidate_version.nil?
            TOKENIZED_WILDCARD
          else
            unless candidate_version.is_a?(LibertyBuildpack::Util::TokenizedVersion)
              raise "Invalid TokenizedVersion '#{candidate_version}'"
            end

            candidate_version
          end
        end

        def matches?(tokenized_candidate_version, tokenized_version)
          (0..3).all? do |i|
            tokenized_candidate_version[i].nil? ||
              tokenized_candidate_version[i] == LibertyBuildpack::Util::TokenizedVersion::WILDCARD ||
              tokenized_candidate_version[i] == tokenized_version[i]
          end
        end

      end

    end

  end
end
