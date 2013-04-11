require 'sunlight/congress'

module Sunlight
  module Congress
    class Bill
      attr_accessor :count, :per_page, :current_page, :current_page_count,
                    :num_pages

      def initialize(response, uri)
        @uri                = uri
        @response           = Hashie::Mash.new(response)
        @count              = @response['count']
        @per_page           = @response.page.per_page
        @current_page       = @response.page.page
        @current_page_count = @response.page['count']
        @num_pages          = ((@count / @per_page) + 0.5).round
      end

      def results
        @response.results
      end

      def page(page_num)
        return false unless page_num <= @num_pages

        new_uri = URI("#{@uri}&page=#{page_num}")
        Hashie::Mash.new(JSON.load(Net::HTTP.get(new_uri)))
      end

      def page!(page_num)
        return false unless page_num <= @num_pages

        new_uri = URI("#{@uri}&page=#{page_num}")
        @response = Hashie::Mash.new(JSON.load(Net::HTTP.get(new_uri)))
        @current_page = @response.page.page
        @current_page_count = @response.page['count']
        @response
      end

      def next_page!
        return false unless (@current_page + 1) <= @num_pages

        @current_page += 1
        new_uri = URI("#{@uri}&page=#{@current_page}")
        @response = Hashie::Mash.new(JSON.load(Net::HTTP.get(new_uri)))
        @current_page_count = @response.page['count']
        @response
      end

      def self.search(query, filters = {})
        args = process_filters(filters)
        uri = URI(URI.escape("#{Sunlight::Congress::BASE_URI}/bills/search?query=\"#{query}\"&apikey=#{Sunlight::Congress.api_key}#{args}"))

        new(JSON.load(Net::HTTP.get(uri)), uri)
      end

      def self.by_fields(filters = {})
        args = process_filters(filters)
        uri = URI(URI.escape("#{Sunlight::Congress::BASE_URI}/bills?apikey=#{Sunlight::Congress.api_key}#{args}"))

        new(JSON.load(Net::HTTP.get(uri)), uri)
      end

      def self.by_bill_id(bill_id)
        uri = URI("#{Sunlight::Congress::BASE_URI}/bills?bill_id=#{bill_id}&apikey=#{Sunlight::Congress.api_key}")
        Hashie::Mash.new(JSON.load(Net::HTTP.get(uri))).results.first
      end

      private
      def self.process_filters(filters)
        opts = ""
        if filters.any?
          filters.each do |k,v|
            opts << "&#{k}=#{v}"
          end
        end

        opts
      end
    end
  end
end
