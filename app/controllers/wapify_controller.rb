# encoding: utf-8
require 'rubygems'
require 'typhoeus'
require 'uri'

class WapifyController < ApplicationController

	def index

		json_rsp = Hash.new
		doc_content = Array.new

		begin

		response = Typhoeus::Request.get(params[:url])
		Rails.logger.info "Response code: " + response.code.to_s # http status code
		Rails.logger.info "Response time: " + response.time.to_s # time in seconds the request took
		Rails.logger.info "Response headers: " + response.headers.to_s # the http headers
		# Rails.logger.info "Response body: " + response.body.to_s # the response body
		doc = Nokogiri::HTML(response.body)

		body = doc.at_css("body")
		# Traverse body
		if body != nil
		body.traverse do |node|

		# Check whether node is an img node.
		if node.name == "img"
		node_hash = Hash.new
		node_hash['elementType'] = 'img'
		node_hash['elementContent'] = (get_complete_url node['src'], params[:url])
		doc_content << node_hash
		# Check whether node is a text node. Disregard script nodes.
		elsif node.text? && (node.parent.name != "script")

		# Get content of node (without the tags)
		node_content = node.content

		# Replace non-word characters in node_content with "".
		# After replacing, if node_content == "", disregard.
		if node_content.gsub( /\W/, '' ) != ""
		node_content = node.content

		# Replace carriage returns \r with newlines \n
		node_content = node_content.gsub(/\r/, "\n")

		# Squeeze consecutive \n into a single newline
		node_content = node_content.squeeze("\n")

		# Squeeze consecutive \t into a single tab
		node_content = node_content.squeeze("\t")

		# Remove \n\t opening characters
		# First pass
		if node_content.starts_with? "\n"
		node_content = node_content.sub(/^\n/, '')
		elsif node_content.starts_with? "\t"
		node_content = node_content.sub(/^\t/, '')
		end
		# Second pass!
		if node_content.starts_with? "\n"
		node_content = node_content.sub(/^\n/, '')
		elsif node_content.starts_with? "\t"
		node_content = node_content.sub(/^\t/, '')
		end

		# TODO: Refine code below. Still buggy.
		# Remove \n\t trailing characters
		if node_content.ends_with? "\n"
		node_content = node_content.sub(/^\n/, '')
		elsif node_content.ends_with? "\t"
		node_content = node_content.sub(/^\t/, '')
		end
		# Second pass!
		if node_content.ends_with? "\n"
		node_content = node_content.sub(/^\n/, '')
		elsif node_content.ends_with? "\t"
		node_content = node_content.sub(/^\t/, '')
		end

		node_hash = Hash.new
		node_hash['elementType'] = 'text'
		node_hash['elementContent'] = node_content
		doc_content << node_hash

		end
		end
		end

		# Enumerate contents in log
		if doc_content != nil
		count = 1
		doc_content.each do |content|
		Rails.logger.info "#{count}. " << content.to_s
		count = count + 1
		end
		end

		else
		Rails.logger.info "Response body is null"
		end

		# Nil/"" checking.
		if doc_content != nil
		json_rsp['transcodedSiteContent'] = doc_content
		end

		rescue Exception => e
		Rails.logger.info "Exception: " + e.message
		end

		render :json => json_rsp

	end

	# Helper method
	def get_complete_url img_url, params_url

		# If img url doesn't begin with "http://", pre-append base url
		if !img_url.starts_with?'http://'

			base_url = URI.parse(params_url)
			base_url = base_url.host.to_s

			Rails.logger.info "IMG URL is incomplete: " << img_url
			Rails.logger.info "URL from params: " << params_url
			Rails.logger.info "Base URL: " << base_url

			if base_url != nil && base_url != ""
				img_url = 'http://' + base_url + '/' + img_url
				Rails.logger.info "Complete IMG URL: " << img_url
				else
				Rails.logger.info "Can't parse base url from " + base_url
			end
			
		end

		return img_url

	end

end