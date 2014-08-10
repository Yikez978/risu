# Copyright (c) 2010-2014 Arxopia LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Arxopia LLC nor the names of its contributors
#     	may be used to endorse or promote products derived from this software
#     	without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL ARXOPIA LLC BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.

module Risu
	module Templates
		class HostFindingsCSV < Risu::Base::TemplateBase

			# 
			#
			def initialize ()
				@template_info =
				{
					:name => "host_findings_csv",
					:author => "hammackj",
					:version => "0.0.1",
					:renderer => "CSV",
					:description => "Generates a findings report by host and outputs to CSV"

				}
			end

			# Writes out a CSV block for the risks passed.
			# @param risks, A query from the Plugin model of the risks
			#
			def csv risks
				risks.order(:cvss_base_score).each do |plugin|
					items = Item.where(:plugin_id => plugin.id)

					items.each do |item|
						host = Host.where(:id => item.host_id).first

						@output.text "#{host.ip}, #{item.plugin_name}, #{plugin.risk_factor}"
					end
				end				
			end

			#
			#
			def render(output)
				csv Plugin.critical_risks
			end
		end
	end
end
