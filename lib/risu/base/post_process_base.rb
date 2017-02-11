# Copyright (c) 2010-2017 Jacob Hammack.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


module Risu
	module Base

		#
		class PostProcessBase
			@possible_postprocesses = Array.new

			class << self
				attr_reader :possible_postprocesses
			end

			#
			attr_accessor :info

			#
			def self.inherited(child)
				possible_postprocesses << child
			end

			def == (other)

				if self.info == nil || self.info[:plugin_id] == nil
					false
				elsif other == nil || other.info == nil || other.info[:plugin_id] == nil
					false
				else
					self.info[:plugin_id] == other.info[:plugin_id]
				end
			end

			def <=> (other)
				if self.info[:plugin_id] < other.info[:plugin_id]
					-1
				elsif self.info[:plugin_id] > other.info[:plugin_id]
					1
				else
					0
				end
			end

			#
			#def initialize
			#	@info = {}
			#end

			# NOTE:
			#looks like its working
			def newest_reader_plugin
				newest = DateTime.new(0001, 01, 01)
				newest_plugin = nil

				@info[:plugin_ids].each do |id|
					plugin = Plugin.find_by_id(id)

					if plugin == nil || plugin.plugin_modification_date == nil
						next
					end

					if plugin.plugin_modification_date >= newest
						newest = plugin.plugin_modification_date if plugin.plugin_modification_date != nil
						newest_plugin = plugin
					end
				end

				return newest_plugin
			end

			# Creates a rollup plugin based on the newest Adobe Reader
			#
			def create_plugin

				plugin = Plugin.find_by_id(@info[:plugin_id])

				newest_plugin = newest_reader_plugin()

				if newest_plugin == nil
					return
				end

				if plugin == nil
					plugin = Plugin.new
				end

				plugin.id = @info[:plugin_id]
				plugin.plugin_name = @info[:plugin_name]
				plugin.family_name = "Risu Rollup Plugins"
				plugin.description = newest_plugin.description || ""
				plugin.plugin_version = newest_plugin.plugin_version || ""
				plugin.plugin_publication_date = newest_plugin.plugin_publication_date
				plugin.plugin_modification_date = newest_plugin.plugin_modification_date
				plugin.vuln_publication_date = newest_plugin.vuln_publication_date
				plugin.cvss_vector = newest_plugin.cvss_vector || ""
				plugin.cvss_base_score = newest_plugin.cvss_base_score
				plugin.cvss_temporal_score = newest_plugin.cvss_temporal_score
				plugin.cvss_temporal_vector = newest_plugin.cvss_temporal_vector
				plugin.risk_factor = newest_plugin.risk_factor
				plugin.solution = newest_plugin.solution
				plugin.synopsis = newest_plugin.synopsis
				plugin.plugin_type = "Rollup"
				plugin.rollup = true

				plugin.save
			end

			#
			def create_item(host_id, severity)
				item = Item.new

					item.host_id = host_id
					item.plugin_id = @info[:plugin_id]
					item.plugin_output = nil
					item.port = 0
					item.severity = severity
					item.plugin_name = @info[:item_name]

				item.save
			end

			#
			def has_reader_findings
				@info[:plugin_ids].each do |plugin_id|
					if Item.where(:plugin_id => plugin_id)
						return true
					end
				end

				return false
			end

			def has_host_reader_findings (host_id)
				@info[:plugin_ids].each do |plugin_id|
					if Item.where(:plugin_id => plugin_id).where(:host_id => host_id).count >= 1
						return true
					end
				end

				return false
			end

			#
			def calculate_severity current_severity, severity
				if severity >= current_severity
					return severity
				else
					return current_severity
				end
			end

			#
			def run
				if !has_reader_findings()
					return
				end

				#Create the dummy plugin
				create_plugin()

				Host.all.each do |host|
					if !has_host_reader_findings(host.id)
						next
					end

					#puts "Found host with reader finding #{host.ip}"

					finding_severity = 0

					@info[:plugin_ids].each do |plugin_id|
						Item.where(:plugin_id => plugin_id).each do |item|
							severity = item.severity
							item.real_severity = severity
							item.severity = -1
							item.save

							finding_severity = calculate_severity(finding_severity, severity)
						end
					end

					create_item(host.id, finding_severity)
				end
			end
		end
	end
end
